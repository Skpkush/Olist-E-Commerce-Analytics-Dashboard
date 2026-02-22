-- Olist E-commerce Data Cleaning - Complete PostgreSQL Guide

-- # PROJECT OVERVIEW
-- Database: olist_ecommerce
-- Schema: raw (source data)
-- Schema: cleaned (cleaned data - to be created)
-- Tables: 9 tables total

---

## 🗂️ TABLE STRUCTURE REFERENCE


select * from raw.category_translation
select * from raw.customers
select * from raw.geolocation
select * from raw.order_items
select * from raw.order_payments
select * from raw.order_reviews
select * from raw.orders
select * from raw.products
select * from raw.sellers


raw.customers              (99,441 records)
raw.orders                 (99,441 records)
raw.order_items            (112,650 records)
raw.order_payments         (103,886 records)
raw.order_reviews          (99,224 records)
raw.products               (32,951 records)
raw.sellers                (3,095 records)
raw.geolocation            (1,000,163 records)
raw.category_translation   (71 records)


/*
═══════════════════════════════════════════════════════════
FILE: 01_create_cleaned_schema.sql
PURPOSE: Create schema for cleaned data
═══════════════════════════════════════════════════════════
*/

-- Create schema for cleaned tables
CREATE SCHEMA IF NOT EXISTS cleaned;

-- Verify schema created
SELECT schema_name 
FROM information_schema.schemata 
WHERE schema_name IN ('raw', 'cleaned');


-- ## 1: DATA PROFILING - ALL TABLES

/*
═══════════════════════════════════════════════════════════
FILE: 02_data_profiling.sql
PURPOSE: Profile all raw tables to identify quality issues
DATE: 2025-02-14
═══════════════════════════════════════════════════════════
*/

-- ═══════════════════════════════════════════════════════════
-- COMPREHENSIVE DATA QUALITY REPORT
-- ═══════════════════════════════════════════════════════════

SELECT 
    'customers' AS table_name,
    COUNT(*) AS total_records,
    COUNT(DISTINCT customer_id) AS unique_ids,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicates,
    COUNT(*) - COUNT(customer_city) AS null_cities,
    COUNT(*) - COUNT(customer_state) AS null_states
FROM raw.customers

UNION ALL

SELECT 
    'orders',
    COUNT(*),
    COUNT(DISTINCT order_id),
    COUNT(*) - COUNT(DISTINCT order_id),
    COUNT(*) - COUNT(order_status),
    COUNT(*) - COUNT(order_purchase_timestamp)
FROM raw.orders

UNION ALL

SELECT 
    'order_items',
    COUNT(*),
    COUNT(DISTINCT order_id || '-' || order_item_id::TEXT),
    0,  -- No duplicates expected with composite key
    COUNT(*) - COUNT(product_id),
    COUNT(*) - COUNT(seller_id)
FROM raw.order_items

UNION ALL

SELECT 
    'order_payments',
    COUNT(*),
    COUNT(DISTINCT order_id || '-' || payment_sequential::TEXT),
    0,
    COUNT(*) - COUNT(payment_type),
    COUNT(*) - COUNT(payment_value)
FROM raw.order_payments

UNION ALL

SELECT 
    'order_reviews',
    COUNT(*),
    COUNT(DISTINCT review_id),
    COUNT(*) - COUNT(DISTINCT review_id),
    COUNT(*) - COUNT(review_score),
    COUNT(*) - COUNT(order_id)
FROM raw.order_reviews

UNION ALL

SELECT 
    'products',
    COUNT(*),
    COUNT(DISTINCT product_id),
    COUNT(*) - COUNT(DISTINCT product_id),
    COUNT(*) - COUNT(product_category_name),
    COUNT(*) - COUNT(product_weight_g)
FROM raw.products

UNION ALL

SELECT 
    'sellers',
    COUNT(*),
    COUNT(DISTINCT seller_id),
    COUNT(*) - COUNT(DISTINCT seller_id),
    COUNT(*) - COUNT(seller_city),
    COUNT(*) - COUNT(seller_state)
FROM raw.sellers

UNION ALL

SELECT 
    'geolocation',
    COUNT(*),
    COUNT(DISTINCT geolocation_zip_code_prefix),
    0,
    COUNT(*) - COUNT(geolocation_city),
    COUNT(*) - COUNT(geolocation_state)
FROM raw.geolocation

UNION ALL

SELECT 
    'category_translation',
    COUNT(*),
    COUNT(DISTINCT product_category_name),
    COUNT(*) - COUNT(DISTINCT product_category_name),
    COUNT(*) - COUNT(product_category_name_english),
    0
