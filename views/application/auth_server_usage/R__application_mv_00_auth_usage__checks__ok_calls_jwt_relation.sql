CREATE SCHEMA IF NOT EXISTS sub_views;

GRANT USAGE ON SCHEMA sub_views TO GROUP readonly_group;

DROP MATERIALIZED VIEW IF EXISTS sub_views.mv_00_auth_usage__checks__ok_calls_jwt_relation CASCADE;

CREATE MATERIALIZED VIEW sub_views.mv_00_auth_usage__checks__ok_calls_jwt_relation AUTO REFRESH YES as
select 
  ( case when erasa.http_response_status = '200' then 1 else 0 end ) as success_call_with_token,
  0 as success_call,
  ((erasa.timestamp / ( 60 * 1000 )) * 60) as epoch_of_the_second_when_the_minute_slot_is_started
from 
  jwt.generated_token_audit gta 
  join application.end_request_auth_server_audit erasa on erasa.correlation_id = gta.correlation_id 
union all 
select 
  0 as success_call_with_token,
  ( case when erasa.http_response_status = '200' then 1 else 0 end ) as success_call,
  ((erasa.timestamp / ( 60 * 1000 )) * 60) as epoch_of_the_second_when_the_minute_slot_is_started
from 
  application.end_request_auth_server_audit erasa 
;
