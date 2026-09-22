-- Data setup: one-time correction for the imported category-translation table.
-- Output: no result set; run only when the imported columns still have generic names.
-- Preserved as a record of the initial BigQuery import correction (2026-09-01).

-- Rename generic imported columns to their intended names
ALTER TABLE olist_brazillian_ecommerce.product_category_name_translation
RENAME COLUMN string_field_0 TO product_category_name;

ALTER TABLE olist_brazillian_ecommerce.product_category_name_translation
RENAME COLUMN string_field_1 TO product_category_name_english;

-- Remove the header row that was imported as data
DELETE FROM olist_brazillian_ecommerce.product_category_name_translation
WHERE product_category_name = 'product_category_name';
