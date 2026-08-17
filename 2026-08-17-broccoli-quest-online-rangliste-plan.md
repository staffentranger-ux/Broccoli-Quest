# Broccoli-Quest Online-Rangliste — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Die bestehende `broccoli-quest.html` um eine geräteübergreifende Online-Rangliste erweitern: Name am Sieg-Screen eintippen → an Supabase senden; Start-Screen zeigt die Top 10. Gehostet auf GitHub Pages.

**Architecture:** Der Canvas-Client spricht direkt mit der Supabase-REST-API (kein eigener Server). Ein neues, asynchrones `LEADERBOARD`-Modul lädt/sendet Scores und schreibt sie in ein `board`-Zustandsobjekt, das die Render-Funktionen jeden Frame lesen. Neue Screen-Zustände (`win` = Namenseingabe, `leaderboard`) werden ergänzt; die Spiellogik bleibt unangetastet.

**Tech Stack:** HTML5 Canvas + reines JavaScript (ES2020, `fetch`), Supabase (PostgREST), GitHub Pages. Kein Build, keine Libraries. Backend-Setup via Supabase-MCP-Plugin.

## Global Constraints

- **Eine Datei:** alle Client-Änderungen in `Projekte/Broccoli-Quest/broccoli-quest.html`; fürs Hosting eine identische Kopie `index.html`. Keine Libraries, kein Build.
- **Kein Test-Framework / Verifikation im Browser:** Preview-Tools (Konsole, `read_page`, `javascript_tool` gegen die echte Supabase). Kein `pytest`.
- **Spielregeln unverändert.** Score = bestehendes `state.score` (Sterne + besiegte Gegner).
- **Supabase-REST exakt:** GET `…/rest/v1/highscores?select=name,score&order=score.desc,created_at.asc&limit=10`; POST `…/rest/v1/highscores` mit Body `{name, score}`. Header immer `apikey` + `Authorization: Bearer <anon>`.
- **Namensregeln:** erlaubte Zeichen `/^[A-Za-z0-9 ]$/`, max. **12** Zeichen, leer → `'Broccoli'`.
- **Screen-Zustände:** `'start' | 'play' | 'win' | 'leaderboard'`.
- **Robustheit:** Netzwerkfehler dürfen das Spiel nie blockieren; nur die Ranglisten-Anzeige zeigt einen Fehler.
- **Sprache:** alle sichtbaren Texte Deutsch.
- **Repo:** `https://github.com/staffentranger-ux/Broccoli-Quest.git` (Branch `main`).

---

## Datei- & Abschnittsstruktur

Ergänzungen an `broccoli-quest.html` (bestehende Abschnitts-Banner-Konvention `// ===== N. NAME =====`):
- **1. CONFIG** — zwei neue Konstanten `SUPABASE_URL`, `SUPABASE_ANON_KEY`.
- **2. STATE** — Felder `nameInput`, `submitState`, `pendingScore`, `lastEntry`; neues Objekt `board`.
- **Neuer Abschnitt `LEADERBOARD`** — `fetchScores()`, `submitScore()`, `confirmName()`.
- **9. INPUT** — `keydown`-Handler um screen-spezifische Tasten erweitern (Namenseingabe, Rangliste, Retry).
- **10. RENDER** — `renderStart` (Board ergänzen), `renderWin` (Namensfeld), neu `renderLeaderboard`, Screen-Weichen.
- **update()** — Screen-Weichen (`start` triggert Fetch, `win`/`leaderboard` = früh return).
- **index.html** — identische Kopie fürs Hosting (Task 6).

**Verifikations-Setup:** Preview-Browser auf die `file://`-URL der Datei; nach jeder Änderung neu laden + `read_console_messages`. Netzwerk gegen die echte Supabase-Instanz (nach Task 1).

---

### Task 1: Supabase-Backend einrichten (MCP) + CONFIG-Block

**Files:**
- Modify: `Projekte/Broccoli-Quest/broccoli-quest.html` (Abschnitt 1 CONFIG)

