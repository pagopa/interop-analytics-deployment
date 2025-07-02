CREATE SCHEMA IF NOT EXISTS views;

GRANT USAGE ON SCHEMA views TO GROUP readonly_group;
GRANT USAGE ON SCHEMA views TO interop_analytics_quicksight_user;

DROP MATERIALIZED VIEW IF EXISTS views.mv_01_daily_calls_overbooking__by_eservice_and_consumer CASCADE;

CREATE MATERIALIZED VIEW views.mv_01_daily_calls_overbooking__by_eservice_and_consumer AS
select
  producer_name,
  eservice_id,
  consumer_name,
  min(eservice_name) as eservice_name,
  min(eservice_declared_daily_calls_total) as eservice_declared_daily_calls_total,
  min(eservice_declared_calls_per_consumer) as eservice_declared_calls_per_consumer,
  sum(consumer_daily_calls) as consumers_declared_daily_calls_sum,
  round(
      100
    *
      sum(consumer_daily_calls) 
    / 
      min(eservice_declared_calls_per_consumer)
    ,
    2 -- keep two decimal digit
  ) 
   as consumer_booked_percentage
from 
  sub_views.mv_00_daily_calls_overbooking__raw_data
group by
  producer_name,
  eservice_id,
  consumer_name
;

GRANT SELECT ON TABLE views.mv_01_daily_calls_overbooking__by_eservice_and_consumer TO interop_analytics_quicksight_user;

COMMENT ON VIEW views.mv_01_daily_calls_overbooking__by_eservice_and_consumer
is 'This view show, for each eservice and consumer, the ratio between: the sum of daily call "promised" for each purpose\n and the total daily calls for each consumer declared by the producer.'
;
