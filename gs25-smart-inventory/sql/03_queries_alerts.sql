-- ============================================================================
-- GS25 Smart Inventory - Restock Alerts & Analytical Queries
-- ============================================================================

USE gs25_smart_inventory;

-- 1. View: Restock alerts comparing predicted demand against current store inventory
CREATE OR REPLACE VIEW vw_restock_alerts AS
SELECT
    s.store_code,
    s.store_name,
    s.district,
    p.sku_code,
    p.product_name,
    p.category,
    p.current_stock,
    df.forecast_date,
    df.predicted_qty,
    GREATEST(df.predicted_qty - p.current_stock, 0) AS recommended_restock_qty,
    CASE
        WHEN df.predicted_qty > p.current_stock THEN 'RESTOCK NEEDED'
        ELSE 'OK'
    END AS stock_status
FROM demand_forecasts df
JOIN stores s ON df.store_id = s.store_id
JOIN products p ON df.product_id = p.product_id;

SELECT * FROM vw_restock_alerts
ORDER BY forecast_date, store_code, recommended_restock_qty DESC;

-- 2. Analytical Query: Promotional vs. non-promotional sales lift by district
SELECT
    s.district,
    sl.is_promo,
    COUNT(*) AS transactions_count,
    SUM(sl.quantity_sold) AS total_units_sold,
    ROUND(AVG(sl.discount_pct), 2) AS avg_discount_pct,
    SUM(sl.quantity_sold * sl.unit_sale_price) AS gross_revenue
FROM sales sl
JOIN stores s ON sl.store_id = s.store_id
GROUP BY s.district, sl.is_promo
ORDER BY s.district, sl.is_promo DESC;

-- 3. Analytical Query: Discount recommendation candidates (high stock, low forecast)
SELECT
    p.sku_code,
    p.product_name,
    p.category,
    p.current_stock,
    COALESCE(SUM(df.predicted_qty), 0) AS total_forecasted_demand,
    (p.current_stock - COALESCE(SUM(df.predicted_qty), 0)) AS projected_surplus
FROM products p
LEFT JOIN demand_forecasts df ON p.product_id = df.product_id
GROUP BY p.product_id, p.sku_code, p.product_name, p.category, p.current_stock
HAVING projected_surplus > 10
ORDER BY projected_surplus DESC;
