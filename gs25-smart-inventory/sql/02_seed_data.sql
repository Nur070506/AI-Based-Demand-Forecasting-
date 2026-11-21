-- ============================================================================
-- GS25 Smart Inventory Management System - Seed Data
-- ============================================================================

USE gs25_smart_inventory;

INSERT INTO stores (store_code, store_name, district, address) VALUES
('GS25-001', 'GS25 Gangnam Station #1', 'Gangnam', 'Gangnam-daero, Gangnam-gu, Seoul'),
('GS25-002', 'GS25 Hongdae Main', 'Hongdae', 'Yanghwa-ro, Mapo-gu, Seoul'),
('GS25-003', 'GS25 Itaewon Central', 'Itaewon', 'Itaewon-ro, Yongsan-gu, Seoul'),
('GS25-004', 'GS25 Myeongdong Street', 'Myeong-dong', 'Myeongdong-gil, Jung-gu, Seoul');

INSERT INTO products (sku_code, product_name, category, unit_price, current_stock, reorder_level) VALUES
('BEV-001', 'Iced Americano RTD', 'Beverages', 2500.00, 18, 25),
('BEV-002', 'Sparkling Citrus Ade', 'Beverages', 2200.00, 42, 20),
('SNK-001', 'Honey Butter Chips', 'Snacks', 1800.00, 9, 15),
('FOD-001', 'Tuna Mayo Triangle Kimbap', 'Fresh Food', 1600.00, 12, 20),
('PRM-001', '1+1 Energy Drink Pack', 'Promotions', 3000.00, 6, 15);

INSERT INTO weather_data (weather_date, store_id, temperature_c, precipitation_mm, humidity_pct, is_holiday) VALUES
('2026-05-08', 1, 23.40, 0.00, 54.00, FALSE),
('2026-05-09', 1, 25.10, 0.00, 56.00, FALSE),
('2026-05-10', 1, 26.50, 0.00, 58.00, FALSE),
('2026-05-10', 2, 27.10, 0.00, 55.00, FALSE),
('2026-05-10', 3, 25.80, 1.20, 62.00, FALSE),
('2026-05-10', 4, 24.90, 0.00, 60.00, FALSE);

INSERT INTO sales (sale_date, store_id, product_id, quantity_sold, unit_sale_price, discount_pct, is_promo, promo_label) VALUES
('2026-05-08', 1, 1, 72, 2500.00, 0.00, FALSE, NULL),
('2026-05-09', 1, 1, 79, 2500.00, 0.00, FALSE, NULL),
('2026-05-10', 1, 1, 85, 2500.00, 0.00, FALSE, NULL),
('2026-05-10', 2, 2, 110, 1760.00, 20.00, TRUE, 'Weekend Beverage Promo'),
('2026-05-10', 3, 3, 45, 1800.00, 0.00, FALSE, NULL),
('2026-05-10', 4, 5, 64, 1500.00, 50.00, TRUE, '1+1 Promo');

INSERT INTO demand_forecasts (forecast_date, store_id, product_id, predicted_qty, model_version) VALUES
('2026-05-11', 1, 1, 92, 'rf_regressor_v1'),
('2026-05-11', 2, 2, 125, 'rf_regressor_v1'),
('2026-05-11', 3, 3, 38, 'rf_regressor_v1'),
('2026-05-11', 4, 5, 70, 'rf_regressor_v1');
