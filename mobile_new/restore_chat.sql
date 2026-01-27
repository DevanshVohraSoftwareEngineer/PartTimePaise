
-- --------------------------------------------------------
-- MISSING: CHAT MESSAGES & LIFECYCLE (Restored)
-- --------------------------------------------------------

create table if not exists chat_messages (
  id uuid default gen_random_uuid() primary key,
  match_id uuid references matches(id) on delete cascade,
  sender_id uuid references profiles(id) on delete cascade,
  content text,
  type text default 'text', -- 'text', 'image', 'video_call', 'video_call_request'
  metadata jsonb,
  is_read boolean default false,
  created_at timestamp with time zone default now()
);

-- Enable RLS
alter table chat_messages enable row level security;

-- CHAT MESSAGES POLICIES
drop policy if exists "Users can send messages in their matches" on chat_messages;
create policy "Users can send messages in their matches"
on chat_messages for insert
with check (
  auth.uid() = sender_id and
  exists (
    select 1 from matches
    where id = match_id
    and (client_id = auth.uid() or worker_id = auth.uid())
  )
);

drop policy if exists "Users can view messages in their matches" on chat_messages;
create policy "Users can view messages in their matches"
on chat_messages for select
using (
  exists (
    select 1 from matches
    where id = match_id
    and (client_id = auth.uid() or worker_id = auth.uid())
  )
);

-- Chat Lifecycle Trigger (Auto-messages on status change)
create or replace function handle_task_status_chat_updates()
returns trigger as $$
declare
  v_match_id uuid;
  v_system_content text;
begin
  -- Find the match/chat session for this task
  select id into v_match_id from matches where task_id = NEW.id;

  if v_match_id is not null then
    -- Decide message content based on status change
    if NEW.status = 'assigned' and OLD.status != 'assigned' then
      v_system_content := '🔒 Chat secure. Worker assigned.';
    elsif NEW.status = 'in_progress' and OLD.status != 'in_progress' then
      v_system_content := '🚀 Working on it! Rider is at pickup.';
    elsif NEW.status = 'completed' then
      v_system_content := '✅ Deal closed. Task completed.';
    elsif NEW.status = 'cancelled' then
      v_system_content := '❌ Task cancelled.';
    end if;

    -- Insert system message if we have a status update
    if v_system_content is not null then
      insert into chat_messages (match_id, sender_id, content, type)
      values (v_match_id, NEW.client_id, v_system_content, 'system');
    end if;
  end if;

  return NEW;
end;
$$ language plpgsql;

drop trigger if exists on_task_status_chat_sync on tasks;
create trigger on_task_status_chat_sync
after update on tasks
for each row
execute function handle_task_status_chat_updates();
