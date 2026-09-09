with payments as (
    select * from {{ ref('stg_payments') }}
),

pivoted as (
    select
        order_id,
        {{ pivot_payments(['credit_card', 'boleto', 'voucher', 'debit_card']) }},
        sum(payment_amount) as total_payment_amount
    from payments
    group by 1
)

select * from pivoted