---
name: medallion-add-source
description: Add a new source table to the TPC-H medallion dbt project and carry it through Bronze (raw copy) and Silver (cleaned staging) with YAML docs, tests and PII tags. Use when the user wants to ingest a new table, add a brz_/stg_ model, or onboard a new source into the pipeline.
---

# Add a source through Bronze and Silver

Each layer has one job. Keep business logic out of Bronze and keep joins for Gold
(the one exception is a small conforming join such as `stg_geography`).

## 1. Register the source

Add the table to `models/bronze/sources.yml` under the right source (`tpch` for
`SNOWFLAKE_SAMPLE_DATA.TPCH_SF1`). For a new database/schema, add a new source block
with `description`, `database`, `schema`.

## 2. Bronze model: `models/bronze/brz_<table>.sql`

Exactly one line. Never hand-write Bronze SQL:

```sql
{{ bronze_copy('<source_name>', '<table>') }}
```

`bronze_copy` adds `_loaded_at` and `_source`. Schema, materialisation, tags and
`meta` come from `dbt_project.yml` folder config, so do not add a `config()` block.

## 3. Silver model: `models/silver/stg_<entity>.sql`

Follow the existing style (see `stg_lineitem.sql`, `stg_orders.sql`):

- Rename source prefixes to readable snake_case: `l_orderkey` → `order_id`,
  `*_key` → `*_id`.
- Cast explicitly: money `::number(12,2)`, rates `::number(5,4)`, dates `::date`.
- `trim()` fixed-width text columns (TPC-H `char` columns are padded).
- Decode code columns with a `case ... else 'Unknown' end` into readable labels.
- Derived line metrics go in an outer `select` over a `base` CTE.
- Read only from `ref('brz_...')`, never from `source()`.
- Lower-case SQL keywords, aligned `as` aliases.

## 4. Document and test in `models/silver/_silver.yml`

For every new model add:

- `description` that states the grain ("One row per ...").
- Primary key: `data_tests: [unique, not_null]`.
- Composite key (no single unique column): model-level test

  ```yaml
  data_tests:
    - unique_combination:
        arguments:
          combination_of_columns: [part_id, supplier_id]
  ```
- Foreign keys: `relationships` with `arguments: {to: ref('...'), field: ...}`.
- Decoded labels: `accepted_values` listing every label including `'Unknown'`.
- Personal data (names of people, addresses, phones, emails):
  `meta: {pii: true}`. The `apply_tags` post-hook turns this into a Snowflake
  `GOVERNANCE.PII` tag; it warns and skips if the column name does not exist, so
  the YAML column name must match the SQL alias exactly.

Use the dbt ≥1.10 syntax: `data_tests:` and test params under `arguments:`.

## 5. Build and verify

From the project root (dbt lives in the parent folder's venv):

```bash
source ../.venv/bin/activate
dbt build --select +stg_<entity>
```

Check the output for passing tests and no `WARNING: PII column ... skipped` lines.
Report row counts if the user wants a sanity check (`dbt show --select stg_<entity>`).
