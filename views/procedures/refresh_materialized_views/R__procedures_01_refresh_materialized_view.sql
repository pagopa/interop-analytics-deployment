CREATE SCHEMA IF NOT EXISTS sub_views;

GRANT USAGE ON SCHEMA sub_views TO GROUP readonly_group;

-- - This procedure has SECURITY DEFINER flag because
--   "Only the owner of a materialized view can perform a REFRESH MATERIALIZED VIEW"
--   See https://docs.aws.amazon.com/redshift/latest/dg/materialized-view-refresh-sql-command.html#mv_REFRESH_MARTERIALIZED_VIEW_usage
-- - We can't change view owner to keep flyway migration working.
-- - For security reason both flyway and refresher user can't be "superusers"

CREATE OR REPLACE PROCEDURE sub_views.refresh_materialized_view(schema_name VARCHAR, view_name VARCHAR)
AS $$
DECLARE
  view_full_name VARCHAR(MAX);
  sql_command VARCHAR(MAX);
BEGIN
  -- Build the REFRESH command string safely using quote_ident to prevent SQL injection
  view_full_name := quote_ident(schema_name) || '.' || quote_ident(view_name);
  sql_command := 'REFRESH MATERIALIZED VIEW ' || view_full_name || ';';
  
  -- Provide an informational message about what is being refreshed
  RAISE INFO 'Attempting to run command: %', sql_command;
  
  -- Execute the dynamically created command
  EXECUTE sql_command;
  
  RAISE INFO 'Successfully refreshed materialized view: %', view_full_name;
  
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER;

GRANT EXECUTE ON procedure sub_views.refresh_materialized_view(schema_name VARCHAR, view_name VARCHAR) 
      TO ${NAMESPACE}_mv_refresher_user
;

