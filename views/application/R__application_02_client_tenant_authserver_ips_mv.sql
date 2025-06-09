CREATE SCHEMA IF NOT EXISTS views;

GRANT USAGE ON SCHEMA views TO GROUP readonly_group;

DROP MATERIALIZED VIEW IF EXISTS views.mv_client_tenant_authserver_ips;

CREATE MATERIALIZED VIEW views.mv_client_tenant_authserver_ips AUTO REFRESH YES AS 
select  main.tenant_name, main.client_name, main.ips, latest_ts.latest_ts, oldest_ts.oldest_ts from (select t."name" as tenant_name , gta.client_id as client_id, c."name" as client_name, bra.requester_ip_address as ips 
from application.begin_request_audit bra
inner join jwt.generated_token_audit gta on bra.correlation_id = gta.correlation_id
left join domains.client c on c.id = gta.client_id
left join domains.client_purpose cp  on cp.client_id = c.id
left join domains.purpose p on p.id = cp.purpose_id 
left join domains.tenant t on t.id = p.consumer_id
where bra.service = 'authorization-server'
group by t."name" , gta.client_id, c."name" , bra.requester_ip_address) main
left join
(select gta.client_id, bra.requester_ip_address as ips, max(bra.timestamp) as latest_ts from application.begin_request_audit bra
inner join jwt.generated_token_audit gta on bra.correlation_id = gta.correlation_id
where bra.service = 'authorization-server'
group by gta.client_id, bra.requester_ip_address) latest_ts
on main.client_id = latest_ts.client_id and main.ips = latest_ts.ips
left join
(select gta.client_id, bra.requester_ip_address as ips, min(bra.timestamp) as oldest_ts from application.begin_request_audit bra
inner join jwt.generated_token_audit gta on bra.correlation_id = gta.correlation_id
where bra.service = 'authorization-server'
group by gta.client_id, bra.requester_ip_address) oldest_ts
on main.client_id = oldest_ts.client_id and main.ips = oldest_ts.ips