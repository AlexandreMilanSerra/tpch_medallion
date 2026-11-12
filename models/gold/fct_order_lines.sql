select
    -- keys
    l.order_line_id,
    l.order_id,
    l.line_number,
    o.customer_id,
    l.part_id,
    l.supplier_id,

    -- dates
    o.order_date,
    l.ship_date,
    l.commit_date,
    l.receipt_date,

    -- descriptive attributes
    o.order_status,
    o.order_priority,
    l.line_status,
    l.return_status,
    l.ship_mode,

    -- measures
    l.quantity,
    l.extended_price,
    l.discount_rate,
    round(l.extended_price * l.discount_rate, 2)               as discount_amount,
    l.net_revenue,
    l.net_revenue_with_tax,
    round(ps.supply_cost * l.quantity, 2)                      as supply_cost_total,
    round(l.net_revenue - ps.supply_cost * l.quantity, 2)      as gross_margin,

    -- delivery performance
    l.days_ship_to_receipt,
    l.is_late_delivery,
    l.days_late
from {{ ref('stg_lineitem') }} l
join {{ ref('stg_orders') }} o
  on l.order_id = o.order_id
left join {{ ref('stg_partsupp') }} ps
  on l.part_id = ps.part_id
 and l.supplier_id = ps.supplier_id