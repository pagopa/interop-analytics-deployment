CREATE SCHEMA IF NOT EXISTS views;

GRANT USAGE ON SCHEMA views TO GROUP readonly_group;
GRANT USAGE ON SCHEMA views TO interop_analytics_quicksight_user;

DROP MATERIALIZED VIEW IF EXISTS views.mv_02_auth_usage__grouped_checks CASCADE;

CREATE MATERIALIZED VIEW views.mv_02_auth_usage__grouped_checks AUTO REFRESH YES as
select
  -- Every token must be related to a call
  sum( token_issued ) - sum( token_related_to_calls ) as token_without_related_call, 
  -- Every token must have not null correlation_id
  sum( token_issued_without_correlation_id ) as token_issued_without_correlation_id, 
  -- Every call with http status '200' have to be related to a token
  sum( success_call ) - sum( success_call_with_token ) as success_calls_without_token, 
  -- Every call must be associated at no more than one tokens.
  -- Can be weird but a "status 500 call" could be associated to a token.
  sum( calls_associated_to_more_than_one_token ) as calls_associated_to_more_than_one_token,  
  epoch_of_the_second_when_the_minute_slot_is_started,
  timestamptz 'epoch' + epoch_of_the_second_when_the_minute_slot_is_started * interval '1 second' as minute_slot
from
  views_test.mv_01_auth_usage__checks__union
group by
  epoch_of_the_second_when_the_minute_slot_is_started
;

GRANT SELECT ON TABLE views.mv_02_auth_usage__grouped_checks TO interop_analytics_quicksight_user;

