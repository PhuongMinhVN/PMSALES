-- RUN THIS IN SUPABASE SQL EDITOR

ALTER TABLE public.products 
ADD COLUMN category text;

-- Optional: Create an index for faster filtering
CREATE INDEX idx_products_category ON public.products(category);