FROM raw.category_translation

ORDER BY table_name;


-- ═══════════════════════════════════════════════════════════
-- DETAILED PROFILING BY TABLE
-- ═══════════════════════════════════════════════════════════

-- 1. CUSTOMERS - Detailed Analysis
SELECT 
    'Total Customers' AS metric,
    COUNT(*)::TEXT AS value
FROM raw.customers
UNION ALL
SELECT 'Unique customer_id', COUNT(DISTINCT customer_id)::TEXT FROM raw.customers
UNION ALL
SELECT 'Unique customer_unique_id', COUNT(DISTINCT customer_unique_id)::TEXT FROM raw.customers
UNION ALL
SELECT 'NULL cities', (COUNT(*) - COUNT(customer_city))::TEXT FROM raw.customers
UNION ALL
SELECT 'NULL states', (COUNT(*) - COUNT(customer_state))::TEXT FROM raw.customers
UNION ALL
SELECT 'Distinct states', COUNT(DISTINCT customer_state)::TEXT FROM raw.customers
UNION ALL
SELECT 'Distinct cities', COUNT(DISTINCT customer_city)::TEXT FROM raw.customers;


-- 2. ORDERS - Detailed Analysis
SELECT 
    'Total Orders' AS metric,
    COUNT(*)::TEXT AS value
FROM raw.orders
UNION ALL
SELECT 'Unique order_id', COUNT(DISTINCT order_id)::TEXT FROM raw.orders
UNION ALL
SELECT 'NULL order_status', (COUNT(*) - COUNT(order_status))::TEXT FROM raw.orders
UNION ALL
SELECT 'NULL purchase_timestamp', (COUNT(*) - COUNT(order_purchase_timestamp))::TEXT FROM raw.orders
UNION ALL
SELECT 'NULL approved_at', (COUNT(*) - COUNT(order_approved_at))::TEXT FROM raw.orders
UNION ALL
SELECT 'NULL delivered_customer_date', (COUNT(*) - COUNT(order_delivered_customer_date))::TEXT FROM raw.orders
UNION ALL
SELECT 'Orders with future dates', 
    COUNT(*)::TEXT 
FROM raw.orders 
WHERE order_purchase_timestamp > CURRENT_TIMESTAMP;


-- 3. ORDER STATUS DISTRIBUTION
SELECT 
    order_status,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM raw.orders
GROUP BY order_status
ORDER BY order_count DESC;


-- 4. PRODUCTS - Checking for incomplete data
SELECT 
    'Products with NULL category' AS issue,
    COUNT(*)::TEXT AS count
FROM raw.products
WHERE product_category_name IS NULL
UNION ALL
SELECT 'Products with NULL weight',
    COUNT(*)::TEXT
FROM raw.products
WHERE product_weight_g IS NULL
UNION ALL
SELECT 'Products with NULL dimensions',
    COUNT(*)::TEXT
FROM raw.products
WHERE product_length_cm IS NULL 
   OR product_height_cm IS NULL 
   OR product_width_cm IS NULL;


-- 5. CHECK REFERENTIAL INTEGRITY

-- Orders without customers
SELECT 
    'Orders without valid customer' AS issue,
    COUNT(*)::TEXT AS count
FROM raw.orders o
LEFT JOIN raw.customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Order items without valid orders
SELECT 
    'Order items without valid order' AS issue,
    COUNT(*)::TEXT AS count
FROM raw.order_items oi
LEFT JOIN raw.orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Order items without valid products
SELECT 
    'Order items without valid product' AS issue,
    COUNT(*)::TEXT AS count
FROM raw.order_items oi
LEFT JOIN raw.products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Order items without valid sellers
SELECT 
    'Order items without valid seller' AS issue,
    COUNT(*)::TEXT AS count
FROM raw.order_items oi
LEFT JOIN raw.sellers s ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;


-- 6. CHECK FOR NEGATIVE OR ZERO VALUES
SELECT 
    'Order items with price <= 0' AS issue,
    COUNT(*)::TEXT AS count
FROM raw.order_items
WHERE price <= 0
UNION ALL
SELECT 'Order payments with value <= 0',
    COUNT(*)::TEXT
FROM raw.order_payments
WHERE payment_value <= 0
UNION ALL
SELECT 'Products with weight <= 0',
    COUNT(*)::TEXT
FROM raw.products
WHERE product_weight_g <= 0;


