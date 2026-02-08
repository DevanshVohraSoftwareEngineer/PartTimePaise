-- ==========================================

-- PartTimePaise Supabase Schema (Consolidated)

-- ==========================================



-- Enable PostGIS for location support

create extension if not exists postgis;



-- --------------------------------------------------------

-- 1. PROFILES & AUTH

-- --------------------------------------------------------

create table if not exists profiles (

  id uuid primary key, -- REMOVED references auth.users to allow Debug Users & Offline Testing

  email text,

  name text,

  role text default 'worker', -- 'client', 'worker', 'admin'

  avatar_url text,

  bio text,

  college text,

  phone text,

  city text,

  

  -- Wallet & Stats

  wallet_balance double precision default 0.0,

  rating double precision default 0.0,

  reliability_score integer default 100, -- 0-100 rating based on completion/cancellation

  acceptance_rate double precision default 1.0, -- 0.0-1.0 rate of accepting offered gigs

  completed_tasks integer default 0,

  last_order_at timestamp with time zone, -- Fairness check

  verified boolean default false,



  -- Live Tracking & Status

  is_online boolean default false,

  is_busy boolean default false, -- Currently on a trip

  service_radius_meters integer default 5000,

  current_lat double precision,

  current_lng double precision,

  last_seen timestamp with time zone,



  created_at timestamp with time zone default now(),

  updated_at timestamp with time zone default now()

);



-- ROBUST COMPATIBILITY: Ensure columns exist if table already exists

-- REMOVE FOREIGN KEY CONSTRAINT to allow Debug Users (Bypass mode)
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;

alter table profiles add column if not exists is_online boolean default false;

alter table profiles add column if not exists is_busy boolean default false;

alter table profiles add column if not exists last_order_at timestamp with time zone;

alter table profiles add column if not exists service_radius_meters integer default 5000;

alter table profiles add column if not exists current_lat double precision;

alter table profiles add column if not exists current_lng double precision;

alter table profiles add column if not exists last_seen timestamp with time zone;

alter table profiles add column if not exists wallet_balance double precision default 0.0;

alter table profiles add column if not exists rating double precision default 0.0;

alter table profiles add column if not exists completed_tasks integer default 0;

alter table profiles add column if not exists verified boolean default false;

alter table profiles add column if not exists id_card_url text;

alter table profiles add column if not exists selfie_url text;

alter table profiles add column if not exists verification_status text; -- 'pending', 'verified', 'rejected'



-- ========================================

-- PHASE 2: SMART SCORING METRICS 🧠

-- ========================================

alter table profiles add column if not exists acceptance_rate double precision default 1.0;

alter table profiles add column if not exists completion_rate double precision default 1.0;

alter table profiles add column if not exists avg_completion_time_minutes integer;

alter table profiles add column if not exists cancellation_count integer default 0;

alter table profiles add column if not exists fatigue_score double precision default 0.0;

alter table profiles add column if not exists total_offers_received integer default 0;

alter table profiles add column if not exists total_offers_accepted integer default 0;



-- Support legacy/static location fields if used by app

alter table profiles add column if not exists latitude double precision;

alter table profiles add column if not exists longitude double precision;

alter table profiles add column if not exists lat double precision; -- some legacy code might use this

alter table profiles add column if not exists lng double precision; -- some legacy code might use this



-- Index for location searches

create index if not exists profiles_location_idx on profiles using gist (

  st_setsrid(st_makepoint(current_lng, current_lat), 4326)

);



-- --------------------------------------------------------

-- 2. TASKS (Gigs)

-- --------------------------------------------------------

create table if not exists tasks (

  id uuid default gen_random_uuid() primary key,

  client_id uuid references profiles(id) on delete cascade not null,

  worker_id uuid references profiles(id), -- Assigned worker

  

  -- Core Info

  title text not null,

  description text not null,

  category text not null,

  type text default 'general', -- 'delivery', 'cleaning'

  status text default 'open', -- 'open', 'broadcasting', 'assigned', 'in_progress', 'completed', 'cancelled'

  

  -- Ranking and Dispatch (Zomato Style)

  candidate_ids uuid[] default '{}', -- Ordered list of workers to offer tasks to

  dispatch_index integer default 0,   -- Current candidate index being offered

  search_radius_meters integer default 2000, -- Starting radius for matching

  

  -- Budget & Timing

  budget double precision not null,

  budget_type text default 'fixed',

  deadline timestamp with time zone,

  urgency text check (urgency in ('asap', 'today')), -- Simplified to ASAP (60min) or Today (10hr)

  estimated_time_minutes integer,

  expires_at timestamp with time zone, -- Auto-calculated based on urgency



  -- Location Info

  location text, -- Human readable address

  pickup_lat double precision,

  pickup_lng double precision,

  dropoff_lat double precision,

  dropoff_lng double precision,

  distance_km double precision,



  -- Anti-Scam Security

  start_otp text,

  end_otp text,



  -- Media & Proofs

  image_url text,

  images text[],

  client_face_url text,      -- Face of person who posted

  client_id_card_url text,   -- ID of person who posted

  

  -- Stats

  bids_count integer default 0,

  reach_count integer default 0, -- Total accounts reached

  realtime_viewers_count integer default 0, -- Current active viewers

  

  created_at timestamp with time zone default now(),

  updated_at timestamp with time zone default now(),

  completed_at timestamp with time zone

);



-- ROBUST COMPATIBILITY: Ensure columns exist if table already exists

alter table tasks add column if not exists completed_at timestamp with time zone;

-- Backfill completed_at for existing tasks
update tasks set completed_at = updated_at where status = 'completed' and completed_at is null;

alter table tasks add column if not exists type text default 'general';

-- Automatically set completed_at when status becomes 'completed'
create or replace function set_task_completed_at()
returns trigger as $$
begin
  if NEW.status = 'completed' and (OLD.status is null or OLD.status != 'completed') then
    NEW.completed_at = now();
  end if;
  return NEW;
end;
$$ language plpgsql;

drop trigger if exists on_task_completed_set_timestamp on tasks;
create trigger on_task_completed_set_timestamp
before update on tasks
for each row
execute function set_task_completed_at();

alter table tasks add column if not exists pickup_lat double precision;

alter table tasks add column if not exists pickup_lng double precision;

alter table tasks add column if not exists dropoff_lat double precision;

alter table tasks add column if not exists dropoff_lng double precision;

alter table tasks add column if not exists distance_km double precision;

alter table tasks add column if not exists start_otp text;

alter table tasks add column if not exists end_otp text;

alter table tasks add column if not exists worker_id uuid references profiles(id);

alter table tasks add column if not exists candidate_ids uuid[] default '{}';

alter table tasks add column if not exists dispatch_index integer default 0;

alter table tasks add column if not exists search_radius_meters integer default 2000;

alter table tasks add column if not exists client_face_url text;

alter table tasks add column if not exists client_id_card_url text;

alter table tasks add column if not exists image_url text;

alter table tasks add column if not exists images text[];

alter table tasks add column if not exists urgency text;

alter table tasks add column if not exists expires_at timestamp with time zone;

alter table tasks add column if not exists client_verification_status text default 'pending';

alter table tasks add column if not exists reach_count integer default 0;
alter table tasks add column if not exists realtime_viewers_count integer default 0;
alter table tasks add column if not exists viewed_by_ids uuid[] default '{}';

-- Functions to track analytics
create or replace function track_task_view(t_id uuid, u_id uuid)
returns void as $$
begin
  update tasks
  set 
    viewed_by_ids = array_append(viewed_by_ids, u_id),
    reach_count = reach_count + 1
  where id = t_id 
  and not (viewed_by_ids @> array[u_id]);
end;
$$ language plpgsql security definer;

-- Realtime Viewer Counter Function
DROP FUNCTION IF EXISTS update_realtime_viewers(uuid, integer);
create or replace function update_realtime_viewers(t_id uuid, increment_val integer)
returns void as $$
begin
  update tasks
  set realtime_viewers_count = greatest(0, realtime_viewers_count + increment_val)
  where id = t_id;
end;
$$ language plpgsql security definer;


-- ========================================

-- PHASE 4: SMART RETRY TRACKING ⚡

-- ========================================

alter table tasks add column if not exists retry_count integer default 0;

alter table tasks add column if not exists last_retry_at timestamp with time zone;



-- Index for task queries

create index if not exists tasks_status_idx on tasks(status);

create index if not exists tasks_client_idx on tasks(client_id);



-- ========================================

-- PHASE 1: STATE MACHINE ENFORCEMENT 🔒

-- ========================================



-- Valid state transitions (Zomato-style strict enforcement)

create table if not exists task_state_transitions (

  from_status text not null,

  to_status text not null,

  primary key (from_status, to_status)

);



-- Define allowed transitions

insert into task_state_transitions (from_status, to_status) values

  ('open', 'broadcasting'),

  ('open', 'assigned'),        -- Direct assignment (manual accept)

  ('open', 'cancelled'),        -- Client cancels before assignment

  ('broadcasting', 'assigned'), -- Worker accepts from dispatch

  ('broadcasting', 'open'),     -- Retry fallback (all rejected)

  ('broadcasting', 'cancelled'),

  ('assigned', 'in_progress'),  -- Worker starts the task

  ('assigned', 'cancelled'),    -- Cancellation after assignment

  ('in_progress', 'completed'), -- Successful completion

  ('in_progress', 'cancelled')  -- Cancellation during work

on conflict do nothing;



-- Enforce state machine (prevent invalid transitions)

create or replace function validate_task_state_transition()

returns trigger as $$

begin

  -- Only validate if status is actually changing

  if OLD.status != NEW.status then

    -- Check if this transition is allowed

    if not exists (

      select 1 from task_state_transitions 

      where from_status = OLD.status and to_status = NEW.status

    ) then

      raise exception 'Invalid state transition: % → % (task_id: %)', 

        OLD.status, NEW.status, NEW.id;

    end if;

  end if;

  return NEW;

end;

$$ language plpgsql;



drop trigger if exists enforce_task_state_machine on tasks;

create trigger enforce_task_state_machine

before update on tasks

for each row

execute function validate_task_state_transition();



-- ========================================

