CREATE SCHEMA IF NOT EXISTS sub_views;

GRANT USAGE ON SCHEMA sub_views TO GROUP readonly_group;

DROP MATERIALIZED VIEW IF EXISTS sub_views.mv_01_not_used_subscribed_eservice__usage_count CASCADE;

-- For each eservice show the number of JWT that provide authorization for that eservice calls.
CREATE MATERIALIZED VIEW sub_views.mv_01_not_used_subscribed_eservice__usage_count AS 
select
  consumer_name,
  eservice_id,
  sum(required_jwt) as how_many_required_jwt
from
  sub_views.mv_00_not_used_subscribed_eservice__raw_data 
group by
  consumer_name,
  eservice_id
;
