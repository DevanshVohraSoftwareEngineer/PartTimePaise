-- ==========================================
-- FIX: Secure Match Creation Function
-- ==========================================

-- This function handles match creation server-side to avoid RLS and duplicate key errors.
-- Run this in your Supabase SQL Editor.

create or replace function create_match_secure(
  p_task_id uuid,
  p_worker_id uuid
)
returns uuid
language plpgsql
security definer -- Bypass RLS
as $$
declare
  v_match_id uuid;
  v_client_id uuid;
begin
  -- Get current user
  v_client_id := auth.uid();
  if v_client_id is null then
    raise exception 'Not authenticated';
  end if;

  -- 1. Verify task ownership
  if not exists (select 1 from tasks where id = p_task_id and client_id = v_client_id) then
    raise exception 'Permission denied: You do not own this task.';
  end if;

  -- 2. Check if match already exists (Idempotency)
  select id into v_match_id from matches 
  where task_id = p_task_id and worker_id = p_worker_id;

  if v_match_id is not null then
    return v_match_id; -- Return existing match
  end if;

  -- 3. Insert new match
  insert into matches (task_id, client_id, worker_id, status)
  values (p_task_id, v_client_id, p_worker_id, 'active')
  returning id into v_match_id;

  -- 4. Create system message
  insert into chat_messages (match_id, sender_id, content, type)
  values (v_match_id, v_client_id, 'You matched! Start the conversation.', 'system');

  return v_match_id;
end;
$$;
