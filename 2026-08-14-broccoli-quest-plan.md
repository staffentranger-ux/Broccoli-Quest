# Broccoli-Quest Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ein spielbares 2D-Jump'n'Run als einzelne `broccoli-quest.html`, in dem ein Broccoli-Männchen 5 Levels mit je eigenem Kostüm (Fähigkeit + Waffe) und Gegnern absolviert.

**Architecture:** Eine einzelne HTML-Datei mit `<canvas>` und einem `requestAnimationFrame`-Game-Loop (Update → Kollision → Render). Levels, Kostüme und Gegner sind als **Daten** definiert; die Kern-Logik (Physik, Kollision, Rendering) ist datengetrieben und bleibt beim Hinzufügen neuer Levels unverändert. Der JS-Code liegt intern in klar getrennten Abschnitten (Config, State, Level-Daten, Player, Enemies, Projectiles, Physics/Collision, Input, Render, Loop).

**Tech Stack:** HTML5, Canvas 2D API, reines JavaScript (ES2020, keine Libraries). Grafik aus Canvas-Formen + Emojis via `ctx.fillText`.

## Global Constraints

- **Eine einzige Datei:** alles in `Projekte/Broccoli-Quest/broccoli-quest.html` — kein externes Asset, keine Library, kein Build-Schritt. Muss per Doppelklick (`file://`) laufen.
- **Kein Test-Framework / kein Git:** Verifikation jeder Aufgabe erfolgt **im Browser** (Preview-Tools: Konsole auf Fehler prüfen, `read_page`/Screenshot zur Sichtprüfung, Interaktion via `computer`). Kein `pytest`, kein `git commit`. Jeder verifizierte Meilenstein = Checkpoint.
- **Canvas-Grösse:** 960×540 (16:9), interne Auflösung fix; Skalierung per CSS optional.
- **Steuerung fix:** ←/→ oder A/D = laufen · Leertaste/↑/W = springen · **F** = Waffe.
- **Regeln fix:** 3 Herzen/Level · Treffer oder Sturz = 1 Herz + Respawn am letzten Checkpoint · 0 Herzen = Level-Neustart.
- **Sprache:** Alle sichtbaren Texte auf Deutsch.
- **Koordinaten:** Level-Welt in Pixeln, Ursprung oben-links, y wächst nach unten.

---

## Datei- & Abschnittsstruktur

Alles in `broccoli-quest.html`. Der `<script>`-Block ist in nummerierte Abschnitte gegliedert (als Kommentar-Banner `// ===== N. NAME =====`), die die Tasks Schritt für Schritt füllen:

1. **CONFIG** — Konstanten (Canvas-Grösse, Schwerkraft, Sprungkraft, Tempo, Farben).
2. **STATE** — globaler Spielzustand (aktuelles Level, Herzen, Punkte, Screen: `start`/`play`/`win`, Kamera-x).
3. **LEVELS** — Array mit 5 Level-Objekten (Plattformen, Hindernisse, Gegner, Sterne, Checkpoints, Start, Ziel, Kostüm-Key).
4. **COSTUMES** — Map von Kostüm-Key → Fähigkeit-Parameter + Waffen-Parameter.
5. **PLAYER** — Player-Objekt + Bewegung/Sprung + Kostüm-Fähigkeit.
6. **ENEMIES** — Gegner-Update (Bewegungsmuster) + „besiegbar"-Status.
7. **PROJECTILES** — abgefeuerte Waffen-Projektile.
8. **PHYSICS** — Schwerkraft, Plattform-Kollision, AABB-Overlap-Helfer.
9. **INPUT** — Tastatur-Handler (keydown/keyup → `keys`-Set).
10. **RENDER** — Zeichnen von Welt, Player, Gegnern, Projektilen, HUD, Screens.
11. **LOOP** — `requestAnimationFrame`-Schleife + Screen-Umschaltung + Level-Übergang.

**Verifikations-Setup (einmalig, vor Task 1):** Öffne die Datei im Preview-Browser mit `preview_start` `{url: "file:///C:/Users/TTUAFST1/Claude_Projects/Meine%20AI%20Projekte/Projekte/Broccoli-Quest/broccoli-quest.html"}`. Nach jeder Code-Änderung: neu laden (`navigate` auf dieselbe URL) und `read_console_messages` auf Fehler prüfen.

---

### Task 1: Grundgerüst — Canvas, Game-Loop, stehender Broccoli

**Files:**
- Create: `Projekte/Broccoli-Quest/broccoli-quest.html`

**Interfaces:**
- Produces: globale Objekte `CONFIG`, `state`, Funktionen `update(dt)`, `render()`, `loop(ts)`; Canvas-Kontext `ctx`.

- [ ] **Step 1: Datei mit Grundgerüst anlegen**

