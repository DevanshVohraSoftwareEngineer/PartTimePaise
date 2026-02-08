-- ==========================================
-- FIX: Task Status Constraint
-- ==========================================

-- The previous constraint likely missed 'assigned' or 'broadcasting', causing errors.
-- This script updates the constraint to allow all valid statuses.

-- 1. Drop the old constraint
ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS tasks_status_check;

-- 2. Add the corrected constraint
ALTER TABLE public.tasks ADD CONSTRAINT tasks_status_check 
CHECK (status IN (
  'open', 
  'broadcasting', 
  'assigned', 
  'in_progress', 
  'completed', 
  'cancelled'
));

-- 3. Verify (Optional comment)
-- If this runs successfully, the "assigned" status error will be resolved.
