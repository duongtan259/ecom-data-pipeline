{{ config(materialized='table') }}

SELECT
    order_id,
    user_id,
    LOWER(TRIM(status))                              AS status,
    LOWER(TRIM(gender))                              AS gender,
    TIMESTAMP(created_at)                            AS created_at,
    TIMESTAMP(returned_at)                           AS returned_at,
    TIMESTAMP(shipped_at)                            AS shipped_at,
    TIMESTAMP(delivered_at)                          AS delivered_at,
    num_of_item,
    DATE(created_at)                                 AS order_date,
    DATE_TRUNC(DATE(created_at), MONTH)              AS order_month,
    EXTRACT(YEAR FROM created_at)                    AS order_year,
    CASE
        WHEN LOWER(status) IN ('complete', 'shipped') THEN TRUE
        ELSE FALSE
    END                                              AS is_completed
FROM {{ ref('bronze_orders') }}
WHERE order_id IS NOT NULL
  AND user_id IS NOT NULL
