CREATE SCHEMA IF NOT EXISTS views;

GRANT USAGE ON SCHEMA views TO GROUP readonly_group;
GRANT USAGE ON SCHEMA views TO ${NAMESPACE}_quicksight_user;

DROP MATERIALIZED VIEW IF EXISTS views.mv_01_client_tenant_authserver_ips CASCADE;

CREATE MATERIALIZED VIEW views.mv_01_client_tenant_authserver_ips AS 
select
  t."name" tenant_name,
  c."name" client_name,
  main.client_id,
  main.ips,
  main.latest_ts,
  main.oldest_ts
from
  sub_views.mv_00_client_tenant_authserver_ips__main main
  inner join domains.client c on c.id = main.client_id
  inner join domains.tenant t on t.id = c.consumer_id
;

GRANT SELECT ON TABLE views.mv_01_client_tenant_authserver_ips TO ${NAMESPACE}_quicksight_user;