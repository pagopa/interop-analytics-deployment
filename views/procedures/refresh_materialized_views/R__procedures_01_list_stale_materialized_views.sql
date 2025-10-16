CREATE SCHEMA IF NOT EXISTS sub_views;

GRANT USAGE ON SCHEMA sub_views TO GROUP readonly_group;

-- - This procedure need to return a result set to a lambda that use RedShift-data-API. We prefer
--   to use a temporary table and do not use cursors. This procedure must be called with
--   ExecuteBatchStatement API call with two statement:
--      CALL sub_views.list_stale_materialized_views( 'views, sub_views' );
--      SELECT mv_schema, mv_name, mv_level FROM list_need_refresh_views_results ORDER BY mv_level
-- - This procedure has SECURITY DEFINER flag because only the
--   materialized views owner or superuser can see information
--   in the SVV_MV_INFO catalog table.
--   Neither users with SYSLOG ACCESS UNRESTRICTED, it is not a SYS table.

-- Save result in temporary table list_need_refresh_views_results
-- Do not use concurrently in the same session
CREATE OR REPLACE PROCEDURE sub_views.list_stale_materialized_views(schema_list IN VARCHAR(MAX) )
AS $$
BEGIN
  
  drop table if exists list_need_refresh_views_results;
  
  create temporary table list_need_refresh_views_results AS 
  (
    with recursive
      recursive_stale_materialized_views( mv_schema, mv_name, incremental_refresh_not_supported, dist ) as (
        select
          trim(schema_name) as mv_schema,
          trim(name) as mv_name,
          (state <> 1 ) as incremental_refresh_not_supported,
          0 as dist
        from
          SVV_MV_INFO
        where
            is_stale = 't'
          and
            -- do not handle cross database references
            database_name = current_database() 
          -- - I need to ask refresh also to "auto-refresh-materialized-views" to ensure refresh "now"
          --   and not "when redshift want"; just in case an higher level materialized view depend on it
          --   and need very fresh data.
          -- AND autorefresh = 'f'  -- Intentionally commented out and kept for documentation purpose
          and
            -- Split string to arrays and use them as second parameter of an "in" operator is too complex
            -- We use some string matching
            -- example ',views,sub_views,' with no spaces
            quote_ident(',' + regexp_replace( schema_list, '\\s', '')  + ',')
              like
              ('%,' + schema_name + ',%')
        union all
        select
          trim(dep.schema_name) as mv_schema,
          trim(dep."name") as mv_name, 
          b.incremental_refresh_not_supported,
          b.dist + 1 as dist
        from
          SVV_MV_DEPENDENCY dep
          join recursive_stale_materialized_views b
              on trim(dep.dependent_schema_name) = b.mv_schema 
                  and trim(dep.dependent_name) = b.mv_name
        where
          -- We support no more than one hundred dependency level between materialized views.
          -- It must be enough. 
          dist < 100 
      ),
      refresh_history as (
        SELECT
          trim(schema_name) as mv_schema,
          trim(mv_name) as mv_name,
          start_time as refresh_start_time,
          end_time as refresh_end_time,
          ROW_NUMBER() over ( partition by database_name, schema_name, mv_name order by start_time desc ) as nr
        FROM
          SYS_MV_REFRESH_HISTORY
        where
          database_name = current_database()
      ),
      last_refresh as (
        SELECT
          *
        FROM
          refresh_history
        where
          nr = 1
      ),
      views_to_refresh as (
        select
          mv_schema,
          mv_name,
          try_cast(REGEXP_REPLACE( trim(mv_name), 'mv_([0-9][0-9]).*', '$1') as integer) as mv_level,
          bool_or( incremental_refresh_not_supported ) as incremental_refresh_not_supported,
          max(dist) as dist
        from recursive_stale_materialized_views
        group by
          mv_schema,
          mv_name,
          mv_level
      )
    select
      v.mv_schema,
      v.mv_name,
      v.mv_level,
      v.incremental_refresh_not_supported,
      r.refresh_start_time as last_refresh_start_time,
      r.refresh_end_time as last_refresh_end_time,
      -- extract give null output for null input
      extract(epoch from r.refresh_start_time) as last_refresh_start_time_epoch,
      extract(epoch from r.refresh_end_time) as last_refresh_end_time_epoch,
      v.dist
    from
      views_to_refresh v
      left join last_refresh r on r.mv_schema  = v.mv_schema and r.mv_name  = v.mv_name
      where
        v.mv_level is not null
  );
  
  GRANT SELECT ON list_need_refresh_views_results to ${NAMESPACE}_mv_refresher_user;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER;

GRANT EXECUTE ON procedure sub_views.list_stale_materialized_views(schema_list IN VARCHAR(MAX) ) 
      TO ${NAMESPACE}_mv_refresher_user;
