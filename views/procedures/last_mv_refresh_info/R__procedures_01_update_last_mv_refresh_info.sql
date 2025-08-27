CREATE SCHEMA IF NOT EXISTS sub_views;

GRANT USAGE ON SCHEMA sub_views TO GROUP readonly_group;


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