```html
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="UTF-8">
<title>Broccoli-Quest</title>
<style>
  html,body{margin:0;height:100%;background:#1b1b2b;display:flex;align-items:center;justify-content:center;font-family:system-ui,sans-serif;}
  canvas{background:#87ceeb;image-rendering:pixelated;box-shadow:0 8px 40px rgba(0,0,0,.5);border-radius:8px;}
</style>
</head>
<body>
<canvas id="game" width="960" height="540"></canvas>
<script>
// ===== 1. CONFIG =====
const CONFIG = {
  W: 960, H: 540,
  GRAVITY: 2000,        // px/s^2
  MOVE_SPEED: 260,      // px/s
  JUMP_V: 720,          // px/s initiale Sprunggeschwindigkeit
  GROUND_Y: 480,        // Boden-Oberkante im Tutorial (überschrieben je Level)
};
const canvas = document.getElementById('game');
const ctx = canvas.getContext('2d');

// ===== 2. STATE =====
const state = {
  screen: 'play',      // 'start' | 'play' | 'win'
  levelIndex: 0,
  hearts: 3,
  score: 0,
  cameraX: 0,
};

// ===== 5. PLAYER (Minimalfassung) =====
const player = { x: 100, y: 400, w: 34, h: 44, vx: 0, vy: 0, onGround: false, facing: 1 };

// ===== 10. RENDER =====
function render(){
  ctx.clearRect(0,0,CONFIG.W,CONFIG.H);
  // Boden
  ctx.fillStyle = '#6b4f2a';
  ctx.fillRect(0, CONFIG.GROUND_Y, CONFIG.W, CONFIG.H - CONFIG.GROUND_Y);
  ctx.fillStyle = '#3fa34d';
  ctx.fillRect(0, CONFIG.GROUND_Y, CONFIG.W, 10);
  // Broccoli (Emoji + Körper)
  ctx.font = '44px serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'alphabetic';
  ctx.fillText('🥦', player.x + player.w/2, player.y + player.h);
}

// ===== 11. LOOP =====
let last = 0;
function loop(ts){
  const dt = Math.min(0.033, (ts - last) / 1000 || 0);
  last = ts;
  update(dt);
  render();
  requestAnimationFrame(loop);
}
function update(dt){ /* Task 2 füllt dies */ }
requestAnimationFrame(loop);
</script>
</body>
</html>
```

- [ ] **Step 2: Im Browser verifizieren**

`preview_start` mit der `file://`-URL, dann `read_console_messages` (Erwartung: keine Fehler) und Screenshot.
Erwartung: Hellblauer Himmel, brauner Boden mit grüner Kante, ein 🥦 steht auf dem Boden.

- [ ] **Step 3: Checkpoint** — Datei ist gültig, rendert ohne Konsolenfehler.

---

### Task 2: Bewegung & Physik — Laufen, Schwerkraft, Springen, Plattform-Kollision

**Files:**
- Modify: `Projekte/Broccoli-Quest/broccoli-quest.html` (Abschnitte 8 PHYSICS, 9 INPUT, 5 PLAYER, `update`)

**Interfaces:**
- Consumes: `player`, `CONFIG`, `state`.
- Produces: `keys` (Set), `aabb(a,b)` (bool), `platforms` (Array temporär im Player-Test), `movePlayer(dt, platforms)`.

- [ ] **Step 1: Input-Handler + AABB-Helfer + Physik einfügen**

Direkt vor `// ===== 10. RENDER =====` einfügen:

```js
// ===== 9. INPUT =====
const keys = new Set();
addEventListener('keydown', e => {
  if(['ArrowLeft','ArrowRight','ArrowUp','Space','KeyA','KeyD','KeyW','KeyF'].includes(e.code)) e.preventDefault();
  keys.add(e.code);
});
addEventListener('keyup', e => keys.delete(e.code));
const left  = () => keys.has('ArrowLeft')  || keys.has('KeyA');
const right = () => keys.has('ArrowRight') || keys.has('KeyD');
const jumpPressed = () => keys.has('ArrowUp') || keys.has('KeyW') || keys.has('Space');

// ===== 8. PHYSICS =====
function aabb(a,b){
  return a.x < b.x+b.w && a.x+a.w > b.x && a.y < b.y+b.h && a.y+a.h > b.y;
}
// temporäre Testplattformen bis Task 3 die Level-Daten liefert
const platforms = [
  { x:0, y:CONFIG.GROUND_Y, w:2000, h:60 },
  { x:300, y:400, w:140, h:20 },
  { x:520, y:320, w:140, h:20 },
];
function movePlayer(dt){
  // horizontal
  player.vx = 0;
  if(left())  { player.vx = -CONFIG.MOVE_SPEED; player.facing = -1; }
  if(right()) { player.vx =  CONFIG.MOVE_SPEED; player.facing =  1; }
  player.x += player.vx * dt;
  // vertikal: Schwerkraft
  player.vy += CONFIG.GRAVITY * dt;
  player.y += player.vy * dt;
  // Plattform-Kollision (nur von oben landen)
  player.onGround = false;
  for(const p of platforms){
    if(aabb(player, p)){
      const prevBottom = (player.y - player.vy*dt) + player.h;
      if(player.vy > 0 && prevBottom <= p.y + 1){
        player.y = p.y - player.h;
        player.vy = 0;
        player.onGround = true;
      }
    }
  }
  // Sprung
  if(jumpPressed() && player.onGround){
    player.vy = -CONFIG.JUMP_V;
    player.onGround = false;
  }
}
```

- [ ] **Step 2: `update` aktivieren**

```js
function update(dt){
  if(state.screen !== 'play') return;
  movePlayer(dt);
}
```

- [ ] **Step 3: Plattformen mitzeichnen**

In `render()` nach dem Boden-Block, vor dem Broccoli, einfügen:

```js
  ctx.fillStyle = '#8a5a2b';
  for(const p of platforms){ if(p.y < CONFIG.GROUND_Y) ctx.fillRect(p.x, p.y, p.w, p.h); }
```

- [ ] **Step 4: Im Browser verifizieren**

Neu laden. Mit `computer` Tasten senden (ArrowRight, Space). Konsole prüfen.
Erwartung: Broccoli läuft nach links/rechts, fällt durch Schwerkraft, springt mit Leertaste, landet auf den zwei schwebenden Plattformen und dem Boden.

- [ ] **Step 5: Checkpoint** — Bewegung, Schwerkraft, Sprung, Landung funktionieren.

---

### Task 3: Level-Datenmodell + Kamera + Level 1 „Der Garten"

**Files:**
- Modify: `broccoli-quest.html` (Abschnitte 3 LEVELS, 2 STATE, 8 PHYSICS, 10 RENDER, `update`)

**Interfaces:**
- Consumes: `player`, `movePlayer`, `aabb`.
- Produces: `LEVELS` (Array), `currentLevel()`, `loadLevel(i)`, `state.cameraX`, `worldToScreen`-Konvention (render subtrahiert `state.cameraX` von allen x).

