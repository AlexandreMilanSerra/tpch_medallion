---
name: semantic-view-extend
description: Add dimensions, metrics, synonyms, tables or relationships to the Snowflake semantic view sv_sales_fulfilment (dbt_semantic_view package), and add a matching golden question to the validation set. Use when the user wants a new metric/KPI, a new business term or synonym, or to expose a Gold column to Cortex Analyst / natural-language queries.
---

# Extend the semantic view

File: `models/semantic/sv_sales_fulfilment.sql`, materialised by the
`Snowflake-Labs/dbt_semantic_view` package (`config(materialized='semantic_view')`).
`persist_docs` is off for this folder on purpose — do not turn it on.

## Clause order and syntax

`tables (...)` → `relationships (...)` → `dimensions (...)` → `metrics (...)`.

- **tables**: `alias as {{ ref('...') }} primary key (col) with synonyms = (...) comment = '...'`
- **relationships**: `name as fact (fk) references dim (pk)`
- **dimensions**: `table.business_name as table.physical_column`
  — rename physical columns to business names where it disambiguates
  (`customers.customer_region as customers.region_name`).
- **metrics**: `fact.metric_name as <aggregate>(fact.column)`.
  Ratios are aggregates over row-level flags: `avg(iff(flag, 1, 0))`.
- Commas between entries, none after the last one in a clause.

## Conventions

- Add `with synonyms = (...)` using words the consumer actually says
  ("revenue", "sales", "net sales"). Do not reuse a synonym already used elsewhere
  in the view — ambiguity confuses Cortex Analyst.
- Add a `comment` on any metric whose definition is not obvious, including caveats.
- The column must exist in Gold first. If it does not, use `gold-star-model`.
- If you add a table or relationship, update the counts in
  `docs/cortex_readiness.md` ("5 tables, 4 relationships, 17 dimensions, 8 metrics").

## Add a golden question (required)

Every new metric or dimension gets a question in `analyses/validation_set.sql`:

1. Add any needed columns to `ref_base`.
2. Add `qN_sv` (via `SEMANTIC_VIEW(TPCH_DEMO.SEMANTIC.SV_SALES_FULFILMENT DIMENSIONS ... METRICS ...)`)
   and `qN_ref` (hand-written SQL on `ref_base`). Same column names and the same
   `ROUND` precision in both (2 for money, 6 for rates).
3. Add a `UNION ALL SELECT N, '<question>', ...` row with the two-way `MINUS` diff.
4. For top-N questions, make sure ties cannot reorder rows between routes
   (pick a metric with distinct values or add a tie-breaker in both).

## Deploy and verify

```bash
source ../.venv/bin/activate
dbt build --select sv_sales_fulfilment
```

Then run the `semantic-view-validate` skill. All rows must show
`rows_with_difference = 0` and `rows_in_semantic_view > 0`.