**Interfaces:**
- Produces: globale Konstanten `SUPABASE_URL` (String), `SUPABASE_ANON_KEY` (String); eine Supabase-Tabelle `public.highscores` mit RLS.

> **Menschliches Gate:** Vor dem Anlegen eines Projekts die Kosten prüfen (`get_cost`) und dem Nutzer zur **Freigabe** vorlegen (`confirm_cost`). Ein bestehendes passendes Projekt bevorzugt wiederverwenden.

- [ ] **Step 1: Konto inspizieren (read-only)**

Supabase-MCP: `list_organizations`, dann `list_projects`. Prüfen, ob ein nutzbares Projekt existiert.

- [ ] **Step 2: Projekt sicherstellen (nach Kosten-Freigabe)**

Falls kein passendes Projekt: `get_cost` → dem Nutzer zeigen → `confirm_cost` → `create_project`. Andernfalls bestehendes Projekt-`id` verwenden.

- [ ] **Step 3: Tabelle + RLS anlegen**

Supabase-MCP `apply_migration` (name `highscores_init`) mit exakt diesem SQL:

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

- [ ] **Step 4: Backend verifizieren**

`execute_sql`: `insert into public.highscores(name,score) values ('SETUP_TEST', 42);` dann `select name,score from public.highscores order by score desc limit 5;` → Erwartung: Zeile `SETUP_TEST | 42` vorhanden. Danach aufräumen: `delete from public.highscores where name='SETUP_TEST';`.

- [ ] **Step 5: Keys holen**

`get_project_url` → `SUPABASE_URL`; `get_publishable_keys` → `anon`-Key. Werte notieren.

- [ ] **Step 6: CONFIG-Block einfügen**

In Abschnitt 1 (nach `const CONFIG = {…};`) einfügen — mit den echten Werten aus Step 5:

```js
// ===== 1b. SUPABASE CONFIG =====
const SUPABASE_URL = 'https://DEIN-PROJEKT.supabase.co';       // aus get_project_url
const SUPABASE_ANON_KEY = 'DEIN-ANON-PUBLIC-KEY';              // aus get_publishable_keys
```

- [ ] **Step 7: Im Browser verifizieren**

Preview neu laden, `javascript_tool`:
```js
JSON.stringify({url: typeof SUPABASE_URL, key: SUPABASE_ANON_KEY.length>20})
```
Erwartung: `{"url":"string","key":true}`. `read_console_messages` → keine Fehler.

- [ ] **Step 8: Commit**

```bash
git add broccoli-quest.html && git commit -m "feat: Supabase-CONFIG + highscores-Tabelle (Backend eingerichtet)"
```

---

### Task 2: LEADERBOARD-Modul — board, fetchScores, submitScore

**Files:**
- Modify: `broccoli-quest.html` (Abschnitt 2 STATE; neuer Abschnitt LEADERBOARD)

**Interfaces:**
- Consumes: `SUPABASE_URL`, `SUPABASE_ANON_KEY`.
- Produces: `board = {status, entries, error}`; `async fetchScores()` (füllt `board`); `async submitScore(name, score) → Promise<boolean>`.

- [ ] **Step 1: board-Zustand + LEADERBOARD-Abschnitt einfügen**

Direkt nach dem `state`-Objekt (Abschnitt 2) einfügen:

