-- RUN THIS IN SUPABASE SQL EDITOR TO DIAGNOSE DATA
-- This will show you exactly what is in the database.

-- 1. Count records
SELECT 
    (SELECT count(*) FROM auth.users) as "Total Auth Users",
    (SELECT count(*) FROM public.profiles) as "Total Profiles (App Valid Users)";

-- 2. List ALL Profiles (This is what the app attempts to load)
SELECT * FROM public.profiles;

-- 3. List ALL Auth Users (This is who acts as logged in users)
SELECT id, email, created_at, last_sign_in_at FROM auth.users;

-- 4. Check if RLS is effectively hiding rows (Diagnostic Policy Check)
-- If "Total Profiles" above > 0 but App shows 0, RLS is the issue.
-- If "Total Profiles" is 0, then the CREATE process failed.
