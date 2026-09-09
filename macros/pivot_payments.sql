{% macro pivot_payments(payment_types, amount_column='payment_amount') %}
    {% for payment_type in payment_types %}
        sum(case when payment_type = '{{ payment_type }}' then {{ amount_column }} else 0 end) as {{ payment_type }}_amount
        {%- if not loop.last -%},{%- endif -%}
    {% endfor %}
{% endmacro %}