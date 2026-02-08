-- ========================================================
-- SURGICAL FIX: CHAT & CONNECTION STABILITY
-- ========================================================

-- 1. ADD MISSING RLS: Allow the 'assigned' worker to see the task details
-- This prevents the "vanish" effect when a match is made.
DROP POLICY IF EXISTS "Workers can view assigned tasks" ON tasks;
CREATE POLICY "Workers can view assigned tasks"
ON public.tasks FOR SELECT
USING (auth.uid() = worker_id);

-- 2. HARDEN MATCHES: Prevent duplicate match records for one pair
-- First, clean up any existing duplicates (keep only the latest one)
DELETE FROM public.matches 
WHERE id IN (
    SELECT id FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY task_id, worker_id ORDER BY created_at DESC) as row_num
        FROM public.matches
    ) t
    WHERE t.row_num > 1
);

ALTER TABLE public.matches DROP CONSTRAINT IF EXISTS matches_task_worker_unique;
ALTER TABLE public.matches ADD CONSTRAINT matches_task_worker_unique UNIQUE (task_id, worker_id);

-- 3. UPGRADE VIEW: Ensure chat entries never "Ghost" due to data lag
DROP VIEW IF EXISTS public.enriched_matches CASCADE;
CREATE OR REPLACE VIEW public.enriched_matches AS
WITH latest_messages AS (
    SELECT DISTINCT ON (match_id)
        match_id,
        content AS last_message,
        created_at AS last_message_at
    FROM public.chat_messages
    ORDER BY match_id, created_at DESC
)
SELECT 
  m.*,
  t.title as task_title,
  t.budget as task_budget,
  t.status as task_status,
  wp.name as worker_name,
  wp.avatar_url as worker_avatar,
  cp.name as client_name,
  cp.avatar_url as client_avatar,
  lm.last_message,
  lm.last_message_at
FROM public.matches m
LEFT JOIN public.tasks t ON m.task_id = t.id
LEFT JOIN public.profiles wp ON m.worker_id = wp.id
LEFT JOIN public.profiles cp ON m.client_id = cp.id
LEFT JOIN latest_messages lm ON m.id = lm.match_id;

GRANT SELECT ON public.enriched_matches TO authenticated;

-- 4. HARDEN TRIGGER: Protect against "query returned more than one row" errors
CREATE OR REPLACE FUNCTION public.handle_task_status_chat_updates()
RETURNS trigger AS $$
DECLARE
  v_match_id uuid;
  v_system_content text;
BEGIN
  SELECT id INTO v_match_id FROM matches WHERE task_id = NEW.id LIMIT 1;

  IF v_match_id IS NOT NULL THEN
    IF NEW.status = 'assigned' AND OLD.status != 'assigned' THEN
      v_system_content := 'Chat secure. Worker assigned.';
    ELSIF NEW.status = 'in_progress' AND OLD.status != 'in_progress' THEN
      v_system_content := 'Working on it! Deal finalized.';
    ELSIF NEW.status = 'completed' THEN
      v_system_content := 'Task completed successfully.';
    ELSIF NEW.status = 'cancelled' THEN
      v_system_content := 'Task cancelled.';
    END IF;

    IF v_system_content IS NOT NULL THEN
      INSERT INTO chat_messages (match_id, sender_id, content, type)
      VALUES (v_match_id, NEW.client_id, v_system_content, 'system');
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

