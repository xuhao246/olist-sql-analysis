-- Q3: Which customer states generate the most delivered orders and merchandise revenue?
-- Output: one row per customer state with order count, rounded revenue, and both ranks.
-- Revenue: sum of order_items.price for delivered orders with a customer delivery date.

WITH order_revenue AS (
  SELECT
    order_id,
    SUM(price) AS total_order_price
  FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.order_items`
  GROUP BY order_id
),
eligible_orders AS (
  SELECT
    order_id,
    customer_id
  FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.orders`
  WHERE order_status = 'delivered'
    AND order_delivered_customer_date IS NOT NULL
),
state_revenue AS (
  SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(r.total_order_price), 0) AS state_total_revenue
  FROM eligible_orders AS o
  JOIN order_revenue AS r ON o.order_id = r.order_id
  JOIN `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.customers` AS c
    ON o.customer_id = c.customer_id
  GROUP BY c.customer_state
)
SELECT
  customer_state,
  order_count,
  state_total_revenue,
  RANK() OVER (ORDER BY state_total_revenue DESC) AS state_revenue_rank,
  RANK() OVER (ORDER BY order_count DESC) AS state_order_rank
FROM state_revenue
ORDER BY state_revenue_rank, state_order_rank;
