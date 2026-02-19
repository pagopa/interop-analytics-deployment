CREATE SCHEMA IF NOT EXISTS sub_views;

GRANT USAGE ON SCHEMA sub_views TO GROUP readonly_group;

DROP MATERIALIZED VIEW IF EXISTS sub_views.mv_00_client_tenant_authserver_ips__oldest_ts CASCADE;

-- REMOVED: unnecessary after refactoring
