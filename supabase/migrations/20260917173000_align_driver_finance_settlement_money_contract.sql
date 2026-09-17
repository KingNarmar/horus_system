-- PC-09 / #233
-- Align Driver Finance and Driver Settlements with the canonical exact-money
-- contract without rewriting historical settlement meaning.

alter table public.driver_financial_movements
  add column if not exists amount_minor_units bigint,
  add column if not exists currency_code text,
  add column if not exists currency_fraction_digits smallint;

update public.driver_financial_movements movement
set
  amount_minor_units = (
    movement.amount * power(10::numeric, company.base_currency_fraction_digits)
  )::bigint,
  currency_code = company.base_currency_code,
  currency_fraction_digits = company.base_currency_fraction_digits
from public.companies company
where company.id = movement.company_id
  and (
    movement.amount_minor_units is null
    or movement.currency_code is null
    or movement.currency_fraction_digits is null
  );

alter table public.driver_financial_movements
  alter column amount_minor_units set not null,
  alter column currency_code set not null,
  alter column currency_fraction_digits set not null;

alter table public.driver_financial_movements
  add constraint driver_financial_movements_amount_minor_units_positive
    check (amount_minor_units > 0),
  add constraint driver_financial_movements_currency_code_format
    check (currency_code = upper(currency_code) and currency_code ~ '^[A-Z]{3}$'),
  add constraint driver_financial_movements_currency_fraction_digits_range
    check (currency_fraction_digits between 0 and 4);

alter table public.driver_settlements
  add column if not exists compensation_revision_id uuid
    references public.driver_compensation_revisions(id) on delete restrict,
  add column if not exists currency_code text,
  add column if not exists currency_fraction_digits smallint,
  add column if not exists opening_driver_balance_minor_units bigint,
  add column if not exists advances_total_minor_units bigint,
  add column if not exists driver_paid_trip_expenses_total_minor_units bigint,
  add column if not exists returned_cash_total_minor_units bigint,
  add column if not exists deductions_total_minor_units bigint,
  add column if not exists settlement_deductions_total_minor_units bigint,
  add column if not exists gross_salary_minor_units bigint,
  add column if not exists salary_deductions_total_minor_units bigint,
  add column if not exists balance_deduction_applied_minor_units bigint,
  add column if not exists net_salary_payable_minor_units bigint,
  add column if not exists closing_driver_balance_minor_units bigint;

update public.driver_settlements settlement
set
  currency_code = company.base_currency_code,
  currency_fraction_digits = company.base_currency_fraction_digits,
  opening_driver_balance_minor_units = (
    settlement.opening_driver_balance * power(10::numeric, company.base_currency_fraction_digits)
  )::bigint,
  advances_total_minor_units = (
    settlement.advances_total * power(10::numeric, company.base_currency_fraction_digits)
  )::bigint,
  driver_paid_trip_expenses_total_minor_units = (
    settlement.driver_paid_trip_expenses_total * power(10::numeric, company.base_currency_fraction_digits)
  )::bigint,
  returned_cash_total_minor_units = (
    settlement.returned_cash_total * power(10::numeric, company.base_currency_fraction_digits)
  )::bigint,
  deductions_total_minor_units = (
    settlement.deductions_total * power(10::numeric, company.base_currency_fraction_digits)
  )::bigint,
  settlement_deductions_total_minor_units = (
    settlement.settlement_deductions_total * power(10::numeric, company.base_currency_fraction_digits)
  )::bigint,
  gross_salary_minor_units = (
    settlement.gross_salary * power(10::numeric, company.base_currency_fraction_digits)
  )::bigint,
  salary_deductions_total_minor_units = (
    settlement.salary_deductions_total * power(10::numeric, company.base_currency_fraction_digits)
  )::bigint,
  balance_deduction_applied_minor_units = (
    settlement.balance_deduction_applied * power(10::numeric, company.base_currency_fraction_digits)
  )::bigint,
  net_salary_payable_minor_units = (
    settlement.net_salary_payable * power(10::numeric, company.base_currency_fraction_digits)
  )::bigint,
  closing_driver_balance_minor_units = (
    settlement.closing_driver_balance * power(10::numeric, company.base_currency_fraction_digits)
  )::bigint
