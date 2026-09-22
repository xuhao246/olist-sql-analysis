# SQL portfolio QA report

## Executive summary

The seven headline findings match independent calculations from the local Olist CSVs. I checked the SQL joins and revenue filters and found no unintended row multiplication or conflicting inclusion rule. After the CTE scope cleanup, I reran the cleaned Q1-Q7 scripts in BigQuery and compared their result sets with the saved CSVs.

The SQL cleanup replaced the Q4-Q7 cross-statement CTE references with temporary tables. The BigQuery rerun agreed with the saved outputs. Q5 still totals rounded seller values rather than exact merchandise revenue, and several Q4 saved values differ by one unit at `.50` boundaries. Neither difference changes the reported findings.

## Source table and key metric validation

| Table | Source rows | Documented rows | Result |
|---|---:|---:|---|
| customers | 99,441 | 99,441 | Match |
| geolocation | 1,000,163 | 1,000,163 | Match |
| order_items | 112,650 | 112,650 | Match |
| order_payments | 103,886 | 103,886 | Match |
| order_reviews | 99,224 | 99,224 | Match |
| orders | 99,441 | 99,441 | Match |
| product_category_name_translation | 71 | 71 | Match |
| products | 32,951 | 32,951 | Match |
| sellers | 3,095 | 3,095 | Match |

Source primary/composite keys checked for uniqueness: `orders.order_id`, `customers.customer_id`, `products.product_id`, `sellers.seller_id`, translation category, `(order_id, order_item_id)` for items, `(order_id, payment_sequential)` for payments, and `(review_id, order_id)` for reviews. The checked order, item, payment, and review foreign keys had zero missing matches.

| Question | Independent source check | Saved result |
|---|---|---|
| Q1 | 96,470 eligible orders; 6,534 late; 6.8% overall; 4.4% median of rounded monthly rates | Matches; all 25 monthly numerator and denominator pairs match |
| Q2 | 25 delivery months; exact eligible item-price sum 13,220,248.93; August 2018 rounds to 1,141,792 | All monthly totals, `LAG` values, absolute changes, and percentage changes match |
| Q3 | SP 40,494 orders / 5,066,563 rounded revenue; RJ 12,350 / 1,759,651; MG 11,354 / 1,552,482 | All 27 state order counts and rounded revenue values match; both ranks are internally correct |
| Q4 | 1,377 state-category groups and 1,282 month-category groups | All order counts match; ranks are correct for the saved rounded totals; seven revenue rounding exceptions noted below |
| Q5 | 2,970 eligible sellers; top 297 produce 8,872,848.08 of exact item-price revenue, or 67.12%; 50/80/90% thresholds occur at positions 127/533/889 | Headline shares and positions match; saved monetary totals differ due to intermediate rounding |
| Q6 | 96,353 review records on 95,824 eligible orders; Early 4.29, On Time 4.03, Late 2.27 average scores | All review-score counts and the cited 1-star/5-star shares match |
| Q7 | 93,350 eligible unique customers; 2,801 repeat customers; 3.0% share; median 2 delivered orders | Distribution counts match, including 2,573 customers with two orders |

## Join and grain review

- Q2 and Q3 aggregate item prices to one row per order before joining to the one-row-per-order `orders` table. Q3 joins one customer row per order. No multiplication was found.
- Q4 joins eligible orders, item rows, unique product rows, unique translation rows, and unique customer rows. The `LEFT JOIN` preserves untranslated categories. The 110,189 eligible item rows remain 110,189 through these lookups. There are 13 product records across two untranslated category values; products with a null source category are also retained.
- Q5 joins eligible item rows to one seller row per seller. Its seller aggregation produces 2,970 rows. No item-row multiplication was found.
- Q6 intentionally uses review-record grain: 96,353 review records represent 95,824 orders, including 525 orders with multiple review records. The analysis does not sum item revenue after the review join, so this one-to-many relationship does not inflate revenue.
- Q7 groups delivered orders by `customer_unique_id` and counts distinct `order_id`, matching the repeat-customer definition.
- None of the business-question queries joins payments to another one-to-many child table.

