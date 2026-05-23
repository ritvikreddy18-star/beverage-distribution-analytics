-- ============================================================
-- Beverage Distribution Performance & Channel Analytics
-- Tool: PostgreSQL
-- Author: Ritvik Reddy Jillella
-- Dataset: Retail & Warehouse Sales — 30,000 records
-- Period: January 2020 – September 2020
-- ============================================================


-- ============================================================
-- SECTION 0: TABLE SETUP & DATA IMPORT
-- ============================================================

DROP TABLE IF EXISTS retail_warehouse_sales;

CREATE TABLE retail_warehouse_sales (
    year                INTEGER,
    month               INTEGER,
    supplier            VARCHAR(200),
    item_code           INTEGER,
    item_description    VARCHAR(300),
    item_type           VARCHAR(50),
    retail_sales        NUMERIC(12,3),
    retail_transfers    NUMERIC(12,3),
    warehouse_sales     NUMERIC(12,3)
);

-- Import: pgAdmin → right-click table → Import/Export Data
-- File: Retail_and_wherehouse_Sale.csv | Delimiter: , | Header: ON


-- ============================================================
-- SECTION 1: DATA QUALITY & EXPLORATION
-- ============================================================

-- 1.1 Record count and completeness check
SELECT
    COUNT(*)                                            AS total_records,
    COUNT(DISTINCT supplier)                            AS unique_suppliers,
    COUNT(DISTINCT item_code)                           AS unique_items,
    COUNT(DISTINCT item_type)                           AS product_categories,
    MIN(month)                                          AS first_month,
    MAX(month)                                          AS last_month,
    SUM(CASE WHEN supplier IS NULL THEN 1 ELSE 0 END)  AS null_suppliers,
    SUM(CASE WHEN retail_sales IS NULL THEN 1 ELSE 0 END) AS null_retail_sales
FROM retail_warehouse_sales;

-- 1.2 Distribution by product category
SELECT
    item_type,
    COUNT(*)                                            AS record_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct_of_total
FROM retail_warehouse_sales
GROUP BY item_type
ORDER BY record_count DESC;

-- 1.3 Fix negative values — treat as data corrections/returns
-- Flag records with negative sales for awareness
SELECT
    COUNT(*) AS negative_retail_records,
    SUM(retail_sales) AS total_negative_retail_value
FROM retail_warehouse_sales
WHERE retail_sales < 0;

SELECT
    COUNT(*) AS negative_warehouse_records,
    SUM(warehouse_sales) AS total_negative_warehouse_value
FROM retail_warehouse_sales
WHERE warehouse_sales < 0;


-- ============================================================
-- SECTION 2: BASELINE KPI DASHBOARD
-- ============================================================

-- 2.1 Overall business KPIs
SELECT
    ROUND(SUM(retail_sales), 0)                                     AS total_retail_sales,
    ROUND(SUM(warehouse_sales), 0)                                  AS total_warehouse_sales,
    ROUND(SUM(retail_transfers), 0)                                 AS total_retail_transfers,
    ROUND(SUM(retail_sales) + SUM(warehouse_sales), 0)              AS total_revenue,
    ROUND(AVG(retail_sales), 2)                                     AS avg_retail_sales_per_sku,
    ROUND(AVG(warehouse_sales), 2)                                  AS avg_warehouse_sales_per_sku,
    ROUND(SUM(retail_sales) * 100.0 /
          NULLIF(SUM(retail_sales) + SUM(warehouse_sales), 0), 1)  AS retail_channel_share_pct,
    ROUND(SUM(warehouse_sales) * 100.0 /
          NULLIF(SUM(retail_sales) + SUM(warehouse_sales), 0), 1)  AS warehouse_channel_share_pct
FROM retail_warehouse_sales
WHERE retail_sales >= 0 AND warehouse_sales >= 0;

