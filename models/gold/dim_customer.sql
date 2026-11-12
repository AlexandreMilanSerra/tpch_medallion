select
    c.customer_id,
    c.customer_name,
    c.market_segment,
    c.account_balance,
    g.nation_name,
    g.region_name
from {{ ref('stg_customer') }} c
left join {{ ref('stg_geography') }} g
  on c.nation_id = g.nation_id