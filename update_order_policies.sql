-- Ensure Orders table has RLS enabled
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- 1. Allow Admins to View ALL Orders
DROP POLICY IF EXISTS "Admins can view all orders" ON public.orders;
CREATE POLICY "Admins can view all orders" 
ON public.orders FOR SELECT 
TO authenticated
USING (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
);

-- 2. Allow Admins to Update Orders (Confirm/Cancel)
DROP POLICY IF EXISTS "Admins can update orders" ON public.orders;
CREATE POLICY "Admins can update orders" 
ON public.orders FOR UPDATE
TO authenticated
USING (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
)
WITH CHECK (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
);

-- 3. Ensure Users can still View their own orders (and Sellers)
-- Note: Multiple policies are inclusive (OR logic), so this adds to existing policies.
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
CREATE POLICY "Users can view own orders" 
ON public.orders FOR SELECT 
TO authenticated
USING (
  auth.uid() = created_by OR auth.uid() = seller_id
);

-- 4. Ensure Users can Insert orders
DROP POLICY IF EXISTS "Users can insert orders" ON public.orders;
CREATE POLICY "Users can insert orders" 
ON public.orders FOR INSERT 
TO authenticated
WITH CHECK (
  auth.uid() = created_by
);
