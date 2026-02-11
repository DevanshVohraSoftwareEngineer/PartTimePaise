
-- ========================================================
-- 🛡️ MATCH FLOW FIX: BRIDGE SWIPES TO BIDS
-- 💡 RUN THIS IN SUPABASE SQL EDITOR 💡
-- ========================================================

-- 1. Trigger Function to sync Swipes -> Bids
-- This ensures task owners see "Likes" from the feed in their "Interested" section
CREATE OR REPLACE FUNCTION sync_swipe_to_bid()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.direction = 'right' THEN
    -- Get user name from profiles for the bid record
    -- (Bids table usually has worker_name denormalized for speed)
    INSERT INTO bids (task_id, worker_id, amount, message, status, worker_face_url)
    SELECT 
      NEW.task_id, 
      NEW.user_id, 
      (SELECT budget FROM tasks WHERE id = NEW.task_id), -- Default to task budget
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

-- 3. Ensure "create_match_secure" works for Instant Match
CREATE OR REPLACE FUNCTION create_match_secure(p_task_id UUID, p_worker_id UUID)
RETURNS UUID AS $$
DECLARE
  v_match_id UUID;
  v_client_id UUID;
BEGIN
  -- 1. Get client ID
  SELECT client_id INTO v_client_id FROM tasks WHERE id = p_task_id;
  
  -- 2. Insert Match
  INSERT INTO matches (task_id, client_id, worker_id, status)
  VALUES (p_task_id, v_client_id, p_worker_id, 'active')
  ON CONFLICT (task_id, worker_id) DO UPDATE SET status = 'active'
  RETURNING id INTO v_match_id;

  -- 3. Update Task Status
  UPDATE tasks SET 
    status = 'assigned', 
    worker_id = p_worker_id 
  WHERE id = p_task_id;

  -- 4. Send System Message
  INSERT INTO chat_messages (match_id, sender_id, content, type)
  VALUES (v_match_id, v_client_id, 'You matched! Start the conversation.', 'system');

  RETURN v_match_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
