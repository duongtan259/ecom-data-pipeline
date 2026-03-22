{{ config(materialized='table') }}

SELECT
    order_date,
    COUNT(DISTINCT order_id)                                            AS total_orders,
    COUNT(DISTINCT user_id)                                             AS unique_customers,
    ROUND(SUM(sale_price), 2)                                          AS total_revenue,
    ROUND(SUM(gross_margin), 2)                                        AS total_gross_margin,
    ROUND(AVG(sale_price), 2)                                          AS avg_sale_price,
    ROUND(SUM(gross_margin) / NULLIF(SUM(sale_price), 0) * 100, 2)    AS gross_margin_pct
FROM {{ ref('stg_order_items') }}
WHERE status NOT IN ('cancelled', 'returned')
GROUP BY order_date
ORDER BY order_date
