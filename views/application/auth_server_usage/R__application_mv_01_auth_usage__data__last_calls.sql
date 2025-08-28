CREATE SCHEMA IF NOT EXISTS views;

GRANT USAGE ON SCHEMA views TO GROUP readonly_group;
GRANT USAGE ON SCHEMA views TO ${NAMESPACE}_quicksight_user;

DROP MATERIALIZED VIEW IF EXISTS views.mv_01_auth_usage__data__last_calls CASCADE;

-- Repeat the same query with three time different time period 
--  Last 5 entire minutes. At 14:05:06 this interval is [ 14:00:00, 14:05:00 [
--  Last 15 entire minutes. At 14:05:06 this interval is [ 13:50:00, 14:05:00 [
--  Last 30 entire minutes. At 14:05:06 this interval is [ 13:35:00, 14:05:00 [
CREATE MATERIALIZED VIEW views.mv_01_auth_usage__data__last_calls as
  select 
    consumer_name,
    client_name,
    sum( calls_quantity ) as calls_quantity,
    sum( total_execution_time ) as total_execution_time,
    sum( quantity_2xx ) as quantity_2xx,
    sum( total_2xx_execution_time ) as total_2xx_execution_time,
    sum( quantity_4xx ) as quantity_4xx,
    sum( total_4xx_execution_time ) as total_4xx_execution_time,
    sum( quantity_5xx ) as quantity_5xx,
    date_add('minute', -1 * 5, date_trunc( 'minute', getdate() ) ) as from_ts,
    date_trunc( 'minute', getdate() ) as to_ts,
    5 as period_length_minutes
  from 
    views.mv_00_auth_usage__data__calls
  where 
    minute_slot between date_add('minute', -1 * 5, date_trunc( 'minute', getdate() ) )
                    and date_trunc( 'minute', getdate() )
  group by 
    consumer_name,
    client_name
UNION ALL 
  select 
    consumer_name,
    client_name,
    sum( calls_quantity ) as calls_quantity,
    sum( total_execution_time ) as total_execution_time,
    sum( quantity_2xx ) as quantity_2xx,
    sum( total_2xx_execution_time ) as total_2xx_execution_time,
    sum( quantity_4xx ) as quantity_4xx,
    sum( total_4xx_execution_time ) as total_4xx_execution_time,
    sum( quantity_5xx ) as quantity_5xx,
    date_add('minute', -1 * 15, date_trunc( 'minute', getdate() ) ) as from_ts,
    date_trunc( 'minute', getdate() ) as to_ts,
    15 as period_length_minutes
  from 
    views.mv_00_auth_usage__data__calls
  where 
    minute_slot between date_add('minute', -1 * 15, date_trunc( 'minute', getdate() ) )
                    and date_trunc( 'minute', getdate() )
  group by 
    consumer_name,
    client_name
UNION ALL 
  select 
    consumer_name,
    client_name,
    sum( calls_quantity ) as calls_quantity,
    sum( total_execution_time ) as total_execution_time,
    sum( quantity_2xx ) as quantity_2xx,
    sum( total_2xx_execution_time ) as total_2xx_execution_time,
    sum( quantity_4xx ) as quantity_4xx,
    sum( total_4xx_execution_time ) as total_4xx_execution_time,
    sum( quantity_5xx ) as quantity_5xx,
    date_add('minute', -1 * 30, date_trunc( 'minute', getdate() ) ) as from_ts,
    date_trunc( 'minute', getdate() ) as to_ts,
    30 as period_length_minutes
  from 
    views.mv_00_auth_usage__data__calls
  where 
    minute_slot between date_add('minute', -1 * 30, date_trunc( 'minute', getdate() ) )
                    and date_trunc( 'minute', getdate() )
  group by 
    consumer_name,
    client_name
;

GRANT SELECT ON TABLE views.mv_01_auth_usage__data__last_calls TO ${NAMESPACE}_quicksight_user;