```js
// ===== 2b. LEADERBOARD STATE =====
const board = { status: 'idle', entries: [], error: '' }; // status: idle|loading|ready|error

// ===== LEADERBOARD =====
const SB_HEADERS = { apikey: SUPABASE_ANON_KEY, Authorization: 'Bearer ' + SUPABASE_ANON_KEY };
async function fetchScores(){
  board.status = 'loading'; board.error = '';
  try {
    const url = `${SUPABASE_URL}/rest/v1/highscores?select=name,score&order=score.desc,created_at.asc&limit=10`;
    const res = await fetch(url, { headers: SB_HEADERS });
    if(!res.ok) throw new Error('HTTP ' + res.status);
    board.entries = await res.json();
    board.status = 'ready';
  } catch(err){
    board.status = 'error'; board.error = String(err && err.message || err);
  }
}
async function submitScore(name, score){
  try {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/highscores`, {
      method: 'POST',
      headers: { ...SB_HEADERS, 'Content-Type': 'application/json', Prefer: 'return=minimal' },
      body: JSON.stringify({ name, score })
    });
    return res.ok;
  } catch(err){ return false; }
}
```

- [ ] **Step 2: Live gegen Supabase verifizieren**

Preview neu laden, `javascript_tool` (async):
```js
(async () => {
  const ok = await submitScore('PLAN_TEST', 777);
  await fetchScores();
  const found = board.entries.some(e => e.name==='PLAN_TEST' && e.score===777);
  return JSON.stringify({ ok, status: board.status, found, count: board.entries.length });
})()
```
Erwartung: `ok:true`, `status:"ready"`, `found:true`.

- [ ] **Step 3: Test-Zeile aufräumen**

Supabase-MCP `execute_sql`: `delete from public.highscores where name='PLAN_TEST';`

- [ ] **Step 4: Fehlerpfad verifizieren**

`javascript_tool`: temporär falsche URL testen, ohne den Code zu ändern:
```js
(async () => {
  const good = SUPABASE_URL;
  try { /* simulate */ } finally {}
  // Fehlversuch über direkten fetch auf ungültigen Pfad:
  try { const r = await fetch(good + '/rest/v1/nope', {headers: SB_HEADERS}); return 'status '+r.status; }
  catch(e){ return 'caught '+e.message; }
})()
```
Erwartung: eine Antwort (Statuscode 404 o.ä.) ohne unbehandelte Exception — bestätigt, dass Fehler abgefangen würden.

- [ ] **Step 5: Commit**

```bash
git add broccoli-quest.html && git commit -m "feat: LEADERBOARD-Modul (fetchScores/submitScore) + board-State"
```

---

### Task 3: Start-Screen mit Rangliste + Auto-Fetch + Screen-Weichen

**Files:**
- Modify: `broccoli-quest.html` (`update()`, `render()`-Weichen, `renderStart`)

**Interfaces:**
- Consumes: `board`, `fetchScores`, `centerText` (vorhanden), `state`.
- Produces: `drawBoard(cx, topY, highlightName)`; erweiterte `renderStart`; `update`/`render`-Weichen für `leaderboard`.

- [ ] **Step 1: update()-Weichen anpassen**

Die vorhandenen Zeilen am Anfang von `update(dt)`
```js
  if(state.screen === 'start'){ if(keys.has('Enter')||keys.has('Space')){ loadLevel(0); state.screen='play'; } return; }
  if(state.screen === 'win'){ if(keys.has('Enter')){ state.screen='start'; } return; }
```
ersetzen durch:
```js
  if(state.screen === 'start'){
    if(board.status === 'idle') fetchScores();
    if(keys.has('Enter')||keys.has('Space')){ loadLevel(0); state.screen='play'; }
    return;
  }
  if(state.screen === 'win' || state.screen === 'leaderboard'){ return; } // Eingaben laufen über keydown
```

- [ ] **Step 2: render()-Weiche für leaderboard ergänzen**

In `render()` bei den Screen-Weichen ergänzen (nach der `win`-Zeile):
```js
  if(state.screen==='leaderboard'){ return renderLeaderboard(); }
