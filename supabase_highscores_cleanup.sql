-- Broccoli-Quest: Rangliste aufräumen + gegen absurde Punktzahlen absichern
-- Im Supabase SQL Editor ausführen (Projekt "staffentranger-ux's Project").
--
-- Hintergrund: Die Punktzahl wird im Browser berechnet und gesendet. Mit den
-- Entwicklertools kann jeder einen beliebigen Wert absenden — so entstanden die
-- Einträge mit 2147483647 (grösste 32-Bit-Zahl).

-- ---------------------------------------------------------------------------
-- 1) Unrealistische Einträge entfernen
-- ---------------------------------------------------------------------------
-- Theoretisches Maximum des Spiels:
--   30 Sterne × 10                       =  300
--   29 Gegner × 20                       =  580
--   Zeitbonus: 625s Par-Zeit gesamt × 3  = 1875
--   ---------------------------------------------
--   absolutes Maximum                    ≈ 2755
delete from public.highscores where score > 3000;

-- Optional: einzelne Spassnamen gezielt entfernen
-- delete from public.highscores
--  where name in ('LOIC','AND','MANU','PWNED','THE','BROCCOLI','GAME','GENERATED','BY','AI');

-- ---------------------------------------------------------------------------
-- 2) Obergrenze dauerhaft erzwingen (serverseitig, nicht umgehbar)
-- ---------------------------------------------------------------------------
alter table public.highscores drop constraint if exists highscores_score_max;
alter table public.highscores add constraint highscores_score_max check (score <= 3000);

-- Die INSERT-Policy zusätzlich verschärfen, damit die Grenze auch dort gilt
drop policy if exists "public_insert" on public.highscores;
create policy "public_insert" on public.highscores
  for insert to anon
  with check (score >= 0 and score <= 3000 and char_length(name) between 1 and 12);

-- ---------------------------------------------------------------------------
-- 3) Kontrolle
-- ---------------------------------------------------------------------------
select name, score, created_at
  from public.highscores
 order by score desc, created_at asc
 limit 20;

-- ---------------------------------------------------------------------------
-- Was das leistet — und was nicht
-- ---------------------------------------------------------------------------
-- LEISTET:      Absurde Werte wie 2147483647 sind ab sofort unmöglich; die
--               Datenbank weist sie zurück, egal was der Browser sendet.
-- LEISTET NICHT: Jemand kann weiterhin einen erfundenen Wert bis 3000 senden,
--               ohne gespielt zu haben. Dagegen hülfe nur eine serverseitige
--               Prüfung (Supabase Edge Function), die den Spielverlauf
--               plausibilisiert — deutlich aufwendiger und für eine
--               Freundes-Rangliste vermutlich übertrieben.
