select
    c_custkey                as customer_id,
    trim(c_name)             as customer_name,
    trim(c_address)          as address,
    c_nationkey              as nation_id,
    trim(c_phone)            as phone,
    c_acctbal::number(12,2)  as account_balance,
    trim(c_mktsegment)       as market_segment
from {{ ref('brz_customer') }}