-- 7. DATE VALIDATION
SELECT 
    'Orders delivered before purchased' AS issue,
    COUNT(*)::TEXT AS count
FROM raw.orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

-- 3: CLEAN TABLE 1 - CUSTOMERS

/*
═══════════════════════════════════════════════════════════
FILE: 03_clean_customers.sql
PURPOSE: Clean and standardize customers table
═══════════════════════════════════════════════════════════
*/

CREATE TABLE cleaned.customers AS
SELECT DISTINCT ON (customer_id)
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    -- Standardize city names (proper case)
    INITCAP(TRIM(customer_city)) AS customer_city,
    -- Standardize state codes (uppercase, 2 chars)
    UPPER(TRIM(customer_state)) AS customer_state
FROM raw.customers
WHERE customer_id IS NOT NULL
ORDER BY customer_id;

-- Add primary key
ALTER TABLE cleaned.customers 
ADD CONSTRAINT pk_customers PRIMARY KEY (customer_id);

-- Create index for faster lookups
CREATE INDEX idx_customers_unique_id ON cleaned.customers(customer_unique_id);
CREATE INDEX idx_customers_state ON cleaned.customers(customer_state);

-- Validation
SELECT 
    'Raw customers' AS version,
    COUNT(*) AS total_records,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM raw.customers
UNION ALL
SELECT 
    'Cleaned customers',
    COUNT(*),
    COUNT(DISTINCT customer_id)
FROM cleaned.customers;

---

-- 4: CLEAN TABLE 2 - ORDERS


/*
═══════════════════════════════════════════════════════════
FILE: 04_clean_orders.sql
PURPOSE: Clean and validate orders table
═══════════════════════════════════════════════════════════
*/

CREATE TABLE cleaned.orders AS
SELECT DISTINCT ON (order_id)
    order_id,
    customer_id,
    -- Standardize order status
    CASE 
        WHEN LOWER(TRIM(order_status)) IN ('delivered') THEN 'delivered'
        WHEN LOWER(TRIM(order_status)) IN ('shipped') THEN 'shipped'
        WHEN LOWER(TRIM(order_status)) IN ('invoiced') THEN 'invoiced'
        WHEN LOWER(TRIM(order_status)) IN ('processing') THEN 'processing'
        WHEN LOWER(TRIM(order_status)) IN ('approved') THEN 'approved'
        WHEN LOWER(TRIM(order_status)) IN ('canceled', 'cancelled') THEN 'canceled'
        WHEN LOWER(TRIM(order_status)) IN ('unavailable') THEN 'unavailable'
        WHEN LOWER(TRIM(order_status)) IN ('created') THEN 'created'
        ELSE 'unknown'
    END AS order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    -- Fix dates that are before purchase (set to NULL)
    CASE 
        WHEN order_delivered_customer_date < order_purchase_timestamp THEN NULL
        ELSE order_delivered_customer_date
    END AS order_delivered_customer_date,
    order_estimated_delivery_date,
    -- Add calculated fields
    EXTRACT(YEAR FROM order_purchase_timestamp) AS order_year,
    EXTRACT(MONTH FROM order_purchase_timestamp) AS order_month,
    EXTRACT(QUARTER FROM order_purchase_timestamp) AS order_quarter,
    TO_CHAR(order_purchase_timestamp, 'Day') AS order_day_of_week,
    TO_CHAR(order_purchase_timestamp, 'Month') AS order_month_name,
    -- Calculate delivery time in days
    CASE 
        WHEN order_delivered_customer_date IS NOT NULL 
        THEN EXTRACT(DAY FROM (order_delivered_customer_date - order_purchase_timestamp))
        ELSE NULL
    END AS delivery_days,
    -- Calculate if delivered on time
    CASE 
        WHEN order_delivered_customer_date IS NOT NULL 
         AND order_estimated_delivery_date IS NOT NULL
        THEN 
            CASE 
                WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN TRUE
                ELSE FALSE
            END
        ELSE NULL
    END AS delivered_on_time
FROM raw.orders
WHERE order_id IS NOT NULL
  AND customer_id IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
ORDER BY order_id;

-- Add primary key
ALTER TABLE cleaned.orders 
ADD CONSTRAINT pk_orders PRIMARY KEY (order_id);

-- Add foreign key to customers
ALTER TABLE cleaned.orders
ADD CONSTRAINT fk_orders_customer 
FOREIGN KEY (customer_id) REFERENCES cleaned.customers(customer_id);

