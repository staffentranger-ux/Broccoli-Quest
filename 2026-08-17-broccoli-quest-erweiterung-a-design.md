# Broccoli-Quest — Erweiterung A: Gefahren, Gegner, Optik, Sound

**Datum:** 2026-08-17
**Status:** Entwurf abgesegnet, bereit für Implementierungsplan
**Erweitert:** bestehendes Spiel `broccoli-quest.html` (5 Levels, Kostüme, Online-Rangliste)

---

## 1. Überblick

Das Spiel bekommt deutlich mehr Abwechslung: neue Gegner-Bewegungstypen, bewegliche und statische Hindernisse, level-weite Umgebungs-Effekte, einen detaillierter gezeichneten und animierten Broccoli, synthetisierten Sound und eine humorvolle „Gekocht"-Todesanimation.

**Nicht Teil dieser Erweiterung:** FPV-Ego-Perspektive und Blöcke abbauen/platzieren. Beides gehört zum separaten **Projekt B** (3D-Minecraft-artiges Spiel, eigener Spec→Plan-Zyklus).

**Unverändert bleiben:** Kostüm-Fähigkeiten, Waffen, 3-Herzen-/Checkpoint-Regeln, Online-Rangliste, Ein-Datei-Prinzip.

## 2. Neue Gegner-Bewegungstypen

Die bestehende Gegner-Objektform wird um typspezifische Felder erweitert. Basis bleibt:
`{x, y, w, h, type, emoji, dir, speed, range, baseX, alive}`

| `type` | Verhalten | Zusätzliche Felder |
|---|---|---|
| `walker` | **(bestehend)** patrouilliert zwischen `baseX ± range` | — |
| `hopper` | patrouilliert wie `walker` **und** hüpft rhythmisch; vertikaler Offset per Sinus | `hopHeight` (px, z.B. 40), `hopSpeed` (Hz, z.B. 2), `baseY` (Ruhehöhe) |
| `flyer` | schwebt frei, ignoriert Schwerkraft; horizontal patrouillierend, vertikal Sinus | `floatAmp` (px, z.B. 60), `floatSpeed` (Hz, z.B. 0.8), `baseY` |
| `chaser` | patrouilliert; sobald der Spieler näher als `aggroRange` ist, bewegt er sich auf ihn zu (mit `chaseSpeed`) | `aggroRange` (px, z.B. 220), `chaseSpeed` (px/s, z.B. 130) |
| `shooter` | bewegt sich nicht; feuert alle `shootInterval` Sekunden ein Projektil Richtung `dir` | `shootInterval` (s, z.B. 2.0), `shotSpeed` (px/s, z.B. 260), `shotEmoji`, interner `cooldown` |

**Regeln für alle Typen (unverändert):**
- Berührung des Spielers → `hurt()` (1 Herz, Respawn am Checkpoint).
- Mit der Kostüm-Waffe besiegbar → `alive = false`, +20 Punkte.
- Besiegte Gegner (`alive === false`) werden weder bewegt noch gezeichnet und verursachen keinen Schaden.

**Gegner-Projektile** (nur `shooter`): eigenes Array `enemyShots` mit Objekten
`{x, y, w: 14, h: 14, dir, speed, emoji, travelled, range}`.
Treffen sie den Spieler → `hurt()`. Sie verschwinden nach `range` (z.B. 400 px). Sie sind **nicht** abschiessbar (bewusste Vereinfachung).

## 3. Neue Hindernis-Typen (`hazards`)

Das bestehende `hazards`-Array pro Level wird um neue Typen erweitert. Basis: `{x, y, w, h, type}`

| `type` | Verhalten | Zusätzliche Felder |
|---|---|---|
| `lava` | **(bestehend)** statisch, Schaden; für `fireproof` begehbare Fläche | — |
| `spikes` | statisch, Schaden bei Berührung | — |
| `saw` | fährt horizontal zwischen `baseX ± range` hin und her, rotiert optisch | `baseX`, `range`, `speed` (px/s), `dir` |
| `fountain` | bricht rhythmisch nach oben aus; **nur im aktiven Zustand** gefährlich | `period` (s, z.B. 2.5), `activeTime` (s, z.B. 1.0), `phase` (s, Startversatz), `maxH` (px Ausbruchshöhe) |
| `falling` | fällt von `baseY` nach unten; nach Aufprall/Verlassen des Bildschirms Respawn oben nach `respawnDelay` | `baseY`, `fallSpeed` (px/s), `respawnDelay` (s), interner `timer` |
| `retracting` | Spikes fahren ein und aus; **nur ausgefahren** gefährlich | `period` (s, z.B. 2.0), `activeTime` (s, z.B. 1.0), `phase` (s), `maxH` (px) |

