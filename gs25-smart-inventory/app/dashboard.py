import os
import pandas as pd
import streamlit as st
from sqlalchemy import create_engine, text

st.set_page_config(page_title="GS25 Smart Inventory", layout="wide")

DB_URL = os.getenv(
    "MYSQL_DATABASE_URL",
    "mysql+pymysql://root:password@localhost:3306/gs25_smart_inventory",
)


@st.cache_resource
def get_engine():
    return create_engine(DB_URL, pool_pre_ping=True)


def load_data(engine):
    stores_df = pd.read_sql(text("SELECT * FROM stores ORDER BY store_id"), engine)
    sales_df = pd.read_sql(
        text("""
            SELECT sl.*, s.store_name, s.district, p.product_name, p.category
            FROM sales sl
            JOIN stores s ON sl.store_id = s.store_id
            JOIN products p ON sl.product_id = p.product_id
        """),
        engine,
    )
    forecasts_df = pd.read_sql(
        text("""
            SELECT df.*, s.store_name, s.district, p.product_name, p.category, p.current_stock
            FROM demand_forecasts df
            JOIN stores s ON df.store_id = s.store_id
            JOIN products p ON df.product_id = p.product_id
        """),
        engine,
    )
    return stores_df, sales_df, forecasts_df


def load_fallback_data():
    stores_df = pd.DataFrame({
        "store_id": [1, 2],
        "store_name": ["GS25 Gangnam Station #1", "GS25 Hongdae Main"],
        "district": ["Gangnam", "Hongdae"],
    })
    sales_df = pd.DataFrame({
        "sale_date": pd.to_datetime(["2026-05-08", "2026-05-09", "2026-05-10", "2026-05-10"]),
        "store_id": [1, 1, 1, 2],
        "product_name": ["Iced Americano RTD", "Iced Americano RTD", "Iced Americano RTD", "Sparkling Citrus Ade"],
        "quantity_sold": [72, 79, 85, 110],
        "discount_pct": [0.0, 0.0, 0.0, 20.0],
        "is_promo": [False, False, False, True],
    })
    forecasts_df = pd.DataFrame({
        "forecast_date": pd.to_datetime(["2026-05-11", "2026-05-11"]),
        "store_id": [1, 2],
        "product_name": ["Iced Americano RTD", "Sparkling Citrus Ade"],
        "category": ["Beverages", "Beverages"],
        "predicted_qty": [92, 125],
        "current_stock": [18, 42],
    })
    return stores_df, sales_df, forecasts_df


st.title("GS25 Smart Inventory & Demand Forecasting")

with st.sidebar:
    st.header("Scenario Controls")
    sim_temp = st.slider("Simulated Temperature (°C)", min_value=-5, max_value=40, value=25)
    promo_boost = st.checkbox("Simulate Active Promotion (+20% Demand)", value=False)
    only_promos = st.checkbox("Filter Historical Sales: Promos Only", value=False)

try:
    engine = get_engine()
    stores_df, sales_df, forecasts_df = load_data(engine)
except Exception as exc:
    st.info(f"Running in standalone preview mode (MySQL offline: {exc}).")
    stores_df, sales_df, forecasts_df = load_fallback_data()

if not stores_df.empty:
    store_labels = {
        f"{row['store_name']} ({row['district']})": int(row["store_id"])
        for _, row in stores_df.iterrows()
    }
    selected_label = st.selectbox("Select Store Branch", list(store_labels.keys()))
    selected_store_id = store_labels[selected_label]

    filtered_sales = sales_df[sales_df["store_id"] == selected_store_id].copy()
    if only_promos and "is_promo" in filtered_sales.columns:
        filtered_sales = filtered_sales[filtered_sales["is_promo"].astype(bool)]

    filtered_fc = forecasts_df[forecasts_df["store_id"] == selected_store_id].copy()
    if not filtered_fc.empty:
        temp_factor = 1.0 + max(sim_temp - 20, 0) * 0.015
        promo_factor = 1.20 if promo_boost else 1.0
        filtered_fc["adjusted_forecast"] = (
            filtered_fc["predicted_qty"] * temp_factor * promo_factor
        ).round().astype(int)
        filtered_fc["recommended_restock"] = (
            filtered_fc["adjusted_forecast"] - filtered_fc["current_stock"]
        ).clip(lower=0)

    col1, col2, col3 = st.columns(3)
    total_hist = int(filtered_sales["quantity_sold"].sum()) if not filtered_sales.empty else 0
    total_pred = int(filtered_fc["adjusted_forecast"].sum()) if not filtered_fc.empty else 0
    restock_alerts = (
        int((filtered_fc["recommended_restock"] > 0).sum())
        if not filtered_fc.empty
        else 0
    )

    col1.metric("Historical Units Sold", total_hist)
    col2.metric(f"Forecasted Demand ({sim_temp}°C)", total_pred)
    col3.metric("Restock Alerts", restock_alerts)

    st.subheader("Forecast & Restock Recommendations")
    st.dataframe(filtered_fc, use_container_width=True)

    st.subheader("Historical Sales & Promotions")
    st.dataframe(filtered_sales, use_container_width=True)
