-- =====================================================
-- DATA QUALITY CHECKS
-- E-Commerce Revenue, Customer & Operations Analytics
-- =====================================================
-- Purpose: Validate data completeness and integrity
-- before running analytical queries.
-- Run these AFTER executing 00_setup_database.sql.
-- =====================================================

-- -------------------------------------------------
-- Q1: Row counts for each clean table
-- Verifies data was loaded completely
-- -------------------------------------------------
SELECT 'customers_clean' AS table_name, COUNT(*) AS row_count FROM customers_clean
UNION ALL
SELECT 'orders_clean', COUNT(*) FROM orders_clean
UNION ALL
SELECT 'order_items_clean', COUNT(*) FROM order_items_clean
UNION ALL
SELECT 'payments_clean', COUNT(*) FROM payments_clean
UNION ALL
SELECT 'products_clean', COUNT(*) FROM products_clean
UNION ALL
SELECT 'sellers_clean', COUNT(*) FROM sellers_clean
UNION ALL
SELECT 'reviews_clean', COUNT(*) FROM reviews_clean;

-- -------------------------------------------------
-- Q2: Null rates for critical columns in orders table
-- Delivery date nulls are expected for non-delivered orders,
-- but purchase timestamp nulls would indicate data issues
-- -------------------------------------------------
SELECT
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS null_purchase_ts,
    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS null_approved,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS null_delivery_date,
    SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS null_estimated_date,
    ROUND(
        100.0 * SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END)
        / COUNT(*), 2
    ) AS pct_null_delivery
FROM orders_clean;

-- -------------------------------------------------
-- Q3: Check for duplicate order_ids in orders table
-- orders table grain: one row per order_id
-- If duplicates exist, downstream JOINs will inflate revenue
-- -------------------------------------------------
SELECT order_id, COUNT(*) AS cnt
FROM orders_clean
GROUP BY order_id
HAVING COUNT(*) > 1;

-- -------------------------------------------------
-- Q4: Order date range and status distribution
-- Uses window function to compute percentage per status
-- -------------------------------------------------
SELECT
    MIN(order_purchase_timestamp) AS earliest_order,
    MAX(order_purchase_timestamp) AS latest_order,
    DATEDIFF(DAY, MIN(order_purchase_timestamp), MAX(order_purchase_timestamp)) AS date_span_days
FROM orders_clean;

SELECT
    order_status,
    COUNT(*) AS order_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct
FROM orders_clean
GROUP BY order_status
ORDER BY order_count DESC;

-- -------------------------------------------------
-- Q5: Check for orphan records
-- order_items should reference valid order_ids and product_ids
-- -------------------------------------------------
SELECT COUNT(*) AS orphan_order_items
FROM order_items_clean oi
LEFT JOIN orders_clean o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS orphan_products
FROM order_items_clean oi
LEFT JOIN products_clean p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;
