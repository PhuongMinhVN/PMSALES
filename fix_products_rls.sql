-- Allow authenticated users (e.g. Sales/Tech) to insert products into 'Khác' category
-- This is required for the "Add Service" feature.

CREATE POLICY "Enable insert for authenticated users for Services" 
ON "public"."products"
FOR INSERT 
TO authenticated 
WITH CHECK (category = 'Khác');

-- Verify it exists
SELECT * FROM pg_policies WHERE tablename = 'products';
