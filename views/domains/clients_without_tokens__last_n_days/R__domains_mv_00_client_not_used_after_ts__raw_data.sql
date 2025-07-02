CREATE SCHEMA IF NOT EXISTS sub_views;

GRANT USAGE ON SCHEMA sub_views TO GROUP readonly_group;

DROP MATERIALIZED VIEW IF EXISTS sub_views.mv_00_client_not_used_after_ts__raw_data CASCADE;

-- We need to know which client have generated token and which haven't.
-- But we can't use lateral (left or right) join; due to a limitation 
--  of redshift materilized views incremental refresh.
-- As a workaround we generate a record for each active client and 
--  one for each JWT of that clients; each record has issued_at field that 
--  can assume -1 value for records not associated to any JWT. As a result clients 
--  that have never detached any JWT have max(issued_at) == -1
CREATE MATERIALIZED VIEW sub_views.mv_00_client_not_used_after_ts__raw_data AUTO REFRESH YES AS 
select 
  t.name as consumer_name,
  c.id as client_id,
  c."name" as client_name,
  -1 as issued_at
from
  domains.client c
  join domains.tenant t on t.id = c.consumer_id
where
    not coalesce( c.deleted, false )
  and
    not coalesce( t.deleted, false )
union all
select 
  t.name as consumer_name,
  c.id as client_id,
  c."name" as client_name,
  jwt.issued_at as issued_at
from
  domains.client c 
  join domains.tenant t on t.id = c.consumer_id
  join jwt.generated_token_audit jwt
       on jwt.client_id = c.id
where
    not coalesce( c.deleted, false )
  and
    not coalesce( t.deleted, false )
;
