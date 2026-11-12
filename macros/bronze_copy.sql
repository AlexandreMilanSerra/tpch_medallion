{% macro bronze_copy(source_name, table_name) %}
select
    *,
    current_timestamp() as _loaded_at,
    '{{ source(source_name, table_name) }}' as _source
from {{ source(source_name, table_name) }}
{% endmacro %}