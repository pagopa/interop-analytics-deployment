CREATE SCHEMA IF NOT EXISTS sub_views;

GRANT USAGE ON SCHEMA sub_views TO GROUP readonly_group;

DROP MATERIALIZED VIEW IF EXISTS sub_views.mv_00_daily_calls_overbooking__raw_data CASCADE;

-- This " sub view" link every active purpose version with its eservice descriptor to extract:
--  - eservice_descriptor.daily_calls_per_consumer
--  - eservice_descriptor.daily_calls_total
--  - purpose_version.daily_calls
-- for aggregation in multiple "higher level" materialized view

CREATE MATERIALIZED VIEW sub_views.mv_00_daily_calls_overbooking__raw_data AUTO REFRESH YES AS 
select 
  t_p."name" as producer_name,
  ed.eservice_id,
  e."name" as eservice_name,
  t_c."name" as consumer_name,
  ed.daily_calls_per_consumer as eservice_declared_calls_per_consumer,
  ed.daily_calls_total as eservice_declared_daily_calls_total,
  pv.daily_calls as consumer_daily_calls
from 
  domains.eservice_descriptor ed 
  join domains.eservice e on e.id = ed.eservice_id
  join domains.agreement a on a.producer_id = e.producer_id
  join domains.purpose p on p.consumer_id = a.consumer_id and p.eservice_id = a.eservice_id
  join domains.purpose_version pv on pv.purpose_id = p.id
  join domains.tenant t_p on t_p.id = e.producer_id
  join domains.tenant t_c on t_c.id = a.consumer_id
where
    ed.state in ('Published', 'Suspended', 'Deprecated')
  and
    a.state in ('Active' )
  and
    pv.state in ('Active' )
  and 
    not coalesce( ed.deleted, false)
  and 
    not coalesce( e.deleted, false)
  and 
    not coalesce( a.deleted, false)
  and
    not coalesce( p.suspended_by_consumer, false )
  and
    not coalesce( p.suspended_by_producer, false )
  and
    not coalesce( p.deleted, false )
  and
    not coalesce( pv.deleted, false )
;
