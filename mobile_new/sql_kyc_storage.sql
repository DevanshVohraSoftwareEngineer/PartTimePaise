-- 0. Create the Storage Bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('chat_assets', 'chat_assets', true)
ON CONFLICT (id) DO NOTHING;

-- 1. Ensure Profiles table has KYC columns
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS verified BOOLEAN DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS id_card_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS selfie_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS selfie_with_id_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS verification_status TEXT; -- 'pending', 'verified', 'rejected'

-- 1b. Ensure Tasks table has require_selfie column
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS require_selfie BOOLEAN DEFAULT false;

-- 2. Create id_verifications table for audit trail
CREATE TABLE IF NOT EXISTS id_verifications (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  selfie_url text,
  id_card_url text,
  selfie_with_id_url text,
  status text DEFAULT 'pending',
  extracted_data jsonb DEFAULT '{}',
  created_at timestamp with time zone DEFAULT now()
);

-- Ensure all columns exist in id_verifications (in case table was created previously)
ALTER TABLE id_verifications ADD COLUMN IF NOT EXISTS selfie_url TEXT;
ALTER TABLE id_verifications ADD COLUMN IF NOT EXISTS id_card_url TEXT;
ALTER TABLE id_verifications ADD COLUMN IF NOT EXISTS selfie_with_id_url TEXT;
ALTER TABLE id_verifications ADD COLUMN IF NOT EXISTS extracted_data JSONB DEFAULT '{}';

-- 2. Add indexes for faster fetching in chats
CREATE INDEX IF NOT EXISTS idx_id_verifications_user_id ON id_verifications(user_id);

-- 3. Enable RLS for id_verifications
ALTER TABLE id_verifications ENABLE ROW LEVEL SECURITY;

-- 4. Policies for id_verifications
-- Allow users to view their own verification status
DROP POLICY IF EXISTS "Users can view their own verification" ON id_verifications;
CREATE POLICY "Users can view their own verification" 
ON id_verifications FOR SELECT 
USING (auth.uid() = user_id);

-- Allow admins to see all (if roles are used)
DROP POLICY IF EXISTS "Admins can view all verification" ON id_verifications;
CREATE POLICY "Admins can view all verification" 
ON id_verifications FOR ALL 
USING (EXISTS (
  SELECT 1 FROM profiles 
  WHERE id = auth.uid() AND role = 'admin'
));

-- 5. Storage Policies for 'chat_assets' bucket

-- Policy: Authenticated users can upload to kyc/ folder
DROP POLICY IF EXISTS "Allow KYC Uploads" ON storage.objects;
CREATE POLICY "Allow KYC Uploads"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'chat_assets' AND (storage.foldername(name))[1] = 'kyc');

-- Policy: Authenticated users can upload to chat_media/ folder
DROP POLICY IF EXISTS "Allow Chat Media Uploads" ON storage.objects;
CREATE POLICY "Allow Chat Media Uploads"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'chat_assets' AND (storage.foldername(name))[1] = 'chat_media');

-- Policy: Allow users to delete their own uploads
DROP POLICY IF EXISTS "Users can delete own assets" ON storage.objects;
CREATE POLICY "Users can delete own assets"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'chat_assets' AND (storage.foldername(name))[2] = auth.uid()::text);

-- Policy: Public read for KYC and Chat assets
DROP POLICY IF EXISTS "Public Asset View" ON storage.objects;
CREATE POLICY "Public Asset View"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'chat_assets');
