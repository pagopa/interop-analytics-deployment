CREATE SCHEMA IF NOT EXISTS views;

GRANT USAGE ON SCHEMA views TO GROUP readonly_group;
GRANT USAGE ON SCHEMA views TO interop_analytics_quicksight_user;

DROP MATERIALIZED VIEW IF EXISTS views.mv_01_auth_usage__data__last_ok_calls CASCADE;

CREATE MATERIALIZED VIEW views.mv_01_auth_usage__data__last_ok_calls AUTO REFRESH YES as
  select 
    consumer_name,
    client_name,
    producer_name,
    eservice_name,
    sum( calls_quantity ) as calls_quantity,
    sum( total_execution_time ) as total_execution_time,
    date_add('minute', -1 * 5, date_trunc( 'minute', getdate() ) ) as from_ts,
    date_trunc( 'minute', getdate() ) as to_ts,
    5 as period_length_minutes
  from 
    views_test.mv_00_auth_usage__data__ok_calls
  where 
    minute_slot between date_add('minute', -1 * 5, date_trunc( 'minute', getdate() ) )  
                    and date_trunc( 'minute', getdate() )
  group by 
    consumer_name,
    client_name,
    producer_name,
    eservice_name
UNION ALL 
  select 
    consumer_name,
    client_name,
    producer_name,
    eservice_name,
    sum( calls_quantity ) as calls_quantity,
    sum( total_execution_time ) as total_execution_time,
    date_add('minute', -1 * 10, date_trunc( 'minute', getdate() ) ) as from_ts,
    date_trunc( 'minute', getdate() ) as to_ts,
    10 as period_length_minutes
  from 
    views_test.mv_00_auth_usage__data__ok_calls
  where 
    minute_slot between date_add('minute', -1 * 10, date_trunc( 'minute', getdate() ) )  
                    and date_trunc( 'minute', getdate() )
  group by 
    consumer_name,
    client_name,
    producer_name,
    eservice_name
UNION ALL 
  select 
    consumer_name,
    client_name,
    producer_name,
    eservice_name,
    sum( calls_quantity ) as calls_quantity,
    sum( total_execution_time ) as total_execution_time,
    date_add('minute', -1 * 15, date_trunc( 'minute', getdate() ) ) as from_ts,
    date_trunc( 'minute', getdate() ) as to_ts,
    15 as period_length_minutes
  from 
    views_test.mv_00_auth_usage__data__ok_calls
  where 
    minute_slot between date_add('minute', -1 * 15, date_trunc( 'minute', getdate() ) )  
                    and date_trunc( 'minute', getdate() )
  group by 
    consumer_name,
    client_name,
    producer_name,
    eservice_name
;

GRANT SELECT ON TABLE views.mv_01_auth_usage__data__last_ok_calls TO interop_analytics_quicksight_user;

