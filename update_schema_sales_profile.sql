-- 1. Add seller_id to Orders
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS seller_id UUID REFERENCES auth.users(id);

-- 2. Create Storage Bucket for Avatars
-- (You need to run this in SQL Editor, currently Supabase SQL API might not support creating buckets directly via SQL in all versions, 
-- but we can try inserting into storage.buckets if it's exposed, or just rely on the user creating it manually if this fails.
-- Standard way is usually via Dashboard -> Storage. But let's try SQL insertion which works on self-hosted/some clouds).

INSERT INTO storage.buckets (id, name, public) 
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- 3. Storage Policies for Avatars
-- Allow public viewing
CREATE POLICY "Avatar Public View"
ON storage.objects FOR SELECT
USING ( bucket_id = 'avatars' );

-- Allow authenticated users to upload their own avatar
CREATE POLICY "Avatar Upload Own"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars' AND 
  auth.uid() = owner
);

-- Allow authenticated users to update their own avatar
CREATE POLICY "Avatar Update Own"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'avatars' AND 
  auth.uid() = owner
);

-- 4. Add avatar_url to profiles if not exists
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS avatar_url TEXT;
