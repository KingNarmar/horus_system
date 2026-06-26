-- Seed default expense types for existing companies.
-- Trip expenses UI uses expense_types as DB-backed master data.

insert into public.expense_types (company_id, name)
select
  c.id as company_id,
  v.name
from public.companies c
cross join (
  values
    ('Fuel'),
    ('Road fees'),
    ('Weighbridge'),
    ('Loading'),
    ('Unloading'),
    ('Fines'),
    ('Emergency maintenance'),
    ('Driver advance'),
    ('Other')
) as v(name)
where not exists (
  select 1
  from public.expense_types et
  where et.company_id = c.id
    and lower(trim(et.name)) = lower(trim(v.name))
);
