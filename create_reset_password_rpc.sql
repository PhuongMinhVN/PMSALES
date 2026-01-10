-- Create the extension required for password hashing if it doesn't exist
create extension if not exists pgcrypto;

-- Create a secure function to allow Admins to reset passwords
create or replace function reset_password_by_admin(target_user_id uuid, new_password text)
returns void
language plpgsql
security definer -- Runs with the privileges of the creator (usually postgres/superuser)
as $$
begin
  -- 1. Security Check: ensure the user calling this function is actually an Admin
  if not exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  ) then
    raise exception 'Access Denied: Only Admins can reset passwords.';
  end if;

  -- 2. Update the password for the target user
  update auth.users
  set encrypted_password = crypt(new_password, gen_salt('bf'))
  where id = target_user_id;
end;
$$;
