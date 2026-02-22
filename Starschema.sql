--1 Creating dim_customer :

--Takes your cleaned customers table
--Adds customer purchase history
--Adds location coordinates
--Creates customer segments (Loyal/Repeat/One-time)


-- STEP 1: Create Customer Dimension
CREATE TABLE cleaned.dim_customer AS
SELECT 
    c.customer_id,
    c.customer_unique_id,
    c.customer_zip_code_prefix,
    c.customer_city,
    c.customer_state,
    -- Add geolocation data
    g.geolocation_lat,
    g.geolocation_lng,
    -- Add customer metrics from orders
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(ops.total_payment_value), 2) AS total_spent,
    ROUND(AVG(ops.total_payment_value), 2) AS avg_order_value,
    MIN(o.order_purchase_timestamp)::DATE AS first_order_date,
    MAX(o.order_purchase_timestamp)::DATE AS last_order_date,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    -- Customer segment
    CASE 
        WHEN COUNT(DISTINCT o.order_id) >= 3 THEN 'Loyal'
        WHEN COUNT(DISTINCT o.order_id) = 2 THEN 'Repeat'
        ELSE 'One-time'
    END AS customer_segment,
    -- Customer value category
    CASE 
        WHEN SUM(ops.total_payment_value) >= 1000 THEN 'High Value'
        WHEN SUM(ops.total_payment_value) >= 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM cleaned.customers c
LEFT JOIN cleaned.orders o ON c.customer_id = o.customer_id
LEFT JOIN cleaned.order_payments_summary ops ON o.order_id = ops.order_id
LEFT JOIN cleaned.order_reviews r ON o.order_id = r.order_id
LEFT JOIN cleaned.geolocation g ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
GROUP BY 
    c.customer_id,
    c.customer_unique_id,
    c.customer_zip_code_prefix,
    c.customer_city,
    c.customer_state,
    g.geolocation_lat,
    g.geolocation_lng;

-- Adding primary key
ALTER TABLE cleaned.dim_customer 
ADD CONSTRAINT pk_dim_customer PRIMARY KEY (customer_id);

-- Verifing is it worked
SELECT COUNT(*) AS total_customers FROM cleaned.dim_customer;

-- Lets See sample data
SELECT * FROM cleaned.dim_customer LIMIT 5;

-- See sample of the data
SELECT 
    customer_id,
    customer_city,
    customer_state,
    total_orders,
    total_spent,
    customer_segment
FROM cleaned.dim_customer 
LIMIT 10;


-- STEP 2: Create Product Dimension (FIXED)
CREATE TABLE cleaned.dim_product AS
SELECT 
    p.product_id,
    p.product_category,
    p.product_category_portuguese,
    p.product_name_length,
    p.product_description_length,
    p.product_photos_qty,
    p.product_weight_kg,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    p.product_volume_cm3,
    p.product_size_category,
    -- Add sales metrics
    COUNT(DISTINCT oi.order_id) AS times_ordered,
    COUNT(oi.order_item_id) AS total_quantity_sold,  -- FIXED: count items instead
    ROUND(COALESCE(SUM(oi.total_item_value), 0), 2) AS total_revenue,
    ROUND(COALESCE(AVG(oi.price), 0), 2) AS avg_price,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    -- Product performance
    CASE 
        WHEN COALESCE(SUM(oi.total_item_value), 0) >= 10000 THEN 'Top Seller'
        WHEN COALESCE(SUM(oi.total_item_value), 0) >= 5000 THEN 'Good Seller'
        WHEN COALESCE(SUM(oi.total_item_value), 0) >= 1000 THEN 'Average Seller'
        ELSE 'Low Seller'
    END AS product_performance
FROM cleaned.products p
LEFT JOIN cleaned.order_items oi ON p.product_id = oi.product_id
LEFT JOIN cleaned.orders o ON oi.order_id = o.order_id
LEFT JOIN cleaned.order_reviews r ON o.order_id = r.order_id
GROUP BY 
    p.product_id,
    p.product_category,
    p.product_category_portuguese,
    p.product_name_length,
    p.product_description_length,
    p.product_photos_qty,
    p.product_weight_kg,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    p.product_volume_cm3,
    p.product_size_category;

-- Add primary key
ALTER TABLE cleaned.dim_product 
ADD CONSTRAINT pk_dim_product PRIMARY KEY (product_id);

