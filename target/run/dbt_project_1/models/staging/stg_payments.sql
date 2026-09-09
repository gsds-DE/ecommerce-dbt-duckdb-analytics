
  
  create view "dev"."main"."stg_payments__dbt_tmp" as (
    with source as (
    select * from "dev"."main"."raw_payments"
),

renamed as (
    select
        order_id,
        payment_sequential,
        payment_type,
        cast(payment_installments as integer) as payment_installments,
        cast(payment_value as double) as payment_amount
    from source
)

select * from renamed
  );
