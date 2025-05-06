CREATE SCHEMA IF NOT EXISTS views;

CREATE TABLE views.test_table (
    id INT PRIMARY KEY,
    foo TEXT
);

DROP MATERIALIZED VIEW IF EXISTS views.mv_1;

CREATE MATERIALIZED VIEW views.mv_1 AS SELECT 
    id, 
    foo, 
    CURRENT_TIMESTAMP AS timestamp 
FROM views.test_table;