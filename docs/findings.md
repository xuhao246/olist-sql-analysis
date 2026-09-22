# Findings

These findings come from the seven final questions and the CSVs in `results/`. Revenue is the sum of `order_items.price` for eligible delivered orders; it excludes freight and payment values.

## Question 1 - how frequently are orders delivered late?

Among **96,470** eligible delivered orders, **6,534** arrived after the estimated calendar date: an overall late-delivery rate of **6.8%**.

The median monthly late-delivery rate was **4.4%**.

Monthly rates varied over time. Some early months produced extreme percentages because they contained very few eligible orders. For example, a 50% monthly late-delivery rate based on only two orders is not directly comparable with rates calculated from thousands of orders.

The overall rate describes all eligible orders. The median monthly rate describes a typical month.

## Question 2 - how has monthly revenue changed over time?

Monthly merchandise revenue rose over the observed period, with large swings between some months.

Revenue is based on the sum of item prices for delivered orders and is attributed to the month in which the customer received the order.

The highest observed monthly revenue was approximately **1,141,792** in **August 2018**.

### Month-over-month changes

Among months retained in the two-row percentage-change summary, **January 2017** had the largest increase: revenue rose from **759** in December 2016 to **33,599**, or **4,326.7%**.

**December 2016** had the largest percentage decrease in that summary: revenue fell from **9,838** in November to **759**, or **92.3%**.

These extreme percentages reflect low early-month comparison values. Measured in absolute revenue, the largest increase outside the partial final months was **345,363** in August 2018, and the largest decrease was **206,803** in July 2018. The summary CSV reports the percentage leaders.

### Overall pattern

Despite short-term fluctuations, revenue expanded substantially through 2017 and into 2018.

Several months in 2018 exceeded one million in merchandise revenue, including:

- April 2018: approximately **1,111,972**
- May 2018: approximately **1,008,602**
- June 2018: approximately **1,003,232**
- August 2018: approximately **1,141,792**

Those 2018 months were much larger than the earlier months in the dataset.

### End-of-dataset caveat

September 2018 and October 2018 show revenue of only approximately **11,469** and **275**, respectively.

These months contain only **56** and **3** eligible delivered orders, respectively, and represent limited dataset coverage. Their apparent declines of approximately 99% and 97.6% should not be interpreted as evidence of a genuine collapse in revenue.

They are retained in the detailed monthly results for transparency but excluded from the summary of meaningful revenue increases and decreases.

## Question 3 - which states generate the most orders and revenue?

Most orders and revenue came from a few customer states.

### Top states

The top three states by both delivered-order volume and merchandise revenue are:

1. **SP**
2. **RJ**
3. **MG**

SP is the clear leader, with approximately:

- **40,494 delivered orders**
- **5,066,563 in merchandise revenue**

RJ ranks second with approximately:

- **12,350 delivered orders**
- **1,759,651 in merchandise revenue**

MG ranks third with approximately:

- **11,354 delivered orders**
- **1,552,482 in merchandise revenue**

Together, SP, RJ, and MG account for much of the observed order volume and revenue.

### Order rank vs revenue rank

Order-volume rank and revenue rank are generally similar, but they are not always identical.

For example:

- **GO** ranks 10th by order volume but 9th by revenue.
- **ES** ranks 9th by order volume but 10th by revenue.

States with similar order counts can have different revenue, likely because average order value differs.

Comparing the two ranks shows where order value differs.

### Interpretation

The results show that state-level revenue is driven primarily by customer concentration in the largest markets, especially SP, RJ, and MG.

However, differences between order rank and revenue rank show that geographic performance is not determined only by the number of orders. Order value also contributes to differences between states.

## Question 4 - how do product-category rankings differ over time or geography?

Category rankings change by state and delivery month.

### Geographic rankings

`health_beauty` is the most geographically dominant category:

- ranked #1 by revenue in 15 of 27 states
- ranked #1 by order count in 17 of 27 states

Other categories such as `sports_leisure`, `watches_gifts`, and `bed_bath_table` lead in selected states.

Revenue rank and order-count rank are not always the same.

For example:

- In RJ, `watches_gifts` ranks #1 by revenue but only #6 by order count, while `bed_bath_table` ranks #1 by order count and #2 by revenue.
- In MG, `health_beauty` ranks #1 by revenue, while `bed_bath_table` ranks #1 by order count.
- Similar differences appear in DF, ES, GO, MS, AP, and TO.

