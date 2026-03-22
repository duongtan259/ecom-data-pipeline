

/*
  Top 50 products by revenue — ready for dashboard consumption.
*/

SELECT
    product_id,
    product_name,
    product_brand,
    product_category,
    department,
    total_items_sold,
    total_orders,
    unique_buyers,
    total_revenue,
    total_gross_margin,
    avg_sale_price,
    gross_margin_pct,
    RANK() OVER (ORDER BY total_revenue DESC)               AS revenue_rank,
    RANK() OVER (ORDER BY total_gross_margin DESC)          AS margin_rank
FROM `data-491008`.`gold_dev`.`product_performance`
QUALIFY RANK() OVER (ORDER BY total_revenue DESC) <= 50