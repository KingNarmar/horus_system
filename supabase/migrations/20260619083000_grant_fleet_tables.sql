-- Issue #15 - Fleet module grants.
-- RLS controls row-level access. These grants allow authenticated users to reach the tables.

GRANT SELECT, INSERT, UPDATE ON public.tractor_heads TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.trailers TO authenticated;
