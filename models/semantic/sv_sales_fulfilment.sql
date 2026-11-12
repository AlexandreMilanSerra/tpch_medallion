{{ config(materialized='semantic_view') }}

tables (
    customers as {{ ref('dim_customer') }}
      primary key (customer_id)
      with synonyms = ('clients', 'buyers')
      comment = 'Customers with their nation, region and market segment',
    suppliers as {{ ref('dim_supplier') }}
      primary key (supplier_id)
      with synonyms = ('vendors')
      comment = 'Suppliers with their nation and region',
    parts as {{ ref('dim_part') }}
      primary key (part_id)
      with synonyms = ('products')
      comment = 'Parts that are sold',
    dates as {{ ref('dim_date') }}
      primary key (date_day)
      comment = 'Calendar days from 1992 to 1998',
    order_lines as {{ ref('fct_order_lines') }}
      primary key (order_line_id)
      with synonyms = ('sales', 'sales lines')
      comment = 'One row per order line, with revenue, discount, margin and delivery data'
)

relationships (
    lines_to_customers as order_lines (customer_id) references customers (customer_id),
    lines_to_suppliers as order_lines (supplier_id) references suppliers (supplier_id),
    lines_to_parts     as order_lines (part_id)     references parts (part_id),
    lines_to_dates     as order_lines (order_date)  references dates (date_day)
)

dimensions (
    customers.customer_name    as customers.customer_name,
    customers.market_segment   as customers.market_segment
      with synonyms = ('segment', 'customer segment'),
    customers.customer_region  as customers.region_name
      with synonyms = ('customer area'),
    customers.customer_nation  as customers.nation_name
      with synonyms = ('customer country'),
    suppliers.supplier_name    as suppliers.supplier_name,
    suppliers.supplier_region  as suppliers.region_name,
    suppliers.supplier_nation  as suppliers.nation_name
      with synonyms = ('supplier country'),
    parts.part_name            as parts.part_name,
    parts.brand                as parts.brand,
    parts.manufacturer         as parts.manufacturer,
    parts.part_type            as parts.part_type,
    dates.order_day            as dates.date_day,
    dates.order_month          as dates.year_month
      with synonyms = ('month'),
    dates.order_year           as dates.year
      with synonyms = ('year'),
    order_lines.order_status   as order_lines.order_status,
    order_lines.order_priority as order_lines.order_priority,
    order_lines.ship_mode      as order_lines.ship_mode,
    order_lines.return_status  as order_lines.return_status
)

metrics (
    order_lines.total_revenue as sum(order_lines.net_revenue)
      with synonyms = ('revenue', 'sales', 'net sales')
      comment = 'Extended price after discount',
    order_lines.total_discount as sum(order_lines.discount_amount)
      with synonyms = ('discounts')
      comment = 'Money given away in discounts',
    order_lines.total_gross_margin as sum(order_lines.gross_margin)
      with synonyms = ('margin', 'profit')
      comment = 'Net revenue minus supply cost. A proxy, not accounting margin',
    order_lines.order_line_count as count(order_lines.order_line_id)
      with synonyms = ('number of lines'),
    order_lines.order_count as count(distinct order_lines.order_id)
      with synonyms = ('number of orders'),
    order_lines.late_line_count as sum(iff(order_lines.is_late_delivery, 1, 0))
      with synonyms = ('late deliveries'),
    order_lines.late_delivery_rate as avg(iff(order_lines.is_late_delivery, 1, 0))
      with synonyms = ('late rate', 'percentage late')
      comment = 'Share of order lines received after the committed date',
    order_lines.average_discount_rate as avg(order_lines.discount_rate)
      with synonyms = ('average discount')
)