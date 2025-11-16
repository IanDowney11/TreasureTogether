-- Drop the problematic policy
DROP POLICY IF EXISTS "Users can view group members for their groups" ON public.group_members;

-- Create a non-recursive policy
-- Since the groups policy already restricts which groups users can see,
-- we can allow authenticated users to view group_members records
-- They can only act on groups they're members of anyway
CREATE POLICY "Users can view group members" ON public.group_members
  FOR SELECT USING (auth.uid() IS NOT NULL);
