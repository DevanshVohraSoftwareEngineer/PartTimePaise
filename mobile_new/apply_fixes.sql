-- ============================================
-- FIX: Grants & Permissions (Run this in SQL Editor)
-- ============================================

-- 1. Grant Permissions to Authenticated Users
grant usage on schema public to authenticated;
grant all on profiles to authenticated;
grant all on tasks to authenticated;
grant all on matches to authenticated;
grant all on chat_messages to authenticated;
grant all on swipes to authenticated;
grant all on gig_requests to authenticated;
grant all on notifications to authenticated;
grant all on id_verifications to authenticated;
grant all on location_updates to authenticated;
grant all on dispatch_analytics to authenticated;
grant all on bids to authenticated;
grant all on task_events to authenticated;

-- 2. Ensure Sequences are accessible (if any)
grant usage, select on all sequences in schema public to authenticated;

-- 3. Simplify Matches Policy (To rule out complex joins failing)
drop policy if exists "Users can create matches for their tasks" on matches;
create policy "Users can create matches for their tasks"
on matches for insert
with check (
  auth.uid() = client_id
);

-- 4. Ensure Chat Messages Policies exist
drop policy if exists "Users can send messages in their matches" on chat_messages;
create policy "Users can send messages in their matches"
on chat_messages for insert
with check (
  auth.uid() = sender_id
);

-- 5. Fix Task Ownership Policy just in case
drop policy if exists "Users can update own tasks" on tasks;
create policy "Users can update own tasks"
on tasks for update
using (auth.uid() = client_id);

-- 6. Add Missing Columns to Notifications
alter table notifications add column if not exists related_id text;
alter table notifications add column if not exists data jsonb default '{}'::jsonb;
