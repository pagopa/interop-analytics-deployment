CREATE SCHEMA IF NOT EXISTS views;

CREATE TABLE views.test_table (
    id INT PRIMARY KEY,
    foo TEXT
);

SELECT COUNT(*) FROM STV_MV_INFO WHERE (db_name = 'interop_dev' AND schema = 'views' AND name = 'mv_1');

-- Can't create a materialized view based on the result of the preceding query. The only way is to create a stored procedure using plpgsql.
CREATE MATERIALIZED VIEW views.mv_1 AS SELECT * FROM views.test_table;