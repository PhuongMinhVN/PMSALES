-- FIX INFINITE RECURSION ERROR & POLICY CONFLICTS
-- We are dropping multiple name variations to ensure we clear the old policies.

-- 1. Secure Admin Check Function (Bypasses RLS recursion)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin');
$$;

-- 2. Reset Policies (Drop ALL potential existing ones to avoid conflicts)
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles; -- Variant 1
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles; 
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles; -- Variant 2
DROP POLICY IF EXISTS "Admins can manage all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can insert profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can delete profiles" ON public.profiles;

-- 3. New Clean Policies
CREATE POLICY "Public profiles are viewable by everyone" 
ON public.profiles FOR SELECT 
USING (true);

CREATE POLICY "Admins can insert profiles" 
ON public.profiles FOR INSERT 
WITH CHECK (is_admin());

CREATE POLICY "Admins can update profiles" 
ON public.profiles FOR UPDATE 
USING (is_admin());

CREATE POLICY "Admins can delete profiles" 
ON public.profiles FOR DELETE 
USING (is_admin());

CREATE POLICY "Users can update own profile" 
ON public.profiles FOR UPDATE 
USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" 
ON public.profiles FOR INSERT 
WITH CHECK (auth.uid() = id);
