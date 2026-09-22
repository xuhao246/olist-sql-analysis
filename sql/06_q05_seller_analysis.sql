-- Q5: How concentrated is merchandise revenue among eligible sellers?
-- Outputs: seller count, top-10% revenue share, and first seller positions above 50%, 80%, and 90%.
-- Revenue follows the existing result convention: each seller's SUM(price) is rounded before ranking.

CREATE TEMP TABLE seller_revenue_rank AS
WITH seller_revenue AS (
  SELECT
    oi.seller_id,
    s.seller_city,
    s.seller_state,
    ROUND(SUM(oi.price), 0) AS total_revenue
  FROM `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.order_items` AS oi
  JOIN `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.orders` AS o
    ON oi.order_id = o.order_id
  JOIN `project-7ee2833b-bc0e-4b3d-9db.olist_brazillian_ecommerce.sellers` AS s
    ON oi.seller_id = s.seller_id
  WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
  GROUP BY oi.seller_id, s.seller_city, s.seller_state
)
SELECT
  seller_id,
  seller_city,
  seller_state,
  total_revenue,
  ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS total_revenue_rank
FROM seller_revenue;

CREATE TEMP TABLE cumulative_revenue_share AS
WITH cumulative_revenue AS (
  SELECT
    seller_id,
    total_revenue,
    total_revenue_rank,
    SUM(total_revenue) OVER (
      ORDER BY total_revenue_rank
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue
  FROM seller_revenue_rank
)
SELECT
  seller_id,
  total_revenue,
  total_revenue_rank,
  cumulative_revenue,
  ROUND(cumulative_revenue / SUM(total_revenue) OVER () * 100, 2) AS cumulative_revenue_share_pct
FROM cumulative_revenue;

-- Eligible seller count.
SELECT COUNT(DISTINCT seller_id) AS eligible_seller
FROM seller_revenue_rank;

-- Top 297 sellers are exactly 10% of the 2,970 eligible sellers in this dataset.
WITH seller_totals AS (
  SELECT
    ROUND(SUM(total_revenue), 0) AS total_revenue_all_sellers,
    ROUND(SUM(CASE WHEN total_revenue_rank <= 297 THEN total_revenue ELSE 0 END), 0)
      AS total_revenue_top10pct_sellers
  FROM seller_revenue_rank
)
SELECT
  total_revenue_all_sellers,
  total_revenue_top10pct_sellers,
  ROUND(total_revenue_top10pct_sellers / total_revenue_all_sellers * 100, 0)
    AS top10pct_seller_share
FROM seller_totals;

-- First position where the rounded cumulative share exceeds 50%.
SELECT
  seller_id,
  total_revenue_rank,
  cumulative_revenue_share_pct,
  ROUND(cumulative_revenue_share_pct - 50, 2) AS reference_50
FROM cumulative_revenue_share
WHERE cumulative_revenue_share_pct > 50
ORDER BY reference_50
LIMIT 1;

-- First position where the rounded cumulative share exceeds 80%.
SELECT
  seller_id,
  total_revenue_rank,
  cumulative_revenue_share_pct,
  ROUND(cumulative_revenue_share_pct - 80, 2) AS reference_80
FROM cumulative_revenue_share
WHERE cumulative_revenue_share_pct > 80
ORDER BY reference_80
LIMIT 1;

-- First position where the rounded cumulative share exceeds 90%.
SELECT
  seller_id,
  total_revenue_rank,
  cumulative_revenue_share_pct,
  ROUND(cumulative_revenue_share_pct - 90, 2) AS reference_90
FROM cumulative_revenue_share
WHERE cumulative_revenue_share_pct > 90
ORDER BY reference_90
LIMIT 1;
