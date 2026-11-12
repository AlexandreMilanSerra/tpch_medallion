-- 00_bootstrap.sql
-- One-time Snowflake setup for the TPC-H Medallion project.
-- Run as ACCOUNTADMIN. Safe to re-run (uses IF NOT EXISTS).
-- Replace <your_username> with your Snowflake login name before running.

USE ROLE ACCOUNTADMIN;

-- 1. Compute: smallest warehouse, stops itself after 60 seconds idle
CREATE WAREHOUSE IF NOT EXISTS DBT_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE;

-- 2. Role used by dbt (least privilege: no admin rights)
CREATE ROLE IF NOT EXISTS DBT_ROLE;
GRANT USAGE, OPERATE ON WAREHOUSE DBT_WH TO ROLE DBT_ROLE;

-- 3. Read access to the TPC-H sample data (read-only share)
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE_SAMPLE_DATA TO ROLE DBT_ROLE;

-- 4. Our own database, fully usable by dbt
CREATE DATABASE IF NOT EXISTS TPCH_DEMO;
GRANT ALL ON DATABASE TPCH_DEMO TO ROLE DBT_ROLE;
GRANT ALL ON FUTURE SCHEMAS IN DATABASE TPCH_DEMO TO ROLE DBT_ROLE;
GRANT ALL ON FUTURE TABLES  IN DATABASE TPCH_DEMO TO ROLE DBT_ROLE;
GRANT ALL ON FUTURE VIEWS   IN DATABASE TPCH_DEMO TO ROLE DBT_ROLE;

-- 5. Give the role to the person who runs dbt locally
GRANT ROLE DBT_ROLE TO USER <your_username>;

-- Check (run as DBT_ROLE): should return 1,500,000
-- USE ROLE DBT_ROLE;
-- USE WAREHOUSE DBT_WH;
-- SELECT COUNT(*) FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS;