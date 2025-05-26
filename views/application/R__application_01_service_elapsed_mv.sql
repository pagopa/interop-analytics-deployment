CREATE SCHEMA IF NOT EXISTS views;

GRANT USAGE ON SCHEMA views TO GROUP readonly_group;

DROP MATERIALIZED VIEW IF EXISTS views.mv_service_endpoint_method_ms_elapsed;

CREATE MATERIALIZED VIEW views.mv_service_endpoint_method_ms_elapsed AS 
select EXTRACT(year from bra.timestamp_tz) as year,EXTRACT(month from bra.timestamp_tz) as month, EXTRACT(day from bra.timestamp_tz) as day,  bra.service, bra.endpoint, bra.http_method, AVG(era."timestamp" - bra."timestamp") as ms_avg_elapsed  from interop_dev.application.begin_request_audit bra left join
interop_dev.application.end_request_audit era on bra.span_id = era.span_id
group by EXTRACT(year from bra.timestamp_tz), EXTRACT(month from bra.timestamp_tz), EXTRACT(day from bra.timestamp_tz), bra.service, bra.endpoint, bra.http_method;