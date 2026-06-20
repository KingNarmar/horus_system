-- Issue #16 - Routes authenticated grants.
-- This keeps authenticated access limited to the application needs only.

revoke delete, truncate, references, trigger
on public.routes
from authenticated;

grant select, insert, update
on public.routes
to authenticated;