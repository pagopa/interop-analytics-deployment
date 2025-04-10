CREATE SCHEMA IF NOT EXISTS views;

CREATE TABLE views.test_table (
    id INT PRIMARY KEY,
    foo TEXT
);

CREATE MATERIALIZED VIEW views.mv_1 AS SELECT * FROM views.test_table;