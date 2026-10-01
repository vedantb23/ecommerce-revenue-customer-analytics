-- =====================================================
-- REVENUE ANALYSIS
-- E-Commerce Revenue, Customer & Operations Analytics
-- =====================================================
-- Key questions:
-- 1. What are the headline revenue KPIs?
-- 2. What is the monthly revenue trend?
-- 3. What is AOV and its distribution?
-- 4. Which categories generate the most revenue?
-- 5. Which states drive the most revenue?
-- =====================================================

-- -------------------------------------------------
-- Q1: Headline Revenue KPIs
-- Filters to delivered orders only to avoid counting
-- cancelled/unavailable orders in revenue
-- -------------------------------------------------
SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT c.customer_unique_id) AS total_customers,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(SUM(oi.freight_value), 2) AS total_freight,
    ROUND(SUM(oi.price) + SUM(oi.freight_value), 2) AS total_gmv,
    ROUND(AVG(oi.price), 2) AS avg_item_price
FROM orders_clean o
JOIN order_items_clean oi ON o.order_id = oi.order_id
JOIN customers_clean c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered';

-- -------------------------------------------------
-- Q2: Monthly Revenue Trend with Month-over-Month Growth
-- LAG() window function compares each month to previous month
-- This shows growth trajectory and seasonal patterns
-- -------------------------------------------------
WITH monthly_revenue AS (
    SELECT
        FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS order_month,
        ROUND(SUM(oi.price), 2) AS revenue,
        COUNT(DISTINCT o.order_id) AS orders
    FROM orders_clean o
    JOIN order_items_clean oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY FORMAT(o.order_purchase_timestamp, 'yyyy-MM')
)
SELECT
    order_month,
    revenue,
    orders,
    LAG(revenue) OVER (ORDER BY order_month) AS prev_month_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY order_month))
        / NULLIF(LAG(revenue) OVER (ORDER BY order_month), 0),
    2) AS mom_growth_pct
FROM monthly_revenue
ORDER BY order_month;

-- -------------------------------------------------
-- Q3: Average Order Value (AOV) Distribution
-- AOV is calculated at the ORDER level, not the item level
-- An order can contain multiple items, so we sum price per order first
-- -------------------------------------------------
WITH order_totals AS (
    SELECT
        oi.order_id,
        SUM(oi.price) AS order_revenue
    FROM order_items_clean oi
    JOIN orders_clean o ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.order_id
)
SELECT
    COUNT(*) AS total_orders,
    ROUND(AVG(order_revenue), 2) AS avg_order_value,
    ROUND(MIN(order_revenue), 2) AS min_order_value,
    ROUND(MAX(order_revenue), 2) AS max_order_value,
    ROUND(STDEV(order_revenue), 2) AS std_order_value
FROM order_totals;

-- -------------------------------------------------
-- Q4: Top 10 Revenue-Generating Product Categories
-- Joins category_translation to get English category names
-- RANK() handles ties (two categories with same revenue get same rank)
-- -------------------------------------------------
SELECT TOP 10
    COALESCE(ct.product_category_name_english, p.product_category_name) AS category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS avg_price,
    RANK() OVER (ORDER BY SUM(oi.price) DESC) AS revenue_rank
FROM order_items_clean oi
JOIN products_clean p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
JOIN orders_clean o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY COALESCE(ct.product_category_name_english, p.product_category_name)
ORDER BY total_revenue DESC;

-- -------------------------------------------------
-- Q5: Revenue by Customer State (Top 10)
-- Shows geographic revenue concentration
-- SUM() OVER() calculates grand total for percentage calculation
-- -------------------------------------------------
SELECT TOP 10
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(
        100.0 * SUM(oi.price) / SUM(SUM(oi.price)) OVER(), 2
    ) AS revenue_share_pct
FROM orders_clean o
JOIN customers_clean c ON o.customer_id = c.customer_id
JOIN order_items_clean oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_revenue DESC;
