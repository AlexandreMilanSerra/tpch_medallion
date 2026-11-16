select
    *,
    {{ lineitem_reject_reason() }} as reject_reason,
    current_timestamp()            as _rejected_at
from {{ ref('brz_lineitem') }}
where {{ lineitem_reject_reason() }} is not null