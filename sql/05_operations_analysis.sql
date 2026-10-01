-- =====================================================
-- DELIVERY & OPERATIONS ANALYSIS
-- E-Commerce Revenue, Customer & Operations Analytics
-- =====================================================
-- Key questions:
-- 1. What is the average delivery time?
-- 2. What percentage of orders are delivered late?
-- 3. Does late delivery affect customer satisfaction?
-- 4. Which states have the worst delivery performance?
-- =====================================================

-- -------------------------------------------------
-- Q1: Delivery Time KPIs
-- delivery_days = actual delivery date - purchase date
-- late = delivered after the estimated delivery date
-- Only includes orders with both dates available
-- -------------------------------------------------
SELECT
    COUNT(*) AS delivered_orders,
    ROUND(AVG(
        DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)
    ), 1) AS avg_delivery_days,
    ROUND(AVG(
        DATEDIFF(DAY, order_purchase_timestamp, order_estimated_delivery_date)
    ), 1) AS avg_estimated_days,
    SUM(CASE
        WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1
        ELSE 0
    END) AS late_deliveries,
    ROUND(100.0 * SUM(CASE
        WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1
        ELSE 0
    END) / COUNT(*), 2) AS late_delivery_pct
FROM orders_clean
WHERE order_status = 'delivered'
    AND order_delivered_customer_date IS NOT NULL
    AND order_estimated_delivery_date IS NOT NULL;

-- -------------------------------------------------
-- Q2: Does Late Delivery Affect Review Scores?
-- Compares average review score for on-time vs late deliveries
-- Also tracks % of low reviews (score 1-2) in each group
-- -------------------------------------------------
WITH delivery_review AS (
    SELECT
        o.order_id,
        CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 'Late'
            ELSE 'On Time'
        END AS delivery_status,
        r.review_score
    FROM orders_clean o
    JOIN reviews_clean r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
)
SELECT
    delivery_status,
    COUNT(*) AS order_count,
    ROUND(AVG(CAST(review_score AS FLOAT)), 2) AS avg_review_score,
    SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) AS low_reviews,
    ROUND(
        100.0 * SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS pct_low_reviews
FROM delivery_review
GROUP BY delivery_status;

-- -------------------------------------------------
-- Q3: Delivery Performance by Customer State
-- Identifies states with longest delivery times and highest late %
-- Useful for logistics optimization
-- -------------------------------------------------
SELECT
    c.customer_state,
    COUNT(*) AS order_count,
    ROUND(AVG(
        DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)
    ), 1) AS avg_delivery_days,
    ROUND(100.0 * SUM(CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1
        ELSE 0
    END) / COUNT(*), 2) AS late_pct,
    RANK() OVER (ORDER BY
        100.0 * SUM(CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1
            ELSE 0
        END) / COUNT(*) DESC
    ) AS worst_delivery_rank
FROM orders_clean o
JOIN customers_clean c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY order_count DESC;

-- -------------------------------------------------
-- Q4: Review Score Distribution
-- Overall satisfaction profile of the marketplace
-- -------------------------------------------------
SELECT
    review_score,
    COUNT(*) AS review_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct
FROM reviews_clean
GROUP BY review_score
ORDER BY review_score;
