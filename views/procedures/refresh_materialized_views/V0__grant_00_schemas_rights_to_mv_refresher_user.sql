
-- Grant needed access to a user dedicated to call this procedure,
--  that user need to be altered 'WITH SYSLOG ACCESS UNRESTRICTED'
CREATE SCHEMA IF NOT EXISTS views;
GRANT USAGE ON SCHEMA views TO ${NAMESPACE}_mv_refresher_user;

CREATE SCHEMA IF NOT EXISTS sub_views;
GRANT USAGE ON SCHEMA sub_views TO ${NAMESPACE}_mv_refresher_user;

