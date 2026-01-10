-- Add missing columns to orders table to support Checkout and Detailed Sales
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS customer_address TEXT,
ADD COLUMN IF NOT EXISTS google_maps_link TEXT,
ADD COLUMN IF NOT EXISTS qr_code TEXT;

-- ensure they are accessible
GRANT ALL ON public.orders TO postgres;
GRANT ALL ON public.orders TO anon;
GRANT ALL ON public.orders TO authenticated;
GRANT ALL ON public.orders TO service_role;
