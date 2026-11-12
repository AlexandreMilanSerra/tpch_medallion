{% macro create_governance_tags() %}
  {% if execute %}
    {% set tags = ['LAYER', 'DOMAIN', 'OWNER', 'CERTIFIED', 'PII'] %}
    {% do run_query('create schema if not exists ' ~ target.database ~ '.GOVERNANCE') %}
    {% for t in tags %}
      {% do run_query('create tag if not exists ' ~ target.database ~ '.GOVERNANCE.' ~ t) %}
    {% endfor %}
  {% endif %}
{% endmacro %}