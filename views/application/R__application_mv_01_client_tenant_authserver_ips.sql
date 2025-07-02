CREATE SCHEMA IF NOT EXISTS views;

GRANT USAGE ON SCHEMA views TO GROUP readonly_group;
GRANT USAGE ON SCHEMA views TO interop_analytics_quicksight_user;

DROP MATERIALIZED VIEW IF EXISTS views.mv_01_client_tenant_authserver_ips CASCADE;

CREATE MATERIALIZED VIEW views.mv_01_client_tenant_authserver_ips AS 
select  main.tenant_name, main.client_name, main.ips, latest_ts.latest_ts, oldest_ts.oldest_ts from sub_views.mv_00_client_tenant_authserver_ips__main main
inner join sub_views.mv_00_client_tenant_authserver_ips__latest_ts latest_ts
on main.client_id = latest_ts.client_id and main.ips = latest_ts.ips
inner join sub_views.mv_00_client_tenant_authserver_ips__oldest_ts oldest_ts
on main.client_id = oldest_ts.client_id and main.ips = oldest_ts.ips;

GRANT SELECT ON TABLE views.mv_01_client_tenant_authserver_ips TO interop_analytics_quicksight_user;