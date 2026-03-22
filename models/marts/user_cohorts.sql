{{ config(materialized='table') }}

/*
  Cohort retention analysis:
  Groups users by their first-order month and tracks monthly revenue
  and active user count per cohort over time.
*/

WITH user_first_order AS (
    SELECT
        user_id,
        DATE_TRUNC(MIN(order_date), MONTH) AS cohort_month
    FROM {{ ref('stg_order_items') }}
    WHERE status NOT IN ('cancelled', 'returned')
    GROUP BY user_id
),

monthly_activity AS (
    SELECT
        oi.user_id,
        DATE_TRUNC(oi.order_date, MONTH)   AS activity_month,
        SUM(oi.sale_price)                  AS monthly_revenue,
        COUNT(DISTINCT oi.order_id)         AS monthly_orders
    FROM {{ ref('stg_order_items') }} oi
    WHERE oi.status NOT IN ('cancelled', 'returned')
    GROUP BY oi.user_id, activity_month
)

SELECT
    ufo.cohort_month,
    ma.activity_month,
    DATE_DIFF(ma.activity_month, ufo.cohort_month, MONTH) AS months_since_first_order,
    COUNT(DISTINCT ma.user_id)                             AS active_users,
    ROUND(SUM(ma.monthly_revenue), 2)                     AS cohort_revenue,
    SUM(ma.monthly_orders)                                 AS cohort_orders
FROM user_first_order ufo
JOIN monthly_activity ma USING (user_id)
GROUP BY ufo.cohort_month, ma.activity_month, months_since_first_order
ORDER BY ufo.cohort_month, months_since_first_order
