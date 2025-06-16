CREATE OR REPLACE PROCEDURE views.refresh_views()
LANGUAGE plpgsql
AS $$
DECLARE
    schema_exists INT;
    result RECORD;
    statement TEXT;
BEGIN
    -- Check if schema exists
    SELECT 1 INTO schema_exists FROM svv_all_schemas WHERE schema_name = 'views';

    IF schema_exists IS NULL THEN
        RAISE EXCEPTION 'Schema views does not exist.';
    END IF;

    -- For each materialized view in the schema for which auto-refresh is 'false' and stale is 'true', perform a manual refresh
    FOR result IN
        SELECT 
            schema,
            name
        FROM 
            STV_MV_INFO
        WHERE 
            (schema = 'views' OR schema = 'sub_views')
            AND is_stale = 't' 
            AND autorefresh = 'f'
        ORDER BY
            name ASC
    LOOP
        statement := 'REFRESH MATERIALIZED VIEW ' || quote_ident(result.schema) || '.' || quote_ident(result.name) || ';';
        RAISE INFO 'Performing: %', statement;
        EXECUTE statement;
    END LOOP;
    RAISE INFO 'Refresh completed.';
END;
$$;