-- Verify it worked
SELECT COUNT(*) AS total_products FROM cleaned.dim_product;

-- See top selling categories
SELECT 
    product_category,
    COUNT(*) AS product_count,
    ROUND(SUM(total_revenue), 2) AS category_revenue
FROM cleaned.dim_product
GROUP BY product_category
ORDER BY category_revenue DESC
LIMIT 10;
select * from cleaned.dim_product


-- STEP 3: Create Seller Dimension
CREATE TABLE cleaned.dim_seller AS
SELECT 
    s.seller_id,
    s.seller_zip_code_prefix,
    s.seller_city,
    s.seller_state,
    -- Add geolocation
    g.geolocation_lat,
    g.geolocation_lng,
    -- Add sales metrics
    COUNT(DISTINCT oi.order_id) AS total_orders_fulfilled,
    COUNT(oi.order_item_id) AS total_items_sold,
    ROUND(COALESCE(SUM(oi.total_item_value), 0), 2) AS total_revenue,
    ROUND(COALESCE(AVG(oi.price), 0), 2) AS avg_item_price,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    -- Seller performance
    CASE 
        WHEN COUNT(DISTINCT oi.order_id) >= 100 THEN 'Top Seller'
        WHEN COUNT(DISTINCT oi.order_id) >= 50 THEN 'Active Seller'
        WHEN COUNT(DISTINCT oi.order_id) >= 10 THEN 'Regular Seller'
        ELSE 'New Seller'
    END AS seller_performance_category
FROM cleaned.sellers s
LEFT JOIN cleaned.order_items oi ON s.seller_id = oi.seller_id
LEFT JOIN cleaned.orders o ON oi.order_id = o.order_id
LEFT JOIN cleaned.order_reviews r ON o.order_id = r.order_id
LEFT JOIN cleaned.geolocation g ON s.seller_zip_code_prefix = g.geolocation_zip_code_prefix
GROUP BY 
    s.seller_id,
    s.seller_zip_code_prefix,
    s.seller_city,
    s.seller_state,
    g.geolocation_lat,
    g.geolocation_lng;

-- Add primary key
ALTER TABLE cleaned.dim_seller 
ADD CONSTRAINT pk_dim_seller PRIMARY KEY (seller_id);

-- Verify it worked
SELECT COUNT(*) AS total_sellers FROM cleaned.dim_seller;

-- See seller distribution by category
SELECT 
    seller_performance_category,
    COUNT(*) AS seller_count
FROM cleaned.dim_seller
GROUP BY seller_performance_category
ORDER BY seller_count DESC;


-- STEP 4: Create Date Dimension
CREATE TABLE cleaned.dim_date AS
SELECT DISTINCT
    o.order_purchase_timestamp::DATE AS date_key,
    o.order_purchase_timestamp::DATE AS full_date,
    EXTRACT(YEAR FROM o.order_purchase_timestamp) AS year,
    EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month,
    EXTRACT(DAY FROM o.order_purchase_timestamp) AS day,
    EXTRACT(QUARTER FROM o.order_purchase_timestamp) AS quarter,
    EXTRACT(DOW FROM o.order_purchase_timestamp) AS day_of_week_number,
    TO_CHAR(o.order_purchase_timestamp, 'Day') AS day_of_week_name,
    TO_CHAR(o.order_purchase_timestamp, 'Month') AS month_name,
    EXTRACT(WEEK FROM o.order_purchase_timestamp) AS week_of_year,
    CASE 
        WHEN EXTRACT(DOW FROM o.order_purchase_timestamp) IN (0, 6) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    -- Year-Month for grouping
    TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM') AS year_month,
    -- Quarter name
    'Q' || EXTRACT(QUARTER FROM o.order_purchase_timestamp)::TEXT || ' ' || 
    EXTRACT(YEAR FROM o.order_purchase_timestamp)::TEXT AS quarter_name
FROM cleaned.orders o
WHERE o.order_purchase_timestamp IS NOT NULL
ORDER BY date_key;

-- Add primary key
ALTER TABLE cleaned.dim_date 
ADD CONSTRAINT pk_dim_date PRIMARY KEY (date_key);

-- Verify it worked
SELECT COUNT(*) AS total_dates FROM cleaned.dim_date;

-- See date range
SELECT 
    MIN(date_key) AS first_date,
    MAX(date_key) AS last_date,
    COUNT(*) AS total_days
