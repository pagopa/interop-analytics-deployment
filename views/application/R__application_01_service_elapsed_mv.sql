CREATE SCHEMA IF NOT EXISTS views;

GRANT USAGE ON SCHEMA views TO GROUP readonly_group;

DROP MATERIALIZED VIEW IF EXISTS views.mv_service_endpoint_method_ms_elapsed;

CREATE MATERIALIZED VIEW views.mv_service_endpoint_method_ms_elapsed AUTO REFRESH YES AS 
select 
DATE_PART(year, (CONVERT_TIMEZONE('Europe/Rome',  TIMESTAMP 'epoch' + (bra.timestamp / 1000) * INTERVAL '1 second'))) as year, 
DATE_PART(month, (CONVERT_TIMEZONE('Europe/Rome',  TIMESTAMP 'epoch' + (bra.timestamp / 1000) * INTERVAL '1 second'))) as month, 
DATE_PART(day, (CONVERT_TIMEZONE('Europe/Rome',  TIMESTAMP 'epoch' + (bra.timestamp / 1000) * INTERVAL '1 second'))) as day, 
bra.service, bra.endpoint, bra.http_method, era."timestamp" - bra."timestamp" as ms_elapsed 
from interop_dev.application.begin_request_audit bra inner join interop_dev.application.end_request_audit era on bra.span_id = era.span_id