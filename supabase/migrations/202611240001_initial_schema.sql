-- Centralised school attendance platform: initial schema
-- Apply with the Supabase SQL editor or `supabase db push`.

create extension if not exists pgcrypto;

create type public.app_role as enum ('student', 'teacher', 'director');
create type public.attendance_status as enum ('present', 'absent', 'late', 'excused');
create type public.validation_status as enum ('pending', 'approved', 'rejected');
create type public.claim_status as enum (
  'pending', 'teacher_approved', 'teacher_rejected', 'escalated',
  'director_approved', 'director_rejected'
);
create type public.session_status as enum ('scheduled', 'open', 'closed');

create table public.school_classes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  level text,
  created_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  role public.app_role not null default 'student',
  class_id uuid references public.school_classes (id),
  created_at timestamptz not null default now()
);

create table public.subjects (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text unique,
  teacher_id uuid not null references public.profiles (id)
);

create table public.sessions (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references public.subjects (id),
  class_id uuid not null references public.school_classes (id),
  teacher_id uuid not null references public.profiles (id),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  room text,
  status public.session_status not null default 'scheduled',
  created_at timestamptz not null default now(),
  constraint sessions_time_order check (ends_at > starts_at)
);

create table public.enrollments (
  student_id uuid not null references public.profiles (id) on delete cascade,
  class_id uuid not null references public.school_classes (id) on delete cascade,
  primary key (student_id, class_id)
);

create table public.attendance_records (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions (id) on delete cascade,
  student_id uuid not null references public.profiles (id),
  status public.attendance_status not null,
  source text not null default 'student' check (source in ('student', 'teacher')),
  declared_by uuid references public.profiles (id),
  declared_at timestamptz not null default now(),
  validation public.validation_status not null default 'pending',
  validated_by uuid references public.profiles (id),
  validated_at timestamptz,
  note text,
  unique (session_id, student_id)
);

create table public.claims (
  id uuid primary key default gen_random_uuid(),
  record_id uuid not null references public.attendance_records (id) on delete cascade,
  student_id uuid not null references public.profiles (id),
  reason text not null check (char_length(trim(reason)) between 5 and 2000),
  status public.claim_status not null default 'pending',
  created_at timestamptz not null default now(),
  decided_by uuid references public.profiles (id),
  decided_at timestamptz,
  decision_note text
);

