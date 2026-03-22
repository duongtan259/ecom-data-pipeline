{{ config(materialized='table') }}

SELECT
    id               AS product_id,
    cost,
    category,
    name             AS product_name,
    brand,
    retail_price,
    department,
    sku,
    distribution_center_id
FROM {{ source('thelook_ecommerce', 'products') }}
