-- Add status column to orders table
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';

-- Update existing orders to be confirmed so they show up in stats
UPDATE public.orders 
SET status = 'confirmed' 
WHERE status = 'pending' AND created_at < NOW(); 
-- Wait, if I just added the column with default 'pending', all old rows might be 'pending'. 
-- Actually, if I add new column with default, existing rows get that default value in Postgres.
-- So yes, I need to update them.

UPDATE public.orders
SET status = 'confirmed'
WHERE status IS NULL OR status = 'pending';

-- Grant access just in case
GRANT ALL ON public.orders TO postgres;
GRANT ALL ON public.orders TO anon;
GRANT ALL ON public.orders TO authenticated;
GRANT ALL ON public.orders TO service_role;
