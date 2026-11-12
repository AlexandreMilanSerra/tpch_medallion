select
    n.n_nationkey            as nation_id,
    trim(n.n_name)           as nation_name,
    r.r_regionkey            as region_id,
    trim(r.r_name)           as region_name
from {{ ref('brz_nation') }} n
join {{ ref('brz_region') }} r
  on n.n_regionkey = r.r_regionkey