-- 2.2 KPIs by product category
SELECT
    item_type,
    ROUND(SUM(retail_sales), 0)         AS total_retail_sales,
    ROUND(SUM(warehouse_sales), 0)      AS total_warehouse_sales,
    ROUND(SUM(retail_transfers), 0)     AS total_retail_transfers,
    ROUND(SUM(retail_sales) + SUM(warehouse_sales), 0) AS total_revenue,
    ROUND(SUM(retail_sales) * 100.0 /
          NULLIF(SUM(retail_sales) + SUM(warehouse_sales), 0), 1) AS retail_pct,
    COUNT(DISTINCT item_code)           AS unique_skus,
    COUNT(DISTINCT supplier)            AS unique_suppliers
FROM retail_warehouse_sales
WHERE retail_sales >= 0 AND warehouse_sales >= 0
GROUP BY item_type
ORDER BY total_revenue DESC;


-- ============================================================
-- SECTION 3: CHANNEL PERFORMANCE ANALYSIS
-- ============================================================

-- 3.1 Retail vs Warehouse channel comparison by category
SELECT
    item_type,
    ROUND(SUM(retail_sales), 0)                         AS retail_sales,
    ROUND(SUM(warehouse_sales), 0)                      AS warehouse_sales,
    ROUND(SUM(retail_sales) - SUM(warehouse_sales), 0)  AS retail_vs_warehouse_gap,
    CASE
        WHEN SUM(retail_sales) > SUM(warehouse_sales) THEN 'Retail-Dominant'
        WHEN SUM(warehouse_sales) > SUM(retail_sales) THEN 'Warehouse-Dominant'
        ELSE 'Balanced'
    END AS channel_dominance
FROM retail_warehouse_sales
WHERE retail_sales >= 0 AND warehouse_sales >= 0
GROUP BY item_type
ORDER BY warehouse_sales DESC;

-- 3.2 Retail transfer rate by category
-- High transfer rate = inventory moving from warehouse to retail shelves
SELECT
    item_type,
    ROUND(SUM(retail_transfers), 0)     AS total_transfers,
    ROUND(SUM(retail_sales), 0)         AS total_retail_sales,
    ROUND(SUM(retail_transfers) * 100.0 /
          NULLIF(SUM(retail_sales), 0), 1) AS transfer_to_sales_ratio_pct
FROM retail_warehouse_sales
WHERE retail_sales > 0
GROUP BY item_type
ORDER BY transfer_to_sales_ratio_pct DESC;

-- 3.3 Channel efficiency score per supplier (top 20)
SELECT
    supplier,
    ROUND(SUM(retail_sales), 0)         AS retail_sales,
    ROUND(SUM(warehouse_sales), 0)      AS warehouse_sales,
    ROUND(SUM(retail_sales) + SUM(warehouse_sales), 0) AS total_revenue,
    ROUND(SUM(retail_sales) * 100.0 /
          NULLIF(SUM(retail_sales) + SUM(warehouse_sales), 0), 1) AS retail_channel_pct
FROM retail_warehouse_sales
WHERE retail_sales >= 0 AND warehouse_sales >= 0
  AND supplier IS NOT NULL
GROUP BY supplier
HAVING SUM(retail_sales) + SUM(warehouse_sales) > 0
ORDER BY total_revenue DESC
LIMIT 20;


-- ============================================================
-- SECTION 4: SUPPLIER PERFORMANCE ANALYSIS
-- ============================================================

-- 4.1 Full supplier performance ranking
SELECT
    supplier,
    COUNT(DISTINCT item_code)               AS unique_skus,
    ROUND(SUM(retail_sales), 0)             AS total_retail_sales,
    ROUND(SUM(warehouse_sales), 0)          AS total_warehouse_sales,
    ROUND(SUM(retail_sales) + SUM(warehouse_sales), 0) AS total_revenue,
    ROUND(AVG(retail_sales + warehouse_sales), 2)      AS avg_revenue_per_sku
FROM retail_warehouse_sales
WHERE retail_sales >= 0 AND warehouse_sales >= 0
  AND supplier IS NOT NULL
