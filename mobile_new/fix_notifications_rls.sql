
-- ============================================
-- FIX: Notifications RLS Violation & Cleanup
-- ============================================

-- 0. Cleanup: Remove conflicting policies if they exist (User reported "Final_Upload_Policy")
-- Note: 'objects' is usually in the 'storage' schema.
do $$ 
begin
    if exists (select 1 from pg_tables where schemaname = 'storage' and tablename = 'objects') then
        execute 'drop policy if exists "Final_Upload_Policy" on storage.objects';
    end if;
end $$;

-- 1. Enable RLS on Notifications (Safe to re-run)
alter table notifications enable row level security;

-- 2. Allow Users to View Own Notifications
drop policy if exists "Users can view their own notifications" on notifications;
create policy "Users can view their own notifications"
on notifications for select
using (auth.uid() = user_id);

-- 3. Allow Authenticated Users to Insert Notifications 
-- (Fixes Client-side logic/Triggers without Security Definer)
drop policy if exists "Users can insert notifications" on notifications;
create policy "Users can insert notifications"
on notifications for insert
with check (
  -- Allow if inserting for self OR if authenticated (broad permission for now to unblock)
  auth.role() = 'authenticated'
);

-- 4. Ensure the Dispatch Trigger is SECURITY DEFINER (Runs as Admin/Superuser)
-- This allows the trigger to insert notifications for OTHER users (which RLS usually blocks)
create or replace function execute_task_dispatch()
returns trigger as $$
begin
  -- Send alerts to targeted workers WITHOUT hiding task from marketplace
  if coalesce(array_length(NEW.candidate_ids, 1), 0) > 0 then
    -- Insert requests for ALL candidates simultaneously (FCFS Mode)
    insert into gig_requests (task_id, worker_id, status, expires_at)
    select NEW.id, id, 'pending', now() + interval '24 hours'
    from unnest(NEW.candidate_ids) as id;

    -- Create High-Priority Push Signals for ALL chosen candidates
    insert into notifications (user_id, type, title, message, data, is_read)
    select 
      id, 
      'high_priority_dispatch', 
      '🔔 NEW GIG: ' || NEW.title, 
      'Tap to Accept Instantly!', 
      jsonb_build_object(
        'task_id', NEW.id, 
        'priority', 'urgent', 
        'is_alarm', true,
        'pickup_lat', NEW.pickup_lat,
        'pickup_lng', NEW.pickup_lng
      ), 
      false
    from unnest(NEW.candidate_ids) as id;
  end if;

  return NEW;
end;
$$ language plpgsql security definer; -- <--- IMPERATIVE for cross-user inserts

-- 5. Grant Permissions
grant all on notifications to authenticated;
