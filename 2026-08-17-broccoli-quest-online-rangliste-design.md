# Broccoli-Quest — Online-Rangliste: Design-Spezifikation

**Datum:** 2026-08-17
**Status:** Entwurf abgesegnet, bereit für Implementierungsplan
**Erweitert:** bestehendes Spiel `broccoli-quest.html` (5 Levels, Score aus Sternen + besiegten Gegnern)

---

## 1. Überblick

Das Spiel bekommt eine **geräteübergreifende Online-Rangliste** (Arcade-Highscore). Die Spielregeln bleiben **unverändert**. Wer alle 5 Levels schafft, tippt am Sieg-Bildschirm seinen Namen ein; `{Name, Punkte}` wird an eine **Supabase**-Datenbank geschickt. Der Start-Bildschirm zeigt die **Top 10** aller Spieler. Die HTML-Datei wird online gehostet (GitHub Pages), sodass alle Spieler denselben Link öffnen und dieselbe Rangliste sehen.

**Kern-Erlebnis:** durchspielen → Namen eintragen → in der gemeinsamen Bestenliste erscheinen und sich mit anderen messen.

## 2. Architektur

```
Browser (broccoli-quest.html, Canvas)
   │  HTTPS (REST, fetch)
   ▼
Supabase  ──  Tabelle public.highscores
   ▲
   │  Row-Level-Security: anon darf nur SELECT + INSERT
```

- Client spricht **direkt** mit der Supabase-REST-API (kein eigener Server).
- Gehostet auf **GitHub Pages** (Repo `https://github.com/staffentranger-ux/Broccoli-Quest.git`). Code funktioniert auch lokal (`file://`) zum Testen — Supabase sendet `Access-Control-Allow-Origin: *`, daher klappt fetch aus beiden Kontexten.
- Alles bleibt in **einer** HTML-Datei, ergänzt um einen CONFIG-Block für `SUPABASE_URL` + `SUPABASE_ANON_KEY`.

## 3. Arbeitsteilung

| Aufgabe | Wer | Wie |
|---|---|---|
| Supabase-Projekt anlegen/wählen | Claude | Supabase-MCP-Plugin (`list_projects`/`create_project`), **erst nach Kosten-Freigabe des Nutzers** (`get_cost`/`confirm_cost`) |
| Tabelle + RLS-Policies anlegen | Claude | `apply_migration` (SQL siehe §4) |
| `Project URL` + `anon key` holen + in CONFIG eintragen | Claude | `get_project_url` / `get_publishable_keys` |
| Spiel-Code (Screens, Namenseingabe, Netzwerk) | Claude | Edits an `broccoli-quest.html` |
| Push ins Repo | Claude | `git push` (Git Credential Manager des Nutzers) |
| GitHub Pages aktivieren | **Nutzer** | einmaliger Web-Klick (Anleitung §9) |

## 4. Supabase — Datenmodell & Sicherheit

**Tabelle** `public.highscores`:

```sql
create table if not exists public.highscores (
  id         bigint generated always as identity primary key,
  name       text        not null check (char_length(name) between 1 and 12),
  score      integer     not null check (score >= 0),
  created_at timestamptz not null default now()
);

alter table public.highscores enable row level security;

create policy "public_read" on public.highscores
  for select to anon using (true);

create policy "public_insert" on public.highscores
  for insert to anon
  with check (score >= 0 and char_length(name) between 1 and 12);
```

- **Nur SELECT + INSERT** für die anonyme Rolle — kein UPDATE/DELETE (Einträge können nicht manipuliert/gelöscht werden).
- Check-Constraints begrenzen Name (1–12 Zeichen) und Score (≥ 0) serverseitig.
- Der `anon`-Key ist **öffentlich** (Supabase-Design) und steht im Client-Code; die Absicherung erfolgt über RLS.

## 5. Client — CONFIG & Netzwerk-Schicht

**CONFIG-Block** (oben in der Datei, von Claude befüllt):

```js
const SUPABASE_URL = 'https://<projekt>.supabase.co';
const SUPABASE_ANON_KEY = '<anon-public-key>';
```

**Abschnitt `LEADERBOARD`** — zwei asynchrone Funktionen:

- `fetchScores()` → GET
  `${SUPABASE_URL}/rest/v1/highscores?select=name,score&order=score.desc,created_at.asc&limit=10`
  Header: `apikey`, `Authorization: Bearer <anon>`.
  Ergebnis in `board` schreiben (siehe §6).
- `submitScore(name, score)` → POST
  `${SUPABASE_URL}/rest/v1/highscores`
  Header: `apikey`, `Authorization: Bearer <anon>`, `Content-Type: application/json`, `Prefer: return=minimal`.
  Body: `{ "name": <name>, "score": <score> }`.

Beide Funktionen sind `async`, fangen Fehler ab (try/catch) und blockieren den Game-Loop nicht.

## 6. Zustände

Ergänzung des bestehenden `state`:

