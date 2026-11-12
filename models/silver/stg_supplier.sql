select
    s_suppkey                as supplier_id,
    trim(s_name)             as supplier_name,
    trim(s_address)          as address,
    s_nationkey              as nation_id,
    trim(s_phone)            as phone,
    s_acctbal::number(12,2)  as account_balance
from {{ ref('brz_supplier') }}