- [ ] **Step 1: Level-Datenstruktur + Level 1 definieren**

Abschnitt 3 (ersetzt die temporären `platforms` aus Task 2 — diese Zeilen aus Abschnitt 8 entfernen):

```js
// ===== 3. LEVELS =====
// Jedes Level: {name, costume, worldW, groundY, bg, platforms[], hazards[], enemies[], stars[], checkpoints[], start{x,y}, goalX}
const LEVELS = [
  {
    name: 'Der Garten', costume: 'basis', worldW: 2600, groundY: 480, bg: '#87ceeb',
    platforms: [
      {x:0,   y:480, w:900,  h:60},
      {x:1000,y:480, w:1600, h:60},           // Lücke 900–1000 = Loch
      {x:340, y:390, w:150, h:20},
      {x:600, y:310, w:150, h:20},
      {x:1250,y:380, w:150, h:20},
    ],
    hazards: [],           // Task 4 füllt Löcher/Spikes-Logik; Löcher entstehen durch Plattform-Lücken
    enemies: [],           // Task 5
    stars:   [{x:400,y:340},{x:660,y:260},{x:1300,y:330}],
    checkpoints: [{x:1000,y:436}],
    start: {x:60, y:420}, goalX: 2500,
  },
];
```

- [ ] **Step 2: STATE erweitern + `currentLevel`/`loadLevel`**

Abschnitt 2 unter `state`:

```js
function currentLevel(){ return LEVELS[state.levelIndex]; }
function loadLevel(i){
  state.levelIndex = i;
  const L = LEVELS[i];
  state.hearts = 3; state.cameraX = 0;
  state.activeCheckpoint = { ...L.start };
  player.x = L.start.x; player.y = L.start.y; player.vx = 0; player.vy = 0;
  CONFIG.GROUND_Y = L.groundY;
}
```

Und in Abschnitt 5 die feste Startzeile durch `loadLevel(0)` nach der Player-Definition ersetzen (am Ende von Abschnitt 5 aufrufen).

- [ ] **Step 3: `movePlayer` auf Level-Plattformen umstellen + Kamera + Ziel**

`movePlayer` nutzt jetzt `currentLevel().platforms`. Ersetze die `for(const p of platforms)`-Zeile durch `for(const p of currentLevel().platforms)`. Danach in `update`:

```js
function update(dt){
  if(state.screen !== 'play') return;
  const L = currentLevel();
  movePlayer(dt);
  // Kamera folgt, geklemmt auf Weltgrenzen
  state.cameraX = Math.max(0, Math.min(player.x + player.w/2 - CONFIG.W/2, L.worldW - CONFIG.W));
  // Sterne einsammeln
  L.stars = L.stars.filter(s => {
    if(aabb(player, {x:s.x,y:s.y,w:28,h:28})){ state.score += 10; return false; }
    return true;
  });
  // Ziel erreicht
  if(player.x >= L.goalX){ nextLevel(); }
}
function nextLevel(){
  if(state.levelIndex + 1 < LEVELS.length){ loadLevel(state.levelIndex + 1); }
  else { state.screen = 'win'; }
}
```

- [ ] **Step 4: Render kamera-relativ + Level-Deko + HUD-Basis**

`render()` komplett ersetzen:

```js
function render(){
  const L = currentLevel();
  ctx.clearRect(0,0,CONFIG.W,CONFIG.H);
  ctx.fillStyle = L.bg; ctx.fillRect(0,0,CONFIG.W,CONFIG.H);
  const cx = state.cameraX;
  // Boden + Plattformen
  for(const p of L.platforms){
    ctx.fillStyle = (p.y >= L.groundY) ? '#6b4f2a' : '#8a5a2b';
    ctx.fillRect(p.x - cx, p.y, p.w, p.h);
    ctx.fillStyle = '#3fa34d';
    ctx.fillRect(p.x - cx, p.y, p.w, 8);
  }
  // Checkpoints
  ctx.font = '30px serif'; ctx.textAlign='center'; ctx.textBaseline='alphabetic';
  for(const c of L.checkpoints) ctx.fillText('🚩', c.x - cx, c.y + 28);
  // Sterne
  ctx.font = '26px serif';
  for(const s of L.stars) ctx.fillText('🌟', s.x - cx + 14, s.y + 24);
  // Ziel
  ctx.font = '40px serif'; ctx.fillText('🏁', L.goalX - cx, L.groundY);
  // Broccoli
  ctx.font = '44px serif';
  ctx.save();
  if(player.facing < 0){ ctx.translate((player.x - cx + player.w/2)*2, 0); ctx.scale(-1,1); }
  ctx.fillText('🥦', player.x - cx + player.w/2, player.y + player.h);
  ctx.restore();
  // HUD
  ctx.font = '22px serif'; ctx.textAlign='left';
  ctx.fillStyle = '#fff';
  ctx.fillText('❤️'.repeat(state.hearts), 16, 34);
  ctx.fillText('🌟 ' + state.score, 16, 64);
  ctx.fillText(L.name, CONFIG.W-220, 34);
}
```

- [ ] **Step 5: Im Browser verifizieren**

Neu laden, nach rechts laufen bis zum Ziel. Konsole prüfen.
Erwartung: Kamera scrollt mit, Sterne verschwinden beim Einsammeln (Score steigt), 🚩 und 🏁 sichtbar, am Ziel würde `nextLevel` (bei nur 1 Level) den Win-Screen setzen — vorerst sichtbar als Stillstand; Win-Screen kommt in Task 11.

- [ ] **Step 6: Checkpoint** — datengetriebenes Level 1 mit Kamera, Sternen, Ziel läuft.

---

### Task 4: Schaden, Herzen, Checkpoints, Respawn, Level-Neustart

**Files:**
- Modify: `broccoli-quest.html` (`update`, neue Funktionen in Abschnitt 8)

