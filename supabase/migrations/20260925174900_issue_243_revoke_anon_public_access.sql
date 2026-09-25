-- Issue #243: Remove unnecessary direct anonymous access to public tables
-- and sequences.
--
-- Application access remains through authenticated RPCs/RLS.
-- authenticated and service_role privileges are intentionally unchanged.

BEGIN;

REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE ALL ON TABLES FROM anon;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE ALL ON SEQUENCES FROM anon;

COMMIT;
