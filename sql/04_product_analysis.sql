-- =====================================================
-- PRODUCT & SELLER ANALYSIS
-- E-Commerce Revenue, Customer & Operations Analytics
-- =====================================================
-- Key questions:
-- 1. Which categories drive the most revenue?
-- 2. How concentrated is revenue across categories?
-- 3. Which sellers perform best?
-- 4. Which categories have highest/lowest satisfaction?
-- =====================================================

-- -------------------------------------------------
-- Q1: Category Performance with Cumulative Revenue Share
-- Cumulative % shows how few categories account for most revenue
-- (useful for Pareto/80-20 analysis)
-- -------------------------------------------------
WITH category_revenue AS (
    SELECT
        COALESCE(ct.product_category_name_english, p.product_category_name) AS category,
        COUNT(DISTINCT oi.order_id) AS order_count,
        COUNT(DISTINCT oi.product_id) AS product_count,
        ROUND(SUM(oi.price), 2) AS revenue
    FROM order_items_clean oi
    JOIN products_clean p ON oi.product_id = p.product_id
    LEFT JOIN category_translation ct
        ON p.product_category_name = ct.product_category_name
    JOIN orders_clean o ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY COALESCE(ct.product_category_name_english, p.product_category_name)
)
SELECT
    category,
    order_count,
    product_count,
    revenue,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
    ROUND(100.0 * revenue / SUM(revenue) OVER(), 2) AS revenue_share_pct,
    ROUND(
        100.0 * SUM(revenue) OVER (ORDER BY revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
        / SUM(revenue) OVER(), 2
    ) AS cumulative_pct
FROM category_revenue
ORDER BY revenue DESC;

-- -------------------------------------------------
-- Q2: Top 10 Sellers by Revenue
-- ROW_NUMBER() gives a unique sequential rank (no ties)
-- Different from RANK which allows ties
-- -------------------------------------------------
SELECT TOP 10
    oi.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS avg_item_price,
    ROW_NUMBER() OVER (ORDER BY SUM(oi.price) DESC) AS seller_rank
FROM order_items_clean oi
JOIN sellers_clean s ON oi.seller_id = s.seller_id
JOIN orders_clean o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.seller_id, s.seller_city, s.seller_state
ORDER BY total_revenue DESC;

-- -------------------------------------------------
-- Q3: Average Review Score by Category
-- Filters to categories with 50+ reviews for statistical reliability
-- Shows both best and worst-rated categories
-- -------------------------------------------------
WITH category_reviews AS (
    SELECT
        COALESCE(ct.product_category_name_english, p.product_category_name) AS category,
        COUNT(*) AS review_count,
        ROUND(AVG(CAST(r.review_score AS FLOAT)), 2) AS avg_review_score
    FROM reviews_clean r
    JOIN orders_clean o ON r.order_id = o.order_id
    JOIN order_items_clean oi ON o.order_id = oi.order_id
    JOIN products_clean p ON oi.product_id = p.product_id
    LEFT JOIN category_translation ct
        ON p.product_category_name = ct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY COALESCE(ct.product_category_name_english, p.product_category_name)
    HAVING COUNT(*) >= 50
)
SELECT category, review_count, avg_review_score
FROM category_reviews
ORDER BY avg_review_score DESC;

-- -------------------------------------------------
-- Q4: Payment Method Distribution
-- Shows how customers prefer to pay
-- -------------------------------------------------
SELECT
    payment_type,
    COUNT(*) AS transaction_count,
    ROUND(SUM(payment_value), 2) AS total_value,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_transactions,
    ROUND(AVG(payment_installments * 1.0), 1) AS avg_installments
FROM payments_clean p
JOIN orders_clean o ON p.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY payment_type
ORDER BY transaction_count DESC;