GROUP BY supplier
ORDER BY total_revenue DESC;

-- 4.2 Top 10 suppliers by total revenue with performance tier
SELECT
    supplier,
    ROUND(SUM(retail_sales) + SUM(warehouse_sales), 0) AS total_revenue,
    COUNT(DISTINCT item_code)               AS sku_count,
    CASE
        WHEN RANK() OVER (ORDER BY SUM(retail_sales) + SUM(warehouse_sales) DESC) <= 10
            THEN 'Tier 1 — Strategic'
        WHEN RANK() OVER (ORDER BY SUM(retail_sales) + SUM(warehouse_sales) DESC) <= 30
            THEN 'Tier 2 — Core'
        WHEN RANK() OVER (ORDER BY SUM(retail_sales) + SUM(warehouse_sales) DESC) <= 80
            THEN 'Tier 3 — Contributing'
        ELSE 'Tier 4 — Long Tail'
    END AS supplier_tier
FROM retail_warehouse_sales
WHERE retail_sales >= 0 AND warehouse_sales >= 0
  AND supplier IS NOT NULL
GROUP BY supplier
ORDER BY total_revenue DESC
LIMIT 10;

-- 4.3 Supplier concentration — what % of revenue comes from top 10 suppliers
WITH supplier_revenue AS (
    SELECT
        supplier,
        SUM(retail_sales + warehouse_sales) AS total_revenue
    FROM retail_warehouse_sales
    WHERE retail_sales >= 0 AND warehouse_sales >= 0
      AND supplier IS NOT NULL
    GROUP BY supplier
),
totals AS (
    SELECT SUM(total_revenue) AS grand_total FROM supplier_revenue
)
SELECT
    ROUND(SUM(CASE WHEN rn <= 10 THEN total_revenue ELSE 0 END) * 100.0 / MAX(grand_total), 1)
        AS top10_supplier_revenue_pct,
    ROUND(SUM(CASE WHEN rn <= 25 THEN total_revenue ELSE 0 END) * 100.0 / MAX(grand_total), 1)
        AS top25_supplier_revenue_pct
FROM (
    SELECT supplier, total_revenue,
           ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS rn
    FROM supplier_revenue
) ranked
CROSS JOIN totals;


-- ============================================================
-- SECTION 5: PRODUCT PERFORMANCE ANALYSIS
-- ============================================================

-- 5.1 Top 20 products by retail sales
SELECT
    item_description,
    item_type,
    supplier,
    ROUND(SUM(retail_sales), 0)         AS total_retail_sales,
    ROUND(SUM(warehouse_sales), 0)      AS total_warehouse_sales,
    ROUND(SUM(retail_sales) + SUM(warehouse_sales), 0) AS total_revenue
FROM retail_warehouse_sales
WHERE retail_sales >= 0 AND warehouse_sales >= 0
GROUP BY item_description, item_type, supplier
ORDER BY total_retail_sales DESC
LIMIT 20;

-- 5.2 Top 20 products by warehouse sales
SELECT
    item_description,
    item_type,
    supplier,
    ROUND(SUM(retail_sales), 0)         AS total_retail_sales,
    ROUND(SUM(warehouse_sales), 0)      AS total_warehouse_sales,
    ROUND(SUM(retail_sales) + SUM(warehouse_sales), 0) AS total_revenue
FROM retail_warehouse_sales
WHERE retail_sales >= 0 AND warehouse_sales >= 0
GROUP BY item_description, item_type, supplier
ORDER BY total_warehouse_sales DESC
LIMIT 20;

