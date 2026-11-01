-- Tuition Manager database schema for Supabase
-- Run this whole file in Supabase Dashboard -> SQL Editor.
-- Every row is scoped to auth.uid(); do not disable RLS.
create extension if not exists pgcrypto;

create table if not exists public.teacher_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text not null default '',
  tuition_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  payment_qr_data text
);

-- Migration-safe profile email field for projects that ran an earlier schema.
alter table public.teacher_profiles add column if not exists email text;
alter table public.teacher_profiles add column if not exists payment_qr_data text;

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  student_code text not null,
  full_name text not null,
  class_level integer not null check (class_level between 1 and 12),
  monthly_fee numeric(12,2) not null default 0 check (monthly_fee >= 0),
  guardian_name text not null default '',
  guardian_phone text not null default '',
  school text not null default '',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(owner_id, student_code)
);

create table if not exists public.fee_payments (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete restrict,
  amount numeric(12,2) not null check (amount > 0),
  paid_on date not null default current_date,
  fee_month text not null check (fee_month ~ '^[0-9]{4}-[0-9]{2}$'),
  method text not null default 'cash' check (method in ('cash','online')),
  receipt_no text not null,
  notes text not null default '',
  created_at timestamptz not null default now(),
  unique(owner_id, receipt_no)
);

-- Migration-safe support for cash and online/UPI payments on existing projects.
alter table public.fee_payments drop constraint if exists fee_payments_method_check;
alter table public.fee_payments add constraint fee_payments_method_check check (method in ('cash','online'));

create table if not exists public.attendance_records (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  attendance_date date not null default current_date,
  status text not null check (status in ('present','absent','leave')),
  created_at timestamptz not null default now(),
  unique(owner_id, student_id, attendance_date)
);

create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  subject text not null default '',
  day_of_week text not null default '',
  start_time time,
  end_time time,
  room text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.work_items (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null,
  kind text not null default 'Homework' check (kind in ('Homework','Test','Exam')),
  class_level integer check (class_level between 1 and 12),
  subject text not null default '',
  due_date date,
  max_marks numeric(8,2) check (max_marks is null or max_marks >= 0),
  details text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists students_owner_idx on public.students(owner_id);
create index if not exists payments_owner_month_idx on public.fee_payments(owner_id, fee_month);
create index if not exists attendance_owner_date_idx on public.attendance_records(owner_id, attendance_date);
create index if not exists classes_owner_idx on public.classes(owner_id);
create index if not exists work_owner_idx on public.work_items(owner_id);

-- Enable Row Level Security on all tables.
alter table public.teacher_profiles enable row level security;
alter table public.students enable row level security;
alter table public.fee_payments enable row level security;
alter table public.attendance_records enable row level security;
alter table public.classes enable row level security;
alter table public.work_items enable row level security;

-- Drop/recreate policies so this script can be re-run safely.
drop policy if exists "profile_select_own" on public.teacher_profiles;
drop policy if exists "profile_insert_own" on public.teacher_profiles;
drop policy if exists "profile_update_own" on public.teacher_profiles;
create policy "profile_select_own" on public.teacher_profiles for select to authenticated using (id = auth.uid());
create policy "profile_insert_own" on public.teacher_profiles for insert to authenticated with check (id = auth.uid());
create policy "profile_update_own" on public.teacher_profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "students_select_own" on public.students;
drop policy if exists "students_insert_own" on public.students;
drop policy if exists "students_update_own" on public.students;
drop policy if exists "students_delete_own" on public.students;
create policy "students_select_own" on public.students for select to authenticated using (owner_id = auth.uid());
create policy "students_insert_own" on public.students for insert to authenticated with check (owner_id = auth.uid());
create policy "students_update_own" on public.students for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "students_delete_own" on public.students for delete to authenticated using (owner_id = auth.uid());

drop policy if exists "payments_select_own" on public.fee_payments;
drop policy if exists "payments_insert_own" on public.fee_payments;
drop policy if exists "payments_update_own" on public.fee_payments;
drop policy if exists "payments_delete_own" on public.fee_payments;
create policy "payments_select_own" on public.fee_payments for select to authenticated using (owner_id = auth.uid());
create policy "payments_insert_own" on public.fee_payments for insert to authenticated with check (owner_id = auth.uid() and exists (select 1 from public.students s where s.id = student_id and s.owner_id = auth.uid()));
create policy "payments_update_own" on public.fee_payments for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid() and exists (select 1 from public.students s where s.id = student_id and s.owner_id = auth.uid()));
create policy "payments_delete_own" on public.fee_payments for delete to authenticated using (owner_id = auth.uid());

drop policy if exists "attendance_select_own" on public.attendance_records;
drop policy if exists "attendance_insert_own" on public.attendance_records;
drop policy if exists "attendance_update_own" on public.attendance_records;
drop policy if exists "attendance_delete_own" on public.attendance_records;
create policy "attendance_select_own" on public.attendance_records for select to authenticated using (owner_id = auth.uid());
create policy "attendance_insert_own" on public.attendance_records for insert to authenticated with check (owner_id = auth.uid() and exists (select 1 from public.students s where s.id = student_id and s.owner_id = auth.uid()));
create policy "attendance_update_own" on public.attendance_records for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid() and exists (select 1 from public.students s where s.id = student_id and s.owner_id = auth.uid()));
create policy "attendance_delete_own" on public.attendance_records for delete to authenticated using (owner_id = auth.uid());

drop policy if exists "classes_select_own" on public.classes;
drop policy if exists "classes_insert_own" on public.classes;
drop policy if exists "classes_update_own" on public.classes;
drop policy if exists "classes_delete_own" on public.classes;
create policy "classes_select_own" on public.classes for select to authenticated using (owner_id = auth.uid());
create policy "classes_insert_own" on public.classes for insert to authenticated with check (owner_id = auth.uid());
create policy "classes_update_own" on public.classes for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "classes_delete_own" on public.classes for delete to authenticated using (owner_id = auth.uid());

drop policy if exists "work_select_own" on public.work_items;
drop policy if exists "work_insert_own" on public.work_items;
drop policy if exists "work_update_own" on public.work_items;
drop policy if exists "work_delete_own" on public.work_items;
create policy "work_select_own" on public.work_items for select to authenticated using (owner_id = auth.uid());
create policy "work_insert_own" on public.work_items for insert to authenticated with check (owner_id = auth.uid());
create policy "work_update_own" on public.work_items for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "work_delete_own" on public.work_items for delete to authenticated using (owner_id = auth.uid());

-- Important: Authenticated users may only access rows that pass RLS above.
-- The Supabase anon/publishable key is intended for browser use; never expose service_role.
