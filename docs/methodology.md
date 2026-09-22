# Primary and foreign key validation

I checked the Olist table relationships in BigQuery before writing the business queries.

### Primary key validation

I checked each candidate primary key in three ways:

1. Compare the total number of rows with the number of distinct candidate-key values.
2. Confirm that the candidate key contains no null values.
3. For composite keys, validate the uniqueness of the combined key values.

A key passed when:

- the number of distinct key values equaled the total number of rows; and
- the key contained no null values.

For example, `orders.order_id` was validated by comparing the total row count with the number of distinct `order_id` values and checking for nulls.

Some tables required composite keys:

- `order_items`: (`order_id`, `order_item_id`)
- `order_payments`: (`order_id`, `payment_sequential`)
- `order_reviews`: (`review_id`, `order_id`)

The `geolocation` table was tested using multiple candidate column combinations, but no natural primary key was identified.

### Foreign key validation

Foreign-key relationships were validated using a child-to-parent `LEFT JOIN`.

General pattern:

```sql
SELECT
  COUNT(*) AS unmatched_rows
FROM child_table AS child
LEFT JOIN parent_table AS parent
  ON child.foreign_key = parent.primary_key
WHERE child.foreign_key IS NOT NULL
  AND parent.primary_key IS NULL;
```
The query counts non-null child keys with no matching parent row.

Zero unmatched rows means the observed child keys all have matching parent rows.

The following relationships were validated with `0` unmatched rows:

* `orders.customer_id` → `customers.customer_id`
* `order_items.order_id` → `orders.order_id`
* `order_items.product_id` → `products.product_id`
* `order_items.seller_id` → `sellers.seller_id`
* `order_payments.order_id` → `orders.order_id`
* `order_reviews.order_id` → `orders.order_id`

### Product category translation exception

The relationship:

`products.product_category_name`\
→ `product_category_name_translation.product_category_name`

was also tested.

Unlike the other relationships, this validation returned 13 unmatched product rows.

The unmatched rows belong to two category values:

* `portateis_cozinha_e_preparadores_de_alimentos`: 10 products
* `pc_gamer`: 3 products

The translation table does not cover every non-null product category.

The category analysis uses a `LEFT JOIN` to retain products without an English translation.

### Constraint interpretation

These checks describe the rows in this dataset.

BigQuery does not declare or enforce these primary and foreign keys.

# Relationship cardinality validation

I checked whether direct joins behave as 1:1 or 1:M and whether bridge tables create M:M relationships.

### Direct relationship checks

To check cardinality, I grouped child rows by foreign key and looked for repeated parent keys.

General pattern:

```sql
SELECT
  foreign_key,
  COUNT(*) AS row_count
FROM child_table
WHERE foreign_key IS NOT NULL
GROUP BY foreign_key
HAVING COUNT(*) > 1
ORDER BY row_count DESC;
```
If the query returned rows, the relationship was classified as 1:M from parent to child.

If no repeated child foreign-key values were found, the relationship was treated as 1:1 for the observed dataset.

### Many-to-many checks

I checked potential many-to-many relationships through bridge tables.

For example, `order_items` connects orders, products, and sellers. To confirm a conceptual M:M relationship, both directions were checked using `COUNT(DISTINCT ...)`.

A relationship was treated as M:M when:

* one record from Table A could be associated with multiple distinct records from Table B; and
* one record from Table B could be associated with multiple distinct records from Table A.

The detailed cardinality results are documented in `docs/schema.md`.

### Interpretation

These cardinalities describe the observed Olist rows.

They are used to guide:

* safe join design
* aggregation strategy
* prevention of row multiplication
* construction of the ER diagram
* later analytical queries

# Business question analysis workflow

I used the same workflow for each question:

1. Define the business question and assumptions.
2. Identify the required tables and confirm table grain.
3. Define the metric(s) needed to answer the question.
4. Explore and validate relevant fields.
5. Write the analytical SQL query.
6. Validate the query result.
7. Interpret the business meaning.
8. Update documentation with definitions, findings, and notable issues.

# Business question 1 - late delivery analysis

## Business question

