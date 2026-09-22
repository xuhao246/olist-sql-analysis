# 2026-09-01

## BigQuery import issue: `order_reviews`

During the initial BigQuery upload, the `order_reviews` CSV failed with the following error:

> CSV table encountered too many errors, giving up.

The issue was caused by review text fields containing embedded line breaks inside quoted CSV values.

### Resolution

Re-uploaded the file with **Allow quoted newlines** enabled in BigQuery's advanced CSV import settings.

The table then uploaded successfully.

### Note

Quoted review text can span several physical CSV lines, so this import needs the quoted-newlines setting.

## Schema correction: `product_category_name_translation`

The `product_category_name_translation` table was initially imported into BigQuery with generic column names:

* `string_field_0`

* `string_field_1`

The first data row contained the intended header values:

* `product_category_name`

* `product_category_name_english`

To correct the schema:

1. Renamed `string_field_0` to `product_category_name`.

2. Renamed `string_field_1` to `product_category_name_english`.

3. Removed the first row because it contained header text rather than actual data.

The corrected table has the source column names and no header row mixed with the data.

## Geolocation table: no natural primary key

The `geolocation` table contains 1,000,163 rows.

Several candidate keys were tested, including:

- latitude + longitude
- ZIP-code prefix + latitude + longitude
- broader combinations of location fields

None uniquely identified every row.

No tested column combination uniquely identified a geolocation row. Treat the table as ZIP-code-prefix reference data and aggregate it before joining to orders.

# 2026-09-04

## Relational schema validation

Completed primary-key and foreign-key validation for the Olist tables before beginning the main SQL analysis.

### Primary key findings

Validated single-column primary keys:

- `customers.customer_id`
- `orders.order_id`
- `products.product_id`
- `sellers.seller_id`
- `product_category_name_translation.product_category_name`

Validated composite primary keys:

- `order_items`: (`order_id`, `order_item_id`)
- `order_payments`: (`order_id`, `payment_sequential`)
- `order_reviews`: (`review_id`, `order_id`)

The `geolocation` table was tested using multiple candidate column combinations, but no natural primary key was identified.

### Foreign key findings

The following relationships were validated with 0 unmatched rows:

- `orders.customer_id` → `customers.customer_id`
- `order_items.order_id` → `orders.order_id`
- `order_items.product_id` → `products.product_id`
- `order_items.seller_id` → `sellers.seller_id`
- `order_payments.order_id` → `orders.order_id`
- `order_reviews.order_id` → `orders.order_id`

### Product category translation gap

Validation of:

`products.product_category_name`
→ `product_category_name_translation.product_category_name`

returned 13 unmatched product rows across two category values:

- `portateis_cozinha_e_preparadores_de_alimentos`: 10 products
- `pc_gamer`: 3 products

The translation table lacks these two categories.

The completed Q4 category analysis uses a `LEFT JOIN` to retain these products when adding English category names.

All validation queries are stored in `sql/01_data_validation.sql`.

## Relationship cardinality review

Completed cardinality checks for the validated table relationships.

The relationship structure is now documented in `docs/schema.md`, including direct 1:1 / 1:M relationships and conceptual M:M relationships resolved through `order_items`.

### Important modeling notes

- `customer_id` behaves as a 1:1 link between `customers` and `orders`, while repeat real-world customers are represented through `customer_unique_id`.
- `order_items` functions as a bridge table and creates several indirect many-to-many relationships.
- `geolocation` does not have a natural primary key and should be handled carefully in later joins.
- The product-category translation table is incomplete for 13 product rows across 2 category values.

I used these results when drawing the ER diagram and writing the analysis joins.

## Business questions defined

Initially drafted eight business questions covering sales, products, sellers, customers, operations, customer experience, and geography. The standalone growth/decline question was later merged into Question 2, leaving the final seven-question set.

The selected questions were designed to provide repeated practice with the project's main SQL skills, including:

