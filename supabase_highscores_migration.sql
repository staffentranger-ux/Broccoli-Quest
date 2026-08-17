-- Broccoli-Quest: highscores-Tabelle + RLS-Policies
-- Anzuwenden im Supabase-Projekt "staffentranger-ux's Project" (rinbhxlquftejvklwdrn)
-- Ausführung via Supabase-MCP-Plugin: apply_migration (name: highscores_init)

create table if not exists public.highscores (
  id         bigint generated always as identity primary key,
  name       text        not null check (char_length(name) between 1 and 12),
  score      integer     not null check (score >= 0),
  created_at timestamptz not null default now()
);

alter table public.highscores enable row level security;

drop policy if exists "public_read" on public.highscores;
create policy "public_read" on public.highscores
  for select to anon using (true);

drop policy if exists "public_insert" on public.highscores;
create policy "public_insert" on public.highscores
  for insert to anon
  with check (score >= 0 and char_length(name) between 1 and 12);

-- WICHTIG: RLS-Policies allein genügen nicht — Postgres prüft zuerst die
-- Tabellen-Rechte (GRANT), erst danach die Row-Level-Policies. Ohne diese
-- GRANTs schlägt jeder Zugriff mit "permission denied for table" (42501) fehl.
grant usage on schema public to anon;
grant select, insert on public.highscores to anon;
