| # | Business Question                                                                         | Main SQL Skills                                                            | Status |
| - | ----------------------------------------------------------------------------------------- | -------------------------------------------------------------------------- |--|
| 1 | How frequently are orders delivered late?                                                 | date functions, aggregation, CTE, temporary table                              | Complete |
| 2 | How has monthly revenue changed over time?                                                | `JOIN`, aggregation, date functions, CTE, window functions                 | Complete |
| 3 | Which states generate the most orders and revenue?                                        | `JOIN`, aggregation, CTE, subquery, `RANK()`                               | Complete |
| 4 | How do product-category rankings differ over time or geography?                           | multi-table JOIN, RANK(), partitioned window functions             | Complete |
| 5 | How concentrated is revenue among top sellers?                                            | multi-table JOIN, cumulative window functions, SUM() OVER(), ranking            | Complete |
| 6 | How does delivery performance relate to customer review scores?                           | multi-table JOIN, CASE WHEN, aggregation, window functions | Complete |
| 7 | How common are repeat purchases, and how many orders do repeat customers typically place? | JOIN, COUNT(DISTINCT), window functions | Complete |

# Question 1 - how frequently are orders delivered late?

## Query scope

The analysis uses only the `orders` table.

Eligible rows must satisfy:

- `order_status = 'delivered'`
- `order_delivered_customer_date` is not null
- `order_estimated_delivery_date` is not null

A null `order_delivered_carrier_date` does **not** exclude an otherwise eligible order from the analysis. Carrier-date nulls are treated separately as a potential data-quality issue because carrier dispatch timing is not required to determine whether the customer received the order late.

## Late-delivery definition

Late delivery is determined by comparing the **calendar dates** of:

- `order_delivered_customer_date`
- `order_estimated_delivery_date`

Classification:

- actual delivery before the estimated date → **Early**
- actual delivery on the same calendar date → **On Time**
- actual delivery one or more calendar days after the estimated date → **Late**

The time of day is ignored. For example, an order estimated for noon but delivered at 3 PM on the same calendar day is treated as on time.

## Delivery deviation

A calculated field, `delivery_deviation`, measures the difference in calendar days between actual customer delivery and estimated delivery:

`actual customer delivery date - estimated delivery date`

Interpretation:

- negative value → delivered early
- `0` → delivered on the estimated calendar day
- positive value → delivered late

Both timestamp fields are converted to `DATE` before calculating the difference.

## Base analysis dataset

A BigQuery temporary table, `eligible_delivery_orders`, is used as the reusable order-level dataset for this analysis.

It contains:

- `order_id`
- `delivery_deviation` calculated from the two customer-delivery calendar dates
- `estimated_delivery_month`

The temporary table retains negative, zero, and positive delivery deviations so the same eligible population can be reused across different calculations.

## Overall late-delivery rate

For all eligible delivered orders:

- **Denominator:** all eligible delivered orders
- **Numerator:** eligible orders where `delivery_deviation > 0`

The numerator and denominator use the same eligibility criteria; the only difference is whether the order was delivered late.

### Result

**Overall late-delivery rate: 6.8%**

This is the main delivery metric.

## Monthly late-delivery trend

Orders are grouped using the month of `order_estimated_delivery_date`.

The month is a `DATE` set to its first day. It sorts chronologically and remains usable in date calculations.

For each estimated-delivery month:

- **Denominator:** all eligible delivered orders for that month
- **Numerator:** eligible late orders for that month
- **Monthly late-delivery rate:** numerator / denominator × 100

The monthly rate accounts for changes in order volume that a late-order count alone would miss.

The monthly results are stored in:

`results/q01_monthly_late_delivery_rate.csv`

## Median monthly late-delivery rate

The monthly rates are rounded to one decimal place, then their median is calculated using the 50th percentile.

### Result

**Median monthly late-delivery rate: 4.4%**

The median describes a typical month.

It complements, rather than replaces, the overall late-delivery rate:

- **Overall rate (6.8%)** → performance across all eligible orders
- **Median monthly rate (4.4%)** → performance of a typical month

## Low-volume month caveat