```

- [ ] **Step 3: drawBoard-Helfer einfügen (Abschnitt 10)**

Vor `renderStart` einfügen:
```js
// Zeichnet die Ranglisten-Box abhängig vom board-Status; highlightName wird hervorgehoben
function drawBoard(cx, topY, highlightName){
  ctx.textAlign = 'center'; ctx.fillStyle = '#ffd23f'; ctx.font = '24px serif';
  ctx.fillText('🏆 Bestenliste', cx, topY);
  ctx.font = '20px serif';
  if(board.status === 'loading' || board.status === 'idle'){
    ctx.fillStyle = '#cfd3dc'; ctx.fillText('lädt …', cx, topY + 36); return;
  }
  if(board.status === 'error'){
    ctx.fillStyle = '#e88'; ctx.fillText('⚠ Rangliste nicht erreichbar', cx, topY + 36);
    ctx.fillStyle = '#cfd3dc'; ctx.fillText('[R] erneut versuchen', cx, topY + 62); return;
  }
  if(board.entries.length === 0){
    ctx.fillStyle = '#cfd3dc'; ctx.fillText('Noch keine Einträge — sei der Erste!', cx, topY + 36); return;
  }
  ctx.textAlign = 'left';
  board.entries.forEach((e, i) => {
    const y = topY + 34 + i*24;
    const isMe = highlightName && e.name === highlightName;
    ctx.fillStyle = isMe ? '#7CFC66' : '#e8e8e8';
    ctx.font = (isMe ? 'bold ' : '') + '19px serif';
    ctx.fillText(`${String(i+1).padStart(2,' ')}.  ${e.name}`, cx - 150, y);
    ctx.textAlign = 'right';
    ctx.fillText(String(e.score), cx + 150, y);
    ctx.textAlign = 'left';
  });
  ctx.textAlign = 'center';
}
```

- [ ] **Step 4: renderStart erweitern**

Bestehende `renderStart` ersetzen durch:
```js
function renderStart(){
  centerText(['🥦 Broccoli-Quest','5 Levels · 5 Kostüme · 5 Waffen','←/→ laufen · Leertaste springen · F Waffe','[Enter] zum Starten'], '#3fa34d');
  drawBoard(CONFIG.W/2, 300, null);
}
```

- [ ] **Step 5: Im Browser verifizieren**

Preview neu laden. `read_console_messages` (keine Fehler). Screenshot des Start-Screens.
Erwartung: Unter dem Titel erscheint „🏆 Bestenliste" — erst „lädt …", dann die Top-Einträge (oder „Noch keine Einträge"). `javascript_tool`: `JSON.stringify({status: board.status, n: board.entries.length})` → `status:"ready"`.

- [ ] **Step 6: Commit**

```bash
git add broccoli-quest.html && git commit -m "feat: Start-Screen zeigt Online-Rangliste + Auto-Fetch"
```

---

### Task 4: Sieg-Screen — Namenseingabe (Canvas)

**Files:**
- Modify: `broccoli-quest.html` (`nextLevel()`, Abschnitt 9 INPUT keydown, `renderWin`)

**Interfaces:**
- Consumes: `state`, `board`, `fetchScores`.
- Produces: `state.nameInput/submitState/pendingScore/lastEntry`; Text-Eingabe im keydown; erweiterte `renderWin`. (`confirmName` folgt in Task 5 — hier zunächst als Vorwärts-Referenz vorbereitet.)

- [ ] **Step 1: nextLevel()-Sieg-Zweig initialisiert die Eingabe**

In `nextLevel()` den else-Zweig
```js
  else { state.screen = 'win'; }
```
ersetzen durch:
```js
  else {
    state.screen = 'win';
    state.pendingScore = state.score;
    state.nameInput = '';
    state.submitState = 'input';
    state.lastEntry = null;
  }
```

- [ ] **Step 2: keydown um Screen-Tasten erweitern**

Im `keydown`-Handler GANZ OBEN (vor dem bestehenden `preventDefault`/`keys.add`) einfügen:
```js
  // Namenseingabe am Sieg-Screen
  if(state.screen === 'win' && state.submitState === 'input'){
    e.preventDefault();
    if(e.key === 'Enter'){ confirmName(); }
    else if(e.key === 'Backspace'){ state.nameInput = state.nameInput.slice(0, -1); }
    else if(/^[A-Za-z0-9 ]$/.test(e.key) && state.nameInput.length < 12){ state.nameInput += e.key; }
    return;
  }
  // Sieg-Screen Fehlerzustand
  if(state.screen === 'win' && state.submitState === 'error'){
    e.preventDefault();
    if(e.key === 'Enter'){ confirmName(); }
    else if(e.key === 'Escape'){ state.lastEntry = null; fetchScores(); state.screen = 'leaderboard'; }
    return;
  }
  // Rangliste-Screen: Enter -> Start
  if(state.screen === 'leaderboard'){
    if(e.key === 'Enter'){ e.preventDefault(); board.status = 'idle'; state.screen = 'start'; }
    return;
  }
  // Start-Screen: R = Rangliste neu laden
  if(state.screen === 'start' && (e.key === 'r' || e.key === 'R')){ e.preventDefault(); fetchScores(); return; }
