select
    s.supplier_id,
    s.supplier_name,
    s.account_balance,
    g.nation_name,
    g.region_name
from {{ ref('stg_supplier') }} s
left join {{ ref('stg_geography') }} g
  on s.nation_id = g.nation_id