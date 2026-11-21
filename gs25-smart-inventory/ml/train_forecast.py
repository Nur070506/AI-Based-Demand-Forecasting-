import os
import numpy as np
import pandas as pd
from sqlalchemy import create_engine, text
from sklearn.ensemble import RandomForestRegressor

DB_URL = os.getenv(
    "MYSQL_DATABASE_URL",
    "mysql+pymysql://root:password@localhost:3306/gs25_smart_inventory",
)

FEATURE_COLS = [
    "store_id",
    "product_id",
    "day_of_week",
    "month_num",
    "temperature_c",
    "precipitation_mm",
    "is_promo",
    "discount_pct",
]


def get_engine():
    return create_engine(DB_URL, pool_pre_ping=True)


def fetch_training_data(engine) -> pd.DataFrame:
    query = text("""
        SELECT
            sl.sale_date,
            sl.store_id,
            sl.product_id,
            sl.quantity_sold,
            CAST(sl.is_promo AS SIGNED) AS is_promo,
            sl.discount_pct,
            DAYOFWEEK(sl.sale_date) AS day_of_week,
            MONTH(sl.sale_date) AS month_num,
            COALESCE(wd.temperature_c, 20.0) AS temperature_c,
            COALESCE(wd.precipitation_mm, 0.0) AS precipitation_mm
        FROM sales sl
        LEFT JOIN weather_data wd
            ON sl.sale_date = wd.weather_date
           AND sl.store_id = wd.store_id
    """)
    return pd.read_sql(query, engine)


def build_synthetic_training_data() -> pd.DataFrame:
    rng = np.random.default_rng(42)
    df = pd.DataFrame({
        "store_id": rng.integers(1, 5, size=200),
        "product_id": rng.integers(1, 6, size=200),
        "day_of_week": rng.integers(1, 8, size=200),
        "month_num": rng.integers(1, 13, size=200),
        "temperature_c": rng.uniform(2.0, 35.0, size=200),
        "precipitation_mm": rng.choice([0.0, 0.0, 0.0, 3.0, 12.0], size=200),
        "is_promo": rng.integers(0, 2, size=200),
        "discount_pct": rng.choice([0.0, 10.0, 20.0, 50.0], size=200),
    })
    df["quantity_sold"] = (
        30
        + np.maximum(df["temperature_c"] - 16.0, 0) * 1.9
        + df["is_promo"] * 24
        + (df["discount_pct"] * 0.35)
        + np.isin(df["day_of_week"], [1, 7]) * 14
        - (df["precipitation_mm"] * 0.8)
        + rng.normal(0, 4, size=200)
    ).clip(min=5).round().astype(int)
    return df


def train_and_forecast(
    horizon_days: int = 7,
    sim_temp_c: float = 24.0,
    sim_promo: bool = False,
    sim_discount_pct: float = 0.0,
    model_version: str = "rf_regressor_v1",
) -> pd.DataFrame:
    engine = get_engine()
    try:
        df = fetch_training_data(engine)
        db_available = True
    except Exception:
        df = pd.DataFrame()
        db_available = False

    if df.empty or len(df) < 15:
        df = build_synthetic_training_data()

    model = RandomForestRegressor(n_estimators=150, random_state=42)
    model.fit(df[FEATURE_COLS], df["quantity_sold"])

    future_dates = pd.date_range(
        start=pd.Timestamp.today().normalize() + pd.Timedelta(days=1),
        periods=horizon_days,
        freq="D",
    )
    stores = sorted(df["store_id"].unique())
    products = sorted(df["product_id"].unique())

    rows = []
    for dt in future_dates:
        for st in stores:
            for pr in products:
                rows.append({
                    "forecast_date": dt.date(),
                    "store_id": int(st),
                    "product_id": int(pr),
                    "day_of_week": int(dt.dayofweek + 1),
                    "month_num": int(dt.month),
                    "temperature_c": float(sim_temp_c),
                    "precipitation_mm": 0.0,
                    "is_promo": int(sim_promo),
                    "discount_pct": float(sim_discount_pct if sim_promo else 0.0),
                })

    pred_df = pd.DataFrame(rows)
    pred_df["predicted_qty"] = np.clip(
        np.round(model.predict(pred_df[FEATURE_COLS])), 0, None
    ).astype(int)
    pred_df["model_version"] = model_version

    if db_available:
        with engine.begin() as conn:
            conn.execute(
                text("DELETE FROM demand_forecasts WHERE model_version = :mv"),
                {"mv": model_version},
            )
            save_cols = [
                "forecast_date",
                "store_id",
                "product_id",
                "predicted_qty",
                "model_version",
            ]
            pred_df[save_cols].to_sql(
                "demand_forecasts", conn, if_exists="append", index=False
            )

    return pred_df


if __name__ == "__main__":
    forecasts = train_and_forecast(horizon_days=7)
    print(f"Generated {len(forecasts)} demand forecast rows.")