-- Create indexes
CREATE INDEX idx_orders_customer ON cleaned.orders(customer_id);
CREATE INDEX idx_orders_status ON cleaned.orders(order_status);
CREATE INDEX idx_orders_purchase_date ON cleaned.orders(order_purchase_timestamp);
CREATE INDEX idx_orders_year_month ON cleaned.orders(order_year, order_month);

-- Validation
SELECT 
    order_status,
    COUNT(*) AS order_count,
    ROUND(AVG(delivery_days), 1) AS avg_delivery_days,
    ROUND(AVG(CASE WHEN delivered_on_time THEN 1 ELSE 0 END) * 100, 1) AS on_time_pct
FROM cleaned.orders
WHERE order_status = 'delivered'
GROUP BY order_status;


---

--  5: CLEAN TABLE 3 - ORDER ITEMS


/*
═══════════════════════════════════════════════════════════
FILE: 05_clean_order_items.sql
PURPOSE: Clean and validate order items
═══════════════════════════════════════════════════════════
*/

CREATE TABLE cleaned.order_items AS
SELECT 
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    -- Ensure positive prices
    CASE 
        WHEN price < 0 THEN 0
        ELSE ROUND(price::NUMERIC, 2)
    END AS price,
    -- Ensure positive freight
    CASE 
        WHEN freight_value < 0 THEN 0
        ELSE ROUND(freight_value::NUMERIC, 2)
    END AS freight_value,
    -- Calculate total item value
    ROUND((CASE WHEN price < 0 THEN 0 ELSE price END + 
           CASE WHEN freight_value < 0 THEN 0 ELSE freight_value END)::NUMERIC, 2) AS total_item_value
FROM raw.order_items
WHERE order_id IS NOT NULL
  AND product_id IS NOT NULL
  AND seller_id IS NOT NULL;

-- Add composite primary key
ALTER TABLE cleaned.order_items 
ADD CONSTRAINT pk_order_items PRIMARY KEY (order_id, order_item_id);

-- Add foreign keys
ALTER TABLE cleaned.order_items
ADD CONSTRAINT fk_order_items_order 
FOREIGN KEY (order_id) REFERENCES cleaned.orders(order_id);

-- Create indexes
CREATE INDEX idx_order_items_order ON cleaned.order_items(order_id);
CREATE INDEX idx_order_items_product ON cleaned.order_items(product_id);
CREATE INDEX idx_order_items_seller ON cleaned.order_items(seller_id);

-- Validation
SELECT 
    COUNT(*) AS total_items,
    COUNT(DISTINCT order_id) AS unique_orders,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(AVG(freight_value), 2) AS avg_freight,
    ROUND(MIN(price), 2) AS min_price,
    ROUND(MAX(price), 2) AS max_price
FROM cleaned.order_items;


---

-- 6: CLEAN TABLE 4 - ORDER PAYMENTS


/*
═══════════════════════════════════════════════════════════
FILE: 06_clean_order_payments.sql
PURPOSE: Clean and aggregate order payments
═══════════════════════════════════════════════════════════
*/

CREATE TABLE cleaned.order_payments AS
SELECT 
    order_id,
    payment_sequential,
    -- Standardize payment types
    CASE 
        WHEN LOWER(TRIM(payment_type)) = 'credit_card' THEN 'credit_card'
        WHEN LOWER(TRIM(payment_type)) = 'boleto' THEN 'boleto'
        WHEN LOWER(TRIM(payment_type)) = 'voucher' THEN 'voucher'
        WHEN LOWER(TRIM(payment_type)) = 'debit_card' THEN 'debit_card'
        ELSE 'other'
    END AS payment_type,
    payment_installments,
    -- Ensure positive payment values
    CASE 
        WHEN payment_value < 0 THEN 0
        ELSE ROUND(payment_value::NUMERIC, 2)
    END AS payment_value
FROM raw.order_payments
WHERE order_id IS NOT NULL
  AND payment_value > 0;

-- Create composite primary key
ALTER TABLE cleaned.order_payments 
ADD CONSTRAINT pk_order_payments PRIMARY KEY (order_id, payment_sequential);

-- Add foreign key
ALTER TABLE cleaned.order_payments
ADD CONSTRAINT fk_order_payments_order 
FOREIGN KEY (order_id) REFERENCES cleaned.orders(order_id);

-- Create indexes
CREATE INDEX idx_order_payments_order ON cleaned.order_payments(order_id);
CREATE INDEX idx_order_payments_type ON cleaned.order_payments(payment_type);

