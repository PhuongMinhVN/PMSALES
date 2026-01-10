-- CLEANUP GHOST USERS (Fixed)
-- This removes accounts from auth.users that do NOT have a corresponding profile in public.profiles.
-- This usually happens when the "Create User" process failed halfway (created Auth, but failed to create Profile due to RLS).

DELETE FROM auth.users 
WHERE id NOT IN (SELECT id FROM public.profiles);
