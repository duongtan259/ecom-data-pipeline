

SELECT
    order_id,
    user_id,
    status,
    gender,
    created_at,
    returned_at,
    shipped_at,
    delivered_at,
    num_of_item
FROM `bigquery-public-data`.`thelook_ecommerce`.`orders`