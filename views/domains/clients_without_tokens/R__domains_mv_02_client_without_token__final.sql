CREATE SCHEMA IF NOT EXISTS views;

GRANT USAGE ON SCHEMA views TO GROUP readonly_group;
GRANT USAGE ON SCHEMA views TO interop_analytics_quicksight_user;

DROP MATERIALIZED VIEW IF EXISTS views.mv_02_client_without_token__final CASCADE;

CREATE MATERIALIZED VIEW views.mv_02_client_without_token__final AS
select
  consumer_name, 
  count( client_id ) as client__count,
  sum( case when number_of_usage = 0 then 1 else 0 end ) as client_not_used__count,
  round(
      100 
    *
      sum( case when number_of_usage = 0 then 1 else 0 end )
    /
      cast( count( client_id) as decimal )
    ,
    2
  )
   as client_not_used__percent
from
  sub_views.mv_01_client_without_token__usage_count
group by
  consumer_name
;

GRANT SELECT ON TABLE views.mv_02_client_without_token__final TO interop_analytics_quicksight_user;

comment on view views.mv_02_client_without_token__final 
is 'This view show, for each consumer tenant: how many active client are registered; \n how many of them have requested at least one token; the ratio in percentage format. '

