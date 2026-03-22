{{ config(materialized='table') }}

SELECT
    oi.order_item_id,
    oi.order_id,
    oi.user_id,
    oi.product_id,
    LOWER(TRIM(oi.status))                          AS status,
    ROUND(oi.sale_price, 2)                         AS sale_price,
    ROUND(p.cost, 2)                                AS product_cost,
    ROUND(oi.sale_price - COALESCE(p.cost, 0), 2)  AS gross_margin,
    p.category                                      AS product_category,
    p.product_name,
    p.brand                                         AS product_brand,
    ROUND(p.retail_price, 2)                        AS retail_price,
    p.department,
    TIMESTAMP(oi.created_at)                        AS created_at,
    DATE(oi.created_at)                             AS order_date,
    DATE_TRUNC(DATE(oi.created_at), MONTH)          AS order_month
FROM {{ ref('bronze_order_items') }} oi
LEFT JOIN {{ ref('bronze_products') }} p USING (product_id)
WHERE oi.order_item_id IS NOT NULL