## Shared definitions

Q2-Q5 consistently filter to `order_status = 'delivered'` with a non-null customer delivery date, and use `order_items.price` for merchandise revenue. Freight and `order_payments.payment_value` are excluded. Q1 and Q6 both classify delivery using calendar dates and require non-null actual and estimated delivery dates. Q7 uses the same delivered-order eligibility as Q2-Q5 and `customer_unique_id` for customer identity. The inclusion rules agree.

**Rounding difference:** Q5 applies `ROUND(SUM(price), 0)` to each seller before summing sellers. Its saved all-seller total is 13,220,390, compared with the exact eligible item-price total of 13,220,248.93. The difference is 141.07 (about 0.0011%). The saved top-297 total is 8,872,853 versus 8,872,848.08 from the source before seller-level rounding. The 67% conclusion is unaffected. To make monetary totals identical across questions, retain unrounded seller revenue through the final aggregation and round only display fields; rerun Q5 and validate any updated CSVs before changing them.

**Category rounding difference:** Seven Q4 saved category revenues are one unit below decimal half-up rounding of the source cent totals. Each source total ends in `.50`; examples include AP `bed_bath_table` (669.50 saved as 669) and ES `health_beauty` (20,038.50 saved as 20,038). Floating-point aggregation is a possible explanation, but the BigQuery column type and execution should be checked before attributing the cause. The affected order counts match. If exact decimal presentation is required, check the source type and consider explicit `NUMERIC` arithmetic, then rerun and validate both Q4 results.

## Partial-month caveats

August 2018 has 8,314 eligible delivered orders and 1,141,791.54 exact merchandise revenue. September has 56 orders / 11,469.04; October has 3 orders / 275.40. The last source purchase timestamp is October 17, 2018. The sharp drop in observed volume makes September and October poor full-month comparisons. `business_questions.md`, `methodology.md`, and `findings.md` preserve this caveat for Q2 and Q4 and retain the months in detailed results.

The Q2 summary CSV selects December 2016 and January 2017 as the largest **percentage** decrease and increase after excluding the partial final months. By absolute amount, other months lead. The documentation now states both the percentage basis and the month-exclusion rule.

## Reproducibility findings

- **CTE scope resolved and rerun verified:** Q4-Q7 now materialize shared intermediate rows in temporary tables, so later statements no longer reference expired CTEs. Q2 and Q3 remain single-statement queries. The cleaned Q1-Q7 scripts were rerun in BigQuery and their result sets compared with the saved CSVs.
- **Moderate, Q5 intermediate rounding:** See the monetary reconciliation above. This changes saved monetary totals slightly but not the concentration conclusion.
- **Minor, Q4 `.50` rounding exceptions:** Seven saved category totals differ by one unit from decimal half-up source rounding. Confirm BigQuery type and desired rounding policy before changing SQL or CSVs.

## Recommended changes

1. Decide whether Q5 monetary totals should retain cents until final display; if changed, rerun and update only validated affected results.
2. Inspect Q4 `price` type and rounding behavior before changing its seven borderline values.

## Results consolidation

All 16 final derived CSVs are now directly under `results/`; no CSV content changed during the move. The three Q5 threshold filenames use `50pct`, `80pct`, and `90pct`, and the Q6 average-score file is `q06_avg_review_score_by_delivery_status.csv`. Every CSV reference in the README and docs resolves to an existing file. The README links five selected findings to their result CSVs; all five displayed figures were checked against those files. The full findings document covers all seven questions.

## Final readiness

Source and join checks support the seven findings. The cleaned Q1-Q7 scripts were rerun in BigQuery and compared with the saved CSVs. The README links the final questions and selected results; the Q4 and Q5 rounding differences remain documented above.
