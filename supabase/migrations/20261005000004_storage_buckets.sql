-- ============================================================================
-- AgentPost — migration 4 of 5: private storage buckets (photos & logos)
-- ============================================================================
-- Plain-language summary:
--   Two private storage folders ("buckets"): one for profile photos, one for
--   brand logos. "Private" means files are never served from a public URL.
--   The app creates short-lived private links only for the owner (and admins).
--
--   Every file is stored under a folder named after the user's ID, e.g.
--       avatars/1f2e3d4c-.../avatar.jpg
--   The rules below allow each user to touch ONLY their own folder.
--
--   Allowed file types: png / jpeg / webp images only. Max size: 5 MB.
-- ============================================================================


insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', false, 5242880, array['image/png', 'image/jpeg', 'image/webp']),
  ('logos',   'logos',   false, 5242880, array['image/png', 'image/jpeg', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;


-- ===========================================================================
-- avatars bucket policies
-- ===========================================================================
create policy "avatars_select_own_or_admin"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'avatars'
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or public.is_admin()
    )
  );

create policy "avatars_insert_own"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "avatars_update_own"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "avatars_delete_own"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );


-- ===========================================================================
-- logos bucket policies
-- ===========================================================================
create policy "logos_select_own_or_admin"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'logos'
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or public.is_admin()
    )
  );

create policy "logos_insert_own"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'logos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "logos_update_own"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'logos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'logos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "logos_delete_own"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'logos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
