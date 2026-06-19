-- Issue #15 - Tighten Fleet authenticated table grants.
-- Keep authenticated access aligned with the application needs only.

REVOKE DELETE, TRUNCATE, REFERENCES, TRIGGER
ON public.tractor_heads, public.trailers
FROM authenticated;

GRANT SELECT, INSERT, UPDATE
ON public.tractor_heads, public.trailers
TO authenticated;
