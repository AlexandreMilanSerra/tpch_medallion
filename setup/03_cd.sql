-- Run once as ACCOUNTADMIN. Creates the identity used by the deploy workflow (dbt_cd.yml).
-- Generate the key pair outside the repo (see README) and paste ONLY the public key below.
USE ROLE ACCOUNTADMIN;

CREATE USER IF NOT EXISTS DBT_CD_USER
  TYPE = SERVICE
  DEFAULT_ROLE = DBT_ROLE
  DEFAULT_WAREHOUSE = DBT_WH
  RSA_PUBLIC_KEY = '<YOUR PUBLIC KEY>'
GRANT ROLE DBT_ROLE TO USER DBT_CD_USER;
