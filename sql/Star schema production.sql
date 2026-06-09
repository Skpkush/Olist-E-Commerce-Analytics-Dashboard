-- ================================================================
-- OLIST STAR SCHEMA — FINAL PRODUCTION VERSION
-- Author  : Sumit Prajapat
-- Source  : raw.*
-- Output  : cleaned.*
-- ================================================================
-- HOW TO RUN:
-- Open pgAdmin → Query Tool on OlistDB
-- Run each BLOCK separately one at a time
-- Wait for green checkmark before next block
-- ================================================================


-- ================================================================
-- BLOCK 0 — Schema setup (1 second)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS cleaned;



-- ================================================================
-- BLOCK 1 — Indexes on raw tables (~1 min)
-- Run once. Makes all joins below 5-10x faster.
-- ================================================================
CREATE INDEX IF NOT EXISTS idx_ord_cust   ON raw.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_ord_ts     ON raw.orders(order_purchase_timestamp);
CREATE INDEX IF NOT EXISTS idx_oi_order   ON raw.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_oi_product ON raw.order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_oi_seller  ON raw.order_items(seller_id);
CREATE INDEX IF NOT EXISTS idx_pay_order  ON raw.order_payments(order_id);
CREATE INDEX IF NOT EXISTS idx_rev_order  ON raw.order_reviews(order_id);
CREATE INDEX IF NOT EXISTS idx_cust_id    ON raw.customers(customer_id);
CREATE INDEX IF NOT EXISTS idx_prod_id    ON raw.products(product_id);
CREATE INDEX IF NOT EXISTS idx_sell_id    ON raw.sellers(seller_id);

-- Block 1 done — indexes created

-- ================================================================
-- BLOCK 2 — dim_customer (~1 min, ~99,441 rows)
-- CTEs pre-aggregate payments and reviews before joining
-- No geolocation join (1M rows = explosion risk)
-- ================================================================
DROP TABLE IF EXISTS cleaned.dim_customer;

CREATE TABLE cleaned.dim_customer AS
WITH
pay_per_order AS (
    SELECT
        order_id,
        ROUND(CAST(SUM(payment_value) AS NUMERIC), 2) AS total_payment_value
    FROM raw.order_payments
    GROUP BY order_id
),
review_per_order AS (
    SELECT DISTINCT ON (order_id)
        order_id,
        review_score
    FROM raw.order_reviews
    ORDER BY order_id, review_score DESC NULLS LAST
)
SELECT
    c.customer_id,
    c.customer_unique_id,
    c.customer_zip_code_prefix,
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT o.order_id)                                          AS total_orders,
    ROUND(CAST(COALESCE(SUM(p.total_payment_value), 0) AS NUMERIC), 2) AS total_spent,
    ROUND(CAST(COALESCE(AVG(p.total_payment_value), 0) AS NUMERIC), 2) AS avg_order_value,
    MIN(o.order_purchase_timestamp)::DATE                               AS first_order_date,
    MAX(o.order_purchase_timestamp)::DATE                               AS last_order_date,
    ROUND(CAST(COALESCE(AVG(r.review_score), 0) AS NUMERIC), 2)       AS avg_review_score,
    CASE
        WHEN COUNT(DISTINCT o.order_id) >= 3 THEN 'Loyal'
        WHEN COUNT(DISTINCT o.order_id) = 2  THEN 'Repeat'
        ELSE 'One-time'
    END AS customer_segment,
    CASE
        WHEN COALESCE(SUM(p.total_payment_value), 0) >= 1000 THEN 'High Value'
        WHEN COALESCE(SUM(p.total_payment_value), 0) >= 500  THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM raw.customers        c
LEFT JOIN raw.orders       o ON c.customer_id = o.customer_id
LEFT JOIN pay_per_order    p ON o.order_id    = p.order_id
LEFT JOIN review_per_order r ON o.order_id    = r.order_id
GROUP BY
    c.customer_id,
    c.customer_unique_id,
    c.customer_zip_code_prefix,
    c.customer_city,
    c.customer_state;

ALTER TABLE cleaned.dim_customer
ADD CONSTRAINT pk_dim_customer PRIMARY KEY (customer_id);

SELECT COUNT(*) AS dim_customer_count FROM cleaned.dim_customer;
-- Expected: 99,441
-- Block 2 done — dim_customer ready


-- ================================================================
-- BLOCK 3 — dim_product (~1 min, ~32,951 rows)
-- Reviews pre-deduped via CTE before joining
-- ================================================================
DROP TABLE IF EXISTS cleaned.dim_product;

