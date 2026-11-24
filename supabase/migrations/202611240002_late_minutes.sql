-- Late duration used by the institution's late_threshold_minutes rule.
alter table public.attendance_records
  add column late_minutes integer
  check (late_minutes is null or (late_minutes between 0 and 1440));

comment on column public.attendance_records.late_minutes is
  'Minutes late declared for a late attendance status; null otherwise.';

-- Column-level grants are required because table-wide UPDATE is not granted.
grant update (late_minutes) on public.attendance_records to authenticated;
