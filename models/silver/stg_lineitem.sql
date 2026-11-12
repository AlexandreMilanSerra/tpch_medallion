with base as (
    select
        l_orderkey                      as order_id,
        l_linenumber                    as line_number,
        l_partkey                       as part_id,
        l_suppkey                       as supplier_id,
        l_quantity::number(12,2)        as quantity,
        l_extendedprice::number(12,2)   as extended_price,
        l_discount::number(5,4)         as discount_rate,
        l_tax::number(5,4)              as tax_rate,
        case l_returnflag
            when 'R' then 'Returned'
            when 'A' then 'Accepted'
            when 'N' then 'Not yet received'
            else 'Unknown'
        end                             as return_status,
        case l_linestatus
            when 'O' then 'Open'
            when 'F' then 'Fulfilled'
            else 'Unknown'
        end                             as line_status,
        l_shipdate::date                as ship_date,
        l_commitdate::date              as commit_date,
        l_receiptdate::date             as receipt_date,
        trim(l_shipmode)                as ship_mode
    from {{ ref('brz_lineitem') }}
)

select
    order_id::varchar || '-' || line_number::varchar                as order_line_id,
    *,
    round(extended_price * (1 - discount_rate), 2)                  as net_revenue,
    round(extended_price * (1 - discount_rate) * (1 + tax_rate), 2) as net_revenue_with_tax,
    datediff('day', ship_date, receipt_date)                        as days_ship_to_receipt,
    receipt_date > commit_date                                      as is_late_delivery,
    greatest(datediff('day', commit_date, receipt_date), 0)         as days_late
from base