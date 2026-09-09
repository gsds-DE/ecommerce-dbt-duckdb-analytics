
  
  create view "dev"."main"."fct_orders__dbt_tmp" as (
    with orders as (
    select * from "dev"."main"."stg_orders"
),

customers as (
    select * from "dev"."main"."stg_customers"
),

payments as (
    select * from "dev"."main"."int_payments_pivoted"
),

final as (
    select
        -- Keys
        o.order_id,
        o.customer_id,
        c.customer_unique_id,

        -- Customer Attributes
        c.city as customer_city,
        c.state as customer_state,

        -- Order Lifecycle Attributes
        o.order_status,
        o.purchased_at,
        o.approved_at,
        o.shipped_at,
        o.delivered_at,
        o.estimated_delivery_at,

        -- Calculated Delivery Metrics (in days)
        date_diff('day', o.purchased_at, o.delivered_at) as actual_delivery_days,
        date_diff('day', o.delivered_at, o.estimated_delivery_at) as delivery_delay_vs_estimated_days,

        -- Payment Breakdown (from Intermediate macro pivot)
        coalesce(p.credit_card_amount, 0) as credit_card_amount,
        coalesce(p.boleto_amount, 0) as boleto_amount,
        coalesce(p.voucher_amount, 0) as voucher_amount,
        coalesce(p.debit_card_amount, 0) as debit_card_amount,
        coalesce(p.total_payment_amount, 0) as total_payment_amount

    from orders o
    left join customers c on o.customer_id = c.customer_id
    left join payments p on o.order_id = p.order_id
)

select * from final
  );
