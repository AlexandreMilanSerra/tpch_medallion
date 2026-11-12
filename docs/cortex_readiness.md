# Cortex readiness

## Status
- Semantic view `TPCH_DEMO.SEMANTIC.SV_SALES_FULFILMENT` is deployed from dbt
  (package Snowflake-Labs/dbt_semantic_view) and appears in the lineage graph.
- Validated: `analyses/validation_set.sql` answers 10 business questions two ways
  (hand-written SQL on Gold vs SEMANTIC_VIEW queries). All 10 match.
- Not run: the natural-language agent. Cortex and agent features are disabled on
  Snowflake free trial accounts.

## What is ready
- Semantic view with 5 tables, 4 relationships, 17 dimensions, 8 metrics and
  business synonyms.
- A reference answer for each of the 10 golden questions.

## To enable in production
1. Enable AI features on the account (not available on free trials).
2. Cross-region inference if the account region lacks the models
   (this account is in Azure Switzerland North). Data-residency decision:
   requests are processed transiently in another region. Needs client approval.
3. Create an agent in the SEMANTIC schema and add the semantic view as a
   Cortex Analyst tool.
4. Grant the agent's role SELECT on the semantic view and the Cortex roles.
5. Run the golden questions through the agent and compare its SQL and results
   with the reference answers. Repeat on every change to the semantic view.