CREATE SCHEMA IF NOT EXISTS sub_views;

GRANT USAGE ON SCHEMA sub_views TO GROUP readonly_group;

DROP MATERIALIZED VIEW IF EXISTS sub_views.mv_00_not_used_subscribed_eservice__raw_data CASCADE;

-- We need to know which eservice was authorized and which wasn't.
-- But we can't use lateral (left or right) join; due to a limitation 
--  of redshift materilized views incremental refresh.
-- As a workaround we generate a record for each active eservice and 
--  one for each JWT was authorizing that eservice; each record has required_jwt field that 
--  can assume 0 or 1 value, 0 if the record is not related to any JWT. The result is
--  that eservices with sum(required_jwt) == 0 are never used.
CREATE MATERIALIZED VIEW sub_views.mv_00_not_used_subscribed_eservice__raw_data AUTO REFRESH YES AS
select
  t.name as consumer_name,
  p.eservice_id,
  0 as required_jwt
from 
  domains.purpose p
  join domains.purpose_version pv on pv.purpose_id = p.id
  join domains.tenant t on t.id = p.consumer_id
where 
  pv.state in ('Active')
union all
select
  t.name as consumer_name,
  p.eservice_id,
  1 as required_jwt
from 
  domains.purpose p
  join domains.purpose_version pv on pv.purpose_id = p.id
  join domains.tenant t on t.id = p.consumer_id
  join jwt.generated_token_audit jwt 
       on jwt.purpose_version_id = pv.id
where 
    pv.state in ('Active')
;
