
-- ========================================================
-- 🛡️ ULTIMATE DATABASE FIX (STORAGE + NOTIFICATIONS + CHAT)
-- 💡 MUST CLEAR THE SQL EDITOR COMPLETELY BEFORE PASTING 💡
-- ========================================================

-- PART 1: NOTIFICATIONS RLS FIX (Failed to post task)
-- --------------------------------------------------------

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Allow Users to View Own Notifications
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
CREATE POLICY "Users can view own notifications" 
ON notifications FOR SELECT 
USING (auth.uid() = user_id);

-- Allow Authenticated Users to Insert Notifications (Critical for Dispatch)
-- This allows the dispatcher to create alerts for other users.
DROP POLICY IF EXISTS "Users can insert notifications" ON notifications;
CREATE POLICY "Users can insert notifications" 
ON notifications FOR INSERT 
WITH CHECK (auth.role() = 'authenticated');

-- Update Dispatch Trigger to be SECURITY DEFINER
-- This ensures the function runs with elevated service privileges.
CREATE OR REPLACE FUNCTION execute_task_dispatch()
RETURNS TRIGGER AS $$
BEGIN
  IF COALESCE(ARRAY_LENGTH(NEW.candidate_ids, 1), 0) > 0 THEN
    -- Insert gig requests
    INSERT INTO gig_requests (task_id, worker_id, status, expires_at)
    SELECT NEW.id, id, 'pending', now() + interval '24 hours'
    FROM UNNEST(NEW.candidate_ids) as id;

    -- Create Notifications for individual candidates
    INSERT INTO notifications (user_id, type, title, message, data, is_read)
    SELECT 
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
    FROM UNNEST(NEW.candidate_ids) as id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions to authenticated users
GRANT ALL ON notifications TO authenticated;


-- PART 2: NO-EXCUSES FINAL STORAGE FIX (User Provided)
-- --------------------------------------------------------

-- 1. Create Buckets
INSERT INTO storage.buckets (id, name, public) VALUES ('task_verifications', 'task_verifications', true) 
ON CONFLICT (id) DO UPDATE SET public = true;
INSERT INTO storage.buckets (id, name, public) VALUES ('kyc_documents', 'kyc_documents', true) 
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. Clean Slate (Robust Drop)
-- We drop these one by one to ensure no name collisions.
DROP POLICY IF EXISTS "Final_Upload_Policy" ON storage.objects;
DROP POLICY IF EXISTS "Final_Select_Policy" ON storage.objects;
DROP POLICY IF EXISTS "Unstoppable Upload" ON storage.objects;
DROP POLICY IF EXISTS "Catch_All_Insert" ON storage.objects;
DROP POLICY IF EXISTS "Open_Upload" ON storage.objects;
DROP POLICY IF EXISTS "Final_Fix_Insert" ON storage.objects;
DROP POLICY IF EXISTS "GodMode_Insert" ON storage.objects;
DROP POLICY IF EXISTS "Global_Auth_Access" ON storage.objects;

-- 3. THE "ANYBODY LOGGED IN CAN UPLOAD" POLICY
CREATE POLICY "Final_Upload_Policy" 
ON storage.objects FOR INSERT 
TO authenticated 
WITH CHECK (bucket_id IN ('task_verifications', 'kyc_documents'));

CREATE POLICY "Final_Select_Policy" 
ON storage.objects FOR SELECT 
TO public 
USING (bucket_id IN ('task_verifications', 'kyc_documents'));


-- PART 3: CHAT CLEANUP (Optional but requested)
-- --------------------------------------------------------

CREATE OR REPLACE FUNCTION cleanup_chats() 
RETURNS void AS $$ 
BEGIN 
  DELETE FROM chat_messages 
  WHERE id IN (
    SELECT m.id 
    FROM chat_messages m 
    JOIN matches ma ON m.match_id = ma.id 
    WHERE ma.created_at < NOW() - INTERVAL '12 hours'
  ); 
END; 
$$ LANGUAGE plpgsql;

-- Grant execute to authenticated users (if needed to call via RPC)
GRANT EXECUTE ON FUNCTION cleanup_chats() TO authenticated;

-- PART 4: MATCH FLOW FIX (Bridge Swipes -> Bids + Instant Match)
-- --------------------------------------------------------

-- 1. Trigger Function to sync Swipes -> Bids
CREATE OR REPLACE FUNCTION sync_swipe_to_bid()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.direction = 'right' THEN
    INSERT INTO bids (task_id, worker_id, amount, message, status, worker_face_url)
    SELECT 
      NEW.task_id, 
      NEW.user_id, 
      (SELECT budget FROM tasks WHERE id = NEW.task_id),
      'Interested for this gig!',
      'pending',
      (SELECT selfie_url FROM profiles WHERE id = NEW.user_id)
    ON CONFLICT (task_id, worker_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Attach Trigger
DROP TRIGGER IF EXISTS on_swipe_right ON swipes;
CREATE TRIGGER on_swipe_right
AFTER INSERT OR UPDATE ON swipes
FOR EACH ROW EXECUTE FUNCTION sync_swipe_to_bid();

-- 3. Secure Match RPC (Used for Instant Match & Manual Accept)
CREATE OR REPLACE FUNCTION create_match_secure(p_task_id UUID, p_worker_id UUID)
RETURNS UUID AS $$
DECLARE
  v_match_id UUID;
  v_client_id UUID;
BEGIN
  SELECT client_id INTO v_client_id FROM tasks WHERE id = p_task_id;
  
  INSERT INTO matches (task_id, client_id, worker_id, status)
  VALUES (p_task_id, v_client_id, p_worker_id, 'active')
  ON CONFLICT (task_id, worker_id) DO UPDATE SET status = 'active'
  RETURNING id INTO v_match_id;

  UPDATE tasks SET status = 'assigned', worker_id = p_worker_id WHERE id = p_task_id;

  INSERT INTO chat_messages (match_id, sender_id, content, type)
  VALUES (v_match_id, v_client_id, 'You matched! Start the conversation.', 'system');

  RETURN v_match_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute to authenticated
GRANT EXECUTE ON FUNCTION create_match_secure(UUID, UUID) TO authenticated;

-- ========================================================
-- FINISHED: RUN THIS IN SUPABASE SQL EDITOR
-- ========================================================