Monthly percentages with very small denominators can be unstable.

For example, a month with 1 late order out of only 2 eligible orders produces a 50% late-delivery rate. Such a percentage should not be interpreted in the same way as a rate based on thousands of orders.

Low-volume months are retained in the monthly trend rather than removed, but they should be interpreted cautiously.

## Query implementation

The analysis was initially developed using CTEs.

Because BigQuery CTEs are scoped to the individual query statement following the `WITH` clause, the final implementation uses one reusable temporary table so multiple result queries can run within the same script.

The script produces:

1. the reusable order-level temporary table
2. the monthly late-delivery trend
3. the overall late-delivery rate
4. the median monthly late-delivery rate

Only one temporary table is used to keep the implementation simple.

## Saved results

Saved outputs:

- `results/q01_late_delivery_summary.csv`
- `results/q01_monthly_late_delivery_rate.csv`

## Scope note

This question measures lateness against the supplied estimated date. It does not test whether longer estimated-delivery windows affect the apparent on-time rate.

# Question 2 - monthly revenue trend and strongest growth / decline

## Business questions

1. How has monthly revenue changed over time?
2. Which periods experienced the strongest revenue growth or decline?

Growth and decline are part of Question 2. Question 4 addresses product-category rankings.

## Revenue definition

Revenue is defined as the sum of `order_items.price` across all items within an order.

This is merchandise revenue.

The calculation excludes:

- freight charges
- payment-processing structure
- payment-method differences
- `order_payments.payment_value`

## Eligible orders

Only orders with:

- `order_status = 'delivered'`
- non-null `order_delivered_customer_date`

are included.

Orders without a customer delivery date are excluded because they cannot be assigned to a delivery month.

## Time basis

Revenue is assigned to the month of `order_delivered_customer_date`.

This means revenue is attributed to the month in which the customer received the order rather than the month in which the order was purchased or paid.

For example, if an order was purchased in January but delivered in February, its revenue is assigned to February.

## Intermediate grain

Because `order_items` contains one row per item line rather than one row per order, item prices are first aggregated by `order_id`.

The intermediate order-level dataset contains one row per eligible order with:

- `order_id`
- delivery date
- delivery month
- total merchandise revenue for the order

## Monthly aggregation

After order-level revenue is calculated, the analysis groups orders by delivery month.

For each month:

- monthly revenue = sum of total merchandise revenue from eligible orders delivered in that month

## Month-over-month trend

Monthly revenue is compared with the previous month using `LAG()`.

The analysis calculates:

- previous-month revenue
- absolute month-over-month revenue change
- percentage month-over-month revenue change

These metrics are used to identify periods of strong growth or decline.

## Strongest percentage growth and decline

The two-row summary selects the largest positive and negative **percentage** month-over-month changes from the monthly trend, excluding September and October 2018 because they have limited dataset coverage. January 2017 is the largest percentage increase (4,326.7%); December 2016 is the largest percentage decrease (-92.3%). These are not the largest changes in absolute revenue, and the summary is selected from the monthly output rather than produced by a separate SQL query.

## Data caveat

The final months in the dataset contain very few delivered orders.

September 2018 and October 2018 therefore show unusually low monthly revenue and large apparent declines because they represent partial dataset coverage rather than comparable full-month business performance.

These months are retained in the detailed output but should be interpreted cautiously when identifying meaningful growth or decline.

## Saved results

Saved outputs:

- `results/q02_monthly_revenue_trend.csv`
- `results/q02_largest_increase_and_decrease_summary.csv`

# Question 3 - orders and revenue by customer state

## Business question

Which states generate the most orders and revenue?

## Geographic definition

Geographic performance is based on the customer's state using `customers.customer_state`.

This analysis measures customer-side demand by state rather than seller location.

## Revenue definition

Revenue uses the same merchandise-revenue definition established in the monthly revenue analysis:

`total_order_price = SUM(order_items.price)`

Freight charges are excluded.

## Eligible orders

Only orders with:

- `order_status = 'delivered'`
- non-null `order_delivered_customer_date`

are included.

## Intermediate grain

