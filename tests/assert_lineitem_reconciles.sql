select src_rows, valid_rows, rejected_rows
from (
    select
        (select count(*) from {{ ref('brz_lineitem') }}) as src_rows,
        (select count(*) from {{ ref('stg_lineitem') }}) as valid_rows,
        (select count(*) from {{ ref('rej_lineitem') }}) as rejected_rows
)
where src_rows != valid_rows + rejected_rows