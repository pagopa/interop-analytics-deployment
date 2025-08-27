CREATE SCHEMA IF NOT EXISTS sub_views;

GRANT USAGE ON SCHEMA sub_views TO GROUP readonly_group;


CREATE OR REPLACE PROCEDURE sub_views.list_need_refresh_views(schema_list IN VARCHAR(MAX) )
AS $$
BEGIN
  
  drop table if exists list_need_refresh_views_results;
  
  create temporary table list_need_refresh_views_results AS 
  (
    with
        views_to_refresh as (
          select
            trim(schema_name) as mv_schema,
            trim(name) as mv_name,
            cast(REGEXP_REPLACE( name, 'mv_([0-9][0-9]).*', '$1') as integer) as mv_level 
          from 
            SVV_MV_INFO
          where
              is_stale = 't'
            and 
              -- Split string to arrays and use them as second parameter of an in operator is too complex
              -- I use some string matching
              -- example ',views,sub_views' with no spaces
	          quote_ident(',' + regexp_replace( schema_list, '\\s', '')  + ',') 
              like
              ('%,' + schema_name + ',%')
        )
      select
        mv_schema,
        mv_name,
        mv_level
      from
        views_to_refresh
  );
  
  GRANT SELECT ON list_need_refresh_views_results to ${NAMESPACE}_mv_refresher_user;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER;

GRANT EXECUTE ON procedure sub_views.list_need_refresh_views(schema_list IN VARCHAR(MAX) ) 
      TO ${NAMESPACE}_mv_refresher_user;