-- PHASE 3: EVENT SOURCING 📡

-- ========================================



-- Event log for analytics, ML, and debugging

create table if not exists task_events (

  id uuid default gen_random_uuid() primary key,

  task_id uuid references tasks(id) on delete cascade not null,

  event_type text not null, -- 'CREATED', 'ASSIGNED', 'REJECTED', 'COMPLETED', 'CANCELLED'

  actor_id uuid references profiles(id),

  metadata jsonb default '{}'::jsonb,

  created_at timestamp with time zone default now()

);



create index if not exists task_events_task_id_idx on task_events(task_id, created_at desc);

create index if not exists task_events_type_idx on task_events(event_type, created_at desc);

create index if not exists task_events_actor_idx on task_events(actor_id, created_at desc);



-- Auto-emit events on task creation

create or replace function emit_task_created_event()

returns trigger as $$

begin

  insert into task_events (task_id, event_type, actor_id, metadata)

  values (NEW.id, 'TASK_CREATED', NEW.client_id, jsonb_build_object(

    'urgency', NEW.urgency,

    'budget', NEW.budget,

    'title', NEW.title

  ));

  return NEW;

end;

$$ language plpgsql;



drop trigger if exists on_task_created_event on tasks;

create trigger on_task_created_event

after insert on tasks

for each row

execute function emit_task_created_event();



-- ========================================

-- PHASE 5: REAL-TIME TRACKING 📍

-- ========================================



-- Location heartbeat log for live tracking and route analysis

create table if not exists location_updates (

  id uuid default gen_random_uuid() primary key,

  rider_id uuid references profiles(id) on delete cascade not null,

  task_id uuid references tasks(id) on delete cascade,

  lat double precision not null,

  lng double precision not null,

  speed double precision, -- m/s

  accuracy double precision, -- meters

  bearing double precision, -- degrees

  created_at timestamp with time zone default now()

);



-- Partition-ready indexes for high-volume inserts

create index if not exists location_updates_rider_time_idx on location_updates(rider_id, created_at desc);

create index if not exists location_updates_task_time_idx on location_updates(task_id, created_at desc);



-- Route deviation detection function

create or replace function detect_route_deviation(

  p_rider_id uuid,

  p_task_id uuid,

  p_threshold_meters double precision default 500

)

returns boolean as $$

declare

  v_expected_location geography;

  v_actual_location geography;

  v_deviation_meters double precision;

begin

  -- Get expected location (task pickup/dropoff)

  select st_setsrid(st_makepoint(pickup_lng, pickup_lat), 4326)::geography

  into v_expected_location

  from tasks

  where id = p_task_id;



  -- Get latest actual location

  select st_setsrid(st_makepoint(lng, lat), 4326)::geography

  into v_actual_location

  from location_updates

  where rider_id = p_rider_id and task_id = p_task_id

  order by created_at desc

  limit 1;



  -- Calculate deviation

  v_deviation_meters := st_distance(v_expected_location, v_actual_location);



  return v_deviation_meters > p_threshold_meters;

end;

$$ language plpgsql stable;



-- ========================================

-- PHASE 6: ANALYTICS LAYER 📊

-- ========================================



-- Dispatch performance metrics for ML training and optimization

create table if not exists dispatch_analytics (

  id uuid default gen_random_uuid() primary key,

  task_id uuid references tasks(id) on delete cascade not null,

  

  -- Timing metrics

  time_to_first_offer interval,

  time_to_acceptance interval,

  total_offers_sent integer default 0,

  total_rejections integer default 0,

  

  -- Radius metrics

  initial_radius_meters integer,

  final_radius_meters integer,

  radius_expansions integer default 0,

  

  -- Winner metrics

  winning_rider_id uuid references profiles(id),

  winning_rider_distance_km double precision,

  winning_rider_score double precision,

  

  -- Outcome

  dispatch_outcome text, -- 'accepted', 'timeout', 'cancelled'

  

  created_at timestamp with time zone default now()

);



create index if not exists dispatch_analytics_task_idx on dispatch_analytics(task_id);

create index if not exists dispatch_analytics_outcome_idx on dispatch_analytics(dispatch_outcome, created_at desc);

create index if not exists dispatch_analytics_time_idx on dispatch_analytics(created_at desc);



-- Auto-track dispatch analytics on task assignment

create or replace function track_dispatch_analytics()

returns trigger as $$

declare

  v_first_offer_time timestamp with time zone;

  v_total_offers integer;

  v_total_rejections integer;

begin

  -- Only track when task gets assigned

  if NEW.status = 'assigned' and OLD.status != 'assigned' then

    

    -- Get first offer time

    select min(created_at) into v_first_offer_time

    from gig_requests

    where task_id = NEW.id;

    

    -- Count offers and rejections

    select count(*), count(*) filter (where status = 'rejected')

    into v_total_offers, v_total_rejections

    from gig_requests

    where task_id = NEW.id;

    

    -- Insert analytics record

    insert into dispatch_analytics (

      task_id,

      time_to_first_offer,

      time_to_acceptance,

      total_offers_sent,

      total_rejections,

      initial_radius_meters,

      final_radius_meters,

      radius_expansions,

      winning_rider_id,

      dispatch_outcome

    ) values (

      NEW.id,

      v_first_offer_time - NEW.created_at,

      now() - NEW.created_at,

      v_total_offers,

      v_total_rejections,

      2000, -- default initial radius

      NEW.search_radius_meters,

      NEW.retry_count,

      NEW.worker_id,

      'accepted'

    );

  end if;

  

  return NEW;

end;

$$ language plpgsql;



drop trigger if exists track_dispatch_analytics_trigger on tasks;

create trigger track_dispatch_analytics_trigger

after update on tasks

for each row

execute function track_dispatch_analytics();



-- --------------------------------------------------------

-- 3. GIG REQUESTS (Real-time Dispatch)

-- --------------------------------------------------------

create table if not exists gig_requests (

  id uuid default gen_random_uuid() primary key,

  task_id uuid references tasks(id) on delete cascade,

  worker_id uuid references profiles(id) on delete cascade,

  status text default 'pending', -- 'pending', 'accepted', 'rejected', 'missed'

  expires_at timestamp with time zone not null,

  created_at timestamp with time zone default now(),

  

  unique(task_id, worker_id)

);



-- --------------------------------------------------------

-- 4. BIDS (For Traditional Marketplace Mode)

-- --------------------------------------------------------

create table if not exists bids (

  id uuid default gen_random_uuid() primary key,

  task_id uuid references tasks(id) on delete cascade,

  worker_id uuid references profiles(id) on delete cascade,

  amount double precision not null,

  message text,

  status text default 'pending', -- 'pending', 'accepted', 'rejected'

  created_at timestamp with time zone default now()

);



-- --------------------------------------------------------

-- 4. AI MEAL SCANNER (Persistent History)

-- --------------------------------------------------------

create table if not exists meal_scans (

  id uuid default gen_random_uuid() primary key,

  user_id uuid references profiles(id) on delete cascade not null,

  item_name text not null,

  calories integer default 0,

  protein text,

  carbs text,

  fats text,

  health_score integer,

  ai_insight text,

  proven_source text,

  image_url text,

  full_result jsonb,

  created_at timestamp with time zone default now()

);



-- Index for user history

create index if not exists meal_scans_user_id_idx on meal_scans(user_id);



-- Enable RLS for Meal Scans

alter table meal_scans enable row level security;



drop policy if exists "Users can view their own meal scans if exists" on meal_scans;
create policy "Users can view their own meal scans if exists"
  on meal_scans for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert their own meal scans if exists" on meal_scans;
create policy "Users can insert their own meal scans if exists"
  on meal_scans for insert
  with check (auth.uid() = user_id);



-- --------------------------------------------------------

-- 5. MATCHES & MESSAGES

-- --------------------------------------------------------

create table if not exists matches (

  id uuid default gen_random_uuid() primary key,

  task_id uuid references tasks(id),

  client_id uuid references profiles(id),

  worker_id uuid references profiles(id),

  status text default 'active',

  created_at timestamp with time zone default now()

);



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



-- Legacy 'messages' table back-compat (if needed, otherwise migrate to chat_messages)

create table if not exists messages (

  id uuid default gen_random_uuid() primary key,

  match_id text not null, -- Use text ID for flexibility or migrate to uuid

  sender_id uuid references profiles(id),

  content text,

  created_at timestamp with time zone default now()

);



-- --------------------------------------------------------

-- 6. SWIPES (Tinder UI)

-- --------------------------------------------------------

create table if not exists swipes (

  id uuid default gen_random_uuid() primary key,

  user_id uuid references profiles(id) on delete cascade,

  task_id uuid references tasks(id) on delete cascade,

  direction text not null, -- 'left', 'right'

  created_at timestamp with time zone default now(),

  unique(user_id, task_id)

);



-- --------------------------------------------------------

-- 7. NOTIFICATIONS

-- --------------------------------------------------------

create table if not exists notifications (

  id uuid default gen_random_uuid() primary key,

  user_id uuid references profiles(id) on delete cascade,

  title text not null,

  message text not null,

  type text default 'general',

  related_id text, -- e.g. task_id or match_id

  is_read boolean default false,

  is_archived boolean default false,

  created_at timestamp with time zone default now()

);



-- --------------------------------------------------------

-- 8. ID VERIFICATION (KYC)

-- --------------------------------------------------------

create table if not exists id_verifications (

  id uuid default gen_random_uuid() primary key,

  user_id uuid references profiles(id) on delete cascade,

  id_card_url text not null,

  selfie_url text not null,

  status text default 'pending', -- 'pending', 'verified', 'rejected'

  extracted_data jsonb,

  created_at timestamp with time zone default now(),

  updated_at timestamp with time zone default now()

);



-- ==========================================

-- REAL-TIME ENABLEMENT (Idempotent)

-- ==========================================

do $$

begin

  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'tasks') then

    alter publication supabase_realtime add table tasks;

  end if;

  

  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'gig_requests') then

    alter publication supabase_realtime add table gig_requests;

  end if;

  

  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'chat_messages') then

    alter publication supabase_realtime add table chat_messages;

  end if;



  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'messages') then

    alter publication supabase_realtime add table messages;

  end if;



  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'notifications') then

    alter publication supabase_realtime add table notifications;

  end if;



  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'id_verifications') then

    alter publication supabase_realtime add table id_verifications;

  end if;



  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'profiles') then

    alter publication supabase_realtime add table profiles;

  end if;

