-- 1. Add identifying column to distinguish Services from Deleted Products
ALTER TABLE "public"."order_items" 
ADD COLUMN IF NOT EXISTS "is_service" BOOLEAN DEFAULT false;

-- 2. Backfill existing data
-- Currently, if product_id is NULL, it is a service.
UPDATE "public"."order_items"
SET "is_service" = true
WHERE "product_id" IS NULL;

-- 3. Update the constraint to allow deleting products
ALTER TABLE "public"."order_items"
DROP CONSTRAINT IF EXISTS "order_items_product_id_fkey";

ALTER TABLE "public"."order_items"
ADD CONSTRAINT "order_items_product_id_fkey"
FOREIGN KEY ("product_id")
REFERENCES "public"."products"("id")
ON DELETE SET NULL;
