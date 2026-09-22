-- Q7: How common are repeat purchases, and how many delivered orders do repeat customers place?
-- Outputs: repeat-order distribution, repeat-customer share, and median repeat-customer order count.
-- Customer identity uses customer_unique_id; the temporary table has one row per unique customer.

CREATE TEMP TABLE customer_order_counts AS
SELECT
  c.customer_unique_id,
  COUNT(DISTINCT o.order_id) AS order_count
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.orders` AS o
JOIN `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.customers` AS c
  ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_unique_id;

-- Distribution among customers with more than one delivered order.
WITH repeat_order_counts AS (
  SELECT
    order_count,
    COUNT(DISTINCT customer_unique_id) AS repeat_customer_count
  FROM customer_order_counts
  WHERE order_count > 1
  GROUP BY order_count
)
SELECT
  order_count,
  repeat_customer_count,
  ROUND(100 * repeat_customer_count / SUM(repeat_customer_count) OVER (), 2)
    AS repeat_customer_share_pct
FROM repeat_order_counts
ORDER BY order_count DESC;

-- Share of eligible customers who placed more than one delivered order.
SELECT
  COUNT(*) AS total_customers,
  COUNTIF(order_count > 1) AS total_repeat_customers,
  ROUND(100 * COUNTIF(order_count > 1) / COUNT(*), 2) AS repeat_customer_share_pct
FROM customer_order_counts;

-- Median delivered-order count among repeat customers.
SELECT DISTINCT
  PERCENTILE_CONT(order_count, 0.5) OVER () AS median_order_count
FROM customer_order_counts
WHERE order_count > 1;