end $$;

-- ========================================



-- Enable RLS on all tables

alter table profiles enable row level security;

alter table tasks enable row level security;

alter table swipes enable row level security;

alter table matches enable row level security;

alter table chat_messages enable row level security;

alter table gig_requests enable row level security;



-- PROFILES: Everyone can view, users can update own

drop policy if exists "Users can view all profiles" on profiles;

create policy "Users can view all profiles"

on profiles for select

using (true);



drop policy if exists "Users can update own profile" on profiles;

create policy "Users can update own profile"

on profiles for update

using (auth.uid() = id);



-- TASKS: Users can create own, view own, and view all open tasks

drop policy if exists "Users can create tasks" on tasks;

create policy "Users can create tasks"

on tasks for insert

with check (auth.uid() = client_id);



drop policy if exists "Users can view own tasks" on tasks;

create policy "Users can view own tasks"

on tasks for select

using (auth.uid() = client_id);



drop policy if exists "Users can view all open tasks" on tasks;

create policy "Users can view all open tasks"

on tasks for select

using (status in ('open', 'broadcasting'));



drop policy if exists "Users can update own tasks" on tasks;

create policy "Users can update own tasks"

on tasks for update

using (auth.uid() = client_id);



drop policy if exists "Users can delete own tasks" on tasks;

create policy "Users can delete own tasks"

on tasks for delete

using (auth.uid() = client_id);



-- SWIPES: Users can create and view own swipes

drop policy if exists "Users can create swipes" on swipes;

create policy "Users can create swipes"

on swipes for insert

with check (auth.uid() = user_id);



drop policy if exists "Users can view own swipes" on swipes;

create policy "Users can view own swipes"

on swipes for select

using (auth.uid() = user_id);



drop policy if exists "Users can view swipes on their tasks" on swipes;

create policy "Users can view swipes on their tasks"

on swipes for select

using (

  exists (

    select 1 from tasks

    where tasks.id = swipes.task_id

    and tasks.client_id = auth.uid()

  )

);



-- MATCHES: Users can view and create matches they're part of

drop policy if exists "Users can view their matches" on matches;

create policy "Users can view their matches"

on matches for select

using (auth.uid() = client_id or auth.uid() = worker_id);



drop policy if exists "Users can create matches for their tasks" on matches;

create policy "Users can create matches for their tasks"

on matches for insert

with check (

  auth.uid() = client_id and

  exists (

    select 1 from tasks

    where tasks.id = task_id

    and tasks.client_id = auth.uid()

  )

);



-- CHAT MESSAGES: Users can send/view messages in their matches

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



-- GIG REQUESTS: Users can view and update their own requests

drop policy if exists "Users can view their gig requests" on gig_requests;

create policy "Users can view their gig requests"

on gig_requests for select

using (auth.uid() = worker_id);



drop policy if exists "Users can update their gig requests" on gig_requests;

create policy "Users can update their gig requests"

on gig_requests for update

using (auth.uid() = worker_id);



-- ========================================

-- INCOMING SWIPES VIEW (For Interested Tab) 👀

-- ========================================



drop view if exists public.incoming_swipes cascade;
create or replace view incoming_swipes as

select 

  s.id,

  s.task_id,

  s.user_id as worker_id,

  s.direction,

  s.created_at,

  t.title as task_title,

  t.budget as task_budget,

  t.client_id,

  p.name as worker_name,

  p.avatar_url as worker_avatar,

  p.rating as worker_rating,

  p.completed_tasks as worker_completed_tasks

from swipes s

join tasks t on s.task_id = t.id

join profiles p on s.user_id = p.id

where s.direction = 'right';



grant select on incoming_swipes to authenticated;







-- ==========================================

-- FUNCTIONS & TRIGGERS

-- ==========================================



-- A. OTP Generation Trigger

create or replace function generate_task_otps()

returns trigger as $$

begin

  -- Generate 4-digit OTPs when status changes to 'assigned'

  if NEW.status = 'assigned' and (OLD.status is null or OLD.status != 'assigned') then

    NEW.start_otp := floor(random() * (9999 - 1000 + 1) + 1000)::text;

    NEW.end_otp := floor(random() * (9999 - 1000 + 1) + 1000)::text;

  end if;

  return NEW;

end;

$$ language plpgsql;



-- Drop trigger if exists to allow clean recreate

drop trigger if exists on_task_assigned on tasks;



create trigger on_task_assigned

before update on tasks

for each row

execute function generate_task_otps();



-- ========================================

-- A. Smart Scoring Function (Zomato-Grade) 🧠

-- ========================================



-- Drop existing function to allow parameter name changes

drop function if exists calculate_rider_score(uuid, double precision, double precision);



create or replace function calculate_rider_score(

  rider_id uuid,

  task_lat double precision,

  task_lng double precision

)

returns double precision as $$

declare

  v_distance_km double precision;

  v_acceptance_rate double precision;

  v_completion_rate double precision;

  v_fatigue double precision;

  v_score double precision;

begin

  -- Fetch rider metrics and calculate distance

  select 

    st_distance(

      st_setsrid(st_makepoint(current_lng, current_lat), 4326),

      st_setsrid(st_makepoint(task_lng, task_lat), 4326)

    ) / 1000.0, -- Convert to km

    coalesce(acceptance_rate, 1.0),

    coalesce(completion_rate, 1.0),

    coalesce(fatigue_score, 0.0)

  into v_distance_km, v_acceptance_rate, v_completion_rate, v_fatigue

  from profiles

  where id = rider_id;



  -- Zomato-style weighted scoring (0-100 scale)

  v_score := 

    (1.0 / (v_distance_km + 0.1)) * 40 +  -- Distance (40%) - inverse, closer = better

    v_acceptance_rate * 30 +               -- Reliability (30%)

    v_completion_rate * 20 +               -- Quality (20%)

    (1.0 - v_fatigue) * 10;                -- Freshness (10%) - less fatigue = better



  return v_score;

end;

$$ language plpgsql stable;



-- B. Smart Dispatch Trigger (Preparation)

-- Sets candidate IDs and status BEFORE the row is fully inserted

create or replace function prepare_task_dispatch()

returns trigger as $$

declare

  v_candidates uuid[];

