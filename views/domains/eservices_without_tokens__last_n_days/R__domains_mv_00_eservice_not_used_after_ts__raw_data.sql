CREATE SCHEMA IF NOT EXISTS sub_views;

GRANT USAGE ON SCHEMA sub_views TO GROUP readonly_group;

DROP MATERIALIZED VIEW IF EXISTS sub_views.mv_00_eservice_not_used_after_ts__raw_data CASCADE;

-- We need to know which eservices are authorized by generated token and which aren't.
--  __N.B.__: we are not interested in "self-traffic" that is token asked by the same 
--            tenant exposing the eservice.
-- We can't use lateral (left or right) join; due to a limitation of redshift 
--  materilized views incremental refresh.
-- As a workaround we generate a record for each active eservice and 
--  one for each JWT authorizing that eservice; each record has issued_at field that 
--  assume -1 value for records not related to a JWT. So we can assume that eservices 
--  that have max(issued_at) == -1 are never called by tenants different from the owner 
--  because there is no effective authorized calls.
CREATE MATERIALIZED VIEW sub_views.mv_00_eservice_not_used_after_ts__raw_data AUTO REFRESH NO AS 
select 
  t.name as producer_name,
  e.id as eservice_id,
  e."name" as eservice_name,
  -1 as issued_at
from
  domains.eservice e
  join domains.tenant t on t.id = e.producer_id
where
    not coalesce( e.deleted, false )
  and
    not coalesce( t.deleted, false )
union all
select 
  t.name as producer_name,
  e.id as eservice_id,
  e."name" as eservice_name,
  jwt.issued_at as issued_at
from
  domains.eservice e
  join domains.tenant t on t.id = e.producer_id
  join jwt.generated_token_audit jwt
       on jwt.eservice_id = e.id
  join domains.agreement a on a.id = jwt.agreement_id
where
    not coalesce( e.deleted, false )
  and
    not coalesce( t.deleted, false )
  and
    a.consumer_id <> a.producer_id -- exclude traffic from producer tenant itself
;
