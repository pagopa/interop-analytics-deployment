CREATE SCHEMA IF NOT EXISTS sub_views;

GRANT USAGE ON SCHEMA sub_views TO GROUP readonly_group;

-- - This procedure need to persist information for later use by QuickSight user; that user has
--   only select rights. For this reason it use a table to save its result.
--   https://documentation.red-gate.com/fd/repeatable-migrations-273973335.html assert that versioned
--   migrations are executed before repeatable ones: this ensure the table presence.
-- - This procedure has SECURITY DEFINER flag so we are not required to give INSERT and DELETE
--   grants on table views.last_mv_refresh_info to the mv_refresher user.
CREATE OR REPLACE PROCEDURE sub_views.update_last_mv_refresh_info(
  schema_list IN VARCHAR(MAX)
)
AS $$
BEGIN
  -- Remove all lines ...
  delete from views.last_mv_refresh_info;
  
  -- ... and refill in the same transaction.
  insert into views.last_mv_refresh_info
  (
	with 
	  refresh_events as (
	    select 
	      database_name,
	      schema_name,
	      mv_name,
	      refresh_type,
	      status,
	      start_time,
	      end_time,
	      duration,
	      ROW_NUMBER() over ( partition by database_name, schema_name, mv_name order by start_time desc ) as nr
	    from
	      SYS_MV_REFRESH_HISTORY
	    where 
	        database_name = current_database()
	      and
              -- Split string to arrays and use them as second parameter of an in operator is too complex
              -- I use some string matching
              -- example ',views,sub_views' with no spaces
	          quote_ident(',' + regexp_replace( schema_list, '\\s', '')  + ',') 
              like
              ('%,' + schema_name + ',%')
	      and 
	        (
	            status like 'Refresh successfully%'
	          or
	            status like 'Refresh partially updated%'
	          or
	            status like '%already updated%'
	        )
	  )
	select
	  database_name,
	  schema_name,
	  mv_name,
	  refresh_type,
	  start_time,
	  end_time,
      duration
	from
	  refresh_events
	where 
	  nr = 1
  );
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER;


GRANT EXECUTE ON procedure sub_views.update_last_mv_refresh_info( schema_list IN VARCHAR(MAX) ) 
      TO ${NAMESPACE}_mv_refresher_user;
