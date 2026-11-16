---
name: snowflake-dbt-ci-setup
description: Set up or troubleshoot the GitHub Actions dbt CI for this Snowflake project — key-pair service user, isolated CI role and database, GitHub secrets and the protected main branch. Use when CI fails to authenticate, when recreating the CI user or rotating its key, or when replicating this CI setup in another Snowflake/dbt repo.
---

# Snowflake + dbt CI

Pieces involved:

- `setup/01_ci.sql` — `DBT_CI_ROLE`, `TPCH_CI` database (owned by the CI role),
  a `TYPE = SERVICE` user with an RSA public key. CI never touches `TPCH_DEMO`.
- `ci/profiles.yml` — target `ci`, reads `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`,
  `SNOWFLAKE_PRIVATE_KEY_PATH` from env.
- `.github/workflows/dbt_ci.yml` — writes the key from a secret, runs
  `dbt deps`, `dbt build`, `dbt docs generate`, uploads docs as an artifact.

## Generate a key pair

Run in a scratch directory, never in the repo:

```bash
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out snowflake_key.p8 -nocrypt
openssl rsa -in snowflake_key.p8 -pubout -out snowflake_key.pub
```

Paste the body of `snowflake_key.pub` (without the BEGIN/END lines, one line) into
`RSA_PUBLIC_KEY` in `setup/01_ci.sql` — or for rotation:
`ALTER USER <CI_USER> SET RSA_PUBLIC_KEY_2 = '...'`, switch the secret, then
`UNSET RSA_PUBLIC_KEY`.

Never commit the `.p8` file or paste real keys into tracked files. Leave the
placeholders in `setup/01_ci.sql` as they are in git.

## GitHub secrets

Ask the user before running any `gh secret set` command (it writes to their repo):

```bash
gh secret set SNOWFLAKE_ACCOUNT        # e.g. orgname-accountname
gh secret set SNOWFLAKE_USER           # the service user name
gh secret set SNOWFLAKE_PRIVATE_KEY < snowflake_key.p8
```

Branch protection: a ruleset on `main` requiring a PR and the `dbt-build` status
check (the job id in the workflow).

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `JWT token is invalid` | Public key not set on the user, wrong account identifier, or key file lost its newlines (the workflow uses `printf '%s\n'` to keep them) |
| `Role 'DBT_CI_ROLE' is not granted` | Missing `GRANT ROLE DBT_CI_ROLE TO USER` |
| `Database 'SNOWFLAKE_SAMPLE_DATA' does not exist` | Missing `IMPORTED PRIVILEGES` grant for the CI role |
| Tag / schema errors in `on-run-start` | CI role must own `TPCH_CI` so `create_governance_tags` can create `GOVERNANCE` and its tags |
| Semantic view fails to create | `dbt deps` step missing or package version drift; check `package-lock.yml` |

Use `gh run list --workflow dbt_ci.yml` and `gh run view <id> --log-failed` to read
failures.

## Keep versions in sync

dbt versions are pinned in both `README.md` and the workflow
(`dbt-core==1.12.6 dbt-snowflake==1.12.5`). Change both together.
