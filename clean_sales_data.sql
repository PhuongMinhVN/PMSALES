-- DANGER: This operation effectively wipes all sales history.
-- Use this to clean test data and start fresh.

-- Delete all rows from order_items and orders, and reset their ID counters to 1.
TRUNCATE TABLE public.order_items, public.orders RESTART IDENTITY CASCADE;
