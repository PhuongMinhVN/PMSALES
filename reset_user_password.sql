-- FUNCTION: Reset password for a specific user (identified by phone number)
-- Pre-requisite: The 'pgcrypto' extension must be enabled (usually is by default in Supabase).

-- REPLACE '0912345678' WITH THE TARGET PHONE NUMBER
-- REPLACE 'new_password_here' WITH THE DESIRED PASSWORD

update auth.users
set encrypted_password = crypt('new_password_here', gen_salt('bf'))
where email = '0912345678@pm.app';

-- NOTE: In this app, users login with phone, but the system stores it as 'PHONE@pm.app'.
-- So when searching/updating in auth.users, we must append '@pm.app'.
