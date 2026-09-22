-- Data validation: primary keys, foreign keys, and relationship cardinalities.
-- Outputs: one result set per source-table or relationship check.

-- ============================================================
-- Table: customers
-- Candidate primary key: customer_id
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT customer_id) AS distinct_customer_id,
  COUNT(DISTINCT customer_unique_id) AS distinct_customer_unique_id,
  COUNTIF(customer_id IS NULL) AS null_customer_id,
  COUNTIF(customer_unique_id IS NULL) AS null_customer_unique_id
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.customers`;
-- ============================================================

-- ============================================================
-- Table: geolocation (no natural primary key identified)
-- Output: row count, ZIP-prefix coverage, and null-prefix count.
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT geolocation_zip_code_prefix) AS distinct_zip_code_prefixes,
  COUNTIF(geolocation_zip_code_prefix IS NULL) AS null_zip_code_prefix_rows
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.geolocation`;
-- ============================================================

-- ============================================================
-- Table: order_items
-- Candidate primary key: order_id + order_item_id
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT CONCAT(order_id, '|', CAST(order_item_id AS STRING))) AS distinct_composite_key,
  COUNTIF(order_id IS NULL OR order_item_id IS NULL) AS null_key_rows
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.order_items`;
-- ============================================================

-- ============================================================
-- Table: order_payments
-- Candidate primary key: order_id + payment_sequential
SELECT
  COUNT(*) AS total_rows,
  COUNT(
    DISTINCT CONCAT(
      order_id,
      '_',
      CAST(payment_sequential AS STRING)
    )
  ) AS distinct_composite_key,
  COUNTIF(
    order_id IS NULL
    OR payment_sequential IS NULL
  ) AS null_key_rows
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.order_payments`;
-- ============================================================

-- ============================================================
-- Table: order_reviews
-- Candidate primary key: review_id + order_id
SELECT
  COUNT(*) AS total_rows,
  COUNT(
    DISTINCT CONCAT(
      review_id,
      "-",
      order_id
    )
  ) AS distinct_review_order_id,
  COUNTIF(
    review_id IS NULL
    OR order_id IS NULL
  ) AS null_key_rows
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.order_reviews`;
-- ============================================================

-- ============================================================
-- Table: orders
-- Candidate primary key: order_id
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT order_id) AS distinct_order_id,
  COUNTIF(order_id IS NULL) AS null_order_id
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.orders`;
-- ============================================================

-- ============================================================
-- Table: product_category_name_translation
-- Candidate primary key: product_category_name
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT product_category_name) AS distinct_product_category_name,
  COUNTIF(product_category_name IS NULL) AS null_product_category_name
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.product_category_name_translation`;
-- ============================================================

-- ============================================================
-- Table: products
-- Candidate primary key: product_id
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT product_id) AS distinct_product_id,
  COUNTIF(product_id IS NULL) AS null_key_rows
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.products`;
-- ============================================================

-- ============================================================
-- Table: sellers
-- Candidate primary key: seller_id
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT seller_id) AS distinct_seller_id,
  COUNTIF(seller_id IS NULL) AS null_key_rows
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.sellers`;
-- ============================================================

-- ============================================================
-- Foreign key validation
-- orders.customer_id -> customers.customer_id
SELECT
  COUNT(*) AS unmatched_rows
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.orders` AS orders
LEFT JOIN `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.customers` AS customers
  ON orders.customer_id = customers.customer_id
WHERE orders.customer_id IS NOT NULL
  AND customers.customer_id IS NULL;
-- ============================================================

-- ============================================================
-- Foreign key validation
-- order_items.order_id -> orders.order_id
SELECT
  COUNT(*) AS unmatched_rows
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.order_items` AS order_items
LEFT JOIN `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.orders` AS orders
  ON order_items.order_id = orders.order_id
WHERE order_items.order_id IS NOT NULL
  AND orders.order_id IS NULL;
-- ============================================================

-- ============================================================
-- Foreign key validation
-- order_payments.order_id -> orders.order_id 
SELECT
  COUNT(*) AS unmatched_rows
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.order_payments` AS order_payments
LEFT JOIN `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.orders` AS orders
  ON order_payments.order_id = orders.order_id
