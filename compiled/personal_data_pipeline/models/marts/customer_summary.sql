

WITH order_stats AS (
    SELECT
        user_id,
        COUNT(DISTINCT order_id)                                  AS total_orders,
        ROUND(SUM(sale_price), 2)                                AS total_spent,
        MIN(order_date)                                           AS first_order_date,
        MAX(order_date)                                           AS last_order_date,
        DATE_DIFF(MAX(order_date), MIN(order_date), DAY)         AS customer_lifespan_days
    FROM `data-491008`.`silver_dev`.`stg_order_items`
    WHERE status NOT IN ('cancelled', 'returned')
    GROUP BY user_id
)

SELECT
    u.user_id,
    u.email,
    u.age,
    u.gender,
    u.country,
    u.city,
    u.traffic_source,
    u.registration_date,
    os.total_orders,
    os.total_spent,
    ROUND(os.total_spent / NULLIF(os.total_orders, 0), 2)        AS avg_order_value,
    os.first_order_date,
    os.last_order_date,
    os.customer_lifespan_days,
    CASE
        WHEN os.total_spent >= 1000 THEN 'VIP'
        WHEN os.total_spent >= 500  THEN 'High Value'
        WHEN os.total_spent >= 100  THEN 'Mid Value'
        WHEN os.total_spent > 0     THEN 'Low Value'
        ELSE 'No Purchase'
    END                                                           AS customer_segment
FROM `data-491008`.`silver_dev`.`stg_users` u
LEFT JOIN order_stats os USING (user_id)