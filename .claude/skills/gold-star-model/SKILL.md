---
name: gold-star-model
description: Add or change a Gold-layer dimension or fact in the TPC-H medallion star schema (dim_*, fct_*), with grain, conformed keys, measures and relationship tests. Use when the user wants a new dimension, a new measure on fct_order_lines, a new fact table, or to answer a new business question from Gold.
---

# Gold star schema models

Gold is a star schema for a named consumer (sales and supply-chain managers).
Fact grain today: one row per order line (`fct_order_lines`).

## Rules

- Read only from Silver (`ref('stg_...')`). Never from Bronze or `source()`.
- **Dimensions** (`dim_<entity>.sql`): one row per entity, keyed by `<entity>_id`.
  Denormalise small hierarchies in (nation and region are folded into
  `dim_customer` / `dim_supplier` via `stg_geography`); do not create snowflaked
  dimensions. Use `left join` to lookups so no entity is dropped.
- **Calendar**: `dim_date` comes from the `date_dimension(start, end)` macro.
  Extend the range there rather than writing a new spine.
- **Facts** (`fct_<process>.sql`): group columns as `-- keys`, `-- dates`,
  `-- descriptive attributes`, `-- measures`, plus any domain block such as
  `-- delivery performance`. Only additive or row-level measures; ratios belong
  in the semantic view as metrics (e.g. `late_delivery_rate = avg(iff(...))`).
- Round money to 2 decimals at the point it is derived.
- Use `inner join` only where the relationship is mandatory (line → order);
  `left join` otherwise (line → partsupp cost).
- State the grain before writing SQL. If a change would alter the grain, stop and
  confirm with the user — it breaks every metric in `sv_sales_fulfilment`.

## YAML (`models/gold/_gold.yml`)

- `description` with the grain.
- PK: `[unique, not_null]`; composite PK: `unique_combination` (see
  `tests/generic/unique_combination.sql`).
- Every FK on a fact: `not_null` + `relationships` to its dimension.
- Describe every measure (what it means, and caveats such as "margin is a proxy,
  not accounting margin").

Gold inherits `certified: 'true'` meta from `dbt_project.yml`; `apply_tags` writes
it as a Snowflake tag after build.

## After the change

1. `source ../.venv/bin/activate && dbt build --select <model>+` (the `+` rebuilds
   the semantic view and its dependants).
2. If a new column should be queryable by business users, follow the
   `semantic-view-extend` skill.
3. Update the README tables if a model was added.
