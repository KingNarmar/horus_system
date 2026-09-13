alter table public.drivers
  add column if not exists profile_image_path text,
  add column if not exists license_image_path text,
  add column if not exists national_id_image_path text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'driver-documents',
  'driver-documents',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create or replace function private.driver_document_company_id(object_name text)
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select case
    when object_name ~ '^companies/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/drivers/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/(profile|license|national-id)/[^/]+$'
      then split_part(object_name, '/', 2)::uuid
    else null
  end;
$$;

drop policy if exists driver_documents_select_company_members on storage.objects;
drop policy if exists driver_documents_insert_managers on storage.objects;
drop policy if exists driver_documents_update_managers on storage.objects;
drop policy if exists driver_documents_delete_managers on storage.objects;

create policy driver_documents_select_company_members
on storage.objects
for select
to authenticated
using (
  bucket_id = 'driver-documents'
  and private.is_company_member(private.driver_document_company_id(name))
);

create policy driver_documents_insert_managers
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'driver-documents'
  and private.has_company_role(
    private.driver_document_company_id(name),
    array['owner', 'admin', 'operations']::company_role[]
  )
);

create policy driver_documents_update_managers
on storage.objects
for update
to authenticated
using (
  bucket_id = 'driver-documents'
  and private.has_company_role(
    private.driver_document_company_id(name),
    array['owner', 'admin', 'operations']::company_role[]
  )
)
with check (
  bucket_id = 'driver-documents'
  and private.has_company_role(
    private.driver_document_company_id(name),
    array['owner', 'admin', 'operations']::company_role[]
  )
);

create policy driver_documents_delete_managers
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'driver-documents'
  and private.has_company_role(
    private.driver_document_company_id(name),
    array['owner', 'admin', 'operations']::company_role[]
  )
);