```

- [ ] **Step 3: renderWin ersetzen (Namensfeld)**

Bestehende `renderWin` ersetzen durch:
```js
function renderWin(){
  ctx.fillStyle = '#10131f'; ctx.fillRect(0,0,CONFIG.W,CONFIG.H);
  ctx.textAlign = 'center';
  ctx.fillStyle = '#ffd23f'; ctx.font = '54px serif';
  ctx.fillText('🏆 Geschafft!', CONFIG.W/2, 150);
  ctx.fillStyle = '#e8e8e8'; ctx.font = '26px serif';
  ctx.fillText('Broccoli hat alle 5 Levels gemeistert!', CONFIG.W/2, 205);
  ctx.fillText('Punkte: ' + state.pendingScore, CONFIG.W/2, 250);
  if(state.submitState === 'sending'){
    ctx.fillStyle = '#cfd3dc'; ctx.fillText('wird gesendet …', CONFIG.W/2, 330); return;
  }
  if(state.submitState === 'error'){
    ctx.fillStyle = '#e88'; ctx.fillText('⚠ Senden fehlgeschlagen', CONFIG.W/2, 320);
    ctx.fillStyle = '#cfd3dc'; ctx.font = '22px serif';
    ctx.fillText('[Enter] nochmal   ·   [Esc] überspringen', CONFIG.W/2, 356); return;
  }
  // submitState === 'input'
  ctx.fillStyle = '#cfd3dc'; ctx.font = '24px serif';
  ctx.fillText('Dein Name:', CONFIG.W/2, 320);
  const blink = (Math.floor(Date.now()/500) % 2 === 0) ? '▊' : ' ';
  ctx.fillStyle = '#fff'; ctx.font = '30px serif';
  ctx.fillText((state.nameInput || '') + blink, CONFIG.W/2, 360);
  ctx.fillStyle = '#8a8f9a'; ctx.font = '18px serif';
  ctx.fillText('tippen · [Enter] eintragen (leer = „Broccoli")', CONFIG.W/2, 396);
}
```

- [ ] **Step 4: Im Browser verifizieren (Eingabe)**

Preview neu laden. `javascript_tool`, um in den Sieg-Screen zu springen und Tippen zu simulieren:
```js
(function(){
  state.screen='win'; state.submitState='input'; state.pendingScore=123; state.nameInput='';
  function type(k){ document.dispatchEvent(new KeyboardEvent('keydown',{key:k})); }
  'AB3 '.split('').forEach(type); type('Backspace');
  return JSON.stringify({nameInput: state.nameInput, submitState: state.submitState});
})()
```
Erwartung: `nameInput:"AB3"` (Leerzeichen getippt, dann per Backspace entfernt), `submitState:"input"`. Screenshot zeigt „🏆 Geschafft!", „Punkte: 123", Namensfeld mit Cursor.

- [ ] **Step 5: Commit**

```bash
git add broccoli-quest.html && git commit -m "feat: Sieg-Screen mit Canvas-Namenseingabe"
```

---

### Task 5: Absenden + Ranglisten-Screen

**Files:**
- Modify: `broccoli-quest.html` (neu `confirmName` im LEADERBOARD-Abschnitt, neu `renderLeaderboard`)

**Interfaces:**
- Consumes: `state`, `board`, `submitScore`, `fetchScores`, `drawBoard`.
- Produces: `confirmName()`; `renderLeaderboard()`.

- [ ] **Step 1: confirmName einfügen (im LEADERBOARD-Abschnitt)**

Nach `submitScore` einfügen:
```js
function confirmName(){
  const name = (state.nameInput.trim() || 'Broccoli').slice(0, 12);
  state.submitState = 'sending';
  submitScore(name, state.pendingScore).then(ok => {
    if(ok){
      state.lastEntry = { name, score: state.pendingScore };
      fetchScores();
      state.screen = 'leaderboard';
    } else {
      state.submitState = 'error';
    }
  });
}
```

- [ ] **Step 2: renderLeaderboard einfügen (Abschnitt 10)**

Nach `renderWin` einfügen:
```js
function renderLeaderboard(){
  ctx.fillStyle = '#10131f'; ctx.fillRect(0,0,CONFIG.W,CONFIG.H);
  ctx.textAlign = 'center';
  ctx.fillStyle = '#ffd23f'; ctx.font = '40px serif';
  ctx.fillText('🏆 Rangliste', CONFIG.W/2, 90);
  drawBoard(CONFIG.W/2, 150, state.lastEntry ? state.lastEntry.name : null);
  ctx.textAlign = 'center'; ctx.fillStyle = '#cfd3dc'; ctx.font = '22px serif';
  ctx.fillText('[Enter] zum Start', CONFIG.W/2, CONFIG.H - 40);
}
```

- [ ] **Step 3: Vollständigen Fluss verifizieren (Erfolg)**

Preview neu laden. `javascript_tool` (async): kompletten Sieg→Eintrag→Rangliste-Fluss simulieren:
```js
(async () => {
  state.screen='win'; state.submitState='input'; state.pendingScore=555; state.nameInput='PLAN5';
  confirmName();
  await new Promise(r=>setTimeout(r, 1500)); // auf Netzwerk warten
  return JSON.stringify({ screen: state.screen, last: state.lastEntry,
    onBoard: board.entries.some(e=>e.name==='PLAN5' && e.score===555), status: board.status });
})()
```
Erwartung: `screen:"leaderboard"`, `last:{name:"PLAN5",score:555}`, `onBoard:true`. Screenshot zeigt die Rangliste mit hervorgehobenem `PLAN5`. Danach Test-Zeile via MCP `execute_sql` löschen: `delete from public.highscores where name='PLAN5';`.

- [ ] **Step 4: Fehlerpfad + Esc verifizieren**

`javascript_tool`: Fehler erzwingen, indem `submitScore` temporär überschrieben wird (nur Laufzeit, nicht im Code):
```js
(async () => {
  const orig = submitScore; submitScore = async () => false;
  state.screen='win'; state.submitState='input'; state.pendingScore=1; state.nameInput='X';
  confirmName(); await new Promise(r=>setTimeout(r,100));
  const errState = state.submitState;
  document.dispatchEvent(new KeyboardEvent('keydown',{key:'Escape'}));
  const after = state.screen;
  submitScore = orig;
  return JSON.stringify({ errState, after });
})()
```
Erwartung: `errState:"error"`, `after:"leaderboard"`.

- [ ] **Step 5: Enter im Rangliste-Screen führt zurück zu Start**

`javascript_tool`:
```js
(function(){ state.screen='leaderboard'; document.dispatchEvent(new KeyboardEvent('keydown',{key:'Enter'}));
  return JSON.stringify({screen: state.screen, boardStatus: board.status}); })()
