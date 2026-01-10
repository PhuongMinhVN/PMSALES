-- Add quantity column to order_items
ALTER TABLE public.order_items 
ADD COLUMN IF NOT EXISTS quantity INTEGER DEFAULT 1;
