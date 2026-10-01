-- =====================================================
-- COHORT & RETENTION ANALYSIS
-- E-Commerce Revenue, Customer & Operations Analytics
-- =====================================================
-- Cohort analysis tracks groups of customers who share a
-- common characteristic (first purchase month) and measures
-- their behavior over time.
--
-- Methodology:
-- 1. Assign each customer a "cohort month" = month of first purchase
-- 2. For each subsequent order, calculate how many months after
--    the cohort month it occurred (cohort_index)
-- 3. Count distinct active customers per cohort per period
-- 4. Retention % = active_customers / cohort_size × 100
-- =====================================================

-- -------------------------------------------------
-- Full Cohort Retention Query
-- -------------------------------------------------
WITH customer_cohort AS (
    -- Step 1: Determine each customer's cohort (first purchase month)
    SELECT
        c.customer_unique_id,
        MIN(FORMAT(o.order_purchase_timestamp, 'yyyy-MM')) AS cohort_month
    FROM orders_clean o
    JOIN customers_clean c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

cohort_activity AS (
    -- Step 2: Map every order to its customer's cohort
    -- and calculate the cohort_index (months since first purchase)
    SELECT
        cc.customer_unique_id,
        cc.cohort_month,
        FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS order_month,
        DATEDIFF(
            MONTH,
            CAST(cc.cohort_month + '-01' AS DATE),
            CAST(FORMAT(o.order_purchase_timestamp, 'yyyy-MM') + '-01' AS DATE)
        ) AS cohort_index
    FROM orders_clean o
    JOIN customers_clean c ON o.customer_id = c.customer_id
    JOIN customer_cohort cc ON c.customer_unique_id = cc.customer_unique_id
    WHERE o.order_status = 'delivered'
),

cohort_counts AS (
    -- Step 3: Count distinct active customers per cohort per period
    SELECT
        cohort_month,
        cohort_index,
        COUNT(DISTINCT customer_unique_id) AS active_customers
    FROM cohort_activity
    GROUP BY cohort_month, cohort_index
),

cohort_sizes AS (
    -- Step 4: Cohort size = number of customers at index 0
    SELECT cohort_month, active_customers AS cohort_size
    FROM cohort_counts
    WHERE cohort_index = 0
)

-- Step 5: Calculate retention percentage
-- retention_pct = (active in period N / initial cohort size) × 100
SELECT
    cc.cohort_month,
    cs.cohort_size,
    cc.cohort_index,
    cc.active_customers,
    ROUND(100.0 * cc.active_customers / cs.cohort_size, 2) AS retention_pct
FROM cohort_counts cc
JOIN cohort_sizes cs ON cc.cohort_month = cs.cohort_month
WHERE cc.cohort_index BETWEEN 0 AND 12
ORDER BY cc.cohort_month, cc.cohort_index;

-- -------------------------------------------------
-- Summary: Average Retention by Cohort Index
-- Shows the typical retention curve across all cohorts
-- -------------------------------------------------
WITH customer_cohort AS (
    SELECT
        c.customer_unique_id,
        MIN(FORMAT(o.order_purchase_timestamp, 'yyyy-MM')) AS cohort_month
    FROM orders_clean o
    JOIN customers_clean c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
cohort_activity AS (
    SELECT
        cc.customer_unique_id,
        cc.cohort_month,
        DATEDIFF(
            MONTH,
            CAST(cc.cohort_month + '-01' AS DATE),
            CAST(FORMAT(o.order_purchase_timestamp, 'yyyy-MM') + '-01' AS DATE)
        ) AS cohort_index
    FROM orders_clean o
    JOIN customers_clean c ON o.customer_id = c.customer_id
    JOIN customer_cohort cc ON c.customer_unique_id = cc.customer_unique_id
    WHERE o.order_status = 'delivered'
),
cohort_counts AS (
    SELECT cohort_month, cohort_index,
        COUNT(DISTINCT customer_unique_id) AS active_customers
    FROM cohort_activity
    GROUP BY cohort_month, cohort_index
),
cohort_sizes AS (
    SELECT cohort_month, active_customers AS cohort_size
    FROM cohort_counts WHERE cohort_index = 0
),
retention AS (
    SELECT cc.cohort_month, cc.cohort_index,
        ROUND(100.0 * cc.active_customers / cs.cohort_size, 2) AS retention_pct
    FROM cohort_counts cc
    JOIN cohort_sizes cs ON cc.cohort_month = cs.cohort_month
    WHERE cc.cohort_index BETWEEN 1 AND 12
)
SELECT
    cohort_index,
    ROUND(AVG(retention_pct), 2) AS avg_retention_pct,
    COUNT(*) AS cohorts_with_data
FROM retention
GROUP BY cohort_index
ORDER BY cohort_index;
