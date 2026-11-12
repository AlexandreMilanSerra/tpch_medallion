{% macro apply_tags() %}
  {% if execute and model.resource_type == 'model' and config.get('materialized') == 'table' %}
    {% set meta = config.get('meta', {}) %}
    {% set tag_path = target.database ~ '.GOVERNANCE.' %}
    {% set existing = adapter.get_columns_in_relation(this) | map(attribute='name') | map('upper') | list %}

    {# Table-level tags, taken from the meta settings of the layer #}
    {% for key in ['layer', 'domain', 'owner', 'certified'] %}
      {% if meta.get(key) is not none %}
        {% do run_query("alter table " ~ this ~ " set tag " ~ tag_path ~ key ~ " = '" ~ meta.get(key) ~ "'") %}
      {% endif %}
    {% endfor %}

    {# Column-level PII tags, only for columns that exist in the table #}
    {% for col_name, col in model.columns.items() %}
      {% if col.meta.get('pii') %}
        {% if (col_name | upper) in existing %}
          {% do run_query("alter table " ~ this ~ " modify column " ~ col_name ~ " set tag " ~ tag_path ~ "pii = 'true'") %}
        {% else %}
          {% do log("WARNING: PII column " ~ col_name ~ " is not in " ~ this ~ ", skipped", info=True) %}
        {% endif %}
      {% endif %}
    {% endfor %}
  {% endif %}
{% endmacro %}