-- Create aggregated payment summary per order
CREATE TABLE cleaned.order_payments_summary AS
SELECT 
    order_id,
    COUNT(*) AS payment_count,
    STRING_AGG(DISTINCT payment_type, ', ') AS payment_methods,
    ROUND(SUM(payment_value)::NUMERIC, 2) AS total_payment_value,
    MAX(payment_installments) AS max_installments
FROM cleaned.order_payments
GROUP BY order_id;

-- Add primary key to summary
ALTER TABLE cleaned.order_payments_summary
ADD CONSTRAINT pk_order_payments_summary PRIMARY KEY (order_id);

-- Validation
SELECT 
    payment_type,
    COUNT(*) AS payment_count,
    ROUND(SUM(payment_value), 2) AS total_value,
    ROUND(AVG(payment_value), 2) AS avg_value,
    ROUND(AVG(payment_installments), 1) AS avg_installments
FROM cleaned.order_payments
GROUP BY payment_type
ORDER BY total_value DESC;


---

-- 7: CLEAN TABLE 5 - ORDER REVIEWS

/*
═══════════════════════════════════════════════════════════
FILE: 07_clean_order_reviews.sql
PURPOSE: Clean customer reviews
═══════════════════════════════════════════════════════════
*/

CREATE TABLE cleaned.order_reviews AS
SELECT DISTINCT ON (review_id)
    review_id,
    order_id,
    -- Ensure review score is between 1-5
    CASE 
        WHEN review_score < 1 THEN 1
        WHEN review_score > 5 THEN 5
        ELSE review_score
    END AS review_score,
    -- Clean review title (trim whitespace)
    NULLIF(TRIM(review_comment_title), '') AS review_comment_title,
    -- Clean review message (trim whitespace)
    NULLIF(TRIM(review_comment_message), '') AS review_comment_message,
    review_creation_date,
    review_answer_timestamp,
    -- Add review sentiment category
    CASE 
        WHEN review_score >= 4 THEN 'positive'
        WHEN review_score = 3 THEN 'neutral'
        ELSE 'negative'
    END AS review_sentiment,
    -- Check if review has comment
    CASE 
        WHEN review_comment_message IS NOT NULL 
         AND TRIM(review_comment_message) != '' 
        THEN TRUE 
        ELSE FALSE 
    END AS has_comment,
    -- Calculate response time
    CASE 
        WHEN review_answer_timestamp IS NOT NULL
        THEN EXTRACT(DAY FROM (review_answer_timestamp - review_creation_date))
        ELSE NULL
    END AS response_time_days
FROM raw.order_reviews
WHERE review_id IS NOT NULL
  AND order_id IS NOT NULL
ORDER BY review_id;

-- Add primary key
ALTER TABLE cleaned.order_reviews 
ADD CONSTRAINT pk_order_reviews PRIMARY KEY (review_id);

-- Add foreign key
ALTER TABLE cleaned.order_reviews
ADD CONSTRAINT fk_order_reviews_order 
FOREIGN KEY (order_id) REFERENCES cleaned.orders(order_id);

-- Create indexes
CREATE INDEX idx_order_reviews_order ON cleaned.order_reviews(order_id);
CREATE INDEX idx_order_reviews_score ON cleaned.order_reviews(review_score);
CREATE INDEX idx_order_reviews_sentiment ON cleaned.order_reviews(review_sentiment);

-- Validation
SELECT 
    review_score,
    review_sentiment,
    COUNT(*) AS review_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    COUNT(*) FILTER (WHERE has_comment = TRUE) AS with_comments
FROM cleaned.order_reviews
GROUP BY review_score, review_sentiment
ORDER BY review_score DESC;


---

--  8: CLEAN TABLE 6 - PRODUCTS


/*
═══════════════════════════════════════════════════════════
FILE: 08_clean_products.sql
PURPOSE: Clean products table and add English translations
═══════════════════════════════════════════════════════════
*/

