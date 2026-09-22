-- Q1: How frequently are orders delivered late?
-- Outputs: monthly late-delivery rates, overall late-delivery rate, and median monthly rate.
-- Grain: one row per eligible delivered order in the temporary table.

CREATE TEMP TABLE eligible_delivery_orders AS
SELECT
  order_id,
  DATE_DIFF(
    DATE(order_delivered_customer_date),
    DATE(order_estimated_delivery_date),
    DAY
  ) AS delivery_deviation,
  DATE_TRUNC(DATE(order_estimated_delivery_date), MONTH) AS estimated_delivery_month
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.orders`
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;

-- Monthly rate by estimated-delivery month.
SELECT
  estimated_delivery_month,
  COUNTIF(delivery_deviation > 0) AS late_delivery,
  COUNT(*) AS all_delivery,
  ROUND(100 * COUNTIF(delivery_deviation > 0) / COUNT(*), 1) AS late_delivery_rate
FROM eligible_delivery_orders
GROUP BY estimated_delivery_month
ORDER BY estimated_delivery_month;

-- Overall rate across eligible orders.
SELECT
  ROUND(100 * COUNTIF(delivery_deviation > 0) / COUNT(*), 1) AS overall_late_delivery_rate
FROM eligible_delivery_orders;

-- Median of the rounded monthly rates used in the saved monthly output.
WITH monthly_rates AS (
  SELECT
    ROUND(100 * COUNTIF(delivery_deviation > 0) / COUNT(*), 1) AS late_delivery_rate
  FROM eligible_delivery_orders
  GROUP BY estimated_delivery_month
)
SELECT DISTINCT
  PERCENTILE_CONT(late_delivery_rate, 0.5) OVER () AS median_monthly_late_delivery_rate
FROM monthly_rates;
