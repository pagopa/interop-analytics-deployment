CREATE SCHEMA IF NOT EXISTS views;

GRANT USAGE ON SCHEMA views TO GROUP readonly_group;
GRANT USAGE ON SCHEMA views TO interop_analytics_quicksight_user;

DROP MATERIALIZED VIEW IF EXISTS views.mv_00_auth_usage__data__ok_calls CASCADE;

CREATE MATERIALIZED VIEW views.mv_00_auth_usage__data__ok_calls AUTO REFRESH YES as
select 
  (( (erasa.timestamp - erasa.execution_time_ms) / ( 60 * 1000 )) * 60) as epoch_of_the_second_when_the_minute_slot_is_started,
  timestamptz 'epoch' + (( (erasa.timestamp - erasa.execution_time_ms) / ( 60 * 1000 )) * 60) * interval '1 second' as minute_slot,
  t_c.name as consumer_name,
  c.name as client_name,
  t_p.name as producer_name,
  e.name as eservice_name,
  count( erasa.span_id ) as calls_quantity,
  sum( erasa.execution_time_ms ) as total_execution_time
from 
  jwt.generated_token_audit gta 
  join application.end_request_auth_server_audit erasa on erasa.correlation_id = gta.correlation_id 
  join domains.client c on c.id = gta.client_id
  join domains.tenant t_c on t_c.id = c.consumer_id
  join domains.eservice e on e.id = gta.eservice_id 
  join domains.tenant t_p on t_p.id = e.producer_id 
where
  erasa.http_response_status = '200'
group by
  epoch_of_the_second_when_the_minute_slot_is_started,
  consumer_name,
  client_name,
  producer_name,
  eservice_name  
;

GRANT SELECT ON TABLE views.mv_00_auth_usage__data__ok_calls TO interop_analytics_quicksight_user;

