-- RUN THIS IN SUPABASE SQL EDITOR TO ENABLE USER DELETION

-- Function to allow admins to delete users safely
CREATE OR REPLACE FUNCTION delete_user_by_admin(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if the executing user is an admin
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: Only admins can delete users';
  END IF;

  -- Delete from auth.users (this cascades to profiles usually, but we ensure it)
  DELETE FROM auth.users WHERE id = target_user_id;
END;
$$;