**Interfaces:**
- Consumes: `player`, `state`, `currentLevel`, `loadLevel`.
- Produces: `hurt()`, `respawn()`, Checkpoint-Aktivierung, Absturz-Erkennung.

- [ ] **Step 1: Schadens-/Respawn-Funktionen einfügen (Abschnitt 8)**

```js
let invuln = 0; // Sekunden Unverwundbarkeit nach Treffer
function respawn(){
  const c = state.activeCheckpoint;
  player.x = c.x; player.y = c.y; player.vx = 0; player.vy = 0;
}
function hurt(){
  if(invuln > 0) return;
  state.hearts--; invuln = 1.2;
  if(state.hearts <= 0){ loadLevel(state.levelIndex); } // ganzes Level neu
  else { respawn(); }
}
```

- [ ] **Step 2: Absturz + Checkpoint-Aktivierung in `update` ergänzen**

In `update`, nach `movePlayer(dt)`:

```js
  if(invuln > 0) invuln -= dt;
  // In Abgrund gefallen?
  if(player.y > L.groundY + 200){ hurt(); }
  // Checkpoint erreichen aktiviert ihn
  for(const c of L.checkpoints){
    if(Math.abs(player.x - c.x) < 30 && player.y < L.groundY){
      state.activeCheckpoint = { x:c.x, y:c.y - player.h };
    }
  }
```

- [ ] **Step 3: Treffer-Blinken im Render andeuten**

In `render()`, unmittelbar vor dem Broccoli-Zeichnen:

```js
  if(invuln > 0 && Math.floor(invuln*10)%2===0){ /* Blink: Broccoli in diesem Frame nicht zeichnen */ }
  else {
```
und nach `ctx.restore();` des Broccoli ein `}` schliessen. (Broccoli blinkt bei Unverwundbarkeit.)

- [ ] **Step 4: Im Browser verifizieren**

Neu laden, in die Lücke (900–1000) fallen. Konsole prüfen.
Erwartung: Sturz kostet ein Herz (HUD −1), Broccoli erscheint am Checkpoint 🚩 bzw. Start, blinkt kurz. Nach 3 Stürzen ohne aktivierten Checkpoint: Level-Neustart, Herzen wieder 3.

- [ ] **Step 5: Checkpoint** — Herz-/Checkpoint-/Respawn-System funktioniert.

---

### Task 5: Gegner — Bewegung & Kollisionsschaden

**Files:**
- Modify: `broccoli-quest.html` (Abschnitte 3 Level-1-Daten, 6 ENEMIES, `update`, `render`)

**Interfaces:**
- Consumes: `aabb`, `hurt`, `currentLevel`, `player`.
- Produces: Gegner-Objekt-Form `{x,y,w,h,type,emoji,dir,speed,range,baseX,alive}`, `updateEnemies(dt)`.

- [ ] **Step 1: Gegner in Level 1 eintragen**

In `LEVELS[0]` das `enemies:[]` ersetzen durch:

```js
    enemies: [
      {x:500, y:452, w:30, h:28, type:'walker', emoji:'🐌', dir:1, speed:60, range:120, baseX:500, alive:true},
      {x:1300,y:452, w:30, h:28, type:'walker', emoji:'🐛', dir:-1, speed:80, range:150, baseX:1300, alive:true},
    ],
```

- [ ] **Step 2: `updateEnemies` einfügen (Abschnitt 6)**

```js
// ===== 6. ENEMIES =====
function updateEnemies(dt){
  const L = currentLevel();
  for(const e of L.enemies){
    if(!e.alive) continue;
    if(e.type === 'walker'){
      e.x += e.dir * e.speed * dt;
      if(e.x > e.baseX + e.range) e.dir = -1;
      if(e.x < e.baseX - e.range) e.dir = 1;
    }
    // Kollision mit Player = Schaden
    if(aabb(player, e)) hurt();
  }
}
```

- [ ] **Step 3: In `update` aufrufen** — nach der Checkpoint-Schleife: `updateEnemies(dt);`

- [ ] **Step 4: Gegner zeichnen**

In `render()`, vor dem Broccoli:

```js
  ctx.font = '30px serif'; ctx.textAlign='center';
  for(const e of L.enemies){ if(e.alive) ctx.fillText(e.emoji, e.x - cx + e.w/2, e.y + e.h); }
```

- [ ] **Step 5: Im Browser verifizieren**

Neu laden. Zu 🐌 laufen. Konsole prüfen.
Erwartung: Schnecke/Raupe patrouillieren hin und her; Berührung kostet ein Herz + Respawn.

- [ ] **Step 6: Checkpoint** — Gegner bewegen sich und verursachen Schaden.

---

### Task 6: Kostüm-Waffen & Projektile

**Files:**
- Modify: `broccoli-quest.html` (Abschnitte 4 COSTUMES, 7 PROJECTILES, 9 INPUT, `update`, `render`)

**Interfaces:**
- Consumes: `currentLevel`, `player`, `aabb`, `keys`.
- Produces: `COSTUMES` (Map), `projectiles` (Array), `fireWeapon()`, `updateProjectiles(dt)`, `player.cooldown`.

- [ ] **Step 1: COSTUMES-Definition (Abschnitt 4)**

```js
// ===== 4. COSTUMES =====
// ability: {gravity?, jumpV?, doubleJump?, wallJump?, swim?, fireproof?} — Task 7–10 nutzen Felder
// weapon:  {emoji, speed, range, cooldown, dmg}  speed=0 => Nahbereich-Strahl
const COSTUMES = {
  basis:     { emoji:'🧢', weapon:{emoji:'🧂', speed:520, range:260, cooldown:0.35, dmg:1} },
  astronaut: { emoji:'🚀', weapon:{emoji:'⚡', speed:700, range:520, cooldown:0.30, dmg:1} },
  taucher:   { emoji:'🤿', weapon:{emoji:'🫧', speed:480, range:300, cooldown:0.40, dmg:1} },
  feuerwehr: { emoji:'💦', weapon:{emoji:'💦', speed:0,   range:110, cooldown:0.15, dmg:1} },
  ninja:     { emoji:'🥷', weapon:{emoji:'⭐', speed:820, range:640, cooldown:0.25, dmg:1} },
};
function costume(){ return COSTUMES[currentLevel().costume]; }
```

