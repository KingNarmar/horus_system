-- Auth registration profile trigger
--
-- Purpose:
-- When a new user signs up, create public.user_profiles automatically from
-- auth.users raw_user_meta_data. This guarantees full_name and phone are stored
-- even when email confirmation prevents the client from inserting the profile
-- immediately after sign up.
--
-- The app must still validate full_name and phone before calling signUp.

create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.user_profiles (
    id,
    full_name,
    phone
  )
  values (
    new.id,
    nullif(trim(coalesce(new.raw_user_meta_data ->> 'full_name', '')), ''),
    nullif(trim(coalesce(new.raw_user_meta_data ->> 'phone', '')), '')
  )
  on conflict (id)
  do update set
    full_name = excluded.full_name,
    phone = excluded.phone,
    updated_at = now();

  return new;
end;
$$;

revoke all on function public.handle_new_user_profile() from public;

drop trigger if exists on_auth_user_created_create_profile on auth.users;

create trigger on_auth_user_created_create_profile
after insert on auth.users
for each row execute function public.handle_new_user_profile();
