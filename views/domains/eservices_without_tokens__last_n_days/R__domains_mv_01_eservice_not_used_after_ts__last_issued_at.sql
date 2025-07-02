CREATE SCHEMA IF NOT EXISTS views;

GRANT USAGE ON SCHEMA views TO GROUP readonly_group;
GRANT USAGE ON SCHEMA views TO interop_analytics_quicksight_user;

DROP MATERIALIZED VIEW IF EXISTS views.mv_01_eservice_not_used_after_ts__last_issued_at CASCADE;

CREATE MATERIALIZED VIEW views.mv_01_eservice_not_used_after_ts__last_issued_at AS 
select
  producer_name,
  eservice_id,
  min(eservice_name) as eservice_name,
  max(issued_at) as last_issued_at,
  timestamp 'epoch' + ( max(issued_at) / 1000 ) * interval '1 second' as last_issued_at_ts
from
  sub_views.mv_00_eservice_not_used_after_ts__raw_data
group by
  producer_name,
  eservice_id  
;

GRANT SELECT ON TABLE views.mv_01_eservice_not_used_after_ts__last_issued_at TO interop_analytics_quicksight_user;

COMMENT ON VIEW views.mv_01_eservice_not_used_after_ts__last_issued_at 
is 'This view show how many eservice for each tenant are unused from a timestamp since now. \n Traffic generated from producer is exluded. \n Only deleted eservice are excluded. '
;