CREATE TABLE cleaned.dim_product AS
WITH
review_per_order AS (
    SELECT DISTINCT ON (order_id)
        order_id,
        review_score
    FROM raw.order_reviews
    ORDER BY order_id, review_score DESC NULLS LAST
)
SELECT
    p.product_id,
    p.product_category_name                                                   AS product_category,
    ct.product_category_name_english                                           AS product_category_english,
    p.product_name_lenght                                                      AS product_name_length,
    p.product_description_lenght                                               AS product_description_length,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    CASE
        WHEN p.product_weight_g >= 5000 THEN 'Heavy'
        WHEN p.product_weight_g >= 1000 THEN 'Medium'
        ELSE 'Light'
    END AS product_size_category,
    COUNT(DISTINCT oi.order_id)                                                AS times_ordered,
    COUNT(oi.order_item_id)                                                    AS total_quantity_sold,
    ROUND(CAST(COALESCE(SUM(oi.price + oi.freight_value), 0) AS NUMERIC), 2) AS total_revenue,
    ROUND(CAST(COALESCE(AVG(oi.price), 0) AS NUMERIC), 2)                    AS avg_price,
    ROUND(CAST(COALESCE(AVG(r.review_score), 0) AS NUMERIC), 2)              AS avg_review_score,
    CASE
        WHEN COALESCE(SUM(oi.price), 0) >= 10000 THEN 'Top Seller'
        WHEN COALESCE(SUM(oi.price), 0) >= 5000  THEN 'Good Seller'
        WHEN COALESCE(SUM(oi.price), 0) >= 1000  THEN 'Average Seller'
        ELSE 'Low Seller'
    END AS product_performance
FROM raw.products                p
LEFT JOIN raw.category_translation ct ON p.product_category_name = ct.product_category_name
LEFT JOIN raw.order_items         oi ON p.product_id             = oi.product_id
LEFT JOIN raw.orders               o ON oi.order_id              = o.order_id
LEFT JOIN review_per_order         r ON o.order_id               = r.order_id
GROUP BY
    p.product_id,
    p.product_category_name,
    ct.product_category_name_english,
    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm;

ALTER TABLE cleaned.dim_product
ADD CONSTRAINT pk_dim_product PRIMARY KEY (product_id);

SELECT COUNT(*) AS dim_product_count FROM cleaned.dim_product;
-- Expected: 32,951
-- Block 3 done — dim_product ready


-- ================================================================
-- BLOCK 4A — dim_seller base (~30 sec, ~3,095 rows)
-- Only sellers + order_items — fastest possible
-- ================================================================
DROP TABLE IF EXISTS cleaned.dim_seller;

CREATE TABLE cleaned.dim_seller AS
SELECT
    s.seller_id,
    s.seller_zip_code_prefix,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id)                                               AS total_orders_fulfilled,
    COUNT(oi.order_item_id)                                                   AS total_items_sold,
    ROUND(CAST(COALESCE(SUM(oi.price + oi.freight_value), 0) AS NUMERIC), 2) AS total_revenue,
    ROUND(CAST(COALESCE(AVG(oi.price), 0) AS NUMERIC), 2)                    AS avg_item_price,
    0.00::NUMERIC                                                              AS avg_review_score,
    CASE
        WHEN COUNT(DISTINCT oi.order_id) >= 100 THEN 'Top Seller'
        WHEN COUNT(DISTINCT oi.order_id) >= 50  THEN 'Active Seller'
        WHEN COUNT(DISTINCT oi.order_id) >= 10  THEN 'Regular Seller'
        ELSE 'New Seller'
    END AS seller_performance_category
FROM raw.sellers           s
LEFT JOIN raw.order_items oi ON s.seller_id = oi.seller_id
GROUP BY
    s.seller_id,
    s.seller_zip_code_prefix,
    s.seller_city,
    s.seller_state;

SELECT COUNT(*) AS dim_seller_count FROM cleaned.dim_seller;
-- Expected: 3,095
-- Block 4A done — dim_seller base ready


-- ================================================================
-- BLOCK 4B — dim_seller review scores (~30 sec)
-- Separate UPDATE keeps it fast
-- ================================================================
UPDATE cleaned.dim_seller ds
SET avg_review_score = sub.avg_score
FROM (
    SELECT
        oi.seller_id,
        ROUND(CAST(AVG(r.review_score) AS NUMERIC), 2) AS avg_score
    FROM raw.order_items   oi
    JOIN raw.order_reviews  r ON oi.order_id = r.order_id
    GROUP BY oi.seller_id
) sub
WHERE ds.seller_id = sub.seller_id;

