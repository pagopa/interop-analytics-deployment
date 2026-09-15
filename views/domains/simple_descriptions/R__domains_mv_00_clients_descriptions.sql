CREATE SCHEMA IF NOT EXISTS views;

GRANT USAGE ON SCHEMA views TO GROUP readonly_group;
GRANT USAGE ON SCHEMA views TO ${NAMESPACE}_quicksight_user;

DROP MATERIALIZED VIEW IF EXISTS views.mv_00_clients_descriptions CASCADE;

CREATE MATERIALIZED VIEW views.mv_00_clients_descriptions AUTO REFRESH NO AS 
select 
  trim(t.id) as "organization_id", 
  trim(t.kind) as "organization_kind",
  trim(t."name") as "organization_name",
  trim(c.id) as "client_id",
  trim(c.kind) as "client_kind",
  trim(c."name") as "client_name",
  trim(c.description) as "client_description"
from 
  domains.tenant t
  join domains.client c on c.consumer_id = t.id
;

COMMENT ON VIEW 
  views.mv_00_clients_descriptions 
IS 'Client name, organization name and client description of each client'
;

GRANT SELECT ON TABLE views.mv_00_clients_descriptions TO ${NAMESPACE}_quicksight_user;
