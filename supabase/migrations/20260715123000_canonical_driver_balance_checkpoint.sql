-- H.O.R.U.S System
-- Issue #66: Canonical Driver Balance foundation.
-- Exposes only the latest finalized settlement checkpoint required to calculate
-- the current driver balance without broadening salary-bearing settlement reads.

create index if not exists driver_settlements_canonical_balance_checkpoint_idx
  on public.driver_settlements (
    company_id,
    driver_id,
    period_end desc,
    finalized_at desc,
    created_at desc,
    id desc
  )
  where status = 'finalized'::public.driver_settlement_status;

create or replace function public.get_driver_balance_checkpoint(
  p_company_id uuid,
  p_driver_id uuid,
  p_before_exclusive date
)
returns table (
  settlement_id uuid,
  period_end date,
  snapshot_created_at timestamp with time zone,
  closing_driver_balance numeric
)
language plpgsql
stable
security definer
set search_path = pg_catalog
as $function$
begin
  if auth.uid() is null then
    raise exception 'Authentication is required.'
      using errcode = '42501';
  end if;

  if p_company_id is null then
    raise exception 'Company id is required.'
      using errcode = '22004';
  end if;

  if p_driver_id is null then
    raise exception 'Driver id is required.'
      using errcode = '22004';
  end if;

  if not private.has_company_role(
    p_company_id,
    array[
      'owner'::public.company_role,
      'admin'::public.company_role,
      'operations'::public.company_role,
      'accountant'::public.company_role,
      'viewer'::public.company_role
    ]
  ) then
    raise exception 'Driver balance access is not allowed.'
      using errcode = '42501';
  end if;

  return query
  select
    ds.id as settlement_id,
    ds.period_end,
    ds.created_at as snapshot_created_at,
    ds.closing_driver_balance
  from public.driver_settlements ds
  where ds.company_id = p_company_id
    and ds.driver_id = p_driver_id
    and ds.status = 'finalized'::public.driver_settlement_status
    and (
      p_before_exclusive is null
      or ds.period_end < p_before_exclusive
    )
  order by
    ds.period_end desc,
    ds.finalized_at desc nulls last,
    ds.created_at desc,
    ds.id desc
  limit 1;
end;
$function$;

revoke all on function public.get_driver_balance_checkpoint(uuid, uuid, date)
  from public;
revoke all on function public.get_driver_balance_checkpoint(uuid, uuid, date)
  from anon;
revoke all on function public.get_driver_balance_checkpoint(uuid, uuid, date)
  from authenticated;

grant execute on function public.get_driver_balance_checkpoint(uuid, uuid, date)
  to authenticated;

comment on function public.get_driver_balance_checkpoint(uuid, uuid, date) is
  'Returns the latest finalized driver settlement balance checkpoint, optionally bounded by period end, for an authorized same-company Driver Finance reader.';