ALTER TABLE cleaned.dim_seller
ADD CONSTRAINT pk_dim_seller PRIMARY KEY (seller_id);

SELECT COUNT(*) AS dim_seller_final FROM cleaned.dim_seller;
-- Expected: 3,095
-- Block 4B done — dim_seller complete


-- ================================================================
-- BLOCK 5 — dim_date (~10 sec, ~600+ rows)
-- CTE extracts distinct dates first — very fast
-- ================================================================
DROP TABLE IF EXISTS cleaned.dim_date;

CREATE TABLE cleaned.dim_date AS
WITH unique_dates AS (
    SELECT DISTINCT order_purchase_timestamp::DATE AS dt
    FROM raw.orders
    WHERE order_purchase_timestamp IS NOT NULL
)
SELECT
    dt                                                     AS date_key,
    dt                                                     AS full_date,
    EXTRACT(YEAR    FROM dt)::INT                          AS year,
    EXTRACT(MONTH   FROM dt)::INT                          AS month,
    EXTRACT(DAY     FROM dt)::INT                          AS day,
    EXTRACT(QUARTER FROM dt)::INT                          AS quarter,
    EXTRACT(DOW     FROM dt)::INT                          AS day_of_week_number,
    TRIM(TO_CHAR(dt, 'Day'))                               AS day_of_week_name,
    TRIM(TO_CHAR(dt, 'Month'))                             AS month_name,
    EXTRACT(WEEK    FROM dt)::INT                          AS week_of_year,
    CASE
        WHEN EXTRACT(DOW FROM dt) IN (0, 6) THEN 'Weekend'
        ELSE 'Weekday'
    END                                                     AS day_type,
    TO_CHAR(dt, 'YYYY-MM')                                 AS year_month,
    'Q' || EXTRACT(QUARTER FROM dt)::TEXT
    || ' ' || EXTRACT(YEAR FROM dt)::TEXT                  AS quarter_name
FROM unique_dates
ORDER BY dt;

ALTER TABLE cleaned.dim_date
ADD CONSTRAINT pk_dim_date PRIMARY KEY (date_key);

SELECT
    COUNT(*)      AS total_dates,
    MIN(date_key) AS first_date,
    MAX(date_key) AS last_date
FROM cleaned.dim_date;

-- Expected: 600+ dates, 2016 to 2018


--Block 5 done — dim_date ready 


-- ================================================================
-- BLOCK 6 — fact_sales (~2-3 min, ~112,650 rows)
-- TWO CTEs pre-aggregate before joining:
-- payments_agg  → 1 row per order (stops payment explosion)
-- reviews_dedup → 1 row per order (stops review explosion)
-- All category/state columns calculated inline
-- ================================================================
DROP TABLE IF EXISTS cleaned.fact_sales;

CREATE TABLE cleaned.fact_sales AS
WITH
payments_agg AS (
    SELECT
        order_id,
        ROUND(CAST(SUM(payment_value) AS NUMERIC), 2)              AS order_total,
        MAX(payment_installments)                                     AS max_installments,
        COUNT(*)                                                       AS payment_count,
        STRING_AGG(DISTINCT payment_type, ', ' ORDER BY payment_type) AS payment_methods
    FROM raw.order_payments
    GROUP BY order_id
),
reviews_dedup AS (
    SELECT DISTINCT ON (order_id)
        order_id,
        review_score,
        review_comment_message
    FROM raw.order_reviews
    ORDER BY order_id, review_score DESC NULLS LAST
)
SELECT
    ROW_NUMBER() OVER (ORDER BY o.order_id, oi.order_item_id)     AS sales_key,
    -- foreign keys
    o.order_id,
    o.customer_id,
    oi.product_id,
    oi.seller_id,
    o.order_purchase_timestamp::DATE                               AS date_key,
    -- order info
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    -- money
    oi.price                                                        AS item_price,
    oi.freight_value,
    ROUND(CAST(oi.price + oi.freight_value AS NUMERIC), 2)         AS total_item_value,
    COALESCE(pa.order_total, 0)                                     AS order_total,
    COALESCE(pa.payment_count, 0)                                   AS payment_count,
    COALESCE(pa.max_installments, 0)                                AS max_installments,
    pa.payment_methods,
    -- delivery
    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
        THEN EXTRACT(DAY FROM (
            o.order_delivered_customer_date - o.order_purchase_timestamp
        ))::INT
        ELSE NULL
    END AS delivery_days,
    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
         AND o.order_delivered_customer_date <= o.order_estimated_delivery_date
        THEN TRUE
        ELSE FALSE
    END AS delivered_on_time,
    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
         AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN EXTRACT(DAY FROM (
            o.order_delivered_customer_date - o.order_estimated_delivery_date
        ))::INT
        ELSE 0
    END AS days_late,
    -- review
    r.review_score,
    CASE
        WHEN r.review_score >= 4 THEN 'Positive'
        WHEN r.review_score =  3 THEN 'Neutral'
        WHEN r.review_score <= 2 THEN 'Negative'
        ELSE 'No Review'
    END AS review_sentiment,
    CASE
        WHEN r.review_comment_message IS NOT NULL THEN TRUE
        ELSE FALSE
    END AS has_comment,
    -- denormalized columns for Power BI
    pa.payment_methods                                              AS payment_type,
    p.product_category_name                                         AS product_category,
    CASE
        WHEN p.product_weight_g >= 5000 THEN 'Heavy'
        WHEN p.product_weight_g >= 1000 THEN 'Medium'
        ELSE 'Light'
    END AS product_size_category,
    c.customer_state,
    c.customer_city,
    s.seller_state,
    s.seller_city,
    -- time fields for Power BI slicers
    EXTRACT(YEAR    FROM o.order_purchase_timestamp)::INT           AS order_year,
    EXTRACT(MONTH   FROM o.order_purchase_timestamp)::INT           AS order_month,
    EXTRACT(QUARTER FROM o.order_purchase_timestamp)::INT           AS order_quarter,
    EXTRACT(DOW     FROM o.order_purchase_timestamp)::INT           AS order_day_of_week,
    TRIM(TO_CHAR(o.order_purchase_timestamp, 'Month'))              AS order_month_name
