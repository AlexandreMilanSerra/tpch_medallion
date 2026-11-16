---
name: semantic-view-validate
description: Run the golden-question validation set that compares SEMANTIC_VIEW() answers against hand-written SQL on the Gold tables, and diagnose any mismatch. Use after changing Gold models or the semantic view, before a PR, or when the user asks whether the semantic layer / Cortex readiness still holds.
---

# Validate the semantic view

`analyses/validation_set.sql` answers each business question two ways and returns
one row per question with `rows_in_semantic_view` and `rows_with_difference`.

## Run it

The file is plain SQL with fully qualified names (`TPCH_DEMO.GOLD...`,
`TPCH_DEMO.SEMANTIC...`), so it only validates the **demo** database. Make sure the
demo target has been built first (`dbt build`).

```bash
source ../.venv/bin/activate
dbt show --inline "$(cat analyses/validation_set.sql)" --limit 50
```

If `dbt show` rejects the trailing `ORDER BY`, wrap it:
`select * from ( ... ) order by 1`.

## Pass criteria

Every question must have `rows_in_semantic_view > 0` **and**
`rows_with_difference = 0`. Report the result as a short table (question, rows,
diff, PASS/FAIL).

## Diagnosing a failure

Narrow it down layer by layer — that is the point of the Medallion design:

1. Run that question's `qN_sv` and `qN_ref` CTEs on their own and diff them.
2. `rows_in_semantic_view = 0`: the dimension filter value is wrong (labels are
   decoded in Silver, e.g. `'Urgent'` not `'1-URGENT'`), or a relationship in the
   view drops rows.
3. Small numeric differences: mismatched `ROUND` precision between the two routes.
4. Different rows in a top-N: ties in the ranking metric.
5. Large differences: the metric definition in `sv_sales_fulfilment.sql` does not
   match the reference SQL, or a join type differs (the view joins via declared
   relationships; `ref_base` uses inner joins to all dimensions).
6. If both routes agree with each other but look wrong, check Gold against Silver,
   then Silver against Bronze.

Do not "fix" a failure by editing the reference SQL to match the view unless the
user confirms the reference was wrong.