-- 5.3 Product performance classification
SELECT
    item_type,
    COUNT(CASE WHEN retail_sales + warehouse_sales = 0 THEN 1 END)      AS zero_sales_skus,
    COUNT(CASE WHEN retail_sales + warehouse_sales > 0
               AND retail_sales + warehouse_sales <= 10 THEN 1 END)      AS low_sales_skus,
    COUNT(CASE WHEN retail_sales + warehouse_sales > 10
               AND retail_sales + warehouse_sales <= 100 THEN 1 END)     AS mid_sales_skus,
    COUNT(CASE WHEN retail_sales + warehouse_sales > 100 THEN 1 END)     AS high_sales_skus,
    COUNT(*)                                                              AS total_skus
FROM retail_warehouse_sales
WHERE retail_sales >= 0 AND warehouse_sales >= 0
GROUP BY item_type
ORDER BY total_skus DESC;


-- ============================================================
-- SECTION 6: MONTHLY TREND ANALYSIS
-- ============================================================

-- 6.1 Monthly revenue trend — overall
SELECT
    month,
    TO_CHAR(TO_DATE(month::TEXT, 'MM'), 'Month')        AS month_name,
    ROUND(SUM(retail_sales), 0)                         AS retail_sales,
    ROUND(SUM(warehouse_sales), 0)                      AS warehouse_sales,
    ROUND(SUM(retail_transfers), 0)                     AS retail_transfers,
    ROUND(SUM(retail_sales) + SUM(warehouse_sales), 0)  AS total_revenue,
    ROUND(SUM(retail_sales) * 100.0 /
          NULLIF(SUM(retail_sales) + SUM(warehouse_sales), 0), 1) AS retail_pct
FROM retail_warehouse_sales
WHERE retail_sales >= 0 AND warehouse_sales >= 0
GROUP BY month
ORDER BY month;

-- 6.2 Month-over-month growth rate
WITH monthly AS (
    SELECT
        month,
        ROUND(SUM(retail_sales) + SUM(warehouse_sales), 0) AS total_revenue
    FROM retail_warehouse_sales
    WHERE retail_sales >= 0 AND warehouse_sales >= 0
    GROUP BY month
)
SELECT
    month,
    total_revenue,
    LAG(total_revenue) OVER (ORDER BY month)            AS prev_month_revenue,
    ROUND((total_revenue - LAG(total_revenue) OVER (ORDER BY month)) * 100.0 /
          NULLIF(LAG(total_revenue) OVER (ORDER BY month), 0), 1) AS mom_growth_pct
FROM monthly
ORDER BY month;

-- 6.3 Monthly trend by product category
SELECT
    month,
    item_type,
    ROUND(SUM(retail_sales), 0)         AS retail_sales,
    ROUND(SUM(warehouse_sales), 0)      AS warehouse_sales,
    ROUND(SUM(retail_sales) + SUM(warehouse_sales), 0) AS total_revenue
FROM retail_warehouse_sales
WHERE retail_sales >= 0 AND warehouse_sales >= 0
GROUP BY month, item_type
ORDER BY month, total_revenue DESC;

-- 6.4 Peak month identification per category
SELECT
    item_type,
    month AS peak_month,
    ROUND(SUM(retail_sales) + SUM(warehouse_sales), 0) AS peak_revenue
FROM retail_warehouse_sales
WHERE retail_sales >= 0 AND warehouse_sales >= 0
GROUP BY item_type, month
QUALIFY ROW_NUMBER() OVER (PARTITION BY item_type ORDER BY SUM(retail_sales) + SUM(warehouse_sales) DESC) = 1
ORDER BY peak_revenue DESC;
-- Note: If QUALIFY is unsupported, use subquery version below:
/*
SELECT item_type, month AS peak_month, peak_revenue
FROM (
    SELECT item_type, month,
           ROUND(SUM(retail_sales) + SUM(warehouse_sales), 0) AS peak_revenue,
           ROW_NUMBER() OVER (PARTITION BY item_type ORDER BY SUM(retail_sales) + SUM(warehouse_sales) DESC) AS rn
    FROM retail_warehouse_sales
    WHERE retail_sales >= 0 AND warehouse_sales >= 0
    GROUP BY item_type, month
) ranked WHERE rn = 1 ORDER BY peak_revenue DESC;
*/


