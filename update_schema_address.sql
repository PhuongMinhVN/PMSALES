-- RUN THIS IN SUPABASE SQL EDITOR

ALTER TABLE public.orders 
ADD COLUMN customer_address text,
ADD COLUMN google_maps_link text;
