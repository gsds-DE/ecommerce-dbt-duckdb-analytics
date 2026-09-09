
  
  create view "dev"."main"."stg_customers__dbt_tmp" as (
    with source as (
    select * from "dev"."main"."raw_customers"
),

renamed as (
    select
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix as zip_code,
        lower(customer_city) as city,
        upper(customer_state) as state
    from source
)

select * from renamed
  );