**Schadenslogik:**
- `lava`: `fireproof`-Kostüme (Feuerwehr) nehmen **keinen** Schaden; Lava bleibt für sie zusätzlich begehbare Fläche (bestehendes Verhalten). Das bleibt der exklusive Vorteil des Feuerwehr-Kostüms.
- `fountain`: schadet **allen** Kostümen, auch `fireproof`. Begründung: Ein Feuerwehranzug lässt heissen Boden begehen, aber ein aktiv ausbrechender Feuerstrahl bleibt gefährlich. Andernfalls wären die Fontänen in Level 4 (Feuerwehr-Level) wirkungslos und damit kein Hindernis.
- `spikes`, `saw`, `falling`, `retracting`: schaden **allen** Kostümen.
- Zeitgesteuerte Typen (`fountain`, `retracting`) verursachen nur im aktiven Fenster Schaden; die Aktivphase berechnet sich als
  `((time + phase) % period) < activeTime`.

## 4. Umgebungs-Effekte pro Level

Neues optionales Feld am Level-Objekt: `env`.

| Level | `env` | Wirkung |
|---|---|---|
| 1 Der Garten | *(keins)* | — |
| 2 Weltraum-Station | `{type:'drift', ax: 40}` | konstanter horizontaler Drift (px/s²) nach rechts — schwereloses Gefühl |
| 3 Korallen-Riff | `{type:'current', zones:[{x,y,w,h,ax}]}` | in den Zonen wirkt eine horizontale Kraft (`ax` px/s², Vorzeichen = Richtung) |
| 4 Vulkan-Höhle | `{type:'heat', zones:[{x,y,w,h,ay}]}` | in den Zonen wirkt Auftrieb nach oben (`ay` negativ, px/s²) |
| 5 Bambus-Tempel | *(keins)* | — |

Umgebungs-Effekte wirken auf die Spielerbewegung (`movePlayer`), **nicht** auf Gegner oder Projektile (bewusste Vereinfachung). Sie sind schwach genug, dass jedes Level weiterhin sicher steuerbar bleibt.

## 5. Verteilung der Gefahren (moderat steigend)

Die neuen Elemente ergänzen die bestehenden. Level 1 bleibt ein sanftes Tutorial, Level 5 wird fordernd.

| Level | Neue Gegner | Neue Hindernisse | Umgebung |
|---|---|---|---|
| 1 Der Garten | 1× `hopper` 🐸 | 1× `spikes` | — |
| 2 Weltraum-Station | 1× `flyer` 🛸 | 2× `falling` ☄️ | Drift |
| 3 Korallen-Riff | 1× `flyer` 🪼 (bestehende Quallen werden zu `flyer`) | 2× `spikes` 🦔 (Seeigel) | Strömung |
| 4 Vulkan-Höhle | 1× `chaser` 🦎 | 2× `fountain`, 1× `falling` | Hitze-Böen |
| 5 Bambus-Tempel | 1× `shooter` 🥷, 1× `chaser` 🦂 | 1× `saw`, 2× `retracting` | — |

Bestehende Gegner und Hindernisse bleiben erhalten; in Level 3 werden die beiden Quallen auf `flyer` umgestellt, weil sie schwimmen sollen.

## 6. Schönerer Broccoli

`drawPlayer` wird überarbeitet — weiterhin reine Canvas-Zeichnung, keine externen Bilddateien, alle 5 Kostüme behalten ihre Farbpalette (`COSTUME_LOOK`).

**Verbesserungen:**
- **Augen** im Broccoli-Kopf (zwei weisse Punkte mit dunkler Pupille, Blickrichtung folgt `facing`).
- **Umrisse und Schattierung**: dunklere Kante am Rumpf, hellerer Streifen als Lichtkante.
- **Lauf-Animation**: bei horizontaler Bewegung am Boden wechseln die Beine sichtbar (2 Phasen, umgeschaltet über eine Schrittzeit), Arme schwingen leicht gegenläufig.
- **Sprung-Pose**: in der Luft (`!onGround`) sind Arme angehoben und Beine angezogen.
- **Idle-Wippen**: im Stand ein sehr leichtes vertikales Wippen (±1 px, langsame Sinuskurve).
- **Schwimm-Pose** (Level 3): Arme seitlich ausgestreckt.

Neuer Zustand am Player: `animTime` (s, läuft mit `dt` mit) für die Animationsphasen.

## 7. Sound (Web Audio API, synthetisiert)

Neuer Abschnitt `SOUND`. Alle Klänge werden **im Code erzeugt** (Oszillatoren + Gain-Hüllkurven) — keine Audio-Dateien, damit das Ein-Datei-Prinzip erhalten bleibt.

| Ereignis | Klang (Charakter) |
|---|---|
| Sprung | kurzer aufsteigender Ton |
| Waffe abfeuern | kurzes, trockenes Zischen/Klick |
| Gegner besiegt | kurzer absteigender „Plopp" |
| 🌟 Stern gesammelt | heller, kurzer Zwei-Ton-Aufstieg |
| Treffer/Schaden | tiefer, kurzer Brumm-Ton |
| Kochen (Tod) | blubbernde, tiefe Tonfolge |
| Level geschafft | kurze aufsteigende Dreiton-Fanfare |
| Sieg (Spiel durch) | längere Fanfare |

