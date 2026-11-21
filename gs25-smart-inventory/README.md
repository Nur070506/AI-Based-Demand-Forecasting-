# GS25 Smart Inventory & Demand Forecasting System

A relational database and machine learning project built for the **Database Design (2026)** course. The system manages convenience store inventory, daily sales, promotional campaigns, local weather conditions, and AI-driven demand forecasts using **MySQL (3NF)**, **SQLAlchemy**, **scikit-learn (Random Forest)**, and **Streamlit**.

## Repository Structure

```text
gs25-smart-inventory/
├── .env.example                 # Sample database connection configuration
├── .gitignore                   # Standard Python & IDE ignore rules
├── README.md                    # Project documentation and setup guide
├── requirements.txt             # Python dependencies
├── docs/
│   └── schema.dbml              # DBML schema definition for dbdiagram.io
├── sql/
│   ├── 01_schema.sql            # DDL script: 3NF tables, constraints, and indexes
│   ├── 02_seed_data.sql         # DML script: sample stores, products, weather, and promo sales
│   └── 03_queries_alerts.sql    # Restock alert view and analytical SQL queries
├── ml/
│   └── train_forecast.py        # Random Forest training & forecast persistence pipeline
└── app/
    └── dashboard.py             # Interactive Streamlit inventory & demand dashboard
```

## Database Schema (3NF)

1. **`stores`** — Master dimension of retail branches (`store_code`, `store_name`, `district`, `address`).
2. **`products`** — Product catalog with pricing, `current_stock`, and `reorder_level`.
3. **`weather_data`** — Branch-level daily weather metrics using a composite primary key `(weather_date, store_id)`.
4. **`sales`** — Fact table capturing daily unit sales, promotional flags (`is_promo`), `discount_pct`, and `promo_label`.
5. **`demand_forecasts`** — Stores model predictions (`predicted_qty`, `model_version`) per store, product, and target date.

## Setup & Execution

### 1. Initialize the MySQL Database
Run the SQL scripts sequentially in MySQL Workbench or the MySQL CLI:
```bash
mysql -u root -p < sql/01_schema.sql
mysql -u root -p < sql/02_seed_data.sql
mysql -u root -p < sql/03_queries_alerts.sql
```

### 2. Install Python Dependencies
```bash
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

### 3. Configure Database Connection
Copy `.env.example` to `.env` (or export the environment variable):
```bash
export MYSQL_DATABASE_URL="mysql+pymysql://root:your_password@localhost:3306/gs25_smart_inventory"
```

### 4. Generate Demand Forecasts
```bash
python ml/train_forecast.py
```

### 5. Launch the Dashboard
```bash
streamlit run app/dashboard.py
```