```js
state.screen        // 'start' | 'play' | 'win' | 'leaderboard'   (win/leaderboard neu genutzt)
state.nameInput     // getippter Name (String)
state.submitState   // 'input' | 'sending' | 'error'  (nur auf dem Sieg-Screen relevant)
state.pendingScore  // beim Sieg eingefrorene Punktzahl
state.lastEntry     // {name, score} des zuletzt gesendeten Eintrags (zum Hervorheben)
```

Neues Modul-Objekt für die Liste:

```js
board = { status: 'idle'|'loading'|'ready'|'error', entries: [ {name, score} ], error: '' }
```

## 7. Screen-Fluss

1. **Start-Screen** (`renderStart`)
   - Beim Betreten (bzw. Laden) `fetchScores()` anstossen, falls `board.status` nicht `loading`/`ready`.
   - Zeigt Titel + Steuerung + **„🏆 Bestenliste":**
     - `loading` → „lädt …"
     - `ready` → nummerierte Top-10-Liste (`#  Name … Punkte`); leer → „Noch keine Einträge".
     - `error` → „⚠ Rangliste nicht erreichbar" + „[R] erneut versuchen".
   - „[Enter] Start".

2. **Spiel** (`play`) — unverändert.

3. **Sieg** (`win`) — Level 5 geschafft:
   - Setzt `pendingScore = score`, `nameInput = ''`, `submitState = 'input'`.
   - `renderWin`: „🏆 Geschafft! Punkte: X", darunter „Dein Name: `<nameInput>`▊" (blinkender Cursor) + Hinweis „[Enter] eintragen".
   - `submitState === 'sending'` → „wird gesendet …".
   - `submitState === 'error'` → „⚠ Senden fehlgeschlagen — [Enter] nochmal · [Esc] überspringen".

4. **Rangliste** (`leaderboard`)
   - Zeigt die aktuellen Top 10; der eigene Eintrag (`state.lastEntry`) ist **hervorgehoben**.
   - „[Enter] zum Start" → `screen='start'` und Liste neu laden.

## 8. Namenseingabe (Canvas)

- Aktiv nur wenn `screen==='win' && submitState==='input'`.
- Im `keydown`-Handler: druckbare Zeichen `/^[A-Za-z0-9 ]$/` an `nameInput` anhängen (max. **12** Zeichen); **Backspace** löscht letztes Zeichen; **Enter** bestätigt; sonstige Spieltasten hier ignorieren.
- Bei Bestätigung: `name = nameInput.trim() || 'Broccoli'` → `submitState='sending'` → `submitScore(name, pendingScore)`:
  - Erfolg → `lastEntry = {name, score}`; `fetchScores()`; `screen='leaderboard'`.
  - Fehler → `submitState='error'`.
- Auf dem `error`-Screen: **Enter** = erneut senden; **Esc** = ohne Eintrag zur Rangliste (zeigt dann die Liste ohne eigenen neuen Eintrag).

## 9. Hosting (GitHub Pages)

1. Claude committet die fertige Datei und pusht sie ins Repo `staffentranger-ux/Broccoli-Quest` (Branch `main`). Zusätzlich wird eine Kopie als **`index.html`** abgelegt, damit der Link ohne Dateinamen funktioniert.
2. **Nutzer** aktiviert Pages: Repo → **Settings → Pages** → Source „Deploy from a branch" → Branch `main` / `/ (root)` → Save.
3. Öffentlicher Link (nach ~1 Min.): `https://staffentranger-ux.github.io/Broccoli-Quest/`.
4. Diesen Link teilen die Spieler.

## 10. Robustheit & Ehrlichkeit

- **Kein Internet / Supabase nicht erreichbar** → das Spiel läuft normal weiter; nur die Ranglisten-Anzeige zeigt eine Fehlermeldung mit Retry. Kein Absturz, keine Blockade.
- **Öffentlicher anon-Key** im Code — Supabase-üblich, über RLS abgesichert (nur Lesen + Einfügen).
- **Client-seitige Scores sind fälschbar** (jemand mit Dev-Tools könnte einen beliebigen Score senden). Für eine Freundes-Rangliste akzeptiert; serverseitige Anti-Cheat-Massnahmen sind **nicht** Teil dieser Version.

## 11. Nicht im Umfang (YAGNI)

- Game-Over / Leben-System (Regeln bleiben unverändert).
- Bearbeiten/Löschen von Einträgen, Moderation, Paginierung über Top 10 hinaus.
- Login/Accounts, serverseitige Score-Validierung/Anti-Cheat.
- Automatisches Anlegen des GitHub-Repos oder Aktivieren von Pages (macht der Nutzer bzw. existiert bereits).

## 12. Betroffene Dateien

- `broccoli-quest.html` — CONFIG-Block, Abschnitt `LEADERBOARD`, erweiterte `update`/`render`/`keydown`, neue Render-Funktionen (`renderLeaderboard`, Anpassung `renderStart`/`renderWin`).
- `index.html` — Kopie fürs Hosting (identischer Inhalt).
