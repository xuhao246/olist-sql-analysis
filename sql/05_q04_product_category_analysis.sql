-- Q4: How do product-category rankings differ by customer state and delivery month?
-- Outputs: state-category rankings, then delivery-month-category rankings.
-- Grain: one eligible order item per row in the temporary table; untranslated categories remain NULL.

CREATE TEMP TABLE eligible_category_items AS
SELECT
  oi.order_id,
  t.product_category_name_english,
  oi.price,
  c.customer_state AS state,
  DATE_TRUNC(DATE(o.order_delivered_customer_date), MONTH) AS order_delivered_customer_month
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.order_items` AS oi
JOIN `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.orders` AS o
  ON oi.order_id = o.order_id
JOIN `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.products` AS p
  ON oi.product_id = p.product_id
LEFT JOIN `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.product_category_name_translation` AS t
  ON p.product_category_name = t.product_category_name
JOIN `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.customers` AS c
  ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL;

-- Revenue and distinct-order ranks within each customer state.
WITH state_category_revenue AS (
  SELECT
    state,
    product_category_name_english,
    ROUND(SUM(price), 0) AS total_revenue,
    COUNT(DISTINCT order_id) AS order_count
  FROM eligible_category_items
  GROUP BY state, product_category_name_english
)
SELECT
  state,
  product_category_name_english,
  total_revenue,
  RANK() OVER (PARTITION BY state ORDER BY total_revenue DESC) AS total_revenue_ranking,
  order_count,
  RANK() OVER (PARTITION BY state ORDER BY order_count DESC) AS order_count_ranking
FROM state_category_revenue;

-- Revenue and distinct-order ranks within each customer-delivery month.
WITH month_category_revenue AS (
  SELECT
    order_delivered_customer_month,
    product_category_name_english,
    ROUND(SUM(price), 0) AS total_revenue,
    COUNT(DISTINCT order_id) AS order_count
  FROM eligible_category_items
  GROUP BY order_delivered_customer_month, product_category_name_english
)
SELECT
  order_delivered_customer_month,
  product_category_name_english,
  total_revenue,
  RANK() OVER (PARTITION BY order_delivered_customer_month ORDER BY total_revenue DESC) AS total_revenue_ranking,
  order_count,
  RANK() OVER (PARTITION BY order_delivered_customer_month ORDER BY order_count DESC) AS order_count_ranking
FROM month_category_revenue;
