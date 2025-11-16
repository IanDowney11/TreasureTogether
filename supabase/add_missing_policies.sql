-- Add missing UPDATE policy for groups
-- Group admins should be able to update their groups
CREATE POLICY "Group admins can update groups" ON public.groups
  FOR UPDATE USING (
    auth.uid() = created_by
  );

-- Add DELETE policy for groups (optional but good to have)
CREATE POLICY "Group creators can delete groups" ON public.groups
  FOR DELETE USING (
    auth.uid() = created_by
  );

-- Add UPDATE policy for group_members (for role changes)
CREATE POLICY "Group admins can update members" ON public.group_members
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.groups g
      WHERE g.id = group_id AND g.created_by = auth.uid()
    )
  );

-- Add DELETE policy for group_members (for removing members)
CREATE POLICY "Users can leave groups" ON public.group_members
  FOR DELETE USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.groups g
      WHERE g.id = group_id AND g.created_by = auth.uid()
    )
  );

-- Add UPDATE and DELETE policies for photos
CREATE POLICY "Photo uploaders can update their photos" ON public.photos
  FOR UPDATE USING (
    auth.uid() = uploaded_by
  );

CREATE POLICY "Photo uploaders can delete their photos" ON public.photos
  FOR DELETE USING (
    auth.uid() = uploaded_by
  );
