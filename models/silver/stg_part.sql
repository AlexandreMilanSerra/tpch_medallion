select
    p_partkey                    as part_id,
    trim(p_name)                 as part_name,
    trim(p_mfgr)                 as manufacturer,
    trim(p_brand)                as brand,
    trim(p_type)                 as part_type,
    p_size                       as part_size,
    trim(p_container)            as container,
    p_retailprice::number(12,2)  as retail_price
from {{ ref('brz_part') }}