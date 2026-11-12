select
    ps_partkey                   as part_id,
    ps_suppkey                   as supplier_id,
    ps_availqty                  as available_quantity,
    ps_supplycost::number(12,2)  as supply_cost
from {{ ref('brz_partsupp') }}