Because `order_items` contains multiple rows per order, item prices are first aggregated by `order_id`.

The intermediate order-level dataset contains one row per eligible delivered order with:

- `order_id`
- `customer_id`
- `customer_state`
- `total_order_price`

## State-level aggregation

For each customer state:

- `order_count` = number of distinct delivered orders
- `state_total_revenue` = sum of merchandise revenue from those orders

`COUNT(DISTINCT order_id)` is used to make the intended order-level grain explicit.

## Ranking

Two independent rankings are calculated using `RANK()`:

- **Order rank** = states ranked by `order_count` descending
- **Revenue rank** = states ranked by `state_total_revenue` descending

The two ranks are separate because order volume and revenue can differ.

## Key result

The top three customer states by both order volume and merchandise revenue are:

1. SP
2. RJ
3. MG

SP leads on both measures.

Some states have different order and revenue rankings. For example:

- GO ranks higher by revenue than by order count
- ES ranks higher by order count than by revenue

Order volume alone does not explain the revenue differences between states.

## Saved result

The state-level output is stored in:

`results/q03_state_orders_and_revenue.csv`

# Question 4 - product-category rankings over time and geography

## Business question

How do product-category rankings differ over time or geography?

## Analysis dimensions

The analysis compares product-category performance across two dimensions:

1. customer state
2. delivery month

Geographic performance is based on `customers.customer_state`.

Time-based performance is based on the month of `order_delivered_customer_date`.

## Eligible orders

Only orders with:

- `order_status = 'delivered'`
- non-null `order_delivered_customer_date`

are included.

## Revenue definition

Revenue uses the same merchandise-revenue definition established in the monthly revenue analysis:

`revenue = SUM(order_items.price)`

Freight charges are excluded.

## Order-count definition

Order count is calculated using:

`COUNT(DISTINCT order_id)`

This prevents multiple item rows from the same order from being counted as multiple orders within the same product category.

## Join structure

The analysis combines:

- `products`
- `product_category_name_translation`
- `order_items`
- `orders`
- `customers`

`products` is joined to `product_category_name_translation` using a `LEFT JOIN`.

This retains 13 products with a non-null category lacking a translation and products whose source category is null. Both appear with a null English category name rather than being dropped.

## Intermediate grain

Before ranking, the analysis is aggregated to:

- one row per customer state + product category for the geography analysis
- one row per delivery month + product category for the time analysis

Each row contains:

- product-category revenue
- distinct order count

## Geography ranking

For each customer state, product categories are ranked independently by:

- total revenue
- distinct order count

The ranking is calculated using `RANK()` with:

`PARTITION BY state`

This allows category rankings to restart within each state.

## Time ranking

For each delivery month, product categories are ranked independently by:

- total revenue
- distinct order count

The ranking is calculated using `RANK()` with:

`PARTITION BY order_delivered_customer_month`

This allows category rankings to restart within each month and makes it possible to observe changes in category leadership over time.

## Key findings

Product-category leadership varies across both geography and time.

`health_beauty` is the most geographically dominant category:

- #1 by revenue in 15 of 27 states
- #1 by order count in 17 of 27 states

Other categories including `sports_leisure`, `watches_gifts`, and `bed_bath_table` lead in selected states.

Revenue rank and order-count rank are not always identical.

For example:

- in RJ, `watches_gifts` ranks #1 by revenue but #6 by order count
- in RJ, `bed_bath_table` ranks #1 by order count but #2 by revenue

Both order volume and order value affect a category's revenue rank.

Category leadership also changes over time.

By revenue:

- `watches_gifts` ranks #1 in 8 months
- `health_beauty` ranks #1 in 5 months
- `bed_bath_table` ranks #1 in 3 months

By order count:

- `bed_bath_table` ranks #1 in 11 months
- `health_beauty` ranks #1 in 6 months
- `furniture_decor` ranks #1 in 5 months

The category with the most orders does not always bring in the most revenue.

## Data caveats

Products without matching English category translations are preserved through the `LEFT JOIN` and may appear with a null English category name.

