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