How frequently are orders delivered late?

## Analysis population

The analysis uses the `orders` table.

An order is eligible for the late-delivery analysis when:

- `order_status = 'delivered'`
- `order_delivered_customer_date` is not null
- `order_estimated_delivery_date` is not null

A null `order_delivered_carrier_date` is treated as a data-quality anomaly but does not exclude an otherwise eligible order from the late-delivery analysis.

## Late-delivery definition

Late delivery is evaluated using calendar dates rather than exact timestamps.

An order is classified as late when the calendar date of `order_delivered_customer_date` is later than the calendar date of `order_estimated_delivery_date`.

Therefore:

- negative `delivery_deviation` = delivered early
- `delivery_deviation = 0` = delivered on the estimated calendar day
- positive `delivery_deviation` = delivered late

The time of day is ignored. For example, an order estimated for noon but delivered at 3 PM on the same calendar day is treated as on time.

## Delivery deviation

`delivery_deviation` represents the number of calendar days between actual customer delivery and estimated delivery.

The field is calculated after converting both timestamps to calendar dates.

## Monthly trend definition

Monthly performance is grouped by the month of `order_estimated_delivery_date`.

For each estimated-delivery month:

- denominator = all eligible delivered orders for that month
- numerator = eligible orders with positive `delivery_deviation`
- monthly late-delivery rate = numerator / denominator × 100

## Summary metrics

Two summary metrics are used:

**Overall late-delivery rate**

Measures the percentage of all eligible orders that were delivered late across the full dataset.

**Median monthly late-delivery rate**

Measures the late-delivery rate of a typical month and is less sensitive than the average monthly rate to months with unusually high or low percentages.

The monthly rates are rounded to one decimal place, then their median is calculated using `PERCENTILE_CONT(..., 0.5)`.

## Low-volume months

Monthly rates with very small denominators should be interpreted cautiously.

For example, a month with 1 late order out of only 2 eligible orders produces a 50% rate, but this does not necessarily represent stable delivery performance.

# Business question 2 - monthly revenue trend

### Business question

How has monthly revenue changed over time?

### Revenue definition

Revenue is defined as the sum of `order_items.price` across all items within an order.

This represents merchandise revenue only. Freight charges and payment-related values are excluded from the metric.

### Eligible orders

Only orders satisfying both conditions are included:

- `order_status = 'delivered'`
- `order_delivered_customer_date` is not null

Orders without a customer delivery date are excluded because they cannot be assigned to a delivery month.

### Time basis

Revenue is attributed to the month of `order_delivered_customer_date`.

This means the analysis measures revenue associated with orders delivered during each month rather than orders purchased or paid for during that month.

For example, if an order was purchased in January and delivered in February, its revenue is assigned to February.

### Order-level revenue

The `order_items` table contains multiple rows per order, so item-level prices are first aggregated by `order_id`.

For each order:

`total_order_price = SUM(order_items.price)`

This produces one revenue value per order before joining to the `orders` table.

### Monthly revenue

After joining order-level revenue to eligible delivered orders, revenue is grouped by delivery month.

For each month:

`total_monthly_revenue = SUM(total_order_price)`

The resulting dataset has one row per delivery month.

### Month-over-month comparison

Monthly revenue is compared with the immediately preceding month using the `LAG()` window function.

For each month:

`monthly_revenue_change = current month revenue - previous month revenue`

and:

`monthly_revenue_change_pct = (current month revenue - previous month revenue) / previous month revenue × 100`

The first month has no previous-month comparison and returns null for the change metrics.

### Partial and low-volume periods

Percentage changes can become unusually large when the previous month's revenue is very small.

In addition, September 2018 and October 2018 contain very few delivered orders because they occur at the end of the available dataset. Their unusually low revenues and large negative month-over-month changes are therefore treated as incomplete dataset coverage rather than evidence of a genuine business decline.

These months remain in the monthly output but are excluded from the two-row summary of the largest positive and negative **percentage** changes. December 2016 and January 2017 lead that summary; absolute revenue changes have different leaders.

# Business question 3 - orders and revenue by customer state

## Business question

Which states generate the most orders and revenue?