- joins
- aggregation
- date functions
- CTEs
- subqueries
- `CASE WHEN`
- window functions
- ranking functions

The final question set is documented in `docs/business_questions.md`.

# 2026-09-11

## SQL implementation update - CTE scope and temporary tables

The initial version of the late-delivery analysis used multiple Common Table Expressions (CTEs).

The CTE structure worked correctly when paired with a single final query. However, BigQuery CTEs are scoped only to the individual query statement that immediately follows the `WITH` clause.

This created a limitation when trying to execute several separate result queries from the same CTE definitions. After the first query statement ended, later queries could no longer access the CTEs and BigQuery interpreted the CTE names as permanent tables.

### Version 1: CTE-based analysis

The first CTE-based version was retained in the SQL file at this stage. It was removed during the final SQL cleanup; this note preserves the learning about statement scope.

Characteristics:

- reusable calculations are organized with CTEs
- the base delivery dataset is defined once within the CTE chain
- monthly, overall, and median late-delivery metrics are derived from the CTEs
- each final result query must be run separately with the CTE definitions

This historical version documented the development process and demonstrated CTE usage.

### Version 2: temporary-table analysis

The second version used a BigQuery temporary table so multiple final queries could share the prepared delivery-analysis dataset within one script. This avoided repeating CTE definitions and kept the analytical definitions unchanged. The final portfolio SQL retains only this temporary-table approach.

## Business question 1 - late delivery analysis

Completed the core SQL analysis for:

> How frequently are orders delivered late?

The analysis was first developed using CTEs. Because BigQuery CTEs are scoped to a single query statement, a second implementation was created using one reusable temporary table.

### Final implementation

The final script uses `eligible_delivery_orders` as an order-level temporary table containing:

- `order_id` for each eligible delivered order
- calendar-day delivery deviation
- estimated-delivery month

Separate queries then calculate:

- monthly late-delivery rate
- overall late-delivery rate
- median monthly late-delivery rate

Only one temporary table was retained to keep the script simple and avoid unnecessary intermediate objects.

### Current results

- Overall late-delivery rate: **6.8%**
- Median monthly late-delivery rate: **4.4%**

Monthly rates are also calculated using estimated-delivery month.

Early months with very small order counts can produce unstable rates and should not be interpreted in the same way as months containing thousands of orders.

# 2026-09-15

## Business question 2 - monthly revenue trend

Completed the SQL analysis for:

> How has monthly revenue changed over time?

### Final query structure

The current SQL uses `order_revenue` (one row per order), `eligible_orders` (one row per delivered order), `monthly_revenue` (one row per delivery month), and `monthly_changes` (monthly revenue with the prior month from `LAG()`). The final query calculates absolute and percentage month-over-month revenue change.

The named CTEs make each step and its row grain easier to follow.

### Data-coverage observation

September 2018 and October 2018 contain very few delivered orders and occur at the end of the dataset.

Their very low revenue values and large apparent declines reflect partial dataset coverage rather than comparable full-month business performance.

These periods remain in the detailed output but are excluded from the saved two-row summary of the largest positive and negative percentage changes.

### Saved results

The monthly query output and its selected percentage-change summary are stored in:

- `results/q02_monthly_revenue_trend.csv`
- `results/q02_largest_increase_and_decrease_summary.csv`

## Business question 3 - orders and revenue by customer state

Completed the SQL analysis for:

> Which states generate the most orders and revenue?

### Final query structure

The current SQL uses `order_revenue` (one row per order), `eligible_orders` (one row per delivered order), and `state_revenue` (one row per customer state after joining customers). The final query calculates:

- revenue rank using `RANK()`
- order-volume rank using `RANK()`

### Key modeling decisions

- Geography is based on **customer state**, not seller state.
- Revenue uses the same merchandise-revenue definition as Question 2.
- Only delivered orders are included.
- `COUNT(DISTINCT order_id)` is used for order volume.
- Order rank and revenue rank are calculated separately because they may not be identical.

### Saved result

The final result is stored in:

