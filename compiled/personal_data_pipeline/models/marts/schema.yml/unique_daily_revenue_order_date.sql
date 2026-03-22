
    
    

with dbt_test__target as (

  select order_date as unique_field
  from `data-491008`.`gold_dev`.`daily_revenue`
  where order_date is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


