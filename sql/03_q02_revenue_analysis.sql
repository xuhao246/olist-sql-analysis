-- Q2: How has monthly merchandise revenue changed over time?
-- Output: revenue by customer-delivery month with prior-month, absolute-change, and percentage-change columns.
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
    order_delivered_customer_date
  FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.orders`
  WHERE order_status = 'delivered'
    AND order_delivered_customer_date IS NOT NULL
),
monthly_revenue AS (
  SELECT
    DATE_TRUNC(DATE(o.order_delivered_customer_date), MONTH) AS delivery_month,
    ROUND(SUM(r.total_order_price), 0) AS total_monthly_revenue
  FROM eligible_orders AS o
  JOIN order_revenue AS r ON o.order_id = r.order_id
  GROUP BY delivery_month
),
monthly_changes AS (
  SELECT
    delivery_month,
    total_monthly_revenue,
    LAG(total_monthly_revenue) OVER (ORDER BY delivery_month) AS previous_monthly_revenue
  FROM monthly_revenue
)
SELECT
  delivery_month,
  total_monthly_revenue,
  previous_monthly_revenue,
  total_monthly_revenue - previous_monthly_revenue AS monthly_revenue_change,
  ROUND(
    100 * (total_monthly_revenue - previous_monthly_revenue) / previous_monthly_revenue,
    1
  ) AS monthly_revenue_change_pct
FROM monthly_changes
ORDER BY delivery_month;
