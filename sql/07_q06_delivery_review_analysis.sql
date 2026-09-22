-- Q6: How is delivery timing associated with customer review scores?
-- Outputs: review-score shares by delivery status, then average score by delivery status.
-- Grain: one review record per row; multiple reviews of one order remain separate observations.

CREATE TEMP TABLE delivery_status_reviews AS
SELECT
  r.order_id,
  r.review_id,
  CASE
    WHEN DATE(o.order_delivered_customer_date) < DATE(o.order_estimated_delivery_date) THEN 'early'
    WHEN DATE(o.order_delivered_customer_date) = DATE(o.order_estimated_delivery_date) THEN 'on_time'
    ELSE 'late'
  END AS delivery_status,
  r.review_score
FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.orders` AS o
JOIN `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.order_reviews` AS r
  ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL;

-- Share of each review score within its delivery-status group.
WITH score_counts AS (
  SELECT
    delivery_status,
    review_score,
    COUNT(*) AS review_score_count
  FROM delivery_status_reviews
  GROUP BY delivery_status, review_score
),
status_totals AS (
  SELECT
    delivery_status,
    review_score,
    review_score_count,
    SUM(review_score_count) OVER (PARTITION BY delivery_status) AS delivery_status_total_count
  FROM score_counts
)
SELECT
  delivery_status,
  review_score,
  review_score_count,
  ROUND(review_score_count / delivery_status_total_count * 100, 2) AS delivery_score_share_pct
FROM status_totals;

-- Mean score and review-record count for each delivery status.
SELECT
  delivery_status,
  ROUND(AVG(review_score), 2) AS avg_review_score,
  COUNT(*) AS status_count
FROM delivery_status_reviews
GROUP BY delivery_status;