September 2018 and October 2018 contain limited activity because they occur at the end of the dataset. Their rankings are retained in the detailed results but should be interpreted cautiously.

## Saved results

The outputs are stored in:

- `results/q04_product_category_geography_ranking.csv`
- `results/q04_product_category_time_ranking.csv`

# Question 5 - seller revenue concentration

## Business question

How concentrated is revenue among top sellers?

## Revenue definition

Revenue uses the same merchandise-revenue definition established in earlier questions:

`revenue = SUM(order_items.price)`

Freight charges are excluded. The current seller query rounds each seller's item-price sum to a whole unit before ranking and totaling sellers; this creates a small presentation difference from the unrounded total used in other questions (see `docs/qa_report.md`).

## Eligible orders

Only orders with:

- `order_status = 'delivered'`
- non-null `order_delivered_customer_date`

are included.

## Seller-level grain

The analysis is aggregated to one row per eligible seller.

Each seller-level row contains:

- `seller_id`
- seller revenue
- seller revenue rank / position

There are **2,970 eligible sellers** in the analysis population.

## Top-seller definition

Top sellers are defined as the highest-revenue 10% of eligible sellers.

With 2,970 eligible sellers:

- top 10% = **297 sellers**

The query uses `ROW_NUMBER()` ordered by seller revenue descending, giving exactly 297 positions. Sellers tied on rounded revenue do not have a stable secondary order, so a seller ID at a threshold may vary without changing the tied revenue total.

## Top-10% revenue share

Total merchandise revenue is calculated across all eligible sellers.

Revenue generated by the top 297 sellers is calculated using conditional aggregation with `CASE WHEN`.

The result shows that the **top 10% of sellers generate approximately 67% of total merchandise revenue**.

## Cumulative revenue analysis

Seller revenue is ordered from highest to lowest.

A cumulative revenue total is calculated using a windowed `SUM()`:

`ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`

The cumulative revenue share is then calculated as:

`cumulative revenue / total eligible seller revenue × 100`

The running total shows how many sellers it takes to reach each revenue threshold.

## Key results

Among 2,970 eligible sellers:

- **297 sellers (10%)** generate approximately **67%** of total revenue
- **127 sellers (4.3%)** generate approximately **50%** of total revenue
- **533 sellers (17.9%)** generate approximately **80%** of total revenue
- **889 sellers (29.9%)** generate approximately **90%** of total revenue

## Interpretation

Revenue is strongly concentrated among a relatively small share of sellers.

The clearest headline result is that only **10% of eligible sellers generate about two-thirds of total merchandise revenue**.

Fewer than 5% of sellers account for half of total revenue, while approximately 30% account for 90%.

## Saved results

The outputs are stored in:

- `results/q05_top10pct_seller_revenue_share.csv`
- `results/q05_seller_rank_50pct_total_revenue.csv`
- `results/q05_seller_rank_80pct_total_revenue.csv`
- `results/q05_seller_rank_90pct_total_revenue.csv`

# Question 6 - delivery performance and customer review scores

## Business question

How does delivery performance relate to customer review scores?

## Eligible orders

The delivery-status analysis includes only orders with:

- `order_status = 'delivered'`
- non-null `order_delivered_customer_date`
- non-null `order_estimated_delivery_date`

## Delivery-status definition

Delivery performance is determined by comparing the calendar dates of:

- `order_delivered_customer_date`
- `order_estimated_delivery_date`

Classification:

- actual delivery before estimated delivery → **Early**
- actual delivery on the estimated calendar date → **On Time**
- actual delivery after estimated delivery → **Late**

Time of day is ignored.

## Review grain

The analysis is conducted at the **review-record level**, not the unique-order level.

If an order contains multiple review records, each review is treated as a separate observation and contributes independently to the analysis.

This preserves all available customer-review responses rather than collapsing multiple reviews into a single order-level score.

## Join structure

Eligible orders are joined to `order_reviews` using `order_id`.

Each resulting row contains:

- `order_id`
- `review_id`
- delivery status
- `review_score`

## Review metrics

Two views are used to evaluate the relationship between delivery performance and review scores:

