{% macro lineitem_reject_reason() %}
    case
        when l_discount < 0 or l_discount > {{ var('max_discount', 0.10) }} then 'discount out of range'
        when l_receiptdate < l_shipdate then 'receipt before ship'
        when l_quantity <= 0 then 'non-positive quantity'
    end
{% endmacro %}