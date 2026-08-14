alter table public.drivers
  add column if not exists license_back_image_path text,
  add column if not exists national_id_back_image_path text;

create or replace function private.driver_document_company_id(object_name text)
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select case
    when object_name ~ '^companies/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/drivers/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/(profile|license|license-front|license-back|national-id|national-id-front|national-id-back)/[^/]+$'
      then split_part(object_name, '/', 2)::uuid
    else null
  end;
$$;
