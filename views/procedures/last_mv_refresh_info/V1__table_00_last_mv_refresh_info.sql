CREATE SCHEMA IF NOT EXISTS views;

GRANT USAGE ON SCHEMA views TO GROUP readonly_group;
GRANT USAGE ON SCHEMA views TO ${NAMESPACE}_quicksight_user;


CREATE TABLE IF NOT EXISTS views.last_mv_refresh_info (
  database_name VARCHAR(250),
  schema_name VARCHAR(250),
  mv_name VARCHAR(250),
  refresh_type VARCHAR(20),
  start_time timestamp,
  end_time timestamp,
  duration bigint
);

GRANT SELECT ON TABLE views.last_mv_refresh_info TO ${NAMESPACE}_quicksight_user;
