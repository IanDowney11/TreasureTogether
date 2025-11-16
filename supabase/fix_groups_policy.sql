-- Drop the existing SELECT policy for groups
DROP POLICY IF EXISTS "Users can view groups they're members of" ON public.groups;

-- Create a new SELECT policy that allows:
-- 1. Users to see groups they're members of
-- 2. Users to see groups they created (needed immediately after creation)
CREATE POLICY "Users can view groups they're members of or created" ON public.groups
  FOR SELECT USING (
    auth.uid() = created_by OR
    EXISTS (
      SELECT 1 FROM public.group_members
      WHERE group_id = id AND user_id = auth.uid()
    )
  );

-- Add UPDATE policy for groups (group creators can update)
DROP POLICY IF EXISTS "Group admins can update groups" ON public.groups;
CREATE POLICY "Group creators can update groups" ON public.groups
  FOR UPDATE USING (
    auth.uid() = created_by
  );

-- Add DELETE policy for groups (group creators can delete)
DROP POLICY IF EXISTS "Group creators can delete groups" ON public.groups;
CREATE POLICY "Group creators can delete groups" ON public.groups
  FOR DELETE USING (
    auth.uid() = created_by
  );
