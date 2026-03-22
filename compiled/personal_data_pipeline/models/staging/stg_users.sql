

SELECT
    user_id,
    TRIM(first_name)                                 AS first_name,
    TRIM(last_name)                                  AS last_name,
    LOWER(TRIM(email))                               AS email,
    age,
    LOWER(TRIM(gender))                              AS gender,
    TRIM(state)                                      AS state,
    TRIM(city)                                       AS city,
    TRIM(country)                                    AS country,
    LOWER(TRIM(traffic_source))                      AS traffic_source,
    latitude,
    longitude,
    TIMESTAMP(created_at)                            AS created_at,
    DATE(created_at)                                 AS registration_date,
    DATE_TRUNC(DATE(created_at), MONTH)              AS registration_month,
    EXTRACT(YEAR FROM created_at)                    AS registration_year
FROM `data-491008`.`bronze_dev`.`bronze_users`
WHERE user_id IS NOT NULL