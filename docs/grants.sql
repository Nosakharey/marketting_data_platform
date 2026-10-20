-- Unity Catalog grants for the production service principal and analysts.
-- Grants for the production service principal (sp-dbt-production) and an analyst.
-- prod_godwin is the production catalog name; change it if yours differs.

-- 1. Service principal: can use and write to the production catalog
GRANT USE CATALOG ON CATALOG prod_godwin TO `2c66d2e0-97ed-48ef-8608-abc35ad645aa`;
GRANT CREATE SCHEMA ON CATALOG prod_godwin TO `2c66d2e0-97ed-48ef-8608-abc35ad645aa`;
GRANT USE SCHEMA, CREATE TABLE, CREATE VIEW, MODIFY, SELECT
  ON CATALOG prod_godwin TO `2c66d2e0-97ed-48ef-8608-abc35ad645aa`;

-- 2. Service principal: read-only access to the raw bronze data
GRANT USE CATALOG ON CATALOG bronze_dev TO `2c66d2e0-97ed-48ef-8608-abc35ad645aa`;
GRANT USE SCHEMA, SELECT ON SCHEMA bronze_dev.facebook_ads TO `2c66d2e0-97ed-48ef-8608-abc35ad645aa`;
GRANT USE SCHEMA, SELECT ON SCHEMA bronze_dev.snapchat_ads TO `2c66d2e0-97ed-48ef-8608-abc35ad645aa`;

-- 3. Analyst: read-only access to the production marts
GRANT USE CATALOG ON CATALOG prod_godwin TO `godwinnosa500@gmail.com`;
GRANT USE SCHEMA, SELECT ON CATALOG prod_godwin TO `godwinnosa500@gmail.com`;
