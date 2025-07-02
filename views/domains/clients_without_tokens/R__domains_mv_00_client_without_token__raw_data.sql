CREATE SCHEMA IF NOT EXISTS sub_views;

GRANT USAGE ON SCHEMA sub_views TO GROUP readonly_group;

DROP MATERIALIZED VIEW sub_views.mv_00_client_without_token__raw_data CASCADE;

-- We need to know which client have generated token and which haven't.
-- But we can't use lateral (left or right) join; due to a limitation 
--  of redshift materilized views incremental refresh.
-- As a workaround we generate a record for each active client and 
--  one for each JWT of that clients; each record has usage_weight field that 
--  can assume 0 or 1 value. Making sum of the usage_weight field as a result 
--  we can assume that clients with total usage_weight equals 0 are clients 
--  never used to detach some JWT.
CREATE MATERIALIZED VIEW sub_views.mv_00_client_without_token__raw_data AUTO REFRESH YES AS 
  select 
    t.name as consumer_name,
    c.id as client_id,
    0 as usage_weight
  from
    domains.client c
    join domains.tenant t on c.consumer_id = t.id
  where
      not coalesce( c.deleted, false )
    and
      not coalesce( t.deleted, false )
  union all
  select
    t.name as consumer_name,
    c.id as client_id,
    1 as usage_weight
  from
    domains.client c
    join domains.tenant t on c.consumer_id = t.id
    join jwt.generated_token_audit jwt
         on jwt.client_id = c.id 
  where
      not coalesce( c.deleted, false )
    and
      not coalesce( t.deleted, false )
;