1. average review score by delivery status
2. percentage distribution of review scores 1-5 within each delivery status

For the distribution analysis:

`review_score_count`

counts review records for each delivery-status + review-score combination.

A windowed `SUM()` partitions by delivery status to calculate the total number of review records in each delivery-status group.

The percentage distribution is then calculated as:

`review_score_count / delivery_status_total_count × 100`

## Key results

Average review score:

- Early: **4.29**
- On Time: **4.03**
- Late: **2.27**

Review-score distribution:

### Early deliveries

- Score 1: **6.60%**
- Score 2: **2.63%**
- Score 3: **7.99%**
- Score 4: **20.34%**
- Score 5: **62.43%**

### On-time deliveries

- Score 1: **8.52%**
- Score 2: **3.87%**
- Score 3: **13.79%**
- Score 4: **23.39%**
- Score 5: **50.43%**

### Late deliveries

- Score 1: **53.74%**
- Score 2: **8.68%**
- Score 3: **10.88%**
- Score 4: **10.17%**
- Score 5: **16.54%**

## Interpretation

Late delivery is strongly associated with lower customer review scores.

More than half of review records associated with late deliveries received a 1-star score, while only 16.54% received 5 stars.

By contrast, 62.43% of review records associated with early deliveries and 50.43% of those associated with on-time deliveries received 5 stars.

This analysis identifies an association between delivery performance and customer satisfaction; it does not establish that delivery timing alone causes the review outcome.

## Saved results

- `results/q06_avg_review_score_by_delivery_status.csv`
- `results/q06_delivery_status_review_score_share_pct.csv`

# Question 7 - repeat purchases and repeat-customer order frequency

## Business question

How common are repeat purchases, and how many orders do repeat customers typically place?

## Eligible orders

Only completed delivered orders are included:

- `order_status = 'delivered'`
- `order_delivered_customer_date` is not null

Orders that are canceled, unavailable, or still in progress are excluded.

## Customer identifier

Repeat purchasing is analyzed using `customers.customer_unique_id`.

`customer_id` is not used to identify repeat customers because it is effectively tied to an individual order in this dataset.

`customer_unique_id` represents the same real customer across multiple orders.

## Repeat-customer definition

A repeat customer is defined as a customer with at least **2 distinct delivered orders**:

`COUNT(DISTINCT order_id) > 1`

Purchasing the same product multiple times is not required. This analysis measures repeat ordering behavior at the customer level rather than repeat purchasing of a specific product.

## Customer-level grain

Delivered orders are joined to `customers` using `customer_id`.

The data is then aggregated to one row per `customer_unique_id`, with:

- `customer_unique_id`
- delivered-order count

## Repeat-customer distribution

Repeat customers are grouped by their number of delivered orders.

For each order count:

- `repeat_customer_count` = number of repeat customers with that order count
- `repeat_customer_share_pct` = share of all repeat customers represented by that group

## Key results

There are:

- **93,350** eligible customers
- **2,801** repeat customers
- repeat customers represent **3.0%** of eligible customers

Among repeat customers:

- **2 orders:** 2,573 customers (**91.86%**)
- **3 orders:** 181 customers (**6.46%**)
- **4 orders:** 28 customers (**1.00%**)
- **5 orders:** 9 customers (**0.32%**)
- **6 orders:** 5 customers (**0.18%**)
- **7 orders:** 3 customers (**0.11%**)
- **9 orders:** 1 customer (**0.04%**)
- **15 orders:** 1 customer (**0.04%**)

The median number of delivered orders among repeat customers is **2.0**.

## Interpretation

Repeat purchasing is relatively uncommon in the eligible customer population.

Only **3.0%** of customers placed more than one delivered order.

Among customers who did return, repeat activity is usually limited: **91.86%** of repeat customers placed exactly two delivered orders, and the median repeat-customer order count is also **2**.

Higher-frequency repeat purchasing is rare.

## Saved results

The outputs are stored in:

- `results/q07_repeat_customer_share.csv`
- `results/q07_repeat_customer_order_distribution.csv`
- `results/q07_median_order_number_repeat_customers.csv`