CREATE TABLE cleaned.products AS
SELECT 
    p.product_id,
    -- Add English category name from translation table
    COALESCE(ct.product_category_name_english, 'unknown') AS product_category,
    p.product_category_name AS product_category_portuguese,
    -- Handle NULL product attributes
    COALESCE(p.product_name_lenght, 0) AS product_name_length,
    COALESCE(p.product_description_lenght, 0) AS product_description_length,
    COALESCE(p.product_photos_qty, 0) AS product_photos_qty,
    -- Weight in kg (convert from grams)
    CASE 
        WHEN p.product_weight_g > 0 
        THEN ROUND((p.product_weight_g / 1000.0)::NUMERIC, 3)
        ELSE NULL
    END AS product_weight_kg,
    p.product_weight_g,
    -- Dimensions in cm
    CASE WHEN p.product_length_cm > 0 THEN p.product_length_cm ELSE NULL END AS product_length_cm,
    CASE WHEN p.product_height_cm > 0 THEN p.product_height_cm ELSE NULL END AS product_height_cm,
    CASE WHEN p.product_width_cm > 0 THEN p.product_width_cm ELSE NULL END AS product_width_cm,
    -- Calculate volume in cubic cm
    CASE 
        WHEN p.product_length_cm > 0 
         AND p.product_height_cm > 0 
         AND p.product_width_cm > 0
        THEN p.product_length_cm * p.product_height_cm * p.product_width_cm
        ELSE NULL
    END AS product_volume_cm3,
    -- Add product size category
    CASE 
        WHEN p.product_weight_g IS NULL OR p.product_weight_g <= 0 THEN 'unknown'
        WHEN p.product_weight_g <= 1000 THEN 'small'      -- <= 1kg
        WHEN p.product_weight_g <= 5000 THEN 'medium'     -- 1-5kg
        WHEN p.product_weight_g <= 20000 THEN 'large'     -- 5-20kg
        ELSE 'extra_large'                                 -- > 20kg
    END AS product_size_category
FROM raw.products p
LEFT JOIN raw.category_translation ct 
    ON p.product_category_name = ct.product_category_name
WHERE p.product_id IS NOT NULL;

-- Add primary key
ALTER TABLE cleaned.products 
ADD CONSTRAINT pk_products PRIMARY KEY (product_id);

-- Create indexes
CREATE INDEX idx_products_category ON cleaned.products(product_category);
CREATE INDEX idx_products_size_category ON cleaned.products(product_size_category);

-- Validation
SELECT 
    product_category,
    COUNT(*) AS product_count,
    ROUND(AVG(product_weight_kg), 2) AS avg_weight_kg,
    COUNT(*) FILTER (WHERE product_weight_kg IS NULL) AS null_weights
FROM cleaned.products
GROUP BY product_category
ORDER BY product_count DESC
LIMIT 10;


---

-- 9: CLEAN TABLE 7 - SELLERS

/*
═══════════════════════════════════════════════════════════
FILE: 09_clean_sellers.sql
PURPOSE: Clean sellers table
═══════════════════════════════════════════════════════════
*/

CREATE TABLE cleaned.sellers AS
SELECT DISTINCT ON (seller_id)
    seller_id,
    seller_zip_code_prefix,
    -- Standardize city names
    INITCAP(TRIM(seller_city)) AS seller_city,
    -- Standardize state codes
    UPPER(TRIM(seller_state)) AS seller_state
FROM raw.sellers
WHERE seller_id IS NOT NULL
ORDER BY seller_id;

-- Add primary key
ALTER TABLE cleaned.sellers 
ADD CONSTRAINT pk_sellers PRIMARY KEY (seller_id);

-- Create indexes
CREATE INDEX idx_sellers_state ON cleaned.sellers(seller_state);
CREATE INDEX idx_sellers_city ON cleaned.sellers(seller_city);

-- Add foreign key to order_items
ALTER TABLE cleaned.order_items
ADD CONSTRAINT fk_order_items_seller 
FOREIGN KEY (seller_id) REFERENCES cleaned.sellers(seller_id);

-- Validation
SELECT 
    seller_state,
    COUNT(DISTINCT seller_id) AS seller_count,
    COUNT(DISTINCT seller_city) AS city_count
FROM cleaned.sellers
GROUP BY seller_state
ORDER BY seller_count DESC;


---

-- 10: CLEAN TABLE 8 - GEOLOCATION

/*
═══════════════════════════════════════════════════════════
FILE: 10_clean_geolocation.sql
PURPOSE: Clean and deduplicate geolocation data
═══════════════════════════════════════════════════════════
*/

-- Geolocation has 1M+ records with many duplicates
-- We'll create a cleaned version with one record per zip code

CREATE TABLE cleaned.geolocation AS
SELECT DISTINCT ON (geolocation_zip_code_prefix)
    geolocation_zip_code_prefix,
    ROUND(geolocation_lat::NUMERIC, 6) AS geolocation_lat,
    ROUND(geolocation_lng::NUMERIC, 6) AS geolocation_lng,
    INITCAP(TRIM(geolocation_city)) AS geolocation_city,
    UPPER(TRIM(geolocation_state)) AS geolocation_state