```
Erwartung: `screen:"start"`, `boardStatus:"idle"` (löst beim nächsten Frame neuen Fetch aus).

- [ ] **Step 6: Commit**

```bash
git add broccoli-quest.html && git commit -m "feat: Score absenden + Ranglisten-Screen mit Highlight"
```

---

### Task 6: Hosting — index.html + Push ins Repo

**Files:**
- Create: `Projekte/Broccoli-Quest/index.html` (identische Kopie)
- Modify: Git-Remote/Push

**Interfaces:**
- Consumes: fertige `broccoli-quest.html`.
- Produces: öffentlich hostbarer Stand im Repo `staffentranger-ux/Broccoli-Quest`.

- [ ] **Step 1: index.html als Kopie erzeugen**

```bash
cd "C:/Users/TTUAFST1/Claude_Projects/Meine AI Projekte/Projekte/Broccoli-Quest" && cp broccoli-quest.html index.html
```

- [ ] **Step 2: Commit**

```bash
git add index.html && git commit -m "chore: index.html fuer GitHub Pages (Kopie von broccoli-quest.html)"
```

- [ ] **Step 3: Remote hinzufügen (falls noch nicht vorhanden)**

```bash
git remote add origin https://github.com/staffentranger-ux/Broccoli-Quest.git 2>/dev/null; git remote -v
```
Erwartung: `origin  https://github.com/staffentranger-ux/Broccoli-Quest.git (fetch/push)`.

