CREATE SCHEMA IF NOT EXISTS sub_views;

GRANT USAGE ON SCHEMA sub_views TO GROUP readonly_group;

DROP MATERIALIZED VIEW IF EXISTS sub_views.mv_01_auth_usage__checks__union CASCADE;

CREATE MATERIALIZED VIEW sub_views.mv_01_auth_usage__checks__union AUTO REFRESH YES as
select 
  token_issued,
  token_issued_without_correlation_id,
  token_related_to_calls,
  0 as calls_associated_to_more_than_one_token,
  epoch_of_the_second_when_the_minute_slot_is_started
from
  sub_views.mv_00_auth_usage__checks__calls_jwt_relation
union all
select 
  0 as token_issued,
  0 as token_issued_without_correlation_id,
  0 as token_related_to_calls,
  calls_associated_to_more_than_one_token,
  epoch_of_the_second_when_the_minute_slot_is_started
from
  sub_views.mv_00_auth_usage__checks__calls_jwt_multi_relation
;