## Geographic definition

State-level performance is based on the customer's state using `customers.customer_state`.

This analysis measures customer-state demand rather than seller location.

## Revenue definition

Revenue uses the same merchandise-revenue definition established in Question 2:

`total_order_price = SUM(order_items.price)`

Freight charges are excluded.

## Eligible orders

Only delivered orders are included:

- `order_status = 'delivered'`
- `order_delivered_customer_date` is not null

## Order-level revenue

Because `order_items` contains multiple rows per order, item prices are first aggregated by `order_id`.

This produces one merchandise-revenue value per order.

## State assignment

The order-level revenue result is joined to:

1. `orders` using `order_id` to obtain `customer_id`
2. `customers` using `customer_id` to obtain `customer_state`

The resulting intermediate dataset contains one row per eligible delivered order with:

- `order_id`
- `customer_id`
- `customer_state`
- `total_order_price`

## State-level metrics

For each customer state:

- `order_count` = number of distinct delivered orders
- `state_total_revenue` = sum of merchandise revenue from those orders

`COUNT(DISTINCT order_id)` is used to make the intended order-level grain explicit.

## Ranking

Two independent rankings are calculated using `RANK()`:

- order-volume rank, ordered by `order_count` descending
- revenue rank, ordered by `state_total_revenue` descending

Using separate rankings allows states with similar order volume but different order values to be distinguished.

Differences between order rank and revenue rank indicate that geographic performance is not driven solely by transaction volume.

JOIN field `product_category_name_english` in table `product_category_name_translation` to table `products` by field `product_category_name`

# Business question 4 - product-category rankings over time and geography

### Business question

How do product-category rankings differ over time or geography?

### Analysis dimensions

Two ranking views are produced:

1. product-category rankings within each customer state
2. product-category rankings within each delivery month

The geographic dimension uses `customers.customer_state`.

The time dimension uses the month of `order_delivered_customer_date`.

### Eligible orders

Only orders satisfying both conditions are included:

- `order_status = 'delivered'`
- `order_delivered_customer_date` is not null

### Revenue definition

Revenue follows the same merchandise-revenue definition used in earlier questions:

`revenue = SUM(order_items.price)`

Freight charges are excluded.

### Order-count definition

Order count is calculated using:

`COUNT(DISTINCT order_id)`

This prevents multiple item rows from the same order from being counted as multiple orders within the same category.

### Join structure

The analysis combines:

- `products`
- `product_category_name_translation`
- `order_items`
- `orders`
- `customers`

The category translation table is joined to `products` using a `LEFT JOIN`.

This preserves products whose Portuguese category name does not have a matching English translation.

### Analytical grain

Before ranking, the data is aggregated to:

- one row per customer state + product category for the geography analysis
- one row per delivery month + product category for the time analysis

Each row contains:

- category revenue
- distinct order count

### Ranking logic

Two independent rankings are calculated within each partition:

- revenue rank
- order-count rank

For geography:

`PARTITION BY state`

For time:

`PARTITION BY order_delivered_customer_month`

Categories are ranked in descending order using `RANK()`.

Separate rankings are retained because a category may generate high revenue without having the highest order volume.

### Partial-month caveat

September 2018 and October 2018 occur at the end of the dataset and contain very limited activity.

Their category rankings are retained in the raw output but should be interpreted cautiously.

# Business question 5 - seller revenue concentration

## Business question

How concentrated is revenue among top sellers?

## Revenue definition

Revenue is defined as:

`SUM(order_items.price)`

This represents merchandise revenue only and excludes freight charges.

## Eligible population

Only delivered orders with non-null customer delivery dates are included.

The seller population is therefore limited to sellers appearing in the eligible delivered-order dataset.

A total of **2,970 eligible sellers** are included.

## Seller-level aggregation

`order_items` is joined to eligible delivered orders and seller information.

Revenue is aggregated to one row per seller. The saved-result query then rounds that sum before ranking:

`total_revenue = ROUND(SUM(price), 0)`

This intermediate rounding makes the saved all-seller monetary total 141.07 higher than the unrounded eligible item-price total. It does not change the reported 67% top-10% share. The underlying merchandise-revenue inclusion rule remains `SUM(order_items.price)`.

