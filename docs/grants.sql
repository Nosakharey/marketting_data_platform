-- Unity Catalog grants for the production service principal and analysts.
-- Replace <SP_APPLICATION_ID> with the service principal's application (client) id.
-- prod_godwin is the production catalog name; change it if yours differs.

-- 1. Service principal: can use and write to the production catalog
GRANT USE CATALOG ON CATALOG prod_godwin TO `<SP_APPLICATION_ID>`;
GRANT CREATE SCHEMA ON CATALOG prod_godwin TO `<SP_APPLICATION_ID>`;
GRANT USE SCHEMA, CREATE TABLE, CREATE VIEW, MODIFY, SELECT
  ON CATALOG prod_godwin TO `<SP_APPLICATION_ID>`;

-- 2. Service principal: read-only access to the raw bronze data
GRANT USE CATALOG ON CATALOG bronze_dev TO `<SP_APPLICATION_ID>`;
GRANT USE SCHEMA, SELECT ON SCHEMA bronze_dev.facebook_ads TO `<SP_APPLICATION_ID>`;
GRANT USE SCHEMA, SELECT ON SCHEMA bronze_dev.snapchat_ads TO `<SP_APPLICATION_ID>`;

-- 3. Analyst: read-only access to the production marts
GRANT USE CATALOG ON CATALOG prod_godwin TO `godwinnosa500@gmail.com`;
GRANT USE SCHEMA, SELECT ON CATALOG prod_godwin TO `godwinnosa500@gmail.com`;