- [ ] **Step 2: Projektil-System (Abschnitt 7)**

```js
// ===== 7. PROJECTILES =====
let projectiles = [];
function fireWeapon(){
  if(player.cooldown > 0) return;
  const w = costume().weapon;
  player.cooldown = w.cooldown;
  projectiles.push({
    x: player.x + (player.facing>0 ? player.w : -10), y: player.y + player.h*0.4,
    w: 18, h: 14, dir: player.facing, speed: w.speed, dmg: w.dmg,
    travelled: 0, range: w.range, emoji: w.emoji,
  });
}
function updateProjectiles(dt){
  const L = currentLevel();
  for(const pr of projectiles){
    const step = (pr.speed || 400) * dt;
    pr.x += pr.dir * step; pr.travelled += step;
    for(const e of L.enemies){
      if(e.alive && aabb(pr, e)){ e.alive = false; state.score += 20; pr.dead = true; }
    }
  }
  projectiles = projectiles.filter(pr => !pr.dead && pr.travelled < pr.range);
}
```

- [ ] **Step 3: Feuer-Taste + Cooldown**

In `keydown`-Handler ist `KeyF` bereits erlaubt. In `update`, nach `movePlayer`:

```js
  player.cooldown = Math.max(0, (player.cooldown||0) - dt);
  if(keys.has('KeyF')) fireWeapon();
  updateProjectiles(dt);
```

- [ ] **Step 4: Projektile zeichnen**

In `render()`, vor dem Broccoli:

```js
  ctx.font = '20px serif';
  for(const pr of projectiles) ctx.fillText(pr.emoji, pr.x - cx, pr.y + 14);
```

- [ ] **Step 5: Im Browser verifizieren**

Neu laden. F drücken Richtung Gegner. Konsole prüfen.
Erwartung: Salz-Projektil fliegt in Blickrichtung, verschwindet nach Reichweite, besiegt getroffene Gegner (Score +20), Cooldown verhindert Dauerfeuer.

- [ ] **Step 6: Checkpoint** — Waffe feuert, Projektile besiegen Gegner, Cooldown wirkt.

---

### Task 7: Kostüm-Fähigkeiten-System + Level 2 „Astronaut" (niedrige Schwerkraft)

**Files:**
- Modify: `broccoli-quest.html` (Abschnitt 4 COSTUMES ability, `movePlayer`, Abschnitt 3 neues Level 2)

**Interfaces:**
- Consumes: `costume()`, `CONFIG`, `player`.
- Produces: `effGravity()`, `effJumpV()` — von `movePlayer` genutzt.

- [ ] **Step 1: Ability-Felder ergänzen**

In `COSTUMES` `basis` und `astronaut` erweitern:

```js
  basis:     { emoji:'🧢', ability:{gravityMul:1, jumpMul:1}, weapon:{emoji:'🧂', speed:520, range:260, cooldown:0.35, dmg:1} },
  astronaut: { emoji:'🚀', ability:{gravityMul:0.45, jumpMul:1.15}, weapon:{emoji:'⚡', speed:700, range:520, cooldown:0.30, dmg:1} },
```

- [ ] **Step 2: `movePlayer` nutzt effektive Werte**

Helfer über `movePlayer` einfügen und die zwei Physik-Zeilen ersetzen:

```js
function effGravity(){ return CONFIG.GRAVITY * (costume().ability?.gravityMul ?? 1); }
function effJumpV(){ return CONFIG.JUMP_V * (costume().ability?.jumpMul ?? 1); }
```
`player.vy += CONFIG.GRAVITY * dt;` → `player.vy += effGravity() * dt;`
`player.vy = -CONFIG.JUMP_V;` → `player.vy = -effJumpV();`

- [ ] **Step 3: Level 2 als Datenobjekt anhängen (in `LEVELS`, nach Level 1)**

```js
  {
    name: 'Weltraum-Station', costume: 'astronaut', worldW: 3000, groundY: 500, bg: '#0b1026',
    platforms: [
      {x:0,y:500,w:500,h:60},
      {x:640,y:430,w:150,h:20},{x:900,y:340,w:150,h:20},{x:1180,y:260,w:150,h:20},
      {x:1450,y:360,w:180,h:20},{x:1780,y:300,w:160,h:20},{x:2050,y:420,w:220,h:20},
      {x:2350,y:500,w:650,h:60},
    ],
    hazards: [],
    enemies: [
      {x:950, y:300, w:30,h:28, type:'walker', emoji:'👾', dir:1, speed:70, range:120, baseX:950, alive:true},
      {x:1820,y:262, w:30,h:28, type:'walker', emoji:'🛸', dir:-1,speed:90, range:100, baseX:1820,alive:true},
    ],
    stars: [{x:960,y:300},{x:1240,y:220},{x:1840,y:260}],
    checkpoints: [{x:1450,y:316}],
    start:{x:60,y:440}, goalX:2900,
  },
```

- [ ] **Step 4: Im Browser verifizieren**

Neu laden. Level 1 durchspielen bis Ziel → Level 2 lädt automatisch.
Erwartung: Im Astronauten-Level springt der Broccoli deutlich höher/schwebender (niedrige Schwerkraft), Kostüm-HUD-Name „Weltraum-Station", Waffe = ⚡-Laser. Die weit auseinanderliegenden Plattformen sind nur mit den hohen Sprüngen erreichbar.

- [ ] **Step 5: Checkpoint** — Fähigkeits-System greift; Level 2 nur mit niedriger Schwerkraft schaffbar.

---

### Task 8: Level 3 „Taucher" — Schwimm-Fähigkeit

