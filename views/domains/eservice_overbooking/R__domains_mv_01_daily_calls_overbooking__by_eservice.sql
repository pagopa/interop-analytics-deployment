CREATE SCHEMA IF NOT EXISTS views;

GRANT USAGE ON SCHEMA views TO GROUP readonly_group;
GRANT USAGE ON SCHEMA views TO interop_analytics_quicksight_user;

DROP MATERIALIZED VIEW IF EXISTS views.mv_01_daily_calls_overbooking__by_eservice CASCADE;

CREATE MATERIALIZED VIEW views.mv_01_daily_calls_overbooking__by_eservice AS 
select
  producer_name,
  eservice_id,
  min(eservice_name) as eservice_name,
  min(eservice_declared_daily_calls_total) as eservice_declared_daily_calls_total,
  sum(consumer_daily_calls) as consumers_declared_daily_calls_sum,
  round(
      100
    *
      sum(consumer_daily_calls) 
    / 
      min(eservice_declared_daily_calls_total)
    ,
    2 -- keep two decimal digit
  ) 
   as total_booked_percentage
from 
  sub_views.mv_00_daily_calls_overbooking__raw_data
group by
  producer_name,
  eservice_id
;

COMMENT ON VIEW views.mv_01_daily_calls_overbooking__by_eservice
is 'This view show, for each eservice, the ratio between: the sum of daily call "promised" to the consumers\n and the total daily calls declared by the producer.'
;