begin

  -- Only dispatch if task has valid coordinates

  if NEW.pickup_lat is null or NEW.pickup_lng is null then

    return NEW; -- Skip dispatch, keep as 'open'

  end if;



  -- RADICAL TRIAL RADIUS: Set starting radius to 50km for cohort sync

  if NEW.search_radius_meters is null then

    NEW.search_radius_meters := 50000; -- High density trial reach

  end if;



  -- 1. Find and Rank Nearby ONLINE workers (RELAXED for testing)

  select array_agg(id) into v_candidates

  from (

    select id

    from profiles

    where 

      is_online = true

      and is_busy = false

      and last_seen > (now() - interval '30 minutes') -- RELAXED from 2 min

      and current_lat is not null 

      and current_lng is not null

      and st_dwithin(

        st_makepoint(current_lng, current_lat)::geography,

        st_makepoint(NEW.pickup_lng, NEW.pickup_lat)::geography,

        NEW.search_radius_meters

      )

      and id != NEW.client_id

    order by 

      calculate_rider_score(id, NEW.pickup_lat, NEW.pickup_lng) desc

    limit 5

  ) as subquery;



  -- 2. Set the sequences

  NEW.candidate_ids := coalesce(v_candidates, '{}');

  NEW.dispatch_index := 0;

  

  -- 3. KEEP AS 'OPEN' for marketplace visibility (don't hide behind broadcasting)

  -- Tasks remain visible to everyone, targeted workers just get priority alerts



  return NEW;

end;

$$ language plpgsql security definer;



-- C. Smart Dispatch Trigger (Execution)

-- Sends ACTUAL gig requests and notifications AFTER the row is committed

create or replace function execute_task_dispatch()

returns trigger as $$

begin

  -- Send alerts to targeted workers WITHOUT hiding task from marketplace

  -- FIXED: coalesce for array_length to handle empty arrays

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

$$ language plpgsql security definer;



-- DROP AND RECREATE (Clean slate for split triggers)

drop trigger if exists on_task_created on tasks;

drop trigger if exists on_task_created_step1_prepare on tasks;

drop trigger if exists on_task_created_step2_execute on tasks;



create trigger on_task_created_step1_prepare

before insert on tasks

for each row

execute function prepare_task_dispatch();



create trigger on_task_created_step2_execute

after insert on tasks

for each row

execute function execute_task_dispatch();



-- B2. Cascade Dispatch with Smart Retry (Zomato-Grade) ⚡

-- Automatically offers to the NEXT candidate with exponential backoff

create or replace function cascade_dispatch_on_rejection()

returns trigger as $$

declare

  v_task tasks%rowtype;

  v_candidates uuid[];

  v_next_candidate uuid;

  v_backoff_seconds integer;

begin

  -- Only care about transitions from 'pending' to 'rejected' or 'missed'

  if (NEW.status = 'rejected' or NEW.status = 'missed') and OLD.status = 'pending' then

    select * into v_task from tasks where id = NEW.task_id for update;



    -- Only continue if task is still 'broadcasting' or 'open'

    if v_task.status = 'broadcasting' or v_task.status = 'open' then

      

      -- ========================================

      -- PHASE 4: EXPONENTIAL BACKOFF ⚡

      -- ========================================

      

      -- Calculate backoff: 10s, 30s, 60s, 120s (max)

      v_backoff_seconds := least(10 * power(2, v_task.retry_count), 120);

      

      -- Check if enough time has passed since last retry

      if v_task.last_retry_at is not null and 

         now() < v_task.last_retry_at + (v_backoff_seconds || ' seconds')::interval then

        return NEW; -- Too soon, skip this retry

      end if;

      

      -- Update retry tracking

      update tasks 

      set retry_count = retry_count + 1,

          last_retry_at = now()

      where id = v_task.id;

      

      -- Refresh task data after update

      select * into v_task from tasks where id = NEW.task_id;

      

      -- ========================================

      -- Continue with cascade logic

      -- ========================================

      

      -- Move to next index

      v_task.dispatch_index := v_task.dispatch_index + 1;

      v_candidates := v_task.candidate_ids;



      if v_task.dispatch_index < array_length(v_candidates, 1) then

        -- OFFER TO NEXT INDIVIDUAL CANDIDATE

        v_next_candidate := v_candidates[v_task.dispatch_index + 1];

        

        insert into gig_requests (task_id, worker_id, status, expires_at)

        values (v_task.id, v_next_candidate, 'pending', now() + interval '1 minute');



        update tasks set dispatch_index = v_task.dispatch_index where id = v_task.id;

      else

        -- REACHED END OF CURRENT CANDIDATES → EXPAND RADIUS

        v_task.search_radius_meters := v_task.search_radius_meters + 25000; -- Add 25km

        

        if v_task.search_radius_meters < 500000 then -- Cap at 500km (Whole region)

          -- Find NEW candidates in wider radius

          select array_agg(id) into v_candidates

          from (

            select id

            from profiles

            where 

              is_online = true

              and is_busy = false

              and id != v_task.client_id

              and st_dwithin(

                st_setsrid(st_makepoint(current_lng, current_lat), 4326),

                st_setsrid(st_makepoint(v_task.pickup_lng, v_task.pickup_lat), 4326),

                v_task.search_radius_meters

              )

            order by calculate_rider_score(id, v_task.pickup_lat, v_task.pickup_lng) desc

            limit 10

          ) as sub;



          if array_length(v_candidates, 1) > 0 then

            -- Update task with NEW candidates and NEW radius

            update tasks set 

              candidate_ids = v_candidates,

              dispatch_index = 0,

              search_radius_meters = v_task.search_radius_meters

            where id = v_task.id;



            -- Offer to the first new candidate

            insert into gig_requests (task_id, worker_id, status, expires_at)

            values (

              v_task.id,

              v_candidates[1],

              'pending',

              now() + interval '1 minute'

            );

          else

             -- Still no new candidates in wider radius? Return to 'open'

             update tasks set status = 'open', dispatch_index = 0 where id = v_task.id;

          end if;

        else

          -- REACHED MAX ESCALATION → Return to 'open' for general swiping

          update tasks set status = 'open', dispatch_index = 0 where id = v_task.id;

        end if;

      end if;



    end if;



  end if;

  return NEW;

end;

$$ language plpgsql security definer;



drop trigger if exists on_gig_request_rejected on gig_requests;

create trigger on_gig_request_rejected

after update on gig_requests

for each row

execute function cascade_dispatch_on_rejection();

-- ============================================
-- FIX: Grants & Permissions (Run this in SQL Editor)
-- ============================================

-- 1. Grant Permissions to Authenticated Users
grant usage on schema public to authenticated;
grant all on profiles to authenticated;
grant all on tasks to authenticated;
grant all on matches to authenticated;
grant all on chat_messages to authenticated;
grant all on swipes to authenticated;
grant all on gig_requests to authenticated;
grant all on notifications to authenticated;
grant all on id_verifications to authenticated;
grant all on location_updates to authenticated;
grant all on dispatch_analytics to authenticated;
grant all on bids to authenticated;
grant all on task_events to authenticated;

-- 2. Ensure Sequences are accessible (if any)
grant usage, select on all sequences in schema public to authenticated;

-- 3. Simplify Matches Policy (To rule out complex joins failing)
drop policy if exists "Users can create matches for their tasks" on matches;
create policy "Users can create matches for their tasks"
on matches for insert
with check (
  auth.uid() = client_id
);

-- 4. Ensure Chat Messages Policies exist
drop policy if exists "Users can send messages in their matches" on chat_messages;
create policy "Users can send messages in their matches"
on chat_messages for insert
with check (
  auth.uid() = sender_id
);

-- 5. Fix Task Ownership Policy just in case
drop policy if exists "Users can update own tasks" on tasks;
create policy "Users can update own tasks"
on tasks for update
using (auth.uid() = client_id);
-- ============================================
-- FIX: Grants & Permissions (Run this in SQL Editor)
-- ============================================

-- 1. Grant Permissions to Authenticated Users
grant usage on schema public to authenticated;
grant all on profiles to authenticated;
grant all on tasks to authenticated;
grant all on matches to authenticated;
grant all on chat_messages to authenticated;
grant all on swipes to authenticated;
grant all on gig_requests to authenticated;
grant all on notifications to authenticated;
grant all on id_verifications to authenticated;
grant all on location_updates to authenticated;
grant all on dispatch_analytics to authenticated;
grant all on bids to authenticated;
grant all on task_events to authenticated;

-- 2. Ensure Sequences are accessible (if any)
grant usage, select on all sequences in schema public to authenticated;

-- 3. Simplify Matches Policy (To rule out complex joins failing)
drop policy if exists "Users can create matches for their tasks" on matches;
create policy "Users can create matches for their tasks"
on matches for insert
with check (
  auth.uid() = client_id
);

-- 4. Ensure Chat Messages Policies exist
drop policy if exists "Users can send messages in their matches" on chat_messages;
create policy "Users can send messages in their matches"
on chat_messages for insert
with check (
  auth.uid() = sender_id
);

-- 5. Fix Task Ownership Policy just in case
drop policy if exists "Users can update own tasks" on tasks;
create policy "Users can update own tasks"
on tasks for update
using (auth.uid() = client_id);

-- 6. Add Missing Columns to Notifications
alter table notifications add column if not exists related_id text;
alter table notifications add column if not exists data jsonb default '{}'::jsonb;





-- C. Accept Gig Function

-- G. Chat Lifecycle Management (Step 6 & 9)

-- Automatically posts system messages and handles chat "closing" logic

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



    -- Insert system message if we have a status update (Step 6)

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



-- D. Verify OTP (Handshake)

create or replace function verify_task_otp(

  p_task_id uuid,

  p_otp_type text, -- 'start' or 'end'

  p_otp_value text,

  p_lat double precision,

  p_lng double precision

)

returns boolean as $$

declare

  v_task tasks%rowtype;

  v_pickup_pt geometry;

  v_worker_pt geometry;

  v_distance double precision;

begin

  select * into v_task from tasks where id = p_task_id;

  

  -- Geofence Check (200m)

  if v_task.pickup_lat is not null and v_task.pickup_lng is not null then

    v_pickup_pt := st_setsrid(st_makepoint(v_task.pickup_lng, v_task.pickup_lat), 4326);

    v_worker_pt := st_setsrid(st_makepoint(p_lng, p_lat), 4326);

    v_distance := st_distance(v_pickup_pt, v_worker_pt, true);

    

    if v_distance > 200 then

      raise exception 'Geofence Error: You are % meters away. Must be within 200m.', round(v_distance::numeric, 0);

    end if;

  end if;



  -- OTP Check

  if p_otp_type = 'start' then

    if v_task.start_otp = p_otp_value then

      update tasks set status = 'in_progress', updated_at = now() where id = p_task_id;

      return true;

    else

      raise exception 'Invalid Start OTP';

    end if;

  elsif p_otp_type = 'end' then

    if v_task.end_otp = p_otp_value then

      update tasks set status = 'completed', updated_at = now() where id = p_task_id;

      return true;

    else

      raise exception 'Invalid End OTP';

    end if;

  end if;



  return false;

end;

$$ language plpgsql security definer;



-- E. Get Nearby Tasks (RPC for Filtering)

create or replace function get_nearby_tasks(

  p_lat double precision,

  p_lng double precision,

  p_radius_meters double precision default 2000

)

returns table (

  id uuid,

  title text,

  description text,

  budget double precision,

  status text,

  image_url text, -- Added for UI

  distance_meters double precision,

  created_at timestamp with time zone,

  client_id uuid

) as $$

begin

  return query

  select

    t.id,

    t.title,

    t.description,

    t.budget,

    t.status,

    t.image_url,

    st_distance(

      st_setsrid(st_makepoint(t.pickup_lng, t.pickup_lat), 4326),

      st_setsrid(st_makepoint(p_lng, p_lat), 4326),

      true -- Use spheroid

    ) as distance_meters,

    t.created_at,

    t.client_id

  from tasks t

  where

    t.status = 'open'

    and t.pickup_lat is not null

    and t.pickup_lng is not null

    and st_dwithin(

      st_setsrid(st_makepoint(t.pickup_lng, t.pickup_lat), 4326),

      st_setsrid(st_makepoint(p_lng, p_lat), 4326),

      p_radius_meters -- Limit to radius (default 2km)

    )

  order by distance_meters asc;

end;

$$ language plpgsql security definer;



-- ==========================================

-- ROW LEVEL SECURITY (RLS) - Basic

-- ==========================================

-- Enable RLS on all tables

alter table profiles enable row level security;

alter table tasks enable row level security;

alter table gig_requests enable row level security;

alter table messages enable row level security;



-- Profiles: Locked down location visibility

drop policy if exists "Public profiles" on profiles;

drop policy if exists "Public profile info" on profiles;

create policy "Public profile info" on profiles for select 

using (true); -- Base info (name, etc) is public



-- ZOMATO STEP 8: Real-time Two-Way Tracking Privacy

-- Allow users to see the coordinates of others ONLY if they are matched

drop policy if exists "View matched partner location" on profiles;

create policy "View matched partner location" on profiles for select

using (

  exists (

    select 1 from matches 

    where (matches.client_id = auth.uid() and matches.worker_id = profiles.id)

       or (matches.worker_id = auth.uid() and matches.client_id = profiles.id)

       and matches.status = 'active'

  )

);



drop policy if exists "Users update own" on profiles;

create policy "Users update own" on profiles for update using (auth.uid() = id);



drop policy if exists "Users insert own" on profiles;

create policy "Users insert own" on profiles for insert with check (auth.uid() = id);



-- Tasks: Public read, Owner update

drop policy if exists "Public tasks" on tasks;

create policy "Public tasks" on tasks for select using (true);



drop policy if exists "Clients create tasks" on tasks;

create policy "Clients create tasks" on tasks for insert with check (auth.uid() = client_id);



drop policy if exists "Clients update own tasks" on tasks;

create policy "Clients update own tasks" on tasks for update using (auth.uid() = client_id OR auth.uid() = worker_id);



-- Gig Requests: Private (Worker sees own, Client sees task's)

drop policy if exists "Workers view own requests" on gig_requests;

create policy "Workers view own requests" on gig_requests for select 

using (auth.uid() = worker_id);



drop policy if exists "Clients view task requests" on gig_requests;

create policy "Clients view task requests" on gig_requests for select 

using (exists (select 1 from tasks where tasks.id = gig_requests.task_id and tasks.client_id = auth.uid()));



drop policy if exists "System insert requests" on gig_requests;

create policy "System insert requests" on gig_requests for insert with check (true); -- Triggers are security definer, this might be redundant but safe



drop policy if exists "Workers update own requests" on gig_requests;

create policy "Workers update own requests" on gig_requests for update using (auth.uid() = worker_id);



-- Matches: Participants only

alter table matches enable row level security;



drop policy if exists "View own matches" on matches;

create policy "View own matches" on matches for select 

using (auth.uid() = client_id OR auth.uid() = worker_id);



-- Chat Messages: Participants only + Assignment Check (Step 1 & 3)

drop policy if exists "View own chat messages" on chat_messages;

create policy "View own chat messages" on chat_messages for select 

using (

  exists (

    select 1 from matches 

    where matches.id = chat_messages.match_id 

    and (matches.client_id = auth.uid() OR matches.worker_id = auth.uid())

  )

);



drop policy if exists "Send chat messages" on chat_messages;

create policy "Send chat messages" on chat_messages for insert 

with check (

  auth.uid() = sender_id 

  AND exists (

    select 1 from matches

    join tasks on tasks.id = matches.task_id

    where matches.id = chat_messages.match_id 

    and (matches.client_id = auth.uid() OR matches.worker_id = auth.uid())

    -- ONLY ALLOW IF TASK IS ACTIVE (assigned or in_progress)

    and tasks.status in ('assigned', 'in_progress')

  )

);



-- Bids: Public read (for now), Worker insert

alter table bids enable row level security;



drop policy if exists "Public view bids" on bids;

create policy "Public view bids" on bids for select using (true);



drop policy if exists "Workers place bids" on bids;

create policy "Workers place bids" on bids for insert with check (auth.uid() = worker_id);



-- Swipes: Users can insert their own swipes

alter table swipes enable row level security;



drop policy if exists "Users insert own swipes" on swipes;

create policy "Users insert own swipes" on swipes for insert 

with check (auth.uid() = user_id);



drop policy if exists "Users view own swipes" on swipes;

create policy "Users view own swipes" on swipes for select 

using (auth.uid() = user_id);



drop policy if exists "Users update own swipes" on swipes;

create policy "Users update own swipes" on swipes for update

using (auth.uid() = user_id);



-- Notifications: Participants only

alter table notifications enable row level security;



drop policy if exists "Users view own notifications" on notifications;

create policy "Users view own notifications" on notifications for select 

using (auth.uid() = user_id);



drop policy if exists "Users update own notifications" on notifications;

create policy "Users update own notifications" on notifications for update 

using (auth.uid() = user_id);



-- ID Verifications: Participants only

alter table id_verifications enable row level security;



drop policy if exists "Users view own verifications" on id_verifications;

create policy "Users view own verifications" on id_verifications for select 

using (

  auth.uid() = user_id 

  or exists (

    select 1 from matches

    where (client_id = auth.uid() and worker_id = id_verifications.user_id)

       or (worker_id = auth.uid() and client_id = id_verifications.user_id)

  )

);



drop policy if exists "Users insert own verifications" on id_verifications;

create policy "Users insert own verifications" on id_verifications for insert 

with check (auth.uid() = user_id);



-- Legacy Messages: Participants only

alter table messages enable row level security;



drop policy if exists "View own legacy messages" on messages;

create policy "View own legacy messages" on messages for select 

using (auth.uid() = sender_id);



-- --------------------------------------------------------

-- 10. REALTIME ONLINE PRESENCE HELPERS

-- --------------------------------------------------------



-- View for online users (Zomato-style pro filtering)

drop view if exists public.online_users cascade;
create or replace view online_users as

select 

  id, 

  name, 

  avatar_url, 

  role, 

  verified,

  current_lat,

  current_lng,

  last_seen

from profiles

where is_online = true;



-- Function to get a live online count via RPC if needed

create or replace function get_online_count()

returns bigint

language sql

security definer

set search_path = public

as $$

  select count(*) from profiles where is_online = true;

$$;



-- Trigger to sync last_seen on profile updates

create or replace function sync_last_seen()

returns trigger as $$

begin

  if (new.is_online = true) then

    new.last_seen = now();

  end if;

  return new;

end;

$$ language plpgsql;



drop trigger if exists on_profile_online_sync on profiles;

create trigger on_profile_online_sync

  before update on profiles

  for each row

  execute function sync_last_seen();



-- --------------------------------------------------------

-- 11. TASK EXPIRATION LOGIC

-- --------------------------------------------------------



-- Function to auto-set expires_at based on urgency

create or replace function set_task_expiration()

returns trigger as $$

begin

  if new.urgency = 'asap' then

    new.expires_at = new.created_at + interval '60 minutes';

  elsif new.urgency = 'today' then

    new.expires_at = new.created_at + interval '10 hours';

  else

    new.expires_at = null; -- No expiration for other urgency levels

  end if;

  return new;

end;

$$ language plpgsql;



drop trigger if exists on_task_set_expiration on tasks;

create trigger on_task_set_expiration

  before insert on tasks

  for each row

  execute function set_task_expiration();



-- Add expires_at column if it doesn't exist

alter table tasks add column if not exists expires_at timestamp with time zone;



-- --------------------------------------------------------

-- 12. ASAP TASK NOTIFICATIONS TO NEARBY WORKERS

-- --------------------------------------------------------



-- Function to notify nearby online workers when ASAP task is posted



-- Function to cleanup notifications and RESET worker status

create or replace function cleanup_task_notifications()

returns trigger as $$

begin

  -- When status changes to 'assigned', delete all ASAP notifications for this task

  if new.status = 'assigned' and old.status != 'assigned' then

    delete from notifications

    where (data->>'task_id')::uuid = new.id;

  end if;



  -- ZOMATO ARCHITECTURE: If task is COMPLETED or CANCELLED, mark worker as FREE (is_busy = false)

  if (new.status = 'completed' or new.status = 'cancelled') and (old.status != 'completed' and old.status != 'cancelled') then

    if new.worker_id is not null then

      update profiles set is_busy = false where id = new.worker_id;

    end if;

  end if;



  return new;

end;

$$ language plpgsql;



drop trigger if exists on_task_assigned_cleanup on tasks;

create trigger on_task_assigned_cleanup

after update on tasks

for each row

execute function cleanup_task_notifications();



-- F. Cascade Dispatch (Zomato Style)

-- When a worker rejects or misses, offering to the NEXT person in rank

-- ESCALATION LOGIC included (Radius expansion)

create or replace function cascade_dispatch_on_rejection()

returns trigger as $$

declare

  v_task record;

  v_next_index integer;

  v_candidates uuid[];

begin

  -- Only trigger on rejected/missed

  if (NEW.status = 'rejected' or NEW.status = 'missed') and (OLD.status = 'pending') then

    

    -- 1. Get task info

    select * into v_task from tasks where id = NEW.task_id;



    v_next_index := v_task.dispatch_index + 1;



    -- 2. CASE A: More candidates in current list

    if v_task.candidate_ids is not null and v_next_index < array_length(v_task.candidate_ids, 1) then

      -- Increment counter

      update tasks set dispatch_index = v_next_index where id = v_task.id;



      -- Create NEW request for the next guy

      insert into gig_requests (task_id, worker_id, status, expires_at)

      values (

        v_task.id,

        v_task.candidate_ids[v_next_index + 1], -- Postgres is 1-indexed

        'pending',

        now() + interval '1 minute'

      );

      

    -- 3. CASE B: Candidates exhausted -> ESCALATE RADIUS (Step 8)

    else

      -- Aggressive Search Expansion (15km hops for 100-user trial)

      v_task.search_radius_meters := coalesce(v_task.search_radius_meters, 50000) + 15000;

      

      -- CAP search radius at 150km (Total cohort visibility)

      if v_task.search_radius_meters <= 150000 then

        -- Find NEW candidates in the wider radius

        select array_agg(id) into v_candidates

        from (

          select id

          from profiles

          where 

            is_online = true

            and is_busy = false

            and last_seen > (now() - interval '2 minutes')

            and current_lat is not null 

            and current_lng is not null

            and st_dwithin(

              st_setsrid(st_makepoint(current_lng, current_lat), 4326),

              st_setsrid(st_makepoint(v_task.pickup_lng, v_task.pickup_lat), 4326),

              v_task.search_radius_meters

            )

            and id != v_task.client_id

            -- EXCLUDE candidates who already rejected this task

            and not (id = any (

              select worker_id from gig_requests 

              where task_id = v_task.id and (status = 'rejected' or status = 'missed')

            ))

          order by 

            calculate_rider_score(id, v_task.pickup_lat, v_task.pickup_lng) desc

          limit 5

        ) as subquery;



        if array_length(v_candidates, 1) > 0 then

          -- Update task with NEW candidates and NEW radius

          update tasks set 

            candidate_ids = v_candidates,

            dispatch_index = 0,

            search_radius_meters = v_task.search_radius_meters

          where id = v_task.id;



          -- Offer to the first new candidate

          insert into gig_requests (task_id, worker_id, status, expires_at)

          values (

            v_task.id,

            v_candidates[1],

            'pending',

            now() + interval '1 minute'

          );

        else

           -- Still no new candidates in wider radius? Return to 'open'

           update tasks set status = 'open', dispatch_index = 0 where id = v_task.id;

        end if;

      else

        -- REACHED MAX ESCALATION -> Return to 'open' for general swiping

        update tasks set status = 'open', dispatch_index = 0 where id = v_task.id;

      end if;

    end if;



  end if;

  return NEW;

end;

$$ language plpgsql security definer;



drop trigger if exists on_gig_request_rejected on gig_requests;

create trigger on_gig_request_rejected

after update on gig_requests

for each row

execute function cascade_dispatch_on_rejection();

-- H. Match Notification Trigger (Commercial Grade Connectivity)

-- Notifies the worker they "Won" the gig and the client that chat is live

create or replace function notify_match_participants()

returns trigger as $$

declare

  v_task_title text;

begin

  select title into v_task_title from tasks where id = new.task_id;



  -- 1. Notify the Worker

  insert into notifications (user_id, type, title, message, related_id)

  values (

    new.worker_id,

    'match_created',

    '🎉 YOU WON THE GIG!',

    'The client matched with you for: ' || v_task_title,

    new.id

  );



  -- 2. Notify the Client (History & Sync)

  insert into notifications (user_id, type, title, message, related_id)

  values (

    new.client_id,

    'match_created',

    '🤝 New Match!',

    'You are now connected with the worker for: ' || v_task_title,

    new.id

  );



  return new;

end;

$$ language plpgsql security definer;



drop trigger if exists on_match_created on matches;

create trigger on_match_created

after insert on matches

for each row

execute function notify_match_participants();



-- I. Sync Verification Media to Task (for no-blur transparency)

create or replace function sync_task_verification()

returns trigger as $$

begin

  update tasks

  set 

    client_face_url = (select selfie_url from id_verifications where user_id = NEW.client_id order by created_at desc limit 1),

    client_id_card_url = (select id_card_url from id_verifications where user_id = NEW.client_id order by created_at desc limit 1),

    client_verification_status = (select status from id_verifications where user_id = NEW.client_id order by created_at desc limit 1)

  where id = NEW.id;

  return NEW;

end;

$$ language plpgsql security definer;



drop trigger if exists on_task_posted_sync_verification on tasks;

create trigger on_task_posted_sync_verification

after insert on tasks

for each row

execute function sync_task_verification();



-- J. Update profile verification status when a verification record is updated

create or replace function on_verification_status_change()

returns trigger as $$

begin

  if NEW.status = 'verified' then

    update profiles 

    set 

      verified = true,

      verification_status = 'verified',

      id_card_url = NEW.id_card_url,

      selfie_url = NEW.selfie_url

    where id = NEW.user_id;

  else

    update profiles 

    set verification_status = NEW.status

    where id = NEW.user_id;

  end if;

  return NEW;

end;

$$ language plpgsql security definer;



drop trigger if exists on_verification_updated on id_verifications;

create trigger on_verification_updated

after insert or update on id_verifications

for each row

execute function on_verification_status_change();



-- J. Heartbeat for Allotment (Ensures no gig gets stuck)

-- This can be called via RPC or triggered by the dashboard to clear stale alerts

create or replace function expire_stale_gig_requests()

returns void as $$

begin

  -- Set any PENDING request that has EXPIRED to 'missed'

  -- This will automatically trigger 'cascade_dispatch_on_rejection'

  update gig_requests

  set status = 'missed'

  where status = 'pending'

  and expires_at < now();

end;

$$ language plpgsql security definer;



-- K. Enriched Matches View (Professional Grade Hydration)

-- Provides a single source of truth for match lists with all names/avatars pre-joined

drop view if exists enriched_matches cascade;



create or replace view enriched_matches as

with latest_messages as (

    select distinct on (match_id)

        match_id,

        content as last_message,

        created_at as last_message_at

    from chat_messages

    order by match_id, created_at desc

),

latest_verifications as (

    select distinct on (user_id)

        user_id,

        id_card_url,

        selfie_url,

        status as verification_status

    from id_verifications

    order by user_id, created_at desc

)

select 

    m.id,

    m.task_id,

    m.client_id,

    m.worker_id,

    m.status,

    m.created_at as matched_at,

    -- Task Info

    t.title as task_title,

    t.budget as task_budget,

    t.status as task_status,

    -- Client Info

    pc.name as client_name,

    pc.avatar_url as client_avatar,

    pc.current_lat as client_lat,

    pc.current_lng as client_lng,

    vc.id_card_url as client_id_card_url,

    vc.selfie_url as client_selfie_url,

    vc.verification_status as client_verification_status,

    -- Worker Info

    pw.name as worker_name,

    pw.avatar_url as worker_avatar,

    pw.current_lat as worker_lat,

    pw.current_lng as worker_lng,

    vw.id_card_url as worker_id_card_url,

    vw.selfie_url as worker_selfie_url,

    vw.verification_status as worker_verification_status,

    -- Last Message

    lm.last_message,

    lm.last_message_at

from matches m

join tasks t on m.task_id = t.id

join profiles pc on m.client_id = pc.id

join profiles pw on m.worker_id = pw.id

left join latest_messages lm on m.id = lm.match_id

left join latest_verifications vc on pc.id = vc.user_id

left join latest_verifications vw on pw.id = vw.user_id;



-- Grant access to authenticated users

grant select on enriched_matches to authenticated;



-- ========================================

-- CRITICAL: RLS POLICIES FOR CORE FLOW 🔒

-- ========================================



-- Enable RLS on all tables

alter table profiles enable row level security;

alter table tasks enable row level security;

alter table swipes enable row level security;

alter table matches enable row level security;

alter table chat_messages enable row level security;

alter table gig_requests enable row level security;



-- PROFILES: Everyone can view, users can update own

drop policy if exists "Users can view all profiles" on profiles;

create policy "Users can view all profiles"

on profiles for select

using (true);



drop policy if exists "Users can update own profile" on profiles;

create policy "Users can update own profile"

on profiles for update

using (auth.uid() = id);



-- TASKS: Users can create own, view own, and view all open tasks

drop policy if exists "Users can create tasks" on tasks;

create policy "Users can create tasks"

on tasks for insert

with check (auth.uid() = client_id);



drop policy if exists "Users can view own tasks" on tasks;

create policy "Users can view own tasks"

on tasks for select

using (auth.uid() = client_id);



drop policy if exists "Users can view all open tasks" on tasks;

create policy "Users can view all open tasks"

on tasks for select

using (status in ('open', 'broadcasting'));



drop policy if exists "Users can update own tasks" on tasks;

create policy "Users can update own tasks"

on tasks for update

using (auth.uid() = client_id);



drop policy if exists "Users can delete own tasks" on tasks;

create policy "Users can delete own tasks"

on tasks for delete

using (auth.uid() = client_id);



-- SWIPES: Users can create and view own swipes

drop policy if exists "Users can create swipes" on swipes;

create policy "Users can create swipes"

on swipes for insert

with check (auth.uid() = user_id);



drop policy if exists "Users can view own swipes" on swipes;

create policy "Users can view own swipes"

on swipes for select

using (auth.uid() = user_id);



drop policy if exists "Users can view swipes on their tasks" on swipes;

create policy "Users can view swipes on their tasks"

on swipes for select

using (

  exists (

    select 1 from tasks

    where tasks.id = swipes.task_id

    and tasks.client_id = auth.uid()

  )

);



-- MATCHES: Users can view and create matches they're part of

drop policy if exists "Users can view their matches" on matches;

create policy "Users can view their matches"

on matches for select

using (auth.uid() = client_id or auth.uid() = worker_id);



drop policy if exists "Users can create matches for their tasks" on matches;

create policy "Users can create matches for their tasks"

on matches for insert

with check (

  auth.uid() = client_id and

  exists (

    select 1 from tasks

    where tasks.id = task_id

    and tasks.client_id = auth.uid()

  )

);



-- CHAT MESSAGES: Users can send/view messages in their matches

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



-- GIG REQUESTS: Users can view and update their own requests

drop policy if exists "Users can view their gig requests" on gig_requests;

create policy "Users can view their gig requests"

on gig_requests for select

using (auth.uid() = worker_id);



drop policy if exists "Users can update their gig requests" on gig_requests;

create policy "Users can update their gig requests"

on gig_requests for update

using (auth.uid() = worker_id);



-- ========================================

-- INCOMING SWIPES VIEW (For Interested Tab) 👀

-- ========================================



drop view if exists public.incoming_swipes cascade;
create or replace view incoming_swipes as

select 

  s.id,

  s.task_id,

  s.user_id as worker_id,

  s.direction,

  s.created_at,

  t.title as task_title,

  t.budget as task_budget,

  t.client_id,

  p.name as worker_name,

  p.avatar_url as worker_avatar,

  p.rating as worker_rating,

  p.completed_tasks as worker_completed_tasks

from swipes s

join tasks t on s.task_id = t.id

join profiles p on s.user_id = p.id

where s.direction = 'right';



grant select on incoming_swipes to authenticated;



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

      v_system_content := '�x   Chat secure. Worker assigned.';

    elsif NEW.status = 'in_progress' and OLD.status != 'in_progress' then

      v_system_content := '�xa�  Working on it! Rider is at pickup.';

    elsif NEW.status = 'completed' then

      v_system_content := '�S&  Deal closed. Task completed.';

    elsif NEW.status = 'cancelled' then

      v_system_content := '�R Task cancelled.';

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


-- ========================================================
-- RECENT ADDITIONS (MATCHES, CHAT, & GIG ALLOTMENT)
-- ========================================================

-- 1. Enriched Matches View (Crucial for UI)
-- Automates joining names and avatars for chat screens.
drop view if exists public.enriched_matches cascade;
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
  wp.current_lat as worker_lat,
  wp.current_lng as worker_lng,
  wp.id_card_url as worker_id_card_url,
  wp.selfie_url as worker_selfie_url,
  wp.verification_status as worker_verification_status,
  cp.name as client_name,
  cp.avatar_url as client_avatar,
  cp.current_lat as client_lat,
  cp.current_lng as client_lng,
  cp.id_card_url as client_id_card_url,
  cp.selfie_url as client_selfie_url,
  cp.verification_status as client_verification_status,
  lm.last_message,
  lm.last_message_at
FROM public.matches m
JOIN public.tasks t ON m.task_id = t.id
JOIN public.profiles wp ON m.worker_id = wp.id
JOIN public.profiles cp ON m.client_id = cp.id
LEFT JOIN latest_messages lm ON m.id = lm.match_id;

-- Grant access to enriched_matches for UI
grant select on public.enriched_matches to authenticated;

-- 2. Gig Acceptance RPC (Atomic & Safe for Multiple Users)
-- Handles matching, task status, and locking in one transaction.
DROP FUNCTION IF EXISTS public.accept_gig(uuid);
CREATE OR REPLACE FUNCTION public.accept_gig(p_request_id UUID)
RETURNS UUID AS $$
DECLARE
  v_task_id UUID;
  v_client_id UUID;
  v_worker_id UUID;
  v_match_id UUID;
  v_task_status TEXT;
BEGIN
  -- 1. Fetch request details
  SELECT task_id, worker_id INTO v_task_id, v_worker_id 
  FROM public.gig_requests 
  WHERE id = p_request_id;

  -- 2. LOCK THE TASK ROW to prevent race conditions
  SELECT status, client_id INTO v_task_status, v_client_id 
  FROM public.tasks 
  WHERE id = v_task_id 
  FOR UPDATE;
  
  -- 3. Safety Check
  IF v_task_status NOT IN ('open', 'broadcasting') THEN
    RAISE EXCEPTION 'Task is already taken or unavailable (Status: %)', v_task_status;
  END IF;
  
  -- 4. Create Match
  INSERT INTO public.matches (task_id, client_id, worker_id, status)
  VALUES (v_task_id, v_client_id, v_worker_id, 'active')
  RETURNING id INTO v_match_id;
  
  -- 5. Update Global State
  UPDATE public.tasks SET status = 'assigned', worker_id = v_worker_id WHERE id = v_task_id;
  UPDATE public.profiles SET is_busy = true, last_order_at = now() WHERE id = v_worker_id;
  UPDATE public.gig_requests SET status = 'accepted' WHERE id = p_request_id;
  UPDATE public.gig_requests SET status = 'missed' WHERE task_id = v_task_id AND id != p_request_id;
  
  -- 6. Notify via Chat
  INSERT INTO public.chat_messages (match_id, sender_id, content, type)
  VALUES (v_match_id, v_client_id, 'You matched! Start the conversation.', 'system');
  
  RETURN v_match_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.accept_gig(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_gig(uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.accept_gig(uuid) TO service_role;

-- 3. Stale Gig Expiration RPC (Heartbeat)
CREATE OR REPLACE FUNCTION public.expire_stale_gig_requests()
RETURNS VOID AS $$
BEGIN
  UPDATE public.gig_requests
  SET status = 'expired'
  WHERE status = 'pending' AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Enable Real-time Publication
-- Note: Ensure these tables are included in your realtime publication in Supabase UI
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles, public.tasks, public.matches, public.chat_messages, public.gig_requests;

-- 5. Ensure Swipe Unique Constraint
-- Prevents duplicate entries when using the new Quick Apply/Reject buttons
ALTER TABLE public.swipes DROP CONSTRAINT IF EXISTS swipes_user_id_task_id_key;
ALTER TABLE public.swipes ADD CONSTRAINT swipes_user_id_task_id_key UNIQUE (user_id, task_id);


-- ========================================================
-- CHAT AUTOMATION & ADVANCED LOGIC (FINAL CONSOLIDATION)
-- ========================================================

-- 1. Automated Chat Status Messages
-- Sends a system message whenever task status changes to keep users informed.
CREATE OR REPLACE FUNCTION public.handle_task_status_chat_updates()
RETURNS trigger AS $$
DECLARE
  v_match_id uuid;
  v_system_content text;
BEGIN
  -- Find the match/chat session for this task
  SELECT id INTO v_match_id FROM matches WHERE task_id = NEW.id;

  IF v_match_id IS NOT NULL THEN
    -- Decide message content based on status change
    IF NEW.status = 'assigned' AND OLD.status != 'assigned' THEN
      v_system_content := ' Chat secure. Worker assigned.';
    ELSIF NEW.status = 'in_progress' AND OLD.status != 'in_progress' THEN
      v_system_content := ' Working on it! Rider is at pickup.';
    ELSIF NEW.status = 'completed' AND OLD.status != 'completed' THEN
      v_system_content := ' Deal closed. Task completed.';
    ELSIF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
      v_system_content := ' Task cancelled.';
    END IF;

    -- Insert system message if we have a status update
    IF v_system_content IS NOT NULL THEN
      INSERT INTO chat_messages (match_id, sender_id, content, type)
      VALUES (v_match_id, NEW.client_id, v_system_content, 'system');
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_task_status_chat_sync ON tasks;
CREATE TRIGGER on_task_status_chat_sync
AFTER UPDATE ON tasks
FOR EACH ROW
EXECUTE FUNCTION handle_task_status_chat_updates();

-- MERGED FROM: append_matches.sql
-- ==================================================


-- --------------------------------------------------------
-- MATCHES & MESSAGES (Added during Fix)
-- --------------------------------------------------------
create table if not exists matches (
  id uuid default gen_random_uuid() primary key,
  task_id uuid references tasks(id),
  client_id uuid references profiles(id),
  worker_id uuid references profiles(id),
  status text default 'active',
  created_at timestamp with time zone default now()
);

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


-- ==================================================
-- MERGED FROM: apply_fixes.sql
-- ==================================================

-- ============================================
-- FIX: Grants & Permissions (Run this in SQL Editor)
-- ============================================

-- 1. Grant Permissions to Authenticated Users
grant usage on schema public to authenticated;
grant all on profiles to authenticated;
grant all on tasks to authenticated;
grant all on matches to authenticated;
grant all on chat_messages to authenticated;
grant all on swipes to authenticated;
grant all on gig_requests to authenticated;
grant all on notifications to authenticated;
grant all on id_verifications to authenticated;
grant all on location_updates to authenticated;
grant all on dispatch_analytics to authenticated;
grant all on bids to authenticated;
grant all on task_events to authenticated;

-- 2. Ensure Sequences are accessible (if any)
grant usage, select on all sequences in schema public to authenticated;

-- 3. Simplify Matches Policy (To rule out complex joins failing)
drop policy if exists "Users can create matches for their tasks" on matches;
create policy "Users can create matches for their tasks"
on matches for insert
with check (
  auth.uid() = client_id
);

-- 4. Ensure Chat Messages Policies exist
drop policy if exists "Users can send messages in their matches" on chat_messages;
create policy "Users can send messages in their matches"
on chat_messages for insert
with check (
  auth.uid() = sender_id
);

-- 5. Fix Task Ownership Policy just in case
drop policy if exists "Users can update own tasks" on tasks;
create policy "Users can update own tasks"
on tasks for update
using (auth.uid() = client_id);

-- 6. Add Missing Columns to Notifications
alter table notifications add column if not exists related_id text;
alter table notifications add column if not exists data jsonb default '{}'::jsonb;


-- ==================================================
-- MERGED FROM: assign_nearest_worker_rpc.sql
-- ==================================================

-- ==========================================
-- Feature: Task Assignment (RPC Version)
-- Goal: Find and assign a task to the nearest student from the same college.
-- ==========================================

create or replace function assign_nearest_worker(p_task_id uuid)
returns void as $$
declare
  v_assigned_worker_id uuid;
  v_client_college text;
  v_task_lat double precision;
  v_task_lng double precision;
  v_client_id uuid;
begin
  -- 1. Get task details and client's college
  select 
    t.pickup_lat, t.pickup_lng, t.client_id, p.college 
  into 
    v_task_lat, v_task_lng, v_client_id, v_client_college
  from tasks t
  join profiles p on t.client_id = p.id
  where t.id = p_task_id;

  -- 2. Find nearest eligible student
  -- Rules: Online, same college, not busy, not the client, within 3km
  select id into v_assigned_worker_id
  from profiles
  where 
    is_online = true
    and is_busy = false
    and college = v_client_college
    and id != v_client_id
    and current_lat is not null 
    and current_lng is not null
    and st_dwithin(
      st_makepoint(current_lng, current_lat)::geography,
      st_makepoint(v_task_lng, v_task_lat)::geography,
      3000 -- 3km radius
    )
  order by 
    st_distance(
      st_makepoint(current_lng, current_lat)::geography,
      st_makepoint(v_task_lng, v_task_lat)::geography
    )
  limit 1;

  -- 3. If found, update task status and worker_id
  if v_assigned_worker_id is not null then
    update tasks
    set 
      worker_id = v_assigned_worker_id,
      status = 'assigned'
    where id = p_task_id;
    
    -- Log assignment event
    insert into task_events (task_id, event_type, actor_id, metadata)
    values (p_task_id, 'MANUAL_ASSIGNMENT', v_assigned_worker_id, '{"method": "rpc"}');
  end if;
end;
$$ language plpgsql security definer;


-- ==================================================
-- MERGED FROM: auto_assign_task.sql
-- ==================================================

-- ==========================================
-- Feature: Automatic Task Assignment
-- Goal: Automatically assign a task to the nearest student from the same college within 3km.
-- ==========================================

-- 1. Function to find and assign the nearest eligible student
create or replace function auto_assign_task_logic()
returns trigger as $$
declare
  v_assigned_worker_id uuid;
  v_client_college text;
begin
  -- Only attempt auto-assignment if the task is 'open' and has pickup coordinates
  if NEW.status != 'open' or NEW.pickup_lat is null or NEW.pickup_lng is null then
    return NEW;
  end if;

  -- Get client's college
  select college into v_client_college
  from profiles
  where id = NEW.client_id;

  -- 2. Find nearest eligible student
  -- Must be online, from the same college, not busy, not the client, and within 3km
  select id into v_assigned_worker_id
  from profiles
  where 
    is_online = true
    and is_busy = false
    and college = v_client_college
    and id != NEW.client_id
    and current_lat is not null 
    and current_lng is not null
    and st_dwithin(
      st_makepoint(current_lng, current_lat)::geography,
      st_makepoint(NEW.pickup_lng, NEW.pickup_lat)::geography,
      3000 -- 3km radius
    )
  order by 
    st_distance(
      st_makepoint(current_lng, current_lat)::geography,
      st_makepoint(NEW.pickup_lng, NEW.pickup_lat)::geography
    )
  limit 1;

  -- 3. If an eligible worker is found, assign them and update status
  if v_assigned_worker_id is not null then
    NEW.worker_id := v_assigned_worker_id;
    NEW.status := 'assigned';
    
    -- Log the assignment event (optional but recommended for visibility)
    -- This assumes task_events table exists from the consolidated schema
    insert into task_events (task_id, event_type, actor_id, metadata)
    values (NEW.id, 'AUTO_ASSIGNED', v_assigned_worker_id, jsonb_build_object(
      'distance_meters', st_distance(
        st_makepoint(NEW.pickup_lng, NEW.pickup_lat)::geography,
        (select st_makepoint(current_lng, current_lat)::geography from profiles where id = v_assigned_worker_id)
      )
    ));
  end if;

  return NEW;
end;
$$ language plpgsql;

-- 2. Trigger to run before task insertion
-- Using BEFORE INSERT so we can modify the NEW record directly
drop trigger if exists on_task_created_auto_assign on tasks;
create trigger on_task_created_auto_assign
before insert on tasks
for each row
execute function auto_assign_task_logic();


-- ==================================================
-- MERGED FROM: availability_logic.sql
-- ==================================================

-- ==========================================
-- Feature: Student Availability
-- Goal: Automatically mark students as offline after 30 minutes of inactivity.
-- ==========================================

-- 1. Function to manually update availability
create or replace function set_student_availability(p_is_online boolean)
returns void as $$
begin
  update profiles
  set 
    is_online = p_is_online,
    last_seen = now(),
    updated_at = now()
  where id = auth.uid();
end;
$$ language plpgsql security definer;

-- 2. Function to update last_seen heartbeat
create or replace function update_student_heartbeat()
returns void as $$
begin
  update profiles
  set 
    last_seen = now(),
    updated_at = now()
  where id = auth.uid();
end;
$$ language plpgsql security definer;

-- 3. Function to cleanup inactive students (Auto-Offline)
-- This marks users offline if they haven't sent a heartbeat in 30+ minutes
-- Can be called via a worker or periodic maintenance RPC
create or replace function cleanup_inactive_students()
returns integer as $$
declare
  v_count integer;
begin
  update profiles
  set is_online = false
  where is_online = true
  and (last_seen < now() - interval '30 minutes' or last_seen is null);
  
  get diagnostics v_count = row_count;
  return v_count;
end;
$$ language plpgsql security definer;


-- ==================================================
-- MERGED FROM: cleanup_notifications.sql
-- ==================================================

-- Trigger to cleanup notifications when a task is accepted
create or replace function cleanup_task_notifications()
returns trigger as $$
begin
  -- When status changes to 'assigned', delete all ASAP notifications for this task
  if new.status = 'assigned' and old.status != 'assigned' then
    delete from notifications
    where type = 'asap_task' 
    and (data->>'task_id')::uuid = new.id;
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists on_task_assigned_cleanup on tasks;
create trigger on_task_assigned_cleanup
after update on tasks
for each row
execute function cleanup_task_notifications();


-- ==================================================
-- MERGED FROM: earnings_logic.sql
-- ==================================================

-- ==========================================
-- Feature: Earnings Calculation Logic
-- Rules:
-- 1. base_pay = task.budget
-- 2. distance_bonus = 5 INR per km after 2km
-- 3. surge_bonus = 15% during peak hours (18:00 - 22:00)
-- 4. incentive = 200 INR for every 5 completed tasks
-- ==========================================

-- Function to calculate earnings for a single task
create or replace function calculate_task_earnings(p_task_id uuid)
returns jsonb as $$
declare
  v_task record;
  v_base_pay double precision;
  v_distance_bonus double precision := 0;
  v_surge_bonus double precision := 0;
  v_is_peak_hour boolean;
  v_hour integer;
begin
  select budget, distance_km, created_at into v_task
  from tasks
  where id = p_task_id;

  if not found then
    return null;
  end if;

  -- 1. Base Pay
  v_base_pay := v_task.budget;

  -- 2. Distance Bonus (₹5/km after 2km)
  if v_task.distance_km > 2 then
    v_distance_bonus := (v_task.distance_km - 2) * 5;
  end if;

  -- 3. Surge Bonus (15% during 6 PM - 10 PM)
  v_hour := extract(hour from v_task.created_at at time zone 'Asia/Kolkata');
  if v_hour >= 18 and v_hour < 22 then
    v_surge_bonus := v_base_pay * 0.15;
  end if;

  return jsonb_build_object(
    'base_pay', v_base_pay,
    'distance_bonus', round(v_distance_bonus::numeric, 2),
    'surge_bonus', round(v_surge_bonus::numeric, 2),
    'total_task_earnings', round((v_base_pay + v_distance_bonus + v_surge_bonus)::numeric, 2)
  );
end;
$$ language plpgsql stable;

-- View for Worker Earnings History
create or replace view worker_earnings_summary as
select 
  t.worker_id,
  t.id as task_id,
  t.title as task_title,
  t.completed_at,
  (calculate_task_earnings(t.id)->>'base_pay')::double precision as base_pay,
  (calculate_task_earnings(t.id)->>'distance_bonus')::double precision as distance_bonus,
  (calculate_task_earnings(t.id)->>'surge_bonus')::double precision as surge_bonus,
  (calculate_task_earnings(t.id)->>'total_task_earnings')::double precision as total_task_earnings
from tasks t
where t.status = 'completed' and t.worker_id is not null;

-- Function to calculate milestone incentives (₹200 for every 5 tasks)
create or replace function get_worker_milestone_incentives(p_worker_id uuid)
returns double precision as $$
declare
  v_completed_count integer;
begin
  select count(*) into v_completed_count
  from tasks
  where worker_id = p_worker_id and status = 'completed';

  -- ₹200 for every block of 5
  return (v_completed_count / 5) * 200;
end;
$$ language plpgsql stable;

-- Function: Calculate Weekly Earnings Summary
-- Parameters:
--   p_worker_id: The ID of the worker
--   p_week_start: The start date of the week (e.g., '2024-02-05')
create or replace function get_weekly_earnings(p_worker_id uuid, p_week_start date)
returns table (
  total_base_pay double precision,
  total_distance_bonus double precision,
  total_surge_bonus double precision,
  total_task_earnings double precision,
  task_count bigint
) as $$
begin
  return query
  select 
    coalesce(sum(base_pay), 0)::double precision,
    coalesce(sum(distance_bonus), 0)::double precision,
    coalesce(sum(surge_bonus), 0)::double precision,
    coalesce(sum(total_task_earnings), 0)::double precision,
    count(*)
  from worker_earnings_summary
  where worker_id = p_worker_id
  and completed_at >= p_week_start::timestamp
  and completed_at < (p_week_start + interval '7 days')::timestamp;
end;
$$ language plpgsql stable;


-- ==================================================
-- MERGED FROM: fix_matches_rls.sql
-- ==================================================

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


-- ==================================================
-- MERGED FROM: restore_chat.sql
-- ==================================================


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


-- ==================================================
-- MERGED FROM: restore_missing.sql
-- ==================================================


-- MISSING: Search Radius for Zomato Logic
alter table tasks add column if not exists search_radius_meters integer default 2000;
alter table tasks add column if not exists candidate_ids uuid[] default '{}';
alter table tasks add column if not exists last_retry_at timestamp with time zone;
alter table tasks add column if not exists completed_at timestamp with time zone;

-- ============================================
-- FINAL SNAPSHOT UPDATES (Social Review & ASAP Sync)
-- ============================================

-- 1. Automatic Task Status Update on Match
-- Ensures that when a client accepts a candidate manually, the task is locked.
CREATE OR REPLACE FUNCTION public.handle_manual_match()
RETURNS TRIGGER AS $$
BEGIN
  -- Mark task as assigned
  UPDATE public.tasks 
  SET status = 'assigned', 
      worker_id = NEW.worker_id 
  WHERE id = NEW.task_id;

  -- Mark worker as busy (Zomato logic)
  UPDATE public.profiles 
  SET is_busy = true, 
      last_order_at = now() 
  WHERE id = NEW.worker_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_manual_match on matches;
CREATE TRIGGER on_manual_match
AFTER INSERT ON matches
FOR EACH ROW
EXECUTE FUNCTION public.handle_manual_match();

-- 2. Social Review Policy Update
-- Allows clients to "Reject" candidates in the interested list by updating the worker's swipe.
DROP POLICY IF EXISTS "Clients can manage swipes on their tasks" ON swipes;
CREATE POLICY "Clients can manage swipes on their tasks" ON swipes
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM tasks t
      WHERE t.id = swipes.task_id
      AND t.client_id = auth.uid()
    )
  );

-- Allows clients to see swipes on tasks they posted (to show interested candidates)
DROP POLICY IF EXISTS "Clients can view swipes on their tasks" ON swipes;
CREATE POLICY "Clients can view swipes on their tasks" ON swipes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM tasks t
      WHERE t.id = swipes.task_id
      AND t.client_id = auth.uid()
    )
  );

-- 3. Optimization: Universal Grants
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- 4. Realtime Replication Set
-- Using DO block to avoid errors if publishing fails in some environments
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'matches') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE matches;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'chat_messages') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'tasks') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'swipes') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE swipes;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'gig_requests') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE gig_requests;
  END IF;
EXCEPTION WHEN OTHERS THEN 
  -- Silent skip if publication doesn't exist (happens in local dev sometimes)
  RAISE NOTICE 'Skipped publication assignment: %', SQLERRM;
END $$;
-- Allow task clients to view swipes (applications) on their own tasks
drop policy if exists "Users can view swipes on their tasks" on swipes;

create policy "Users can view swipes on their tasks"
on swipes for select
using (
  exists (
    select 1 from tasks
    where tasks.id = swipes.task_id
    and tasks.client_id = auth.uid()
  )
);

-- ==========================================
-- TASK ANALYTICS EXTENSION
-- ==========================================
-- Add tracking columns to tasks table
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS reach_count INTEGER DEFAULT 0;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS realtime_viewers_count INTEGER DEFAULT 0;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS viewed_by_ids UUID[] DEFAULT '{}';


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