**Files:**
- Modify: `broccoli-quest.html` (Abschnitt 4 ability, `movePlayer`, Abschnitt 3 Level 3)

**Interfaces:**
- Consumes: `costume()`, `keys`, `player`.
- Produces: `ability.swim` (bool); `movePlayer` verzweigt in Schwimm-Modus.

- [ ] **Step 1: Taucher-Ability setzen**

```js
  taucher:   { emoji:'🤿', ability:{swim:true, swimSpeed:200}, weapon:{emoji:'🫧', speed:480, range:300, cooldown:0.40, dmg:1} },
```

- [ ] **Step 2: Schwimm-Modus in `movePlayer`**

Am Anfang von `movePlayer`, nach dem horizontalen Block, verzweigen:

```js
  if(costume().ability?.swim){
    // frei steuerbares Schwimmen, gedämpfte „Schwerkraft" (Auftrieb)
    const up = keys.has('ArrowUp')||keys.has('KeyW')||keys.has('Space');
    const down = keys.has('ArrowDown')||keys.has('KeyS');
    const s = costume().ability.swimSpeed;
    player.vy = (up ? -s : down ? s : 40); // leichtes Absinken
    player.y += player.vy * dt;
    // horizontale Bewegung wurde oben schon gesetzt; keine Plattform-Landung nötig, aber Boden begrenzt
    const L = currentLevel();
    if(player.y + player.h > L.groundY){ player.y = L.groundY - player.h; }
    if(player.y < 0) player.y = 0;
    return; // Schwerkraft/Sprung überspringen
  }
```

Ergänze `'ArrowDown','KeyS'` zur erlaubten Tastenliste im `keydown`-Handler.

- [ ] **Step 3: Level 3 anhängen (in `LEVELS`)**

```js
  {
    name: 'Korallen-Riff', costume: 'taucher', worldW: 3000, groundY: 520, bg: '#0a5c8a',
    platforms: [ {x:0,y:520,w:3000,h:40} ], // Meeresboden durchgehend
    hazards: [],
    enemies: [
      {x:700, y:200, w:30,h:30, type:'walker', emoji:'🪼', dir:1, speed:60, range:140, baseX:700, alive:true},
      {x:1200,y:360, w:30,h:30, type:'walker', emoji:'🐚', dir:1, speed:50, range:120, baseX:1200,alive:true},
      {x:1900,y:150, w:30,h:30, type:'walker', emoji:'🪼', dir:-1,speed:70, range:160, baseX:1900,alive:true},
    ],
    stars: [{x:760,y:120},{x:1500,y:300},{x:2200,y:180}],
    checkpoints: [{x:1500,y:300}],
    start:{x:60,y:200}, goalX:2900,
  },
```

- [ ] **Step 4: Wasser-Optik (optional, kleiner Touch)**

In `render()` nach dem `bg`-Fill, nur wenn `costume().ability?.swim`, einen halbtransparenten Blauschleier legen:

```js
  if(costume().ability?.swim){ ctx.fillStyle='rgba(0,80,160,.15)'; ctx.fillRect(0,0,CONFIG.W,CONFIG.H); }
```

- [ ] **Step 5: Im Browser verifizieren**

Neu laden, bis Level 3 spielen (ggf. via Debug-Sprung, s.u.).
Erwartung: Broccoli schwimmt frei hoch/runter mit ↑/↓, sinkt sonst langsam; erreicht hochliegende Sterne und weicht Quallen aus.

> **Debug-Tipp zum schnellen Testen später Levels:** temporär in der Konsole `loadLevel(2)` aufrufen (Preview-Browser `javascript_tool`), nicht im Code belassen.

- [ ] **Step 6: Checkpoint** — Schwimm-Level funktioniert.

---

### Task 9: Level 4 „Feuerwehr" — Lava-Hazards + Wasserstrahl-Nahwaffe

**Files:**
- Modify: `broccoli-quest.html` (Abschnitt 4 ability, `updateEnemies`/hazards, `update`, Abschnitt 3 Level 4, `render`)

**Interfaces:**
- Consumes: `hurt`, `aabb`, `currentLevel`.
- Produces: `hazards`-Verarbeitung (`{x,y,w,h,type:'lava'}`), Nahbereich-Waffe (speed 0).

- [ ] **Step 1: Feuerwehr-Ability + Hazard-Kollision**

```js
  feuerwehr: { emoji:'🔥', ability:{gravityMul:1, jumpMul:1}, weapon:{emoji:'💦', speed:0, range:110, cooldown:0.15, dmg:1} },
```

Hazard-Prüfung in `update`, nach `updateEnemies(dt)`:

```js
  for(const hz of (L.hazards||[])){
    if(hz.type==='lava' && aabb(player, hz)) hurt();
  }
```

- [ ] **Step 2: Nahbereich-Waffe (speed 0) in `updateProjectiles` behandeln**

`updateProjectiles` erweitern: bei `pr.speed===0` bleibt das Projektil am Player „kleben" und wirkt als kurzer Strahl:

```js
function updateProjectiles(dt){
  const L = currentLevel();
  for(const pr of projectiles){
    if(pr.speed === 0){
      // Nahbereich-Strahl: folgt dem Player, kurze Lebensdauer über range als „Zeit*100"
      pr.x = player.x + (pr.dir>0 ? player.w : -pr.range); pr.w = pr.range; pr.h = 20;
      pr.y = player.y + player.h*0.4;
      pr.travelled += 300*dt;
    } else {
      const step = pr.speed * dt; pr.x += pr.dir*step; pr.travelled += step;
    }
    for(const e of L.enemies){ if(e.alive && aabb(pr, e)){ e.alive=false; state.score+=20; if(pr.speed!==0) pr.dead=true; } }
  }
  projectiles = projectiles.filter(pr => !pr.dead && pr.travelled < pr.range + (pr.speed===0?100:0));
}
```