## Seller ordering

Sellers are ordered from highest to lowest revenue.

The query uses `ROW_NUMBER()` for an exact top-10% cutoff; `RANK()` could return a different number of sellers at a tie. There is no secondary seller-ID tie-breaker, so an ID at a tied position may vary.

With 2,970 eligible sellers:

`2,970 × 10% = 297 sellers`

## Top-10% revenue share

The revenue generated by the top 297 sellers is calculated using conditional aggregation:

`SUM(CASE WHEN total_revenue_rank <= 297 THEN total_revenue ELSE 0 END)`

The concentration metric is:

`top-10% seller revenue / total seller revenue × 100`

## Cumulative revenue

A cumulative seller-revenue total is calculated using:

`SUM(total_revenue) OVER (...)`

with sellers ordered from highest to lowest revenue.

The explicit window frame is:

`ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`

This produces a running revenue total from the highest-revenue seller through the current seller.

## Cumulative revenue share

For each seller position:

`cumulative revenue share = cumulative revenue / total seller revenue × 100`

The first seller position whose **rounded** cumulative share exceeds each threshold is used to identify the number of sellers required to generate:

- 50% of revenue
- 80% of revenue
- 90% of revenue

# Business question 6 - delivery performance and review scores

## Business question

How does delivery performance relate to customer review scores?

## Eligible population

Only delivered orders with non-null actual and estimated customer delivery dates are included.

## Delivery classification

Delivery status is derived using calendar dates:

- Early: actual delivery date < estimated delivery date
- On Time: actual delivery date = estimated delivery date
- Late: actual delivery date > estimated delivery date

## Analysis grain

The analysis uses **review records as observations**.

Multiple review records associated with the same order are retained as separate observations.

As a result, calculated averages and distributions represent review-record behavior rather than unique-order behavior.

## Join method

Eligible orders are joined to `order_reviews` using `order_id`.

## Average review score

For each delivery-status group:

`average review score = AVG(review_score)`

## Review-score distribution

Review records are first grouped by:

- delivery status
- review score

The number of records within each pair is counted.

A window function then calculates the total review-record count within each delivery-status group:

`SUM(review_score_count) OVER (PARTITION BY delivery_status)`

The percentage distribution is:

`review_score_count / delivery_status_total_count × 100`

## Interpretation constraint

The analysis evaluates association rather than causality.

Differences in review scores may also reflect other factors such as product quality, seller experience, packaging, service, or customer expectations.

# Business question 7 - repeat purchases

## Business question

How common are repeat purchases, and how many orders do repeat customers typically place?

## Eligible population

Only delivered orders with non-null customer delivery dates are included.

This limits the analysis to completed purchases.

## Customer identity

The analysis uses `customer_unique_id` as the customer identifier.

Although `orders.customer_id` joins to `customers.customer_id`, `customer_id` is effectively order-specific in this dataset and is not suitable for identifying repeat purchasing behavior.

`customer_unique_id` is used to link multiple orders placed by the same real customer.

## Customer-level order count

After joining eligible orders to `customers`, the data is aggregated to one row per `customer_unique_id`.

For each customer:

`order_count = COUNT(DISTINCT order_id)`

## Repeat-customer definition

A repeat customer is defined as:

`order_count > 1`

This includes customers with two or more completed delivered orders.

## Repeat-customer share

The analysis calculates:

`repeat customer share = repeat customers / total eligible customers × 100`

The current query reads the customer-level temporary table, using `COUNT(*)` for eligible customers and `COUNTIF(order_count > 1)` for repeat customers.

## Repeat-customer order distribution

Repeat customers are grouped by `order_count`.

For each order count:

- number of repeat customers is calculated
- share of all repeat customers is calculated using:

`repeat_customer_count / SUM(repeat_customer_count) OVER() × 100`

## Typical repeat-customer order count

The median number of orders among repeat customers is calculated using:

`PERCENTILE_CONT(order_count, 0.5) OVER()`

Only customers with `order_count > 1` are included in the median calculation.