FROM raw.orders             o
INNER JOIN raw.order_items oi ON o.order_id    = oi.order_id
LEFT JOIN  payments_agg    pa ON o.order_id    = pa.order_id
LEFT JOIN  reviews_dedup    r ON o.order_id    = r.order_id
LEFT JOIN  raw.products     p ON oi.product_id = p.product_id
LEFT JOIN  raw.customers    c ON o.customer_id = c.customer_id
LEFT JOIN  raw.sellers      s ON oi.seller_id  = s.seller_id;

ALTER TABLE cleaned.fact_sales
ADD CONSTRAINT pk_fact_sales PRIMARY KEY (sales_key);

-- Power BI performance indexes
CREATE INDEX idx_fact_customer ON cleaned.fact_sales(customer_id);
CREATE INDEX idx_fact_product  ON cleaned.fact_sales(product_id);
CREATE INDEX idx_fact_seller   ON cleaned.fact_sales(seller_id);
CREATE INDEX idx_fact_date     ON cleaned.fact_sales(date_key);
CREATE INDEX idx_fact_year     ON cleaned.fact_sales(order_year);
CREATE INDEX idx_fact_state    ON cleaned.fact_sales(customer_state);

SELECT COUNT(*) AS fact_sales_count FROM cleaned.fact_sales;
-- Expected: 112,650

--Block 6 done — 

-- ================================================================
-- BLOCK 7 — Final validation (30 sec)
-- All relationship checks must return 0
-- ================================================================

-- Table counts
SELECT 'dim_customer' AS tbl, COUNT(*) AS cnt FROM cleaned.dim_customer
UNION ALL SELECT 'dim_product',  COUNT(*) FROM cleaned.dim_product
UNION ALL SELECT 'dim_seller',   COUNT(*) FROM cleaned.dim_seller
UNION ALL SELECT 'dim_date',     COUNT(*) FROM cleaned.dim_date
UNION ALL SELECT 'fact_sales',   COUNT(*) FROM cleaned.fact_sales;


SELECT 'orphan customers' AS check_name, COUNT(*) AS issues
FROM cleaned.fact_sales f
LEFT JOIN cleaned.dim_customer c ON f.customer_id = c.customer_id
WHERE c.customer_id IS NULL
UNION ALL
SELECT 'orphan products', COUNT(*)
FROM cleaned.fact_sales f
LEFT JOIN cleaned.dim_product p ON f.product_id = p.product_id
WHERE p.product_id IS NULL
UNION ALL
SELECT 'orphan sellers', COUNT(*)
FROM cleaned.fact_sales f
LEFT JOIN cleaned.dim_seller s ON f.seller_id = s.seller_id
WHERE s.seller_id IS NULL
UNION ALL
SELECT 'orphan dates', COUNT(*)
FROM cleaned.fact_sales f
LEFT JOIN cleaned.dim_date d ON f.date_key = d.date_key
WHERE d.date_key IS NULL;

-- Relationship checks — all must be 0



--Block 7 done — validation complete
