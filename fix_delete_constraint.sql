-- Allow deleting products even if they are in orders.
-- The order history will be preserved (product_name, price), but product_id will become NULL in order_items.

ALTER TABLE "public"."order_items"
DROP CONSTRAINT IF EXISTS "order_items_product_id_fkey";

ALTER TABLE "public"."order_items"
ADD CONSTRAINT "order_items_product_id_fkey"
FOREIGN KEY ("product_id")
REFERENCES "public"."products"("id")
ON DELETE SET NULL;
