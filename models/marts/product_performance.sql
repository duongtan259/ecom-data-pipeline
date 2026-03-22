{{ config(materialized='table') }}

SELECT
    product_id,
    product_name,
    product_brand,
    product_category,
    department,
    COUNT(*)                                                         AS total_items_sold,
    COUNT(DISTINCT order_id)                                         AS total_orders,
    COUNT(DISTINCT user_id)                                          AS unique_buyers,
    ROUND(SUM(sale_price), 2)                                       AS total_revenue,
    ROUND(SUM(gross_margin), 2)                                     AS total_gross_margin,
    ROUND(AVG(sale_price), 2)                                       AS avg_sale_price,
    ROUND(AVG(retail_price), 2)                                     AS avg_retail_price,
    ROUND(SUM(gross_margin) / NULLIF(SUM(sale_price), 0) * 100, 2) AS gross_margin_pct
FROM {{ ref('stg_order_items') }}
WHERE status NOT IN ('cancelled', 'returned')
GROUP BY product_id, product_name, product_brand, product_category, department
ORDER BY total_revenue DESC
