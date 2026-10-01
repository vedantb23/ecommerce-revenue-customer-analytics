-- =====================================================
-- DATABASE SETUP & DATA INGESTION
-- E-Commerce Revenue, Customer & Operations Analytics
-- Vedant Bhavsar
-- =====================================================
-- This file handles the one-time infrastructure setup:
-- 1. Create database
-- 2. Create raw staging tables (all NVARCHAR for safe ingestion)
-- 3. Bulk-load CSV data
-- 4. Create cleaned/typed analytical tables
-- =====================================================

-- Step 1: Create Database
CREATE DATABASE EcommerceAnalytics;
GO
USE EcommerceAnalytics;
GO

-- =====================================================
-- Step 2: Create Raw Staging Tables
-- All columns as NVARCHAR to safely ingest messy CSV data
-- (avoids type-cast failures during bulk insert)
-- =====================================================

CREATE TABLE customers (
    customer_id NVARCHAR(50),
    customer_unique_id NVARCHAR(50),
    customer_zip_code_prefix NVARCHAR(20),
    customer_city NVARCHAR(100),
    customer_state NVARCHAR(10)
);

CREATE TABLE orders (
    order_id NVARCHAR(50),
    customer_id NVARCHAR(50),
    order_status NVARCHAR(50),
    order_purchase_timestamp NVARCHAR(50),
    order_approved_at NVARCHAR(50),
    order_delivered_carrier_date NVARCHAR(50),
    order_delivered_customer_date NVARCHAR(50),
    order_estimated_delivery_date NVARCHAR(50)
);

CREATE TABLE order_items (
    order_id NVARCHAR(50),
    order_item_id NVARCHAR(50),
    product_id NVARCHAR(50),
    seller_id NVARCHAR(50),
    shipping_limit_date NVARCHAR(50),
    price NVARCHAR(50),
    freight_value NVARCHAR(50)
);

CREATE TABLE payments (
    order_id NVARCHAR(50),
    payment_sequential NVARCHAR(50),
    payment_type NVARCHAR(50),
    payment_installments NVARCHAR(50),
    payment_value NVARCHAR(50)
);

CREATE TABLE products (
    product_id NVARCHAR(50),
    product_category_name NVARCHAR(100),
    product_name_length NVARCHAR(50),
    product_description_length NVARCHAR(50),
    product_photos_qty NVARCHAR(50),
    product_weight_g NVARCHAR(50),
    product_length_cm NVARCHAR(50),
    product_height_cm NVARCHAR(50),
    product_width_cm NVARCHAR(50)
);

CREATE TABLE sellers (
    seller_id NVARCHAR(100),
    seller_zip_code_prefix NVARCHAR(100),
    seller_city NVARCHAR(200),
    seller_state NVARCHAR(200)
);

CREATE TABLE reviews (
    review_id NVARCHAR(MAX),
    order_id NVARCHAR(MAX),
    review_score NVARCHAR(MAX),
    review_comment_title NVARCHAR(MAX),
    review_comment_message NVARCHAR(MAX),
    review_creation_date NVARCHAR(MAX),
    review_answer_timestamp NVARCHAR(MAX)
);

CREATE TABLE category_translation (
    product_category_name NVARCHAR(MAX),
    product_category_name_english NVARCHAR(MAX)
);

-- =====================================================
-- Step 3: Bulk Insert CSV Data
-- NOTE: Update file paths below to match your local data directory
-- =====================================================

BULK INSERT customers
FROM '<YOUR_DATA_PATH>\olist_customers_dataset.csv'
WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='0x0a');

BULK INSERT orders
FROM '<YOUR_DATA_PATH>\olist_orders_dataset.csv'
WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='0x0a');

BULK INSERT order_items
FROM '<YOUR_DATA_PATH>\olist_order_items_dataset.csv'
WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='0x0a');

BULK INSERT payments
FROM '<YOUR_DATA_PATH>\olist_order_payments_dataset.csv'
WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='0x0a');

BULK INSERT products
FROM '<YOUR_DATA_PATH>\olist_products_dataset.csv'
WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='0x0a');

BULK INSERT sellers
FROM '<YOUR_DATA_PATH>\olist_sellers_dataset.csv'
WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='0x0a');

BULK INSERT reviews
FROM '<YOUR_DATA_PATH>\olist_order_reviews_dataset.csv'
WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='0x0a');

BULK INSERT category_translation
FROM '<YOUR_DATA_PATH>\product_category_name_translation.csv'
WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='0x0a');

-- =====================================================
-- Step 4: Create Clean Analytical Tables
-- Converts NVARCHAR columns to proper data types using TRY_CAST
-- Trims whitespace from text fields
-- =====================================================

SELECT customer_id, customer_unique_id,
    TRY_CAST(customer_zip_code_prefix AS INT) AS customer_zip_code_prefix,
    LTRIM(RTRIM(customer_city)) AS customer_city,
    LTRIM(RTRIM(customer_state)) AS customer_state
INTO customers_clean
FROM customers;

SELECT order_id, customer_id,
    LTRIM(RTRIM(order_status)) AS order_status,
    TRY_CAST(order_purchase_timestamp AS DATETIME) AS order_purchase_timestamp,
    TRY_CAST(order_approved_at AS DATETIME) AS order_approved_at,
    TRY_CAST(order_delivered_carrier_date AS DATETIME) AS order_delivered_carrier_date,
    TRY_CAST(order_delivered_customer_date AS DATETIME) AS order_delivered_customer_date,
    TRY_CAST(order_estimated_delivery_date AS DATETIME) AS order_estimated_delivery_date
INTO orders_clean
FROM orders;

SELECT order_id,
    TRY_CAST(order_item_id AS INT) AS order_item_id,
    product_id, seller_id,
    TRY_CAST(shipping_limit_date AS DATETIME) AS shipping_limit_date,
    TRY_CAST(price AS FLOAT) AS price,
    TRY_CAST(freight_value AS FLOAT) AS freight_value
INTO order_items_clean
FROM order_items;

SELECT order_id,
    TRY_CAST(payment_sequential AS INT) AS payment_sequential,
    LTRIM(RTRIM(payment_type)) AS payment_type,
    TRY_CAST(payment_installments AS INT) AS payment_installments,
    TRY_CAST(payment_value AS FLOAT) AS payment_value
INTO payments_clean
FROM payments;

SELECT product_id,
    LTRIM(RTRIM(product_category_name)) AS product_category_name,
    TRY_CAST(product_name_length AS INT) AS product_name_length,
    TRY_CAST(product_description_length AS INT) AS product_description_length,
    TRY_CAST(product_photos_qty AS INT) AS product_photos_qty,
    TRY_CAST(product_weight_g AS INT) AS product_weight_g,
    TRY_CAST(product_length_cm AS INT) AS product_length_cm,
    TRY_CAST(product_height_cm AS INT) AS product_height_cm,
    TRY_CAST(product_width_cm AS INT) AS product_width_cm
INTO products_clean
FROM products;

SELECT seller_id,
    TRY_CAST(seller_zip_code_prefix AS INT) AS seller_zip_code_prefix,
    LTRIM(RTRIM(seller_city)) AS seller_city,
    LTRIM(RTRIM(seller_state)) AS seller_state
INTO sellers_clean
FROM sellers;

SELECT review_id, order_id,
    TRY_CAST(review_score AS INT) AS review_score,
    review_comment_title, review_comment_message,
    TRY_CAST(review_creation_date AS DATETIME) AS review_creation_date,
    TRY_CAST(review_answer_timestamp AS DATETIME) AS review_answer_timestamp
INTO reviews_clean
FROM reviews;
