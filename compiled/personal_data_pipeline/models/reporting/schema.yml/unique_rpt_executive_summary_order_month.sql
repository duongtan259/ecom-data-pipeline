
    
    

with dbt_test__target as (

  select order_month as unique_field
  from `data-491008`.`reporting_dev`.`rpt_executive_summary`
  where order_month is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