WHERE order_payments.order_id IS NOT NULL
  AND orders.order_id IS NULL;
-- ============================================================

-- ============================================================
-- Foreign key validation
-- order_reviews.order_id -> orders.order_id
SELECT
  COUNT(*) AS unmatched_rows
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.order_reviews` AS order_reviews
LEFT JOIN `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.orders` AS orders
  ON order_reviews.order_id = orders.order_id
WHERE order_reviews.order_id IS NOT NULL
  AND orders.order_id IS NULL;
-- ============================================================

-- ============================================================
-- Foreign key validation
-- order_items.seller_id -> sellers.seller_id
SELECT
  COUNT(*) AS unmatched_rows
FROM
  `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.order_items` AS order_items
LEFT JOIN
  `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.sellers` AS sellers
ON order_items.seller_id = sellers.seller_id
WHERE
  order_items.seller_id IS NOT NULL
AND
  sellers.seller_id IS NULL;
-- ============================================================

-- ============================================================
-- Foreign key validation
-- products.product_category_name -> product_category_name_translation.product_category_name
SELECT
  COUNT(*) AS unmatched_rows
FROM
  `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.products` AS products
LEFT JOIN
  `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.product_category_name_translation` AS product_category_name_translation
ON products.product_category_name = product_category_name_translation.product_category_name 
WHERE
  products.product_category_name IS NOT NULL
AND
  product_category_name_translation.product_category_name IS NULL;
-- ============================================================

-- ============================================================
-- Foreign key validation
-- order_items.product_id -> products.product_id
SELECT
  COUNT(*) AS unmatched_rows
FROM
  `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.order_items` AS order_items
LEFT JOIN
  `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.products` AS products
ON order_items.product_id = products.product_id
WHERE
  order_items.product_id IS NOT NULL
AND
  products.product_id IS NULL;
-- ============================================================

-- ============================================================
-- Cardinality check
-- orders.customer_id
SELECT
  customer_id,
  COUNT(*) AS row_count
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.orders`
WHERE customer_id IS NOT NULL
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY row_count DESC;
-- ============================================================

-- ============================================================
-- Cardinality check
-- order_items.order_id
SELECT
  order_id,
  COUNT(*) AS row_count
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.order_items`
WHERE order_id IS NOT NULL
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY row_count DESC;

SELECT
  order_id,
  COUNT(DISTINCT product_id) AS product_count
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.order_items`
GROUP BY order_id
HAVING COUNT(DISTINCT product_id) > 1
ORDER BY product_count DESC;
-- ============================================================

-- ============================================================
-- Cardinality check
-- order_items.product_id
SELECT
  product_id,
  COUNT(*) AS row_count
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.order_items`
WHERE product_id IS NOT NULL
GROUP BY product_id
HAVING COUNT(*) > 1
ORDER BY row_count DESC;
-- ============================================================

-- ============================================================
-- Cardinality check
-- order_items.seller_id
SELECT
  seller_id,
  COUNT(*) AS row_count
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.order_items` AS order_items
WHERE seller_id IS NOT NULL
GROUP BY seller_id
HAVING COUNT(*) > 1
ORDER BY row_count DESC;

SELECT
  order_id,
  COUNT(DISTINCT seller_id) AS seller_count
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.order_items` AS order_items
GROUP BY order_id
HAVING seller_count > 1
ORDER BY seller_count DESC;
-- ============================================================

-- ============================================================
-- Cardinality check
-- order_payments.order_id
SELECT
  order_id,
  COUNT(*) AS row_count
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.order_payments` AS order_payments
GROUP BY order_id
HAVING row_count > 1
ORDER BY row_count DESC;
-- ============================================================

-- ============================================================
-- Cardinality check
-- order_reviews.order_id
SELECT
  order_id,
  COUNT(DISTINCT review_id) AS review_count
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.order_reviews`
GROUP BY order_id
HAVING review_count > 1
ORDER BY review_count DESC;
-- ============================================================

-- ============================================================
-- Cardinality check
-- products.product_category_name
SELECT
  product_category_name,
  COUNT(DISTINCT product_id) AS product_count
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.products`
GROUP BY product_category_name
HAVING product_count > 1
ORDER BY product_count DESC;
-- ============================================================
