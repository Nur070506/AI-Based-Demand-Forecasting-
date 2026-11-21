-- ============================================================================
-- GS25 Smart Inventory Management System - Relational Schema (3NF, MySQL)
-- Subject: Database Design (2026)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS gs25_smart_inventory
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE gs25_smart_inventory;

-- Drop tables in reverse dependency order for clean re-runs
DROP TABLE IF EXISTS demand_forecasts;
DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS weather_data;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS stores;

-- 1. Stores (Master dimension for convenience store branches)
CREATE TABLE stores (
    store_id      INT AUTO_INCREMENT PRIMARY KEY,
    store_code    VARCHAR(30) NOT NULL UNIQUE,
    store_name    VARCHAR(120) NOT NULL,
    district      VARCHAR(80) NOT NULL,
    address       VARCHAR(255) NULL,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Products (Catalog of items sold across branches)
CREATE TABLE products (
    product_id    INT AUTO_INCREMENT PRIMARY KEY,
    sku_code      VARCHAR(40) NOT NULL UNIQUE,
    product_name  VARCHAR(150) NOT NULL,
    category      VARCHAR(80) NOT NULL,
    unit_price    DECIMAL(10, 2) NOT NULL CHECK (unit_price >= 0),
    current_stock INT NOT NULL DEFAULT 0 CHECK (current_stock >= 0),
    reorder_level INT NOT NULL DEFAULT 10 CHECK (reorder_level >= 0),
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. Weather Data (Composite PK: weather_date + store_id for branch-level granularity)
CREATE TABLE weather_data (
    weather_date       DATE NOT NULL,
    store_id           INT NOT NULL,
    temperature_c      DECIMAL(5, 2) NOT NULL,
    precipitation_mm   DECIMAL(6, 2) NOT NULL DEFAULT 0.00,
    humidity_pct       DECIMAL(5, 2) NULL,
    is_holiday         BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (weather_date, store_id),
    CONSTRAINT fk_weather_store FOREIGN KEY (store_id)
        REFERENCES stores(store_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 4. Sales (Fact table tracking daily sales, promotions, and discounts)
CREATE TABLE sales (
    sale_id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    sale_date        DATE NOT NULL,
    store_id         INT NOT NULL,
    product_id       INT NOT NULL,
    quantity_sold    INT NOT NULL CHECK (quantity_sold > 0),
    unit_sale_price  DECIMAL(10, 2) NOT NULL CHECK (unit_sale_price >= 0),
    discount_pct     DECIMAL(5, 2) NOT NULL DEFAULT 0.00 CHECK (discount_pct BETWEEN 0.00 AND 100.00),
    is_promo         BOOLEAN NOT NULL DEFAULT FALSE,
    promo_label      VARCHAR(100) NULL,
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sales_store FOREIGN KEY (store_id)
        REFERENCES stores(store_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_sales_product FOREIGN KEY (product_id)
        REFERENCES products(product_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 5. Demand Forecasts (Machine Learning / Random Forest prediction storage)
CREATE TABLE demand_forecasts (
    forecast_id      BIGINT AUTO_INCREMENT PRIMARY KEY,
    forecast_date    DATE NOT NULL,
    store_id         INT NOT NULL,
    product_id       INT NOT NULL,
    predicted_qty    INT NOT NULL CHECK (predicted_qty >= 0),
    model_version    VARCHAR(50) NOT NULL DEFAULT 'rf_regressor_v1',
    generated_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_forecast_slot (forecast_date, store_id, product_id, model_version),
    CONSTRAINT fk_forecast_store FOREIGN KEY (store_id)
        REFERENCES stores(store_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_forecast_product FOREIGN KEY (product_id)
        REFERENCES products(product_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Performance Indexes
CREATE INDEX idx_sales_date_store ON sales(sale_date, store_id);
CREATE INDEX idx_sales_product_date ON sales(product_id, sale_date);
CREATE INDEX idx_forecasts_date_store ON demand_forecasts(forecast_date, store_id);