FROM cleaned.dim_date;




-- STEP 5: Create Fact Sales (Main Table!)
CREATE TABLE cleaned.fact_sales AS
SELECT 
    -- Unique row ID
    ROW_NUMBER() OVER (ORDER BY o.order_id, oi.order_item_id) AS sales_key,
    
    -- Foreign keys (links to dimension tables)
    o.order_id,
    o.customer_id,
    oi.product_id,
    oi.seller_id,
    o.order_purchase_timestamp::DATE AS date_key,
    
    -- Order information
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    
    -- Money measures
    oi.price AS item_price,
    oi.freight_value,
    oi.total_item_value,
    COALESCE(op.total_payment_value, 0) AS order_total,
    COALESCE(op.payment_count, 0) AS payment_count,
    COALESCE(op.max_installments, 0) AS max_installments,
    
    -- Delivery measures
    o.delivery_days,
    o.delivered_on_time,
    CASE 
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 0
        WHEN o.order_delivered_customer_date IS NOT NULL AND o.order_estimated_delivery_date IS NOT NULL
        THEN EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date))
        ELSE NULL
    END AS days_late,
    
    -- Review measures
    r.review_score,
    r.review_sentiment,
    r.has_comment,
    
    -- Categories for filtering (from dimension tables)
    op.payment_methods,
    p.product_category,
    p.product_size_category,
    c.customer_state,
    c.customer_city,
    s.seller_state AS seller_state,
    s.seller_city AS seller_city,
    
    -- Time fields for easy filtering
    o.order_year,
    o.order_month,
    o.order_quarter,
    o.order_day_of_week,
    o.order_month_name

FROM cleaned.orders o
INNER JOIN cleaned.order_items oi ON o.order_id = oi.order_id
LEFT JOIN cleaned.order_payments_summary op ON o.order_id = op.order_id
LEFT JOIN cleaned.order_reviews r ON o.order_id = r.order_id
LEFT JOIN cleaned.products p ON oi.product_id = p.product_id
LEFT JOIN cleaned.customers c ON o.customer_id = c.customer_id
LEFT JOIN cleaned.sellers s ON oi.seller_id = s.seller_id;

-- Add primary key
ALTER TABLE cleaned.fact_sales 
ADD CONSTRAINT pk_fact_sales PRIMARY KEY (sales_key);

-- Verify it worked
SELECT COUNT(*) AS total_sales_records FROM cleaned.fact_sales;

-- See summary stats
SELECT 
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    COUNT(DISTINCT product_id) AS total_products,
    ROUND(SUM(item_price), 2) AS total_revenue,
    ROUND(AVG(item_price), 2) AS avg_item_price
FROM cleaned.fact_sales;



-- STEP 6: Final Validation

-- Check all tables exist and record counts
SELECT 
    'dim_customer' AS table_name,
    COUNT(*)::TEXT AS record_count
FROM cleaned.dim_customer
UNION ALL
SELECT 'dim_product', COUNT(*)::TEXT FROM cleaned.dim_product
UNION ALL
SELECT 'dim_seller', COUNT(*)::TEXT FROM cleaned.dim_seller
UNION ALL
SELECT 'dim_date', COUNT(*)::TEXT FROM cleaned.dim_date
UNION ALL
SELECT 'fact_sales', COUNT(*)::TEXT FROM cleaned.fact_sales;

-- Validate relationships (should all return 0)
SELECT 
    'fact_sales without valid customer' AS validation_check,
    COUNT(*)::TEXT AS issue_count
FROM cleaned.fact_sales f
LEFT JOIN cleaned.dim_customer c ON f.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

SELECT 'fact_sales without valid product',
    COUNT(*)::TEXT
FROM cleaned.fact_sales f
LEFT JOIN cleaned.dim_product p ON f.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

SELECT 'fact_sales without valid seller',
    COUNT(*)::TEXT
FROM cleaned.fact_sales f
LEFT JOIN cleaned.dim_seller s ON f.seller_id = s.seller_id
WHERE s.seller_id IS NULL

UNION ALL

SELECT 'fact_sales without valid date',
    COUNT(*)::TEXT
FROM cleaned.fact_sales f
LEFT JOIN cleaned.dim_date d ON f.date_key = d.date_key
WHERE d.date_key IS NULL;