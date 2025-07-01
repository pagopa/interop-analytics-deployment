CREATE SCHEMA IF NOT EXISTS views;

GRANT USAGE ON SCHEMA views TO GROUP readonly_group;
GRANT USAGE ON SCHEMA views TO interop_analytics_quicksight_user;

DROP MATERIALIZED VIEW IF EXISTS views.mv_02_not_used_subscribed_eservice__final CASCADE;

CREATE MATERIALIZED VIEW views.mv_02_not_used_subscribed_eservice__final AS 
select
  consumer_name,
  sum( case when how_many_required_jwt > 0 then 1 else 0 end ) as used_eservices,
  count( * ) as subscribed_eservices,
  round(
      100
    *
      (
          sum( case when how_many_required_jwt > 0 then 1 else 0 end ) 
        / 
          cast( count( * ) as decimal )
      )
    ,
    2 -- keep two decimal digit
  )
   as used_eservices_percent
from
  sub_views.mv_01_not_used_subscribed_eservice__usage_count
group by
  consumer_name
;

COMMENT ON VIEW views.mv_02_not_used_subscribed_eservice__final
is 'For each consumer show the number of subscribed eservices; \n the number of distinct eservices with, at least, one detached token;\n the ration as percentage.\n N.B.: tenant self invocations are included'
;
