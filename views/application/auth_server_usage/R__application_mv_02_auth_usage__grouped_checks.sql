CREATE SCHEMA IF NOT EXISTS views;

GRANT USAGE ON SCHEMA views TO GROUP readonly_group;
GRANT USAGE ON SCHEMA views TO interop_analytics_quicksight_user;

DROP MATERIALIZED VIEW IF EXISTS views.mv_02_auth_usage__grouped_checks CASCADE;

CREATE MATERIALIZED VIEW views.mv_02_auth_usage__grouped_checks AUTO REFRESH YES as
select
  -- Ogni token è associato a una invocazione
  sum( token_issued ) - sum( token_related_to_calls ) as token_without_related_call, 
  -- In ogni token correlation_id is not null
  sum( token_issued_without_correlation_id ) as token_issued_without_correlation_id, 
  -- Ogni call che risponde 200 ha un token associato
  sum( success_call ) - sum( success_call_with_token ) as success_calls_without_token, 
  -- Ogni invocazione è associata ad al più un token;
  -- controintuitivamente potrebbero esistere chiamate in errore cassociate a token: dovrebbero essere solo delle 500
  sum( calls_associated_to_more_than_one_token ) as calls_associated_to_more_than_one_token,  
  epoch_of_the_second_when_the_minute_slot_is_started,
  timestamp 'epoch' + epoch_of_the_second_when_the_minute_slot_is_started * interval '1 second' as minute_slot
from
  views_test.mv_01_auth_usage__checks__union
group by
  epoch_of_the_second_when_the_minute_slot_is_started
;

GRANT SELECT ON TABLE views.mv_02_auth_usage__grouped_checks TO interop_analytics_quicksight_user;

