-- RUN THIS IN SUPABASE SQL EDITOR

-- 1. Create the search function
-- This function allows searching for orders by phone, name, or QR code
-- It runs with "security definer" to bypass RLS for this specific query only
create or replace function search_orders_warranty(keyword text)
returns table (
  id bigint,
  created_at timestamptz,
  customer_name text,
  customer_phone text,
  qr_code text,
  order_items json
)
security definer
set search_path = public
as $$
begin
  return query
  select
    o.id,
    o.created_at,
    o.customer_name,
    o.customer_phone,
    o.qr_code,
    coalesce(
      (
        select json_agg(oi)
        from order_items oi
        where oi.order_id = o.id
      ),
      '[]'::json
    ) as order_items
  from orders o
  where
    o.customer_phone ilike '%' || keyword || '%'
    or o.customer_name ilike '%' || keyword || '%'
    or (o.qr_code is not null and o.qr_code = keyword)
  order by o.created_at desc;
end;
$$ language plpgsql;

-- 2. Grant permission to public users (anon)
grant execute on function search_orders_warranty to anon;
grant execute on function search_orders_warranty to authenticated;
grant execute on function search_orders_warranty to service_role;
