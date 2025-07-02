CREATE SCHEMA IF NOT EXISTS sub_views;

GRANT USAGE ON SCHEMA sub_views TO GROUP readonly_group;

DROP MATERIALIZED VIEW IF EXISTS sub_views.mv_01_eservice_without_token__usage_count CASCADE;

-- number_of_usage is the number of JWT granting access to eservice to "not owner tenants".
CREATE MATERIALIZED VIEW sub_views.mv_01_eservice_without_token__usage_count AS
select
  producer_name, 
  eservice_id,
  sum( usage_weight) as number_of_usage
from
  sub_views.mv_00_eservice_without_token__raw_data
group by
  producer_name, 
  eservice_id
;