- [ ] **Step 3: Level 4 anhängen (in `LEVELS`)**

```js
  {
    name: 'Vulkan-Höhle', costume: 'feuerwehr', worldW: 3000, groundY: 500, bg: '#2a0d0d',
    platforms: [
      {x:0,y:500,w:520,h:60},{x:700,y:500,w:300,h:60},{x:1150,y:500,w:300,h:60},
      {x:1600,y:420,w:180,h:20},{x:1900,y:340,w:180,h:20},{x:2200,y:500,w:800,h:60},
    ],
    hazards: [
      {x:520,y:520,w:180,h:40,type:'lava'},   // Lavabecken in Plattform-Lücken
      {x:1000,y:520,w:150,h:40,type:'lava'},
      {x:1450,y:520,w:150,h:40,type:'lava'},
    ],
    enemies: [
      {x:800, y:472, w:30,h:28, type:'walker', emoji:'🦎', dir:1, speed:70, range:100, baseX:800, alive:true},
      {x:2400,y:472, w:30,h:28, type:'walker', emoji:'🔥', dir:-1,speed:60, range:150, baseX:2400,alive:true},
    ],
    stars: [{x:760,y:440},{x:1950,y:290},{x:2500,y:440}],
    checkpoints: [{x:1600,y:376}],
    start:{x:60,y:440}, goalX:2900,
  },
```

- [ ] **Step 4: Lava zeichnen**

In `render()`, nach den Plattformen:

```js
  for(const hz of (L.hazards||[])){ if(hz.type==='lava'){ ctx.fillStyle='#ff5522'; ctx.fillRect(hz.x-cx,hz.y,hz.w,hz.h); } }
```

- [ ] **Step 5: Im Browser verifizieren**

Neu laden, bis Level 4 (Debug `loadLevel(3)`).
Erwartung: Lavabecken kosten bei Berührung ein Herz; Wasserstrahl (F) wirkt als kurzer Nahbereich-Strahl und besiegt nahe Gegner.

- [ ] **Step 6: Checkpoint** — Lava-Hazards + Nahwaffe funktionieren.

---

### Task 10: Level 5 „Ninja" — Wandsprung + Doppelsprung (Finale)

**Files:**
- Modify: `broccoli-quest.html` (Abschnitt 4 ability, `movePlayer`, Abschnitt 3 Level 5)

**Interfaces:**
- Consumes: `costume()`, `player`, `keys`.
- Produces: `ability.doubleJump`, `ability.wallJump`; `player.jumpsLeft`, `player.touchingWall`.

- [ ] **Step 1: Ninja-Ability**

```js
  ninja: { emoji:'🥷', ability:{doubleJump:true, wallJump:true}, weapon:{emoji:'⭐', speed:820, range:640, cooldown:0.25, dmg:1} },
```

- [ ] **Step 2: Doppelsprung + Wandsprung in `movePlayer`**

Sprung-Logik ersetzen. Vor der Kollisionsschleife `player.touchingWall = 0;` setzen; in der Kollisionsschleife bei seitlichem Überlappen `player.touchingWall = (player.x < p.x ? -1 : 1);`. Danach:

```js
  // Springen mit Doppel-/Wandsprung
  const canDouble = costume().ability?.doubleJump;
  const canWall   = costume().ability?.wallJump;
  const jp = jumpPressed();
  if(jp && !player.jumpHeld){
    if(player.onGround){ player.vy = -effJumpV(); player.jumpsLeft = canDouble?1:0; }
    else if(canWall && player.touchingWall){ player.vy = -effJumpV(); player.vx = -player.touchingWall*CONFIG.MOVE_SPEED; player.jumpsLeft = canDouble?1:0; }
    else if(canDouble && player.jumpsLeft>0){ player.vy = -effJumpV()*0.9; player.jumpsLeft--; }
  }
  player.jumpHeld = jp;
  if(player.onGround) player.jumpsLeft = canDouble?1:0;
```

Entferne den alten einfachen Sprung-Block (`if(jumpPressed() && player.onGround)…`).

- [ ] **Step 3: Level 5 anhängen (in `LEVELS`)**

```js
  {
    name: 'Bambus-Tempel', costume: 'ninja', worldW: 3200, groundY: 500, bg: '#123a2a',
    platforms: [
      {x:0,y:500,w:400,h:60},
      {x:560,y:200,w:40,h:300},   // hohe Wand für Wandsprung
      {x:760,y:380,w:140,h:20},{x:1000,y:280,w:40,h:220},
      {x:1200,y:360,w:150,h:20},{x:1500,y:260,w:150,h:20},
      {x:1780,y:200,w:40,h:300},{x:1980,y:340,w:180,h:20},
      {x:2300,y:440,w:200,h:20},{x:2600,y:500,w:600,h:60},
    ],
    hazards: [
      {x:400,y:540,w:160,h:20,type:'lava'},{x:2500,y:540,w:100,h:20,type:'lava'},
    ],
    enemies: [
      {x:820, y:352, w:30,h:28, type:'walker', emoji:'🦂', dir:1, speed:90, range:80, baseX:820, alive:true},
      {x:2050,y:312, w:30,h:28, type:'walker', emoji:'🥷', dir:-1,speed:110,range:120, baseX:2050,alive:true},
    ],
    stars: [{x:820,y:320},{x:1560,y:200},{x:2360,y:380}],
    checkpoints: [{x:1500,y:216}],
    start:{x:60,y:440}, goalX:3100,
  },
```

- [ ] **Step 4: Im Browser verifizieren**

Neu laden, bis Level 5 (Debug `loadLevel(4)`).
Erwartung: In der Luft nochmals Sprung = Doppelsprung; an einer Wand + Sprungtaste = Wandsprung wegstossen. Die hohen Wände sind nur so überwindbar.

- [ ] **Step 5: Checkpoint** — Doppel- und Wandsprung funktionieren; Finale spielbar.

---

