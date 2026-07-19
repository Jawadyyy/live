-- ============================================================================
-- Lock down the chat-attachments bucket (item 1).
--
-- Files are stored under path: <senderId>/<receiverId>/<timestamp>_<name>
-- so the first two folder segments are the two participants' user ids.
--
-- After running this the app MUST use signed URLs (already changed in
-- message_service.dart / message_screen.dart / voice_message_bubble.dart).
-- Run in Supabase → SQL Editor.
-- ============================================================================

-- 1. Make the bucket private (public URLs stop working; signed URLs still do).
update storage.buckets set public = false where id = 'chat-attachments';

-- 2. Replace any existing policies on this bucket's objects.
drop policy if exists "chat_attachments_select_participants" on storage.objects;
drop policy if exists "chat_attachments_insert_owner"        on storage.objects;
drop policy if exists "chat_attachments_delete_owner"        on storage.objects;

-- Read: only the two participants (uid is the 1st or 2nd folder segment).
create policy "chat_attachments_select_participants"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'chat-attachments'
    and (
      auth.uid()::text = (storage.foldername(name))[1]
      or auth.uid()::text = (storage.foldername(name))[2]
    )
  );

-- Write: uploader may only write under their own uid (matches the code path
-- `$currentUserId/$receiverId/...`).
create policy "chat_attachments_insert_owner"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'chat-attachments'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- Delete: sender can remove their own uploads.
create policy "chat_attachments_delete_owner"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'chat-attachments'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
