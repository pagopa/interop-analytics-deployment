CREATE SCHEMA IF NOT EXISTS views;

GRANT USAGE ON SCHEMA views TO GROUP readonly_group;
GRANT USAGE ON SCHEMA views TO interop_analytics_quicksight_user;

DROP MATERIALIZED VIEW IF EXISTS views.mv_01_eservice_without_token__usage_count CASCADE;

CREATE MATERIALIZED VIEW views.mv_02_eservice_without_token__final AS
select
  producer_name, 
  count( eservice_id) as exposed_eservice__count,
  sum( case when number_of_usage = 0 then 1 else 0 end ) as eservice_not_used_by_others__count,
  round(
      100 
    *
      sum( case when number_of_usage = 0 then 1 else 0 end )
    /
      cast( count( eservice_id) as decimal )
    ,
    2
  )
   as eservice_not_used_by_others__percent
from
  sub_views.mv_01_eservice_without_token__usage_count
group by
  producer_name
;

COMMENT ON VIEW views.mv_02_eservice_without_token__final 
is 'This view show how many unused eservice each tenant has. \n Traffic generated from producer is exluded. \n Only deleted eservice are excluded. '
;