-- ============================================================
-- SECTION 7: SEGMENTATION ANALYSIS
-- ============================================================

-- 7.1 Supplier segmentation by revenue and channel mix
WITH supplier_metrics AS (
    SELECT
        supplier,
        ROUND(SUM(retail_sales), 0)         AS retail_sales,
        ROUND(SUM(warehouse_sales), 0)      AS warehouse_sales,
        ROUND(SUM(retail_sales) + SUM(warehouse_sales), 0) AS total_revenue,
        COUNT(DISTINCT item_code)           AS sku_count
    FROM retail_warehouse_sales
    WHERE retail_sales >= 0 AND warehouse_sales >= 0
      AND supplier IS NOT NULL
    GROUP BY supplier
)
SELECT
    supplier,
    total_revenue,
    sku_count,
    retail_sales,
    warehouse_sales,
    CASE
        WHEN total_revenue >= PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_revenue) OVER()
            THEN 'High Value'
        WHEN total_revenue >= PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_revenue) OVER()
            THEN 'Mid Value'
        WHEN total_revenue >= PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_revenue) OVER()
            THEN 'Low Value'
        ELSE 'Tail'
    END AS supplier_segment
FROM supplier_metrics
ORDER BY total_revenue DESC;

-- 7.2 SKU-level performance segmentation
SELECT
    CASE
        WHEN retail_sales + warehouse_sales = 0         THEN 'Dead Stock'
        WHEN retail_sales + warehouse_sales <= 5        THEN 'Low Performer'
        WHEN retail_sales + warehouse_sales <= 50       THEN 'Mid Performer'
        WHEN retail_sales + warehouse_sales <= 200      THEN 'Strong Performer'
        ELSE 'Top Performer'
    END AS sku_segment,
    COUNT(*)                                            AS sku_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct_of_skus,
    ROUND(SUM(retail_sales + warehouse_sales), 0)      AS segment_revenue,
    ROUND(SUM(retail_sales + warehouse_sales) * 100.0 /
          NULLIF(SUM(SUM(retail_sales + warehouse_sales)) OVER(), 0), 1) AS pct_of_revenue
FROM retail_warehouse_sales
WHERE retail_sales >= 0 AND warehouse_sales >= 0
GROUP BY sku_segment
ORDER BY segment_revenue DESC;


-- ============================================================
-- SECTION 8: BUSINESS IMPACT ANALYSIS
-- ============================================================

