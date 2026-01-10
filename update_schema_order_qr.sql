-- RUN THIS IN SUPABASE SQL EDITOR

ALTER TABLE public.orders 
ADD COLUMN qr_code text;

CREATE INDEX idx_orders_qr_code ON public.orders(qr_code);
