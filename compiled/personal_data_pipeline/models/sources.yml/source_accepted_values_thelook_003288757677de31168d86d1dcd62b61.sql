
    
    

with all_values as (

    select
        status as value_field,
        count(*) as n_records

    from `bigquery-public-data`.`thelook_ecommerce`.`orders`
    group by status

)

select *
from all_values
where value_field not in (
    'Shipped','Complete','Processing','Cancelled','Returned'
)