### Task 11: Rahmen — Start-Screen, Win-Screen, Level-Übergangstext, Politur

**Files:**
- Modify: `broccoli-quest.html` (Abschnitt 2 STATE, `update`, `render`, INPUT)

**Interfaces:**
- Consumes: alles Bisherige.
- Produces: `state.screen` Steuerung (`start`/`play`/`levelIntro`/`win`), `renderStart()`, `renderWin()`, `renderLevelIntro()`.

- [ ] **Step 1: Startzustand auf `start` setzen** — in Abschnitt 2 `screen:'start'`; `loadLevel(0)` erst beim Start auslösen.

- [ ] **Step 2: Enter/Leertaste startet & Level-Intro**

In `update`, ganz oben:

```js
  if(state.screen === 'start'){ if(keys.has('Enter')||keys.has('Space')){ loadLevel(0); state.screen='play'; } return; }
  if(state.screen === 'win'){ if(keys.has('Enter')){ state.screen='start'; } return; }
```
Ergänze `'Enter'` zur erlaubten Tastenliste.

- [ ] **Step 3: Screens zeichnen**

In `render()` ganz am Anfang:

```js
  if(state.screen==='start'){ return renderStart(); }
  if(state.screen==='win'){ return renderWin(); }
```
Und neue Funktionen (Abschnitt 10):

```js
function centerText(lines, colorTitle){
  ctx.fillStyle='#10131f'; ctx.fillRect(0,0,CONFIG.W,CONFIG.H);
  ctx.textAlign='center';
  lines.forEach((l,i)=>{ ctx.fillStyle = i===0?colorTitle:'#e8e8e8'; ctx.font = (i===0?'54px':'26px')+' serif'; ctx.fillText(l, CONFIG.W/2, 180 + i*56); });
}
function renderStart(){ centerText(['🥦 Broccoli-Quest','5 Levels · 5 Kostüme · 5 Waffen','←/→ laufen · Leertaste springen · F Waffe','[Enter] zum Starten'], '#3fa34d'); }
function renderWin(){ centerText(['🏆 Geschafft!','Broccoli hat alle 5 Levels gemeistert!','Punkte: '+state.score,'[Enter] zurück zum Start'], '#ffd23f'); }
```

- [ ] **Step 4: Level-Intro-Einblendung (2 Sek.)**

In `loadLevel` `state.introTimer = 2;` setzen (Feld `introTimer`). In `update` (play-Zweig) `if(state.introTimer>0) state.introTimer -= dt;`. In `render()` am Ende, wenn `state.introTimer>0`, Overlay:

```js
  if(state.introTimer>0){ ctx.fillStyle='rgba(0,0,0,.45)'; ctx.fillRect(0,0,CONFIG.W,CONFIG.H);
    ctx.textAlign='center'; ctx.fillStyle='#fff'; ctx.font='40px serif';
    ctx.fillText('Level '+(state.levelIndex+1)+': '+L.name, CONFIG.W/2, 240);
    ctx.font='30px serif'; ctx.fillText(costume().emoji+' Kostüm bereit!', CONFIG.W/2, 300); }
```

- [ ] **Step 5: Vollständigen Durchlauf verifizieren**

Neu laden. Start-Screen → Enter → Level 1 bis 5 durchspielen → Win-Screen. `read_console_messages` (keine Fehler), Screenshots von Start-, einem Spiel- und Win-Screen.
Erwartung: Kompletter Ablauf ohne Fehler; jedes Level zeigt Intro mit Levelname + Kostüm; nach Level 5 erscheint der Win-Screen mit Punktzahl.

- [ ] **Step 6: Finaler Checkpoint** — Spiel von Start bis Sieg durchgängig spielbar.

---

## Self-Review

**Spec-Abdeckung:**
- Technik (eine HTML/Canvas-Datei, keine Libs) → Task 1 + Global Constraints ✓
- Ansicht Seitenansicht + Kamera → Task 3 ✓
- Steuerung ←/→/A/D, Sprung, F → Tasks 2, 6 ✓
- Regeln 3 Herzen/Checkpoint/Respawn/Level-Neustart → Task 4 ✓
- 5 Levels mit Kostüm+Fähigkeit+Waffe+Gegnern → Tasks 3,5,6,7,8,9,10 ✓
- Kostüm=Fähigkeit (Astronaut Schwerkraft, Taucher Schwimmen, Feuerwehr feuerfest/Dash, Ninja Doppel-/Wandsprung) → Tasks 7–10 ✓
- Kostüm-Waffe pro Level + Cooldown, kein Munitionszählen → Task 6 ✓
- Gegner mit Bewegung, besiegbar, Berührungsschaden → Tasks 5,6 ✓
- Sterne/Punkte, Start-/Win-Screen, Level-Übergänge → Tasks 3,11 ✓
- Feuerwehr-Dash: als Nahbereich-Waffe umgesetzt; separater Bewegungs-Dash ist YAGNI für V1 (Spec nennt „Wasser-Dash" primär als Waffe) — bewusst so gefasst.

**Platzhalter-Scan:** keine TBD/TODO; jeder Code-Schritt enthält vollständigen Code. ✓

**Typ-Konsistenz:** Gegner-Objektform `{x,y,w,h,type,emoji,dir,speed,range,baseX,alive}` durchgehend identisch (Tasks 5,7,8,9,10). Waffen-Objekt `{emoji,speed,range,cooldown,dmg}` und Ability-Felder `{gravityMul,jumpMul,swim,swimSpeed,doubleJump,wallJump}` konsistent. Funktionsnamen `hurt/respawn/loadLevel/currentLevel/costume/fireWeapon/updateProjectiles/updateEnemies/effGravity/effJumpV` überall gleich geschrieben. ✓

**Hinweis für die Umsetzung:** In Task 11 Step 4 wurde beim Feldnamen `introTimer` verwendet — durchgehend exakt `state.introTimer` schreiben (keine Umlaut-Tippfehler).
