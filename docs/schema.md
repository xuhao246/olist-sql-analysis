# Schema and relationships

## Table row counts

I recorded the row counts in BigQuery after import, then checked them against the local CSVs.

| Table | Row Count |
|---|---:|
| customers | 99,441 |
| geolocation | 1,000,163 |
| order_items | 112,650 |
| order_payments | 103,886 |
| order_reviews | 99,224 |
| orders | 99,441 |
| product_category_name_translation | 71 |
| products | 32,951 |
| sellers | 3,095 |

## Primary key and foreign key

The keys below are unique in this dataset. BigQuery does not enforce them. Column names, including the source spelling `product_name_lenght`, match the CSVs.

| Table | Grain | Primary Key | Attributes | Foreign Keys | Notes |
|---|---|---|---|---|---|
| customers | One row per `customer_id` | `customer_id` | `customer_unique_id`, `customer_zip_code_prefix`, `customer_city`, `customer_state` | None | `customer_unique_id` identifies the same customer across multiple orders and is not unique. |
| geolocation | One row per geolocation observation associated with a ZIP-code prefix | None identified | `geolocation_zip_code_prefix`, `geolocation_lat`, `geolocation_lng`, `geolocation_city`, `geolocation_state` | None | ZIP-code prefixes repeat; aggregate before joining to order-level data. |
| order_items | One row per item line within an order | (`order_id`, `order_item_id`) | `product_id`, `seller_id`, `shipping_limit_date`, `price`, `freight_value` | `order_id` → `orders.order_id`; `product_id` → `products.product_id`; `seller_id` → `sellers.seller_id` | Composite primary key validated across all 112,650 rows. All listed foreign keys validated with 0 unmatched rows. |
| order_payments | One row per payment transaction/sequence within an order | (`order_id`, `payment_sequential`) | `payment_type`, `payment_installments`, `payment_value` | `order_id` → `orders.order_id` | Composite key validated against all 103,886 rows. All listed foreign keys validated with 0 unmatched rows. |
| order_reviews | One row per review associated with an order | (`review_id`, `order_id`) | `review_score`, `review_comment_title`, `review_comment_message`, `review_creation_date`, `review_answer_timestamp` | `order_id` → `orders.order_id` | Composite key validated as unique and non-null. All listed foreign keys validated with 0 unmatched rows. |
| orders | One row per order | `order_id` | `customer_id`, `order_status`, `order_purchase_timestamp`, `order_approved_at`, `order_delivered_carrier_date`, `order_delivered_customer_date`, `order_estimated_delivery_date` | `customer_id` → `customers.customer_id` | `order_id` validated as unique and non-null across all 99,441 rows. All listed foreign keys validated with 0 unmatched rows. |
| product_category_name_translation | One row per Portuguese product category name and its English translation | `product_category_name` | `product_category_name_english` | None | `product_category_name` validated as unique and non-null across all 71 rows. |
| products | One row per product | `product_id` | `product_category_name`, `product_name_lenght`, `product_description_lenght`, `product_photos_qty`, `product_weight_g`, `product_length_cm`, `product_height_cm`, `product_width_cm` | `product_category_name` → `product_category_name_translation.product_category_name` | `product_id` validated as unique and non-null. Category relationship is not fully complete: 13 products across 2 non-null category values have no translation; another 610 products have a null source category. |
| sellers | One row per seller | `seller_id` | `seller_zip_code_prefix`, `seller_city`, `seller_state` | None | `seller_id` validated as unique and non-null across all 3,095 rows. |

## Cardinality check

| Table A | Table B | Relationship / Join Path | Cardinality | Notes |
|---|---|---|---|---|
| `customers` | `orders` | `customers.customer_id` → `orders.customer_id` | 1:1 | `customer_id` is unique in both tables. Repeat real-world customers are represented by `customer_unique_id`. |
| `orders` | `order_items` | `orders.order_id` → `order_items.order_id` | 1:M | One order can contain multiple item rows. |
| `products` | `order_items` | `products.product_id` → `order_items.product_id` | 1:M | One product can appear in multiple order-item rows. |
| `sellers` | `order_items` | `sellers.seller_id` → `order_items.seller_id` | 1:M | One seller can appear in multiple order-item rows. |
| `orders` | `order_payments` | `orders.order_id` → `order_payments.order_id` | 1:M | One order can have multiple payment sequences. |
| `orders` | `order_reviews` | `orders.order_id` → `order_reviews.order_id` | 1:M | One order can have multiple review records. |
| `product_category_name_translation` | `products` | `product_category_name_translation.product_category_name` → `products.product_category_name` | 1:M | One category can contain many products. Relationship is not fully referentially complete because 13 product rows across 2 category values have no matching translation record. |
| `orders` | `products` | `orders` → `order_items` ← `products` | M:M | Resolved through `order_items`. One order can contain multiple products, and one product can appear in multiple orders. |
| `orders` | `sellers` | `orders` → `order_items` ← `sellers` | M:M | Resolved through `order_items`. One order can involve multiple sellers, and one seller can participate in multiple orders. |