FROM raw.geolocation
WHERE geolocation_zip_code_prefix IS NOT NULL
  AND geolocation_lat IS NOT NULL
  AND geolocation_lng IS NOT NULL
  -- Filter invalid coordinates
  AND geolocation_lat BETWEEN -90 AND 90
  AND geolocation_lng BETWEEN -180 AND 180
ORDER BY geolocation_zip_code_prefix, geolocation_lat;

-- Add primary key
ALTER TABLE cleaned.geolocation 
ADD CONSTRAINT pk_geolocation PRIMARY KEY (geolocation_zip_code_prefix);

-- Create index
CREATE INDEX idx_geolocation_state ON cleaned.geolocation(geolocation_state);

-- Validation
SELECT 
    'Raw geolocation' AS version,
    COUNT(*) AS total_records,
    COUNT(DISTINCT geolocation_zip_code_prefix) AS unique_zip_codes
FROM raw.geolocation
UNION ALL
SELECT 
    'Cleaned geolocation',
    COUNT(*),
    COUNT(DISTINCT geolocation_zip_code_prefix)
FROM cleaned.geolocation;


---

-- 11: CLEAN TABLE 9 - CATEGORY TRANSLATION


/*
═══════════════════════════════════════════════════════════
FILE: 11_clean_category_translation.sql
PURPOSE: Clean category translation table
═══════════════════════════════════════════════════════════
*/

CREATE TABLE cleaned.category_translation AS
SELECT DISTINCT ON (product_category_name)
    TRIM(product_category_name) AS product_category_name,
    TRIM(product_category_name_english) AS product_category_name_english
FROM raw.category_translation
WHERE product_category_name IS NOT NULL
  AND product_category_name_english IS NOT NULL
ORDER BY product_category_name;

-- Add primary key
ALTER TABLE cleaned.category_translation 
ADD CONSTRAINT pk_category_translation PRIMARY KEY (product_category_name);

-- Validation
SELECT COUNT(*) AS total_categories
FROM cleaned.category_translation;


---

-- 12: FINAL DATA QUALITY VALIDATION


/*
═══════════════════════════════════════════════════════════
FILE: 12_final_validation.sql
PURPOSE: Validate all cleaned tables
═══════════════════════════════════════════════════════════
*/

-- ═══════════════════════════════════════════════════════════
-- COMPREHENSIVE VALIDATION REPORT
-- ═══════════════════════════════════════════════════════════

-- Table record counts comparison
SELECT 
    'customers' AS table_name,
    (SELECT COUNT(*) FROM raw.customers) AS raw_count,
    (SELECT COUNT(*) FROM cleaned.customers) AS cleaned_count,
    (SELECT COUNT(*) FROM raw.customers) - (SELECT COUNT(*) FROM cleaned.customers) AS records_removed
UNION ALL
SELECT 'orders',
    (SELECT COUNT(*) FROM raw.orders),
    (SELECT COUNT(*) FROM cleaned.orders),
    (SELECT COUNT(*) FROM raw.orders) - (SELECT COUNT(*) FROM cleaned.orders)
UNION ALL
SELECT 'order_items',
    (SELECT COUNT(*) FROM raw.order_items),
    (SELECT COUNT(*) FROM cleaned.order_items),
    (SELECT COUNT(*) FROM raw.order_items) - (SELECT COUNT(*) FROM cleaned.order_items)
UNION ALL
SELECT 'order_payments',
    (SELECT COUNT(*) FROM raw.order_payments),
    (SELECT COUNT(*) FROM cleaned.order_payments),
    (SELECT COUNT(*) FROM raw.order_payments) - (SELECT COUNT(*) FROM cleaned.order_payments)
UNION ALL
SELECT 'order_reviews',
    (SELECT COUNT(*) FROM raw.order_reviews),
    (SELECT COUNT(*) FROM cleaned.order_reviews),
    (SELECT COUNT(*) FROM raw.order_reviews) - (SELECT COUNT(*) FROM cleaned.order_reviews)
UNION ALL
SELECT 'products',
    (SELECT COUNT(*) FROM raw.products),
    (SELECT COUNT(*) FROM cleaned.products),
    (SELECT COUNT(*) FROM raw.products) - (SELECT COUNT(*) FROM cleaned.products)
UNION ALL
SELECT 'sellers',
    (SELECT COUNT(*) FROM raw.sellers),
    (SELECT COUNT(*) FROM cleaned.sellers),
    (SELECT COUNT(*) FROM raw.sellers) - (SELECT COUNT(*) FROM cleaned.sellers)
