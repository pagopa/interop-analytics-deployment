CREATE SCHEMA IF NOT EXISTS views;

GRANT USAGE ON SCHEMA views TO GROUP readonly_group;
GRANT USAGE ON SCHEMA views TO interop_analytics_quicksight_user;

DROP MATERIALIZED VIEW IF EXISTS views.mv_01_avg_first_token_delta_by_eservice__final CASCADE;

CREATE MATERIALIZED VIEW views.mv_01_avg_first_token_delta_by_eservice__final AS 
select
  producer_name,
  eservice_id,
  avg(
    datediff(
      seconds,
      agreement_activation_ts at time zone 'GMT',
      first_jwt_issued_at_tz at time zone 'GMT'
    )
  ) as avg_first_token_delta_time__seconds,
  count(*) as num_of_agreement
from 
  sub_views.mv_00_avg_first_token_delta_by_eservice__first_issued_token
group by
  producer_name,
  eservice_id
;


COMMENT ON VIEW views.mv_01_avg_first_token_delta_by_eservice__final
is 'This view show, for each eservice, the average delta time between agreement accepted time and fist detached JWT issued_at time.\n Self tenant invocation are included.'
;
