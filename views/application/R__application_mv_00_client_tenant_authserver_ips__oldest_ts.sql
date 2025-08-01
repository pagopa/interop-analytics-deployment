CREATE SCHEMA IF NOT EXISTS sub_views;

GRANT USAGE ON SCHEMA sub_views TO GROUP readonly_group;

DROP MATERIALIZED VIEW IF EXISTS sub_views.mv_00_client_tenant_authserver_ips__oldest_ts CASCADE;

CREATE MATERIALIZED VIEW sub_views.mv_00_client_tenant_authserver_ips__oldest_ts AUTO REFRESH YES as
select gta.client_id, bra.requester_ip_address ips, min(bra.timestamp) as oldest_ts from application.begin_request_audit bra
inner join jwt.generated_token_audit gta on bra.correlation_id = gta.correlation_id
where bra.service = 'authorization-server'
group by gta.client_id, bra.requester_ip_address