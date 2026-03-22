
    
    

with all_values as (

    select
        status as value_field,
        count(*) as n_records

    from `data-491008`.`silver_dev`.`stg_orders`
    group by status

)

select *
from all_values
where value_field not in (
    'shipped','complete','processing','cancelled','returned'
)


