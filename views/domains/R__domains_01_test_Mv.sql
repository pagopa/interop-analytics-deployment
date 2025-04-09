CREATE SCHEMA IF NOT EXISTS test;

CREATE TABLE test.test_table (
    id INT PRIMARY KEY,
    foo TEXT
);

CREATE MATERIALIZED VIEW test.test_mv_1 AS SELECT * FROM test.test_table;