-- Initial schema for the educational platform.
-- Review and test all RLS policies before production use.
create extension if not exists pgcrypto;

create type public.app_role as enum ('super_admin', 'teacher', 'student');
create type public.enrollment_status as enum ('active', 'expired', 'revoked');
create type public.lecture_status as enum ('draft', 'published', 'archived');
create type public.exam_attempt_status as enum ('in_progress', 'submitted', 'timed_out');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text,
  role public.app_role not null default 'student',
  grade_id uuid,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.academic_grades (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

alter table public.profiles
  add constraint profiles_grade_fk
  foreign key (grade_id) references public.academic_grades(id) on delete set null;

create table public.subjects (
  id uuid primary key default gen_random_uuid(),
  grade_id uuid references public.academic_grades(id) on delete set null,
  name text not null,
  description text,
  created_at timestamptz not null default now(),
  unique (grade_id, name)
);

create table public.courses (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid references public.subjects(id) on delete set null,
  title text not null,
  description text,
  cover_path text,
  price_egp numeric(10,2) not null default 0 check (price_egp >= 0),
  is_published boolean not null default false,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.course_teachers (
  course_id uuid not null references public.courses(id) on delete cascade,
  teacher_id uuid not null references public.profiles(id) on delete cascade,
  assigned_at timestamptz not null default now(),
  primary key (course_id, teacher_id)
);

create table public.chapters (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  title text not null,
  description text,
  sort_order integer not null default 0,
  is_published boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.lectures (
  id uuid primary key default gen_random_uuid(),
  chapter_id uuid not null references public.chapters(id) on delete cascade,
  title text not null,
  description text,
  video_storage_path text,
  notes_storage_path text,
  duration_seconds integer check (duration_seconds is null or duration_seconds >= 0),
  status public.lecture_status not null default 'draft',
  is_preview boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.enrollments (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  status public.enrollment_status not null default 'active',
  starts_at timestamptz not null default now(),
  expires_at timestamptz,
  source text not null default 'admin',
  created_at timestamptz not null default now(),
  unique (student_id, course_id),
  check (expires_at is null or expires_at > starts_at)
);

create table public.activation_codes (
  id uuid primary key default gen_random_uuid(),
  code_hash text not null unique,
  course_id uuid references public.courses(id) on delete cascade,
  chapter_id uuid references public.chapters(id) on delete cascade,
  lecture_id uuid references public.lectures(id) on delete cascade,
  max_redemptions integer not null default 1 check (max_redemptions > 0),
  redemption_count integer not null default 0 check (redemption_count >= 0),
  expires_at timestamptz,
  is_active boolean not null default true,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  check (num_nonnulls(course_id, chapter_id, lecture_id) = 1),
  check (redemption_count <= max_redemptions)
);

create table public.code_redemptions (
  id uuid primary key default gen_random_uuid(),
  code_id uuid not null references public.activation_codes(id) on delete restrict,
  student_id uuid not null references public.profiles(id) on delete restrict,
  redeemed_at timestamptz not null default now(),
  unique (code_id, student_id)
);

create table public.lecture_progress (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  lecture_id uuid not null references public.lectures(id) on delete cascade,
  last_position_seconds integer not null default 0 check (last_position_seconds >= 0),
  completion_percent numeric(5,2) not null default 0 check (completion_percent between 0 and 100),
  completed boolean not null default false,
  last_playback_speed numeric(3,2) not null default 1.0 check (last_playback_speed between 0.5 and 2.0),
  last_watched_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (student_id, lecture_id)
);

create table public.watch_events (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  lecture_id uuid not null references public.lectures(id) on delete cascade,
  session_id uuid not null default gen_random_uuid(),
  event_type text not null check (event_type in ('start', 'progress', 'pause', 'resume', 'complete', 'error')),
  position_seconds integer not null default 0 check (position_seconds >= 0),
  playback_speed numeric(3,2) not null default 1.0 check (playback_speed between 0.5 and 2.0),
  client_event_at timestamptz,
  received_at timestamptz not null default now()
);

create table public.exams (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  chapter_id uuid references public.chapters(id) on delete cascade,
  title text not null,
  duration_minutes integer check (duration_minutes is null or duration_minutes > 0),
  max_attempts integer not null default 1 check (max_attempts > 0),
  pass_percent numeric(5,2) not null default 50 check (pass_percent between 0 and 100),
  opens_at timestamptz,
  closes_at timestamptz,
  show_explanations boolean not null default true,
  is_published boolean not null default false,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  check (closes_at is null or opens_at is null or closes_at > opens_at)
);

create table public.questions (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.exams(id) on delete cascade,
  prompt text not null,
  explanation text,
  points numeric(8,2) not null default 1 check (points >= 0),
  sort_order integer not null default 0
);

create table public.answer_options (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.questions(id) on delete cascade,
  option_text text not null,
  is_correct boolean not null default false,
  sort_order integer not null default 0
);

create table public.exam_attempts (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.exams(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  status public.exam_attempt_status not null default 'in_progress',
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  score numeric(8,2),
  max_score numeric(8,2),
  percent numeric(5,2) check (percent is null or percent between 0 and 100),
  unique (id, student_id)
);

create table public.student_answers (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.exam_attempts(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  selected_option_id uuid references public.answer_options(id) on delete set null,
  text_answer text,
  is_correct boolean,
  awarded_points numeric(8,2),
  answered_at timestamptz not null default now(),
  unique (attempt_id, question_id)
);

create table public.devices (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  device_label text not null default 'Android device',
  device_token_hash text not null,
  is_bound boolean not null default true,
  bound_at timestamptz not null default now(),
  last_seen_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  unique (student_id, device_token_hash)
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  audience_type text not null check (audience_type in ('all', 'grade', 'course', 'student')),
  audience_id uuid,
  created_by uuid references public.profiles(id) on delete set null,
  scheduled_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  target_type text,
  target_id text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index courses_subject_idx on public.courses(subject_id);
create index chapters_course_idx on public.chapters(course_id, sort_order);
create index lectures_chapter_idx on public.lectures(chapter_id, sort_order);
create index enrollments_student_status_idx on public.enrollments(student_id, status);
create index progress_student_idx on public.lecture_progress(student_id);
create index watch_events_student_lecture_idx on public.watch_events(student_id, lecture_id, received_at desc);
create index exam_attempts_student_idx on public.exam_attempts(student_id, exam_id);
create index notifications_created_idx on public.notifications(created_at desc);

-- Enable RLS on all application tables. Policies will be added and tested
-- in the next implementation step before connecting real clients.
alter table public.profiles enable row level security;
alter table public.academic_grades enable row level security;
alter table public.subjects enable row level security;
alter table public.courses enable row level security;
alter table public.course_teachers enable row level security;
alter table public.chapters enable row level security;
alter table public.lectures enable row level security;
alter table public.enrollments enable row level security;
alter table public.activation_codes enable row level security;
alter table public.code_redemptions enable row level security;
alter table public.lecture_progress enable row level security;
alter table public.watch_events enable row level security;
alter table public.exams enable row level security;
alter table public.questions enable row level security;
alter table public.answer_options enable row level security;
alter table public.exam_attempts enable row level security;
alter table public.student_answers enable row level security;
alter table public.devices enable row level security;
alter table public.notifications enable row level security;
alter table public.audit_logs enable row level security;
