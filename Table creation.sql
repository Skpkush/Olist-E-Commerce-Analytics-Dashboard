

CREATE SCHEMA raw;

-- 1. Customers
CREATE TABLE raw.customers (
    customer_id VARCHAR,
    customer_unique_id VARCHAR,
    customer_zip_code_prefix VARCHAR,
    customer_city VARCHAR,
    customer_state VARCHAR
);

-- 2. Orders (core table)
CREATE TABLE raw.orders (
    order_id VARCHAR,
    customer_id VARCHAR,
    order_status VARCHAR,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

-- 3. Order Items
CREATE TABLE raw.order_items (
    order_id VARCHAR,
    order_item_id INT,
    product_id VARCHAR,
    seller_id VARCHAR,
    shipping_limit_date TIMESTAMP,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
);

-- 4. Order Payments
CREATE TABLE raw.order_payments (
    order_id VARCHAR,
    payment_sequential INT,
    payment_type VARCHAR,
    payment_installments INT,
    payment_value DECIMAL(10,2)
);

-- 5. Order Reviews
CREATE TABLE raw.order_reviews (
    review_id VARCHAR,
    order_id VARCHAR,
    review_score INT,
    review_comment_title VARCHAR,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

-- 6. Products
CREATE TABLE raw.products (
    product_id VARCHAR,
    product_category_name VARCHAR,
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

-- 7. Sellers
CREATE TABLE raw.sellers (
    seller_id VARCHAR,
    seller_zip_code_prefix VARCHAR,
    seller_city VARCHAR,
    seller_state VARCHAR
);

-- 8. Geolocation
CREATE TABLE raw.geolocation (
    geolocation_zip_code_prefix VARCHAR,
    geolocation_lat DECIMAL(10,6),
    geolocation_lng DECIMAL(10,6),
    geolocation_city VARCHAR,
    geolocation_state VARCHAR
);

-- 9. Category Translation
CREATE TABLE raw.category_translation (
    product_category_name VARCHAR,
    product_category_name_english VARCHAR
);

select * from raw.category_translation
select * from raw.customers
select * from raw.geolocation
select * from raw.order_items
select * from raw.order_payments
select * from raw.order_reviews
select * from raw.orders
select * from raw.products
select * from raw.sellers


SELECT pg_relation_filepath('raw.category_translation');