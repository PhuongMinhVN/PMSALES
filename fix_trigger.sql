-- 1. Create a ROBUST function to handle new user creation
-- SECURITY DEFINER means it runs with system privileges, bypassing all policies.
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role, phone_number)
  VALUES (
    new.id, 
    new.raw_user_meta_data->>'full_name', 
    COALESCE(new.raw_user_meta_data->>'role', 'viewer'),
    new.raw_user_meta_data->>'phone_number'
  )
  ON CONFLICT (id) DO UPDATE
  SET 
    full_name = EXCLUDED.full_name,
    role = EXCLUDED.role,
    phone_number = EXCLUDED.phone_number;
  return new;
END;
$$;

-- 2. Drop the old trigger to make sure we attach the new one
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 3. Re-attach the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 4. CLEANUP (Run this once)
-- Delete any "partial" users from your previous failed attempts
DELETE FROM auth.users WHERE id NOT IN (SELECT id FROM public.profiles);
