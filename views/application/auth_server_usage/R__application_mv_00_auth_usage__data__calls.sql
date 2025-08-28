CREATE SCHEMA IF NOT EXISTS views;

GRANT USAGE ON SCHEMA views TO GROUP readonly_group;
GRANT USAGE ON SCHEMA views TO ${NAMESPACE}_quicksight_user;

DROP MATERIALIZED VIEW IF EXISTS views.mv_00_auth_usage__data__calls CASCADE;

CREATE MATERIALIZED VIEW views.mv_00_auth_usage__data__calls AUTO REFRESH YES as
select 
  -- Compute the start time and use that for time bucketing.
  -- Bucket time by minutes and remove the millisecond factor from the epoch.
  (( (erasa.timestamp - erasa.execution_time_ms) / ( 60 * 1000 )) * 60) as epoch_of_the_second_when_the_minute_slot_is_started,
  -- Start of bucket as timestamp with timezone 
  timestamptz 'epoch' + (( (erasa.timestamp - erasa.execution_time_ms) / ( 60 * 1000 )) * 60) * interval '1 second' as minute_slot,
  t_c.name as consumer_name,
  c.name as client_name,
  -- Total number of calls for this group
  count( erasa.span_id ) as calls_quantity,
  -- Total execution time for all calls for this group
  sum( erasa.execution_time_ms ) as total_execution_time,
  sum( case when erasa.http_response_status like '2%' then 1 else 0 end ) as quantity_2xx,
  sum( case when erasa.http_response_status like '2%' then erasa.execution_time_ms else 0 end ) as total_2xx_execution_time,
  sum( case when erasa.http_response_status like '4%' then 1 else 0 end ) as quantity_4xx,
  sum( case when erasa.http_response_status like '4%' then erasa.execution_time_ms else 0 end ) as total_4xx_execution_time,
  sum( case when erasa.http_response_status like '5%' then 1 else 0 end ) as quantity_5xx
from 
  application.end_request_auth_server_audit erasa 
  join domains.client c on c.id = erasa.client_id
  join domains.tenant t_c on t_c.id = c.consumer_id
group by
  epoch_of_the_second_when_the_minute_slot_is_started,
  consumer_name,
  client_name
;

GRANT SELECT ON TABLE views.mv_00_auth_usage__data__calls TO ${NAMESPACE}_quicksight_user;

