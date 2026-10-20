-- #327 — The legacy and canonical driver balance checkpoint RPCs return
-- monetary settlement balances. Their SECURITY DEFINER guards must not
-- include operations/viewer, regardless of table RLS.
BEGIN;

CREATE OR REPLACE FUNCTION public.get_driver_balance_checkpoint(p_company_id uuid, p_driver_id uuid, p_before_exclusive date)
 RETURNS TABLE(settlement_id uuid, period_end date, snapshot_created_at timestamp with time zone, closing_driver_balance numeric)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
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

      'accountant'::public.company_role
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

CREATE OR REPLACE FUNCTION public.get_driver_balance_checkpoint_v2(p_company_id uuid, p_driver_id uuid, p_before_exclusive date)
 RETURNS TABLE(settlement_id uuid, period_end date, snapshot_created_at timestamp with time zone, closing_driver_balance_minor_units bigint, currency_code text, currency_fraction_digits smallint)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication is required.'
      USING ERRCODE = '42501';
  END IF;

  IF p_company_id IS NULL THEN
    RAISE EXCEPTION 'Company id is required.'
      USING ERRCODE = '22004';
  END IF;

  IF p_driver_id IS NULL THEN
    RAISE EXCEPTION 'Driver id is required.'
      USING ERRCODE = '22004';
  END IF;

  IF NOT private.has_company_role(
    p_company_id,
    ARRAY[
      'owner'::public.company_role,
      'admin'::public.company_role,

      'accountant'::public.company_role
    ]
  ) THEN
    RAISE EXCEPTION 'Driver balance access is not allowed.'
      USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    settlement.id,
    settlement.period_end,
    settlement.created_at,
    settlement.closing_driver_balance_minor_units,
    settlement.currency_code,
    settlement.currency_fraction_digits
  FROM public.driver_settlements AS settlement
  WHERE settlement.company_id = p_company_id
    AND settlement.driver_id = p_driver_id
    AND settlement.status = 'finalized'::public.driver_settlement_status
    AND settlement.closing_driver_balance_minor_units IS NOT NULL
    AND settlement.currency_code IS NOT NULL
    AND settlement.currency_fraction_digits IS NOT NULL
    AND (
      p_before_exclusive IS NULL
      OR settlement.period_end < p_before_exclusive
    )
  ORDER BY
    settlement.period_end DESC,
    settlement.finalized_at DESC NULLS LAST,
    settlement.created_at DESC,
    settlement.id DESC
  LIMIT 1;
END;
$function$;

COMMIT;