create table public.audit_log (
  id bigint generated always as identity primary key,
  entity_type text not null,
  entity_id text not null,
  action text not null,
  actor_id uuid,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.institution_rules (
  key text primary key,
  value text not null,
  description text,
  updated_by uuid references public.profiles (id),
  updated_at timestamptz not null default now()
);

create index sessions_starts_at_idx on public.sessions (starts_at);
create index sessions_class_idx on public.sessions (class_id, starts_at);
create index attendance_records_student_idx on public.attendance_records (student_id, declared_at desc);
create index attendance_records_session_idx on public.attendance_records (session_id);
create index attendance_records_pending_idx on public.attendance_records (session_id) where validation = 'pending';
create index claims_status_idx on public.claims (status, created_at desc);
create index audit_log_created_idx on public.audit_log (created_at desc);
create index audit_log_actor_idx on public.audit_log (actor_id, created_at desc);

-- Role comes from app_metadata (never user_metadata, which users can edit).
create or replace function public.current_app_role()
returns public.app_role
language sql
stable
set search_path = ''
as $$
  select nullif(auth.jwt() -> 'app_metadata' ->> 'role', '')::public.app_role;
$$;

revoke all on function public.current_app_role() from public, anon;
grant execute on function public.current_app_role() to authenticated;

-- Every mutation is recorded so the workflow stays auditable.
create or replace function public.audit_write()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  insert into public.audit_log (entity_type, entity_id, action, actor_id, details)
  values (
    tg_table_name,
    coalesce(to_jsonb(new) ->> 'id', to_jsonb(new) ->> 'key'),
    tg_op,
    auth.uid(),
    to_jsonb(new)
  );
  return new;
end;
$$;

create trigger attendance_records_audit
after insert or update on public.attendance_records
for each row execute function public.audit_write();

create trigger claims_audit
after insert or update on public.claims
for each row execute function public.audit_write();

create trigger institution_rules_audit
after insert or update on public.institution_rules
for each row execute function public.audit_write();

alter table public.school_classes enable row level security;
alter table public.profiles enable row level security;
alter table public.subjects enable row level security;
alter table public.sessions enable row level security;
alter table public.enrollments enable row level security;
alter table public.attendance_records enable row level security;
alter table public.claims enable row level security;
alter table public.audit_log enable row level security;
alter table public.institution_rules enable row level security;

-- Shared reference data: readable by every signed-in user.
create policy "Authenticated users read classes" on public.school_classes
for select to authenticated using (true);
create policy "Authenticated users read subjects" on public.subjects
for select to authenticated using (true);
create policy "Authenticated users read sessions" on public.sessions
for select to authenticated using (true);
create policy "Authenticated users read rules" on public.institution_rules
for select to authenticated using (true);

-- Profiles: everyone needs names for display, but only the owner or director may edit.
create policy "Authenticated users read profiles" on public.profiles
for select to authenticated using (true);
create policy "Users update own profile" on public.profiles
for update to authenticated
using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy "Director updates profiles" on public.profiles
for update to authenticated
using (public.current_app_role() = 'director')
with check (public.current_app_role() = 'director');

create policy "Users read own enrollments" on public.enrollments
for select to authenticated
using (student_id = (select auth.uid()) or public.current_app_role() = 'director');

-- Attendance records: student sees own, teacher sees own sessions, director sees all.
create policy "Read attendance with permission" on public.attendance_records
for select to authenticated
using (
  student_id = (select auth.uid())
  or public.current_app_role() = 'director'
  or exists (
    select 1 from public.sessions s
    where s.id = session_id and s.teacher_id = (select auth.uid())
  )
);

create policy "Students declare own attendance" on public.attendance_records
for insert to authenticated
with check (
  source = 'student'
  and student_id = (select auth.uid())
  and declared_by = (select auth.uid())
  and validation = 'pending'
  and exists (
    select 1 from public.sessions s
    join public.enrollments e on e.class_id = s.class_id
    where s.id = session_id and e.student_id = (select auth.uid())
  )
);

create policy "Teachers and director record attendance" on public.attendance_records
for insert to authenticated
with check (
  public.current_app_role() in ('teacher', 'director')
  and declared_by = (select auth.uid())
  and exists (
    select 1 from public.sessions s
    where s.id = session_id
      and (s.teacher_id = (select auth.uid()) or public.current_app_role() = 'director')
  )
);

create policy "Students correct pending declarations" on public.attendance_records
for update to authenticated
using (
  student_id = (select auth.uid()) and validation = 'pending'
)
with check (
  student_id = (select auth.uid()) and validation = 'pending'
);

create policy "Teachers validate their sessions" on public.attendance_records
for update to authenticated
using (
  exists (
    select 1 from public.sessions s
    where s.id = session_id and s.teacher_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1 from public.sessions s
    where s.id = session_id and s.teacher_id = (select auth.uid())
  )
);

create policy "Director manages all attendance" on public.attendance_records
for update to authenticated
using (public.current_app_role() = 'director')
with check (public.current_app_role() = 'director');

-- Claims: only the author can file, teachers/director decide.
create policy "Read claims with permission" on public.claims
for select to authenticated
using (
  student_id = (select auth.uid())
  or public.current_app_role() = 'director'
  or exists (
    select 1 from public.attendance_records ar
    join public.sessions s on s.id = ar.session_id
    where ar.id = record_id and s.teacher_id = (select auth.uid())
  )
);

create policy "Students file claims on own records" on public.claims
for insert to authenticated
with check (
  student_id = (select auth.uid())
  and status = 'pending'
  and exists (
    select 1 from public.attendance_records ar
    where ar.id = record_id and ar.student_id = (select auth.uid())
  )
);

create policy "Teachers decide first level claims" on public.claims
for update to authenticated
using (
  exists (
    select 1 from public.attendance_records ar
    join public.sessions s on s.id = ar.session_id
    where ar.id = record_id and s.teacher_id = (select auth.uid())
  )
)
with check (status in ('teacher_approved', 'teacher_rejected', 'escalated'));

create policy "Director decides final claims" on public.claims
for update to authenticated
using (public.current_app_role() = 'director')
with check (status in ('director_approved', 'director_rejected'));

-- Audit trail: own actions visible to all, full trail only to director.
create policy "Read own audit entries" on public.audit_log
for select to authenticated
using (actor_id = (select auth.uid()) or public.current_app_role() = 'director');

create policy "Write own audit entries" on public.audit_log
for insert to authenticated
with check (actor_id = (select auth.uid()));

create policy "Director updates rules" on public.institution_rules
for update to authenticated
using (public.current_app_role() = 'director')
with check (public.current_app_role() = 'director');

-- New public tables are no longer auto-exposed to the Data API: grant explicitly.
grant usage on schema public to authenticated;
grant select on public.school_classes, public.subjects, public.sessions,
  public.profiles, public.enrollments, public.institution_rules to authenticated;
grant select, insert on public.attendance_records to authenticated;
grant update (status, validation, validated_by, validated_at, note)
  on public.attendance_records to authenticated;
grant select, insert on public.claims to authenticated;
grant update (status, decided_by, decided_at, decision_note)
  on public.claims to authenticated;
grant select, insert on public.audit_log to authenticated;
grant update (value, updated_by, updated_at) on public.institution_rules to authenticated;
grant all on all tables in schema public to service_role;