These differences suggest that category performance depends not only on transaction volume but also on order value.

### Rankings over time

Category leadership also changes across delivery months.

By revenue:

- `watches_gifts` ranks #1 in 8 months
- `health_beauty` ranks #1 in 5 months
- `bed_bath_table` ranks #1 in 3 months

By order count:

- `bed_bath_table` ranks #1 in 11 months
- `health_beauty` ranks #1 in 6 months
- `furniture_decor` ranks #1 in 5 months

The difference between revenue leadership and order-volume leadership shows that the most frequently purchased category is not always the category generating the most revenue.

### Interpretation

Product-category rankings are sensitive to both geography and time.

Some categories generate high revenue because of strong order volume, while others achieve high revenue with fewer orders and therefore likely higher average order value.

Keeping both ranks shows which categories sell often and which bring in more revenue.

### Data caveats

The category join retains products without an English translation. The source product table includes **13** products with non-null categories lacking a translation and **610** products with a null source category; both appear under a null English category name when present in eligible orders.

The final months of the dataset, particularly September and October 2018, contain limited activity and should not be interpreted as representative full-month category performance.

## Question 5 - how concentrated is revenue among top sellers?

A small share of sellers accounts for most revenue.

Among 2,970 eligible sellers:

- the **top 10% of sellers (297 sellers)** generate approximately **67% of total merchandise revenue**
- the top **127 sellers** (about **4.3%**) generate approximately **50% of total revenue**
- the top **533 sellers** (about **17.9%**) generate approximately **80% of total revenue**
- the top **889 sellers** (about **29.9%**) generate approximately **90% of total revenue**

### Interpretation

Seller revenue is strongly concentrated toward the top of the distribution.

The clearest headline finding is that only **10% of eligible sellers generate about two-thirds of total merchandise revenue**.

The cumulative-revenue analysis shows even stronger concentration at the upper end:

- fewer than **5% of sellers account for half of total revenue**
- fewer than **20% account for 80% of revenue**
- approximately **30% account for 90% of revenue**

Most marketplace revenue comes from a small group of sellers.

The seller query rounds each seller's revenue to a whole unit before summing sellers. Its saved all-seller total is **141.07** above the exact eligible item-price sum; the approximate concentration shares above are unchanged. See `docs/qa_report.md` for the reconciliation.

## Question 6 - how does delivery performance relate to customer review scores?

Delivery performance is strongly associated with customer review scores.

### Average review score

Average review scores decline sharply for late deliveries:

- **Early:** 4.29
- **On Time:** 4.03
- **Late:** 2.27

Late deliveries therefore receive substantially lower review scores on average than early or on-time deliveries.

### Review-score distribution

The distribution uses **96,353 review records** on **95,824 orders**; orders with multiple reviews contribute multiple observations. The scores show an even clearer pattern.

For early deliveries:

- **62.43%** of review records are 5-star
- only **6.60%** are 1-star

For on-time deliveries:

- **50.43%** are 5-star
- **8.52%** are 1-star

For late deliveries:

- only **16.54%** are 5-star
- **53.74%** are 1-star

### Interpretation

The strongest contrast is among late deliveries: more than half of associated review records receive the lowest possible score.

Early and on-time deliveries show the opposite pattern, with 5-star reviews representing the largest share.

In this dataset, later delivery is associated with lower review scores.

The result should not be interpreted as causal, because review scores may also be influenced by product quality, seller service, packaging, and other aspects of the customer experience.

## Question 7 - how common are repeat purchases, and how many orders do repeat customers typically place?

Few eligible customers placed a second delivered order.

Among **93,350** customers with completed delivered orders, only **2,801** placed more than one order.

This corresponds to a repeat-customer rate of **3.0%**.

### Repeat-customer order frequency

Most repeat customers returned only once after their initial purchase.

Among repeat customers:

- **91.86%** placed exactly 2 delivered orders
- **6.46%** placed 3 orders
- **1.00%** placed 4 orders
- fewer than 1% placed 5 or more orders

The median number of delivered orders among repeat customers is **2.0**.

### Interpretation

Repeat purchases are uncommon in the observed period.

Only a small share of customers make a second completed purchase, and customers who do return overwhelmingly stop after two total orders.

Higher-frequency repeat purchasing is rare: only a very small number of customers place five or more delivered orders.

This describes repeat delivered orders within the observed dataset. It is not a lifetime customer-retention measure, because later purchases outside the dataset are unobserved.
