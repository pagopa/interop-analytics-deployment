CREATE SCHEMA IF NOT EXISTS sub_views;

GRANT USAGE ON SCHEMA sub_views TO GROUP readonly_group;

DROP MATERIALIZED VIEW IF EXISTS sub_views.mv_00_avg_first_token_delta_by_eservice__first_issued_token CASCADE;

CREATE MATERIALIZED VIEW sub_views.mv_00_avg_first_token_delta_by_eservice__first_issued_token AUTO REFRESH YES AS
select
  t.name as producer_name,
  a.eservice_id,
  a.id as agreement_id,
  min( a_s.when ) as agreement_activation_ts,
  min( jwt.issued_at_tz ) as first_jwt_issued_at_tz
from 
  domains.agreement a
  join domains.agreement_stamp a_s on a_s.agreement_id = a.id
  join domains.tenant t on t.id = a.producer_id
  join jwt.generated_token_audit jwt on jwt.agreement_id = a.id
where
    a.state in ('Active', 'Suspended', 'Archived', 'MissingCertifiedAttributes' ) -- Keep every agreement that was "Active" fore some time.
  and
    a_s.kind = 'activation' -- Select the agreement activation timestamp
  and
    not coalesce( a.deleted, false)
  and
    not coalesce( a_s.deleted, false)
  and
    not coalesce( t.deleted, false)
group by
  t.name,
  a.eservice_id,
  a.id
;
