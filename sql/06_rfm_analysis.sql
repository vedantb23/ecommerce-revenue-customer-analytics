-- =====================================================
-- RFM CUSTOMER SEGMENTATION
-- E-Commerce Revenue, Customer & Operations Analytics
-- =====================================================
-- RFM (Recency, Frequency, Monetary) is a customer
-- segmentation technique used in marketing analytics.
--
-- Recency (R)  = Days since last purchase (lower = better)
-- Frequency (F) = Number of orders placed (higher = better)
-- Monetary (M)  = Total amount spent (higher = better)
--
-- Methodology:
-- 1. Calculate raw R, F, M values per customer
-- 2. Score each dimension 1-5 using NTILE(5)
-- 3. Map score combinations to named business segments
--    using CASE expressions
-- =====================================================

-- -------------------------------------------------
-- Full RFM Pipeline in a Single Query
-- Uses chained CTEs to build the analysis step by step
-- -------------------------------------------------

-- Step 1: Calculate raw RFM metrics per customer
WITH rfm_base AS (
    SELECT
        c.customer_unique_id,
        DATEDIFF(
            DAY,
            MAX(o.order_purchase_timestamp),
            (SELECT MAX(order_purchase_timestamp) FROM orders_clean)
        ) AS recency,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(oi.price), 2) AS monetary
    FROM orders_clean o
    JOIN customers_clean c ON o.customer_id = c.customer_id
    JOIN order_items_clean oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

-- Step 2: Assign 1-5 scores using NTILE
-- NTILE(5) divides the ordered set into 5 roughly equal buckets
-- For Recency: ORDER BY DESC so lowest recency (most recent) gets score 5
-- For Frequency & Monetary: ORDER BY ASC so highest values get score 5
rfm_scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
),

-- Step 3: Map score combinations to named segments
-- These segment names are standard in marketing analytics
rfm_segments AS (
    SELECT *,
        r_score + f_score + m_score AS rfm_total,
        CASE
            -- Best customers: recent, frequent, high-spending
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
                THEN 'Champions'
            -- Consistent buyers with good overall scores
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3
                THEN 'Loyal Customers'
            -- Recently purchased but low frequency — could become loyal
            WHEN r_score >= 4 AND f_score <= 2
                THEN 'New Customers'
            -- Decent across dimensions, worth nurturing
            WHEN r_score >= 3 AND f_score >= 1 AND m_score >= 2
                THEN 'Potential Loyalists'
            -- Were active but haven't purchased recently
            WHEN r_score <= 2 AND f_score >= 3
                THEN 'At Risk'
            -- Low on all dimensions
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2
                THEN 'Lost / Low Value'
            ELSE 'Needs Attention'
        END AS segment
    FROM rfm_scored
)

-- Step 4: Segment summary with key metrics
SELECT
    segment,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_customers,
    ROUND(AVG(recency), 0) AS avg_recency_days,
    ROUND(AVG(CAST(frequency AS FLOAT)), 2) AS avg_frequency,
    ROUND(AVG(monetary), 2) AS avg_monetary,
    ROUND(SUM(monetary), 2) AS total_revenue
FROM rfm_segments
GROUP BY segment
ORDER BY total_revenue DESC;

-- -------------------------------------------------
-- Optional: Detailed RFM output for Power BI
-- Exports individual customer-level RFM data
-- -------------------------------------------------
-- Uncomment below to create a view for Power BI:
/*
CREATE VIEW vw_rfm_segments AS
WITH rfm_base AS (
    SELECT c.customer_unique_id,
        DATEDIFF(DAY, MAX(o.order_purchase_timestamp),
            (SELECT MAX(order_purchase_timestamp) FROM orders_clean)) AS recency,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(oi.price), 2) AS monetary
    FROM orders_clean o
    JOIN customers_clean c ON o.customer_id = c.customer_id
    JOIN order_items_clean oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
)
SELECT *,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
        WHEN r_score >= 3 AND f_score >= 1 AND m_score >= 2 THEN 'Potential Loyalists'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Lost / Low Value'
        ELSE 'Needs Attention'
    END AS segment
FROM rfm_scored;
*/
