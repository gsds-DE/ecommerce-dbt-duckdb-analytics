
  
  create view "dev"."main"."int_payments_pivoted__dbt_tmp" as (
    with payments as (
    select * from "dev"."main"."stg_payments"
),

pivoted as (
    select
        order_id,
        
    
        sum(case when payment_type = 'credit_card' then payment_amount else 0 end) as credit_card_amount,
        sum(case when payment_type = 'boleto' then payment_amount else 0 end) as boleto_amount,
        sum(case when payment_type = 'voucher' then payment_amount else 0 end) as voucher_amount,
        sum(case when payment_type = 'debit_card' then payment_amount else 0 end) as debit_card_amount
,
        sum(payment_amount) as total_payment_amount
    from payments
    group by 1
)

select * from pivoted
  );