UNION ALL
SELECT 'geolocation',
    (SELECT COUNT(*) FROM raw.geolocation),
    (SELECT COUNT(*) FROM cleaned.geolocation),
    (SELECT COUNT(*) FROM raw.geolocation) - (SELECT COUNT(*) FROM cleaned.geolocation);


-- ═══════════════════════════════════════════════════════════
-- CHECK FOR ORPHANED RECORDS (Referential Integrity)
-- ═══════════════════════════════════════════════════════════

SELECT 
    'Orders without valid customer' AS integrity_check,
    COUNT(*)::TEXT AS issue_count
FROM cleaned.orders o
LEFT JOIN cleaned.customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

SELECT 'Order items without valid order',
    COUNT(*)::TEXT
FROM cleaned.order_items oi
LEFT JOIN cleaned.orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT 'Order items without valid product',
    COUNT(*)::TEXT
FROM cleaned.order_items oi
LEFT JOIN cleaned.products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

SELECT 'Order items without valid seller',
    COUNT(*)::TEXT
FROM cleaned.order_items oi
LEFT JOIN cleaned.sellers s ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL

UNION ALL

SELECT 'Order payments without valid order',
    COUNT(*)::TEXT
FROM cleaned.order_payments op
LEFT JOIN cleaned.orders o ON op.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT 'Order reviews without valid order',
    COUNT(*)::TEXT
FROM cleaned.order_reviews r
LEFT JOIN cleaned.orders o ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


-- ═══════════════════════════════════════════════════════════
-- DATA QUALITY METRICS
-- ═══════════════════════════════════════════════════════════

SELECT 
    'Total Orders' AS metric,
    COUNT(*)::TEXT AS value
FROM cleaned.orders
UNION ALL
SELECT 'Total Customers',
    COUNT(DISTINCT customer_id)::TEXT
FROM cleaned.orders
UNION ALL
SELECT 'Total Products Sold',
    COUNT(DISTINCT product_id)::TEXT
FROM cleaned.order_items
UNION ALL
SELECT 'Total Sellers',
    COUNT(*)::TEXT
FROM cleaned.sellers
UNION ALL
SELECT 'Average Order Value',
    '₹' || ROUND(AVG(total_payment_value), 2)::TEXT
FROM cleaned.order_payments_summary
UNION ALL
SELECT 'Average Review Score',
    ROUND(AVG(review_score), 2)::TEXT
FROM cleaned.order_reviews
UNION ALL
SELECT 'Orders Delivered On Time %',
    ROUND(AVG(CASE WHEN delivered_on_time THEN 1 ELSE 0 END) * 100, 1)::TEXT || '%'
FROM cleaned.orders
WHERE order_status = 'delivered';


---

-- 13: EXPORT CLEANED DATA (OPTIONAL)


/*
═══════════════════════════════════════════════════════════
FILE: 13_export_cleaned_data.sql
PURPOSE: Export cleaned tables to CSV for backup/sharing
═══════════════════════════════════════════════════════════
*/
SELECT * FROM cleaned.customers;



-- Then manually move the file from C:\temp\ to your OneDrive folder
-- Export cleaned customers
\copy cleaned.customers 
TO 'C:\Users\sumit\OneDrive\Documents\Olist dataset practise\cleaned Data\customers_clean.csv'
CSV HEADER;

-- Export cleaned orders
COPY cleaned.orders 
TO 'C:\\Users\\sumit\\OneDrive\\Documents\\Olist dataset practise\\cleaned Data\\orders_clean.csv' 
CSV HEADER;

-- Export cleaned products
COPY cleaned.products 
TO 'C:\\Users\\sumit\\OneDrive\\Documents\\Olist dataset practise\\cleaned Data\\products_clean.csv' 
CSV HEADER;

-- Export data quality summary
COPY (
    SELECT * FROM (
        SELECT 
            'customers' AS table_name,
            COUNT(*) AS records,
            COUNT(DISTINCT customer_id) AS unique_ids
        FROM cleaned.customers
        UNION ALL
        SELECT 'orders', COUNT(*), COUNT(DISTINCT order_id)
        FROM cleaned.orders
        UNION ALL
        SELECT 'products', COUNT(*), COUNT(DISTINCT product_id)
        FROM cleaned.products
    ) summary
) 
TO 'C:\\Users\\sumit\\OneDrive\\Documents\\Olist dataset practise\\cleaned Data\\data_quality_summary.csv' 
CSV HEADER;