**Regeln:**
- **`AudioContext` wird erst bei der ersten Nutzereingabe erzeugt** (Browser blockieren Audio vor Interaktion). Vorher werden Klänge stillschweigend verworfen.
- **[M] schaltet den Sound stumm/wieder an.** Der Zustand wird in `localStorage` (`broccoliQuestMuted`) gemerkt.
- Der Mute-Status wird im HUD und auf dem Start-Screen als kleiner Hinweis angezeigt (🔊 / 🔇).
- Fehlt Web Audio im Browser, läuft das Spiel normal weiter — nur ohne Ton (kein Absturz).

## 8. „Gekocht"-Todesanimation

Ersetzt den bisherigen sofortigen Respawn.

**Ablauf bei jedem Herzverlust (`hearts > 0` danach):**
1. Neuer Zustand `state.cooking = {t: 0, big: false}`; Spielerbewegung und Gegner sind währenddessen eingefroren.
2. ~1,0 Sekunde Animation: Broccoli-Kopf färbt sich olivgrün, sinkt leicht zusammen, 💨 Dampfwolken steigen auf, Blubber-Sound.
3. Danach `respawn()` am letzten Checkpoint, `cooking` wird zurückgesetzt.

**Ablauf bei 0 Herzen (grosse Version):**
1. `state.cooking = {t: 0, big: true}`; ~2,0 Sekunden.
2. 🍲 Topf mit blubberndem Wasser wird gezeichnet, Broccoli sinkt hinein, Dampf, Schrift **„Gekocht!"**.
3. Danach `loadLevel(state.levelIndex)` — Level-Neustart mit 3 Herzen (bestehendes Verhalten).

Während `state.cooking` aktiv ist, verarbeitet `update` keine Spielereingaben und keine Gegner-/Hindernis-Bewegung; `render` zeichnet das Level weiter plus die Koch-Animation. Tasteneingaben können die Animation nicht überspringen (verhindert versehentliches Weiterspielen).

## 9. Technische Struktur

Alles bleibt in `broccoli-quest.html` (plus die Hosting-Kopie `index.html`), keine Libraries, kein Build.

**Neue bzw. geänderte Abschnitte:**
- **`SOUND`** (neu): `initAudio()`, `playSound(name)`, `toggleMute()`, `muted`-Zustand.
- **`ENEMIES`**: `updateEnemies(dt)` verzweigt pro `type`; neu `enemyShots` + `updateEnemyShots(dt)`.
- **`HAZARDS`** (neu): `updateHazards(dt)` bewegt `saw`/`falling` und berechnet Aktivphasen; `hazardActive(hz)` und `hazardDamages(hz)` als Helfer; `hazardRect(hz)` liefert die aktuell gefährliche Fläche (für `fountain`/`retracting` abhängig von der Phase).
- **`PHYSICS`/`movePlayer`**: wendet `env`-Kräfte an (Drift/Strömung/Hitze).
- **`RENDER`**: `drawPlayer` mit Animation und Details; neue Zeichenroutinen für alle Hazard-Typen und Gegner-Projektile; Koch-Animation; Mute-Anzeige.
- **`STATE`**: neu `state.cooking`, `state.time` (globale Spielzeit in Sekunden für Phasenberechnung), `player.animTime`.
- **`INPUT`**: `[M]` für Mute; erste Eingabe initialisiert Audio.

**Design-Prinzip:** Gegner- und Hindernis-Verhalten bleiben **datengetrieben** — neue Levels oder Varianten entstehen durch neue Datenobjekte, nicht durch neue Kern-Logik.

## 10. Robustheit

- Fehlende optionale Felder (z.B. kein `env`, kein `hazards`) dürfen nie zu einem Fehler führen — überall defensive Zugriffe (`(L.hazards||[])`).
- Web Audio nicht verfügbar oder blockiert → Spiel läuft ohne Ton weiter.
- `localStorage` nicht verfügbar → Mute-Zustand wird nur für die Sitzung gehalten.
- Die Koch-Animation darf nicht dauerhaft blockieren: Sie endet zwingend nach Ablauf ihrer Zeit, auch wenn zwischenzeitlich Tasten gedrückt werden.

## 11. Nicht im Umfang (YAGNI)

- FPV/3D und Blöcke abbauen/platzieren → **Projekt B**.
- Abschiessbare Gegner-Projektile.
- Umgebungs-Effekte auf Gegner/Projektile.
- Musik (nur Effekt-Sounds).
- Neue Levels, neue Kostüme, neue Waffen.
- Änderungen an der Online-Rangliste.

## 12. Betroffene Dateien

- `Projekte/Broccoli-Quest/broccoli-quest.html` — alle Änderungen.
- `Projekte/Broccoli-Quest/index.html` — identische Kopie fürs Hosting (am Ende aktualisieren + pushen).