from public.companies company
where company.id = settlement.company_id
  and settlement.currency_code is null;

alter table public.driver_settlements
  alter column currency_code set not null,
  alter column currency_fraction_digits set not null,
  alter column opening_driver_balance_minor_units set not null,
  alter column advances_total_minor_units set not null,
  alter column driver_paid_trip_expenses_total_minor_units set not null,
  alter column returned_cash_total_minor_units set not null,
  alter column deductions_total_minor_units set not null,
  alter column settlement_deductions_total_minor_units set not null,
  alter column gross_salary_minor_units set not null,
  alter column salary_deductions_total_minor_units set not null,
  alter column balance_deduction_applied_minor_units set not null,
  alter column net_salary_payable_minor_units set not null,
  alter column closing_driver_balance_minor_units set not null;

alter table public.driver_settlements
  add constraint driver_settlements_currency_code_format
    check (currency_code = upper(currency_code) and currency_code ~ '^[A-Z]{3}$'),
  add constraint driver_settlements_currency_fraction_digits_range
    check (currency_fraction_digits between 0 and 4);

alter table public.driver_settlement_items
  add column if not exists amount_minor_units bigint,
  add column if not exists currency_code text,
  add column if not exists currency_fraction_digits smallint;

update public.driver_settlement_items item
set
  amount_minor_units = (
    item.amount * power(10::numeric, settlement.currency_fraction_digits)
  )::bigint,
  currency_code = settlement.currency_code,
  currency_fraction_digits = settlement.currency_fraction_digits
from public.driver_settlements settlement
where settlement.id = item.settlement_id
  and settlement.company_id = item.company_id
  and item.amount_minor_units is null;

alter table public.driver_settlement_items
  alter column amount_minor_units set not null,
  alter column currency_code set not null,
  alter column currency_fraction_digits set not null;

alter table public.driver_settlement_items
  add constraint driver_settlement_items_amount_minor_units_positive
    check (amount_minor_units > 0),
  add constraint driver_settlement_items_currency_code_format
    check (currency_code = upper(currency_code) and currency_code ~ '^[A-Z]{3}$'),
  add constraint driver_settlement_items_currency_fraction_digits_range
    check (currency_fraction_digits between 0 and 4);

create or replace function public.get_driver_balance_checkpoint_v2(
  p_company_id uuid,
  p_driver_id uuid,
  p_before_exclusive date
)
returns table(
  settlement_id uuid,
  period_end date,
  snapshot_created_at timestamptz,
  closing_driver_balance_minor_units bigint,
  currency_code text,
  currency_fraction_digits smallint
)
language plpgsql
stable
security definer
set search_path = pg_catalog
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication is required.' using errcode = '42501';
  end if;

  if p_company_id is null then
    raise exception 'Company id is required.' using errcode = '22004';
  end if;

  if p_driver_id is null then
    raise exception 'Driver id is required.' using errcode = '22004';
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
    raise exception 'Driver balance access is not allowed.' using errcode = '42501';
  end if;

  return query
  select
    settlement.id,
    settlement.period_end,
    settlement.created_at,
    settlement.closing_driver_balance_minor_units,
    settlement.currency_code,
    settlement.currency_fraction_digits
  from public.driver_settlements settlement
  where settlement.company_id = p_company_id
    and settlement.driver_id = p_driver_id
    and settlement.status = 'finalized'::public.driver_settlement_status
    and (
      p_before_exclusive is null
      or settlement.period_end < p_before_exclusive
    )
  order by
    settlement.period_end desc,
    settlement.finalized_at desc nulls last,
    settlement.created_at desc,
    settlement.id desc
  limit 1;
end;
$$;

revoke all on function public.get_driver_balance_checkpoint_v2(uuid, uuid, date)
from public, anon;
grant execute on function public.get_driver_balance_checkpoint_v2(uuid, uuid, date)
to authenticated;