-- 8.1 Revenue concentration — Pareto analysis
-- What % of SKUs drive 80% of revenue
WITH sku_revenue AS (
    SELECT
        item_code,
        item_description,
        item_type,
        SUM(retail_sales + warehouse_sales) AS total_revenue
    FROM retail_warehouse_sales
    WHERE retail_sales >= 0 AND warehouse_sales >= 0
    GROUP BY item_code, item_description, item_type
),
ranked AS (
    SELECT *,
           SUM(total_revenue) OVER (ORDER BY total_revenue DESC
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue,
           SUM(total_revenue) OVER () AS grand_total,
           ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS rank
    FROM sku_revenue
    WHERE total_revenue > 0
)
SELECT
    COUNT(*) AS skus_driving_80pct_revenue,
    ROUND(COUNT(*) * 100.0 / MAX(rank), 1) AS pct_of_total_skus,
    ROUND(MAX(grand_total) * 0.8, 0) AS revenue_threshold
FROM ranked
WHERE cumulative_revenue <= grand_total * 0.8;

-- 8.2 Zero-movement inventory (dead stock analysis)
SELECT
    item_type,
    COUNT(*) AS dead_stock_skus,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct_of_dead_stock
FROM retail_warehouse_sales
WHERE retail_sales = 0 AND warehouse_sales = 0 AND retail_transfers = 0
GROUP BY item_type
ORDER BY dead_stock_skus DESC;

-- 8.3 High-value supplier-category combinations
SELECT
    supplier,
    item_type,
    ROUND(SUM(retail_sales + warehouse_sales), 0) AS total_revenue,
    COUNT(DISTINCT item_code) AS sku_count,
    ROUND(AVG(retail_sales + warehouse_sales), 2) AS avg_revenue_per_sku
FROM retail_warehouse_sales
WHERE retail_sales >= 0 AND warehouse_sales >= 0
  AND supplier IS NOT NULL
GROUP BY supplier, item_type
HAVING SUM(retail_sales + warehouse_sales) > 0
ORDER BY total_revenue DESC
LIMIT 15;


-- ============================================================
-- SECTION 9: TABLEAU EXPORT VIEWS
-- ============================================================

-- 9.1 Master view for Tableau — clean flat file with all dimensions
CREATE OR REPLACE VIEW vw_tableau_master AS
SELECT
    year,
    month,
    TO_CHAR(TO_DATE(month::TEXT, 'MM'), 'Month')    AS month_name,
    MAKE_DATE(year, month, 1)                        AS period_date,
    supplier,
    item_code,
    item_description,
    item_type,
    CASE
        WHEN retail_sales >= 0 THEN retail_sales ELSE 0
    END AS retail_sales,
    retail_transfers,
    CASE
        WHEN warehouse_sales >= 0 THEN warehouse_sales ELSE 0
    END AS warehouse_sales,
    CASE
        WHEN (retail_sales + warehouse_sales) >= 0
        THEN retail_sales + warehouse_sales ELSE 0
    END AS total_revenue,
    CASE
        WHEN retail_sales + warehouse_sales = 0         THEN 'Dead Stock'
        WHEN retail_sales + warehouse_sales <= 5        THEN 'Low Performer'
        WHEN retail_sales + warehouse_sales <= 50       THEN 'Mid Performer'
        WHEN retail_sales + warehouse_sales <= 200      THEN 'Strong Performer'
        ELSE 'Top Performer'
    END AS sku_segment
FROM retail_warehouse_sales;

-- 9.2 Monthly summary for trend charts
CREATE OR REPLACE VIEW vw_monthly_summary AS
SELECT
    month,
    TO_CHAR(TO_DATE(month::TEXT, 'MM'), 'Month')    AS month_name,
    item_type,
    ROUND(SUM(CASE WHEN retail_sales >= 0 THEN retail_sales ELSE 0 END), 0) AS retail_sales,
    ROUND(SUM(CASE WHEN warehouse_sales >= 0 THEN warehouse_sales ELSE 0 END), 0) AS warehouse_sales,
    ROUND(SUM(CASE WHEN retail_sales >= 0 THEN retail_sales ELSE 0 END) +
          SUM(CASE WHEN warehouse_sales >= 0 THEN warehouse_sales ELSE 0 END), 0) AS total_revenue
FROM retail_warehouse_sales
GROUP BY month, item_type
ORDER BY month, total_revenue DESC;

-- 9.3 Supplier summary for ranking charts
CREATE OR REPLACE VIEW vw_supplier_summary AS
SELECT
    supplier,
    item_type,
    ROUND(SUM(CASE WHEN retail_sales >= 0 THEN retail_sales ELSE 0 END), 0) AS retail_sales,
    ROUND(SUM(CASE WHEN warehouse_sales >= 0 THEN warehouse_sales ELSE 0 END), 0) AS warehouse_sales,
    ROUND(SUM(CASE WHEN retail_sales >= 0 THEN retail_sales ELSE 0 END) +
          SUM(CASE WHEN warehouse_sales >= 0 THEN warehouse_sales ELSE 0 END), 0) AS total_revenue,
    COUNT(DISTINCT item_code) AS sku_count
FROM retail_warehouse_sales
WHERE supplier IS NOT NULL
GROUP BY supplier, item_type
ORDER BY total_revenue DESC;

-- Preview master view
SELECT * FROM vw_tableau_master LIMIT 10;
