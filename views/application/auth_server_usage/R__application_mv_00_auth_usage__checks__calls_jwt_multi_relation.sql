CREATE SCHEMA IF NOT EXISTS sub_views;

GRANT USAGE ON SCHEMA sub_views TO GROUP readonly_group;

DROP MATERIALIZED VIEW IF EXISTS sub_views.mv_00_auth_usage__checks__calls_jwt_multi_relation CASCADE;

CREATE MATERIALIZED VIEW sub_views.mv_00_auth_usage__checks__calls_jwt_multi_relation AUTO REFRESH YES as
select
  gta.correlation_id,
  (case when count( gta.jwt_id ) > 1 then 1 else 0 end ) as calls_associated_to_more_than_one_token,
  -- Bucket time by minutes and remove the millisecond factor from the epoch.
  -- Get the time of the most recent call in the group
  ((max(erasa.timestamp) / ( 60 * 1000 )) * 60) as epoch_of_the_second_when_the_minute_slot_is_started
-- If multiple token have the same correlation_id or multiple calls have the same correlation_id ...
from 
  jwt.generated_token_audit gta 
  join application.end_request_auth_server_audit erasa on erasa.correlation_id = gta.correlation_id 
-- ... this group by group multiple records
group by
  gta.correlation_id
;
