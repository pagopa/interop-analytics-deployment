CREATE SCHEMA IF NOT EXISTS sub_views;

GRANT USAGE ON SCHEMA sub_views TO GROUP readonly_group;

DROP MATERIALIZED VIEW sub_views.mv_01_client_without_token__usage_count CASCADE;

-- number_of_usage is the number of detached JWT.
CREATE MATERIALIZED VIEW sub_views.mv_01_client_without_token__usage_count AS
select
  consumer_name, 
  client_id,
  sum( usage_weight) as number_of_usage
from
  sub_views.mv_00_client_without_token__raw_data
group by
  consumer_name, 
  client_id
;