- [ ] **Step 4: Push nach main**

```bash
git push -u origin main
```
Erwartung: Push erfolgreich (Git Credential Manager liefert die Zugangsdaten). Bei Fehlermeldung zu abweichender History: Rückmeldung an den Nutzer (nicht erzwingen).

- [ ] **Step 5: Nutzer aktiviert GitHub Pages (manuell)**

Dem Nutzer die Schritte geben: Repo → **Settings → Pages** → Source „Deploy from a branch" → Branch `main` / `/(root)` → Save. Öffentlicher Link nach ~1 Min: `https://staffentranger-ux.github.io/Broccoli-Quest/`.

- [ ] **Step 6: Live verifizieren**

Sobald Pages aktiv: Preview-Browser auf `https://staffentranger-ux.github.io/Broccoli-Quest/` → Start-Screen lädt, Rangliste erscheint (`board.status==='ready'`), `read_console_messages` ohne CORS-/Netzwerkfehler.

---

## Self-Review

**Spec-Abdeckung:**
- §2 Architektur (Client↔Supabase, Hosting) → Tasks 1, 2, 6 ✓
- §3 Arbeitsteilung (MCP-Setup, Push, Pages durch Nutzer) → Task 1 (Gate), Task 6 ✓
- §4 Tabelle + RLS (exakt) → Task 1 Step 3 ✓
- §5 CONFIG + fetchScores/submitScore (exakte Endpunkte/Header) → Tasks 1, 2 ✓
- §6 Zustände (screen, nameInput, submitState, pendingScore, lastEntry, board) → Tasks 2, 3, 4 ✓
- §7 Screen-Fluss (start/win/leaderboard, loading/error/[R]) → Tasks 3, 4, 5 ✓
- §8 Namenseingabe (Regex, max 12, leer→Broccoli, Backspace/Enter, Esc) → Tasks 4, 5 ✓
- §9 Hosting (index.html, Push, Pages, Link) → Task 6 ✓
- §10 Robustheit (Fehler blockiert Spiel nicht, try/catch) → Task 2 (Step 4), Task 3 (error-Anzeige) ✓
- §11 YAGNI (kein Game-Over/Auth/Anti-Cheat) → nicht eingebaut ✓

**Platzhalter-Scan:** `DEIN-PROJEKT`/`DEIN-ANON-PUBLIC-KEY` in Task 1 Step 6 sind bewusste Config-Werte, die in Task 1 aus Step 5 (`get_project_url`/`get_publishable_keys`) real eingesetzt werden — kein offener TODO. Sonst keine Platzhalter.

**Typ-/Namens-Konsistenz:** `board {status, entries, error}`, `fetchScores()`, `submitScore(name, score)→bool`, `confirmName()`, `drawBoard(cx, topY, highlightName)`, `renderLeaderboard()`, Screen-Werte `'start'|'play'|'win'|'leaderboard'`, `state.nameInput/submitState/pendingScore/lastEntry` — überall identisch verwendet. `SB_HEADERS` konsistent in fetch/submit. Endpunkt-Strings identisch zur Spec §5.
