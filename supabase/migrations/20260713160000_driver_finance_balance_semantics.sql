-- Issue #61 - Align driver financial movements with driver-perspective balance semantics.
-- Negative driver balance means the driver owes the company.
-- Positive driver balance means the company owes the driver.

begin;

alter table public.driver_financial_movements
  drop constraint if exists driver_financial_movements_trip_link_check,
  drop constraint if exists driver_financial_movements_movement_type_check;

update public.driver_financial_movements
set movement_type = 'driver_charge'
where movement_type = 'deduction';

alter table public.driver_financial_movements
  add constraint driver_financial_movements_movement_type_check
    check (movement_type in ('advance', 'driver_charge', 'cash_return'))
    not valid,
  add constraint driver_financial_movements_trip_link_check
    check (trip_id is null or movement_type = 'driver_charge')
    not valid;

alter table public.driver_financial_movements
  validate constraint driver_financial_movements_movement_type_check;

alter table public.driver_financial_movements
  validate constraint driver_financial_movements_trip_link_check;

commit;
