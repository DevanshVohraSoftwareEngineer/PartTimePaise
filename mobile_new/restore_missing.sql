
-- --------------------------------------------------------
-- MISSING: MATCHES TABLE (Restored)
-- --------------------------------------------------------
create table if not exists matches (
  id uuid default gen_random_uuid() primary key,
  task_id uuid references tasks(id),
  client_id uuid references profiles(id),
  worker_id uuid references profiles(id),
  status text default 'active',
  created_at timestamp with time zone default now()
);

-- MISSING: Search Radius for Zomato Logic
alter table tasks add column if not exists search_radius_meters integer default 2000;
alter table tasks add column if not exists candidate_ids uuid[] default '{}';
alter table tasks add column if not exists dispatch_index integer default 0;
alter table tasks add column if not exists retry_count integer default 0;
alter table tasks add column if not exists last_retry_at timestamp with time zone;

