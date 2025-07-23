CREATE SCHEMA IF NOT EXISTS sub_views;

GRANT USAGE ON SCHEMA sub_views TO GROUP readonly_group;

DROP MATERIALIZED VIEW IF EXISTS sub_views.mv_00_auth_usage__checks__calls_jwt_multi_relation CASCADE;

CREATE MATERIALIZED VIEW sub_views.mv_00_auth_usage__checks__calls_jwt_multi_relation AUTO REFRESH YES as
select
  erasa.span_id,
  (case when count( gta.jwt_id ) > 1 then 1 else 0 end ) as calls_associated_to_more_than_one_token,
  ((max(erasa.timestamp) / ( 60 * 1000 )) * 60) as epoch_of_the_second_when_the_minute_slot_is_started
from 
  jwt.generated_token_audit gta 
  join application.end_request_auth_server_audit erasa on erasa.correlation_id = gta.correlation_id 
group by
  erasa.span_id
;
