-- Add status column to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS status text DEFAULT 'active' CHECK (status IN ('active', 'disabled'));

-- Update existing records to have 'active' status if null
UPDATE public.profiles SET status = 'active' WHERE status IS NULL;
