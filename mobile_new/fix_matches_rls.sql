-- Enable RLS
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;

-- Allow Users to View their own matches (Client or Worker)
DROP POLICY IF EXISTS "Users can view own matches" ON matches;
CREATE POLICY "Users can view own matches" ON matches
  FOR SELECT USING (
    auth.uid() = client_id OR auth.uid() = worker_id
  );

-- Allow Clients to Create Matches
DROP POLICY IF EXISTS "Clients can create matches" ON matches;
CREATE POLICY "Clients can create matches" ON matches
  FOR INSERT WITH CHECK (
    auth.uid() = client_id
  );

-- Allow Updates (e.g. status change)
DROP POLICY IF EXISTS "Participants can update matches" ON matches;
CREATE POLICY "Participants can update matches" ON matches
  FOR UPDATE USING (
    auth.uid() = client_id OR auth.uid() = worker_id
  );

-- Fix Swipes RLS while we are at it
ALTER TABLE swipes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own swipes" ON swipes;
CREATE POLICY "Users can view own swipes" ON swipes
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create swipes" ON swipes;
CREATE POLICY "Users can create swipes" ON swipes
  FOR INSERT WITH CHECK (auth.uid() = user_id);
