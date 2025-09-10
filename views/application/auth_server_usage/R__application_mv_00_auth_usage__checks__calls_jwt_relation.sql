CREATE SCHEMA IF NOT EXISTS sub_views;

GRANT USAGE ON SCHEMA sub_views TO GROUP readonly_group;

DROP MATERIALIZED VIEW IF EXISTS sub_views.mv_00_auth_usage__checks__calls_jwt_relation CASCADE;

-- Every token must be related to the call that has asked for that.
-- This view also pin out the tokens that have null correlation_id.
-- To use incremental refresh we can't use outer join. This query count the number of 
-- token in a minute and the number of token related to a call in the same minute.
CREATE MATERIALIZED VIEW sub_views.mv_00_auth_usage__checks__calls_jwt_relation AUTO REFRESH NO as
select 
  1 as token_issued,
  ( case when gta.jwt_id is null then 1 else 0 end ) as token_issued_without_correlation_id,
  0 as token_related_to_calls, 
  -- Bucket time by minutes and remove the millisecond factor from the epoch.
  ((gta.issued_at / ( 60 * 1000 )) * 60) as epoch_of_the_second_when_the_minute_slot_is_started
from 
  jwt.generated_token_audit gta 
union all 
select 
  0 as token_issued,
  0 as token_issued_without_correlation_id,
  1 as token_related_to_calls, 
  -- Bucket time by minutes and remove the millisecond factor from the epoch.
  ((gta.issued_at / ( 60 * 1000 )) * 60) as epoch_of_the_second_when_the_minute_slot_is_started
from 
  jwt.generated_token_audit gta 
  join application.end_request_auth_server_audit erasa on erasa.correlation_id = gta.correlation_id 
;
