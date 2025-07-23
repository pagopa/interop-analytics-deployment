CREATE SCHEMA IF NOT EXISTS sub_views;

GRANT USAGE ON SCHEMA sub_views TO GROUP readonly_group;

DROP MATERIALIZED VIEW IF EXISTS sub_views.mv_00_auth_usage__checks__calls_jwt_relation CASCADE;

CREATE MATERIALIZED VIEW sub_views.mv_00_auth_usage__checks__calls_jwt_relation AUTO REFRESH YES as
select 
  1 as token_issued,
  ( case when gta.jwt_id is null then 1 else 0 end ) as token_issued_without_correlation_id,
  0 as token_related_to_calls, 
  ((gta.issued_at / ( 60 * 1000 )) * 60) as epoch_of_the_second_when_the_minute_slot_is_started
from 
  jwt.generated_token_audit gta 
union all 
select 
  0 as token_issued,
  0 as token_issued_without_correlation_id,
  1 as token_related_to_calls, 
  ((gta.issued_at / ( 60 * 1000 )) * 60) as epoch_of_the_second_when_the_minute_slot_is_started
from 
  jwt.generated_token_audit gta 
  join application.end_request_auth_server_audit erasa on erasa.correlation_id = gta.correlation_id 
;
