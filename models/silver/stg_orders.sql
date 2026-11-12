select
    o_orderkey                                   as order_id,
    o_custkey                                    as customer_id,
    case o_orderstatus
        when 'O' then 'Open'
        when 'F' then 'Fulfilled'
        when 'P' then 'Partially fulfilled'
        else 'Unknown'
    end                                          as order_status,
    o_totalprice::number(12,2)                   as total_price,
    o_orderdate::date                            as order_date,
    split_part(o_orderpriority, '-', 1)::int     as order_priority_code,
    initcap(split_part(o_orderpriority, '-', 2)) as order_priority,
    trim(o_clerk)                                as clerk
from {{ ref('brz_orders') }}