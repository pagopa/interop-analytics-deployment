CREATE SCHEMA IF NOT EXISTS views;

GRANT USAGE ON SCHEMA views TO GROUP readonly_group;
GRANT USAGE ON SCHEMA views TO ${NAMESPACE}_quicksight_user;

DROP MATERIALIZED VIEW IF EXISTS views.mv_01_client_not_used_after_ts__last_issued_at CASCADE;

CREATE MATERIALIZED VIEW views.mv_01_client_not_used_after_ts__last_issued_at AS
select
  consumer_name,
  client_id,
  min(client_name) as client_name,
  max(issued_at) as last_issued_at,
  timestamp 'epoch' + ( max(issued_at) / 1000 ) * interval '1 second' as last_issued_at_ts
from
  sub_views.mv_00_client_not_used_after_ts__raw_data
group by
  consumer_name,
  client_id  
;

GRANT SELECT ON TABLE views.mv_01_client_not_used_after_ts__last_issued_at TO ${NAMESPACE}_quicksight_user;

COMMENT ON VIEW views.mv_01_client_not_used_after_ts__last_issued_at 
is 'This view show, for each client, the epoch timestamp of last issued token. \n The last_issued_at field assume value -1 for clients that have never detachd a JWT.'
;
