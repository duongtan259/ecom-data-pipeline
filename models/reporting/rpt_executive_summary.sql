{{ config(materialized='table') }}

/*
  Monthly executive summary — the top-level KPI roll-up for dashboards.
  Aggregates daily_revenue to monthly granularity with MoM growth.
*/

WITH monthly AS (
    SELECT
        DATE_TRUNC(order_date, MONTH)                                       AS order_month,
        SUM(total_orders)                                               AS monthly_orders,
        SUM(unique_customers)                                           AS monthly_active_customers,
        ROUND(SUM(total_revenue), 2)                                   AS monthly_revenue,
        ROUND(SUM(total_gross_margin), 2)                              AS monthly_gross_margin,
        ROUND(SUM(total_revenue) / NULLIF(SUM(total_orders), 0), 2)   AS avg_order_value,
        ROUND(
            SUM(total_gross_margin) / NULLIF(SUM(total_revenue), 0) * 100, 2
        )                                                               AS gross_margin_pct
    FROM {{ ref('daily_revenue') }}
    GROUP BY order_month
)

SELECT
    order_month,
    monthly_orders,
    monthly_active_customers,
    monthly_revenue,
    monthly_gross_margin,
    avg_order_value,
    gross_margin_pct,
    ROUND(
        (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY order_month))
        / NULLIF(LAG(monthly_revenue) OVER (ORDER BY order_month), 0) * 100,
        2
    )                                                                   AS mom_revenue_growth_pct
FROM monthly
ORDER BY order_month
