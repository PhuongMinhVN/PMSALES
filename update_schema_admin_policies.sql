-- Allow Admins to INSERT/UPSERT into profiles (to fix missing profiles)
CREATE POLICY "Admins can insert profiles"
ON public.profiles
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- Ensure Admins can DELETE profiles (already handled by DELETE USER func, but good for cleanup)
CREATE POLICY "Admins can delete profiles"
ON public.profiles
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
);
