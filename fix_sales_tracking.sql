-- 1. Ensure seller_id column exists
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS seller_id UUID REFERENCES auth.users(id);

-- 2. Enable RLS on orders if not already
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- 3. Policy: Sellers can view their own orders (Critical for Chart)
DROP POLICY IF EXISTS "Sellers can view own orders" ON public.orders;
CREATE POLICY "Sellers can view own orders"
ON public.orders FOR SELECT
USING (auth.uid() = seller_id);

-- 4. Policy: Users can create orders (This likely exists, but ensuring it)
DROP POLICY IF EXISTS "Users can create orders" ON public.orders;
CREATE POLICY "Users can create orders"
ON public.orders FOR INSERT
WITH CHECK (auth.uid() = created_by);

-- 5. Policy: Admins can view everything
DROP POLICY IF EXISTS "Admins can view all orders" ON public.orders;
CREATE POLICY "Admins can view all orders"
ON public.orders FOR SELECT
USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);
