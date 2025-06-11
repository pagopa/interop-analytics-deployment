CREATE SCHEMA IF NOT EXISTS sub_views;

GRANT USAGE ON SCHEMA sub_views TO GROUP readonly_group;

CREATE MATERIALIZED VIEW sub_views.mv_client_tenant_authserver_ips__main AUTO REFRESH YES as
select t."name" tenant_name , gta.client_id client_id, c."name" client_name  , bra.requester_ip_address ips 
from application.begin_request_audit bra
inner join jwt.generated_token_audit gta on bra.correlation_id = gta.correlation_id
inner join domains.client c on c.id = gta.client_id
inner join domains.client_purpose cp  on cp.client_id = c.id
inner join domains.purpose p on p.id = cp.purpose_id 
inner join domains.tenant t on t.id = p.consumer_id
where bra.service = 'authorization-server'
group by t."name" , gta.client_id, c."name" , bra.requester_ip_address