`results/q03_state_orders_and_revenue.csv`

# 2026-09-18

## Business question 4 - product-category rankings

Completed the SQL analysis for:

> How do product-category rankings differ over time or geography?

### Query design

The analysis uses a multi-table join chain:

`products`
→ `product_category_name_translation`
→ `order_items`
→ `orders`
→ `customers`

A `LEFT JOIN` is used between `products` and the translation table so products without an English category translation are preserved.

### Final outputs

The final script stores eligible item rows in `eligible_category_items` and produces two result sets in one BigQuery script:

1. geography ranking by customer state
2. time ranking by delivery month

The temporary table allows both outputs to reuse the same filtered item-level data.

### Window-function practice

This question introduced partitioned ranking:

- category ranking within each state
- category ranking within each month

Both revenue rank and order-count rank are calculated using `RANK()`.

### Saved results

- `results/q04_product_category_geography_ranking.csv`
- `results/q04_product_category_time_ranking.csv`

## Business question 5 - seller revenue concentration

Completed the SQL analysis for:

> How concentrated is revenue among top sellers?

### Query design

The analysis:

1. filters to eligible delivered orders
2. joins eligible orders to `order_items`
3. joins seller information
4. aggregates merchandise revenue to one row per seller
5. orders sellers by revenue
6. calculates top-seller revenue share
7. calculates cumulative revenue and cumulative revenue share

### Top-10% definition

The eligible population contains **2,970 sellers**.

The top 10% contains **297 sellers**.

The current query uses `ROW_NUMBER()` for exactly 297 seller positions. It rounds each seller's item-price sum before ranking and totaling sellers; the small total-revenue difference is documented in `docs/qa_report.md`.

### Window-function practice

This question introduced several window-function patterns:

- ranking / seller positioning
- total revenue using `SUM(...) OVER()`
- cumulative revenue using running `SUM(...) OVER(...)`
- explicit window frames using `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`

### Conditional aggregation

`CASE WHEN` is used inside `SUM()` to calculate revenue generated only by the top 10% of sellers.

This sums revenue for the selected sellers.

### Final results

- top 10% of sellers generate approximately **67%** of total revenue
- top 127 sellers generate approximately **50%**
- top 533 sellers generate approximately **80%**
- top 889 sellers generate approximately **90%**

### Saved results

- `results/q05_top10pct_seller_revenue_share.csv`
- `results/q05_seller_rank_50pct_total_revenue.csv`
- `results/q05_seller_rank_80pct_total_revenue.csv`
- `results/q05_seller_rank_90pct_total_revenue.csv`

## Business question 6 - delivery performance and customer reviews

Completed the SQL analysis for:

> How does delivery performance relate to customer review scores?

### Query design

The analysis:

1. filters to eligible delivered orders
2. classifies each order as Early, On Time, or Late using `CASE WHEN`
3. joins eligible orders to `order_reviews`
4. retains review records as the analytical grain
5. calculates average review score by delivery status
6. groups review records by delivery status and review score
7. calculates within-status review-score percentages using a windowed `SUM()`

### Grain decision

`order_reviews` may contain multiple review records for the same order.

The analysis keeps each review record, including multiple reviews on one order.

Therefore:

- averages are review-record averages
- counts are review-record counts
- percentage distributions describe review records rather than unique orders

### SQL learning notes

A window-function version of the delivery-status + review-score count was tested using:

`COUNT(*) OVER (PARTITION BY delivery_status, review_score)`

That repeated each group count on every review row instead of returning one row per group.

The final script uses `GROUP BY delivery_status, review_score` for the grouped counts because this directly matches the desired analytical grain.

A windowed `SUM()` is then used to calculate the total count within each delivery-status group.

### Saved results

- `results/q06_avg_review_score_by_delivery_status.csv`
- `results/q06_delivery_status_review_score_share_pct.csv`

# 2026-09-22

## Business question 7 - repeat purchases

Completed the SQL analysis for:

> How common are repeat purchases, and how many orders do repeat customers typically place?

### Key modeling decision

An initial attempt grouped orders by `customer_id`.

This produced an order count of 1 for every customer because `customer_id` is effectively unique to each order in the Olist dataset.

The analysis was corrected to use `customer_unique_id`, which identifies the same real customer across multiple orders.

### Final query structure

The final script joins eligible delivered orders to `customers` and stores one row per `customer_unique_id` in `customer_order_counts`. Three queries then produce the repeat-order distribution, the overall repeat-customer share, and the median order count among repeat customers.

### SQL techniques practiced

This question uses:

- multi-table `JOIN`
- `COUNT(DISTINCT)`
- aggregation at multiple grains
- filtering after customer-level aggregation
- windowed `SUM()`
- `COUNTIF()` for the repeat-customer summary
- `PERCENTILE_CONT()` for the median

### Final results

- eligible customers: **93,350**
- repeat customers: **2,801**
- repeat-customer share: **3.0%**
- median delivered orders among repeat customers: **2.0**
- **91.86%** of repeat customers placed exactly 2 delivered orders

### Saved results

- `results/q07_repeat_customer_share.csv`
- `results/q07_repeat_customer_order_distribution.csv`
- `results/q07_median_order_number_repeat_customers.csv`


## QA validation review (2026-09-22)

Independent checks against the local source CSVs confirmed all nine documented table row counts and the headline results for Q1-Q7. Q2-Q5 use the same delivered-order eligibility and item-price revenue definition; Q1 and Q6 use the same calendar-date delivery classification. Join checks found no accidental multiplication of eligible item rows. September and October 2018 contain only 56 and 3 eligible delivered orders, respectively, supporting the partial-month caveats.

The detailed evidence and recommended changes are in `docs/qa_report.md`. At this review stage, Q4-Q7 multi-result files still reused CTEs after the first statement; the following SQL Cleanup entry records the fix. Q5 sums seller revenues after rounding each seller, leaving its saved monetary total 141.07 above the unrounded source item-price total. No SQL or result CSV was changed in this review.


## SQL cleanup (2026-09-22)

The final analysis SQL now has a consistent question/output header, concise CTE names, and one portfolio version per question. The obsolete Q1 CTE draft and Q6 window-count test query were removed. Q4-Q7 now use temporary tables for values shared by multiple output statements. The validation script's duplicated `customers` query under the geolocation heading was corrected to query `geolocation`; its unqualified `order_payments` reference was also qualified. No result CSV was changed. BigQuery execution and saved-output comparison remain pending.


## Results consolidation (2026-09-22)

All 16 final derived CSVs were moved from question subfolders into `results/` without changing their contents. The three seller-threshold filenames now use `50pct`, `80pct`, and `90pct`; the Q6 average-score file is `q06_avg_review_score_by_delivery_status.csv`. Documentation references were updated. The README selects five findings for a quick overview, while `results/` retains all 16 outputs for detailed review.

## Documentation finalization (2026-09-22)

The final documents now use Questions 1-7 consistently. The Q2 growth/decline summary is explicitly described as a percentage-change selection, the Q4 and Q7 methods match the cleaned SQL, and the Q5 per-seller rounding difference is documented. Historical implementation notes remain in this log, while current-method descriptions and saved-result references point to the final files.

## README finalization (2026-09-22)

The root README now states the objective, dataset and BigQuery tools, schema diagram, seven business questions, SQL techniques, selected results, limitations, repository structure, and reproduction steps. It explains the project-specific BigQuery identifiers and how the two-row Q2 percentage-change summary is selected. The BigQuery rerun remains open.

## BigQuery rerun completed (2026-09-22)

Reran the cleaned Q1-Q7 scripts in BigQuery and compared each result set with its saved CSV. The outputs matched. The Q4 category rounding and Q5 seller rounding differences documented in `docs/qa_report.md` remain differences from independent source calculations, not new differences between the rerun and saved outputs.
