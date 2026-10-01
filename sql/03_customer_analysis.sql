-- =====================================================
-- CUSTOMER ANALYSIS
-- E-Commerce Revenue, Customer & Operations Analytics
-- =====================================================
-- Key questions:
-- 1. What is the repeat vs one-time customer split?
-- 2. How is customer lifetime value distributed?
-- 3. Who are the highest-value customers?
-- 4. How much revenue do repeat customers contribute?
-- =====================================================
-- IMPORTANT NOTE ON CUSTOMER IDs:
-- customer_id = unique per order (anonymized per transaction)
-- customer_unique_id = tracks the same person across orders
-- Always use customer_unique_id for customer-level analysis
-- =====================================================

-- -------------------------------------------------
-- Q1: Repeat vs One-Time Customer Split
-- A repeat customer is someone with more than one order
-- -------------------------------------------------
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count,
        ROUND(SUM(oi.price), 2) AS total_spend
    FROM orders_clean o
    JOIN customers_clean c ON o.customer_id = c.customer_id
    JOIN order_items_clean oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS total_unique_customers,
    SUM(CASE WHEN order_count = 1 THEN 1 ELSE 0 END) AS one_time_customers,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(
        100.0 * SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS repeat_pct
FROM customer_orders;

-- -------------------------------------------------
-- Q2: Customer Lifetime Value (CLV) Distribution by Quartile
-- NTILE(4) divides all customers into 4 equal-sized groups
-- based on their total spend, from lowest (Q1) to highest (Q4)
-- -------------------------------------------------
WITH customer_value AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(oi.price), 2) AS lifetime_value
    FROM orders_clean o
    JOIN customers_clean c ON o.customer_id = c.customer_id
    JOIN order_items_clean oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
quartiled AS (
    SELECT *,
        NTILE(4) OVER (ORDER BY lifetime_value) AS clv_quartile
    FROM customer_value
)
SELECT
    clv_quartile,
    COUNT(*) AS customer_count,
    ROUND(AVG(lifetime_value), 2) AS avg_clv,
    ROUND(MIN(lifetime_value), 2) AS min_clv,
    ROUND(MAX(lifetime_value), 2) AS max_clv,
    ROUND(SUM(lifetime_value), 2) AS quartile_revenue
FROM quartiled
GROUP BY clv_quartile
ORDER BY clv_quartile;

-- -------------------------------------------------
-- Q3: Top 20 Highest-Value Customers
-- DENSE_RANK() assigns ranks without gaps
-- (unlike RANK which skips ranks after ties)
-- -------------------------------------------------
SELECT TOP 20
    c.customer_unique_id,
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS lifetime_value,
    MIN(o.order_purchase_timestamp) AS first_order,
    MAX(o.order_purchase_timestamp) AS last_order,
    DENSE_RANK() OVER (ORDER BY SUM(oi.price) DESC) AS value_rank
FROM orders_clean o
JOIN customers_clean c ON o.customer_id = c.customer_id
JOIN order_items_clean oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id, c.customer_state
ORDER BY lifetime_value DESC;

-- -------------------------------------------------
-- Q4: Revenue Contribution — Repeat vs One-Time Customers
-- Shows whether the 3% repeat customers contribute
-- a disproportionate share of total revenue
-- SUM() OVER() without PARTITION BY gives the grand total
-- -------------------------------------------------
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count,
        ROUND(SUM(oi.price), 2) AS total_spend
    FROM orders_clean o
    JOIN customers_clean c ON o.customer_id = c.customer_id
    JOIN order_items_clean oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    CASE WHEN order_count = 1 THEN 'One-Time' ELSE 'Repeat' END AS customer_type,
    COUNT(*) AS customer_count,
    ROUND(SUM(total_spend), 2) AS total_revenue,
    ROUND(AVG(total_spend), 2) AS avg_spend,
    ROUND(
        100.0 * SUM(total_spend) / SUM(SUM(total_spend)) OVER(), 2
    ) AS revenue_share_pct
FROM customer_orders
GROUP BY CASE WHEN order_count = 1 THEN 'One-Time' ELSE 'Repeat' END;
