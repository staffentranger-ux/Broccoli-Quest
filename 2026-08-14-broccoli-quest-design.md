# Broccoli-Quest — Design-Spezifikation

**Datum:** 2026-08-14
**Status:** Entwurf abgesegnet, bereit für Implementierungsplan
**Typ:** Kleines lokales 2D-Jump'n'Run (Browser-Spiel)

---

## 1. Überblick

Ein 2D-Jump'n'Run im Browser: Ein Broccoli-Männchen 🥦 absolviert 5 Levels. In jedem Level trägt es ein **anderes Kostüm**, das ihm **eine einzigartige Fähigkeit** und **eine themenpassende Waffe** verleiht. Ohne die jeweilige Fähigkeit lässt sich das Level nicht bestehen — das macht jedes Kostüm bedeutsam.

**Kern-Erlebnis:** Von links nach rechts durch das Level navigieren, Hindernisse überwinden, Gegner mit der Kostüm-Waffe besiegen, das 🏁 Ziel-Beet erreichen.

---

## 2. Technik & Rahmen

- **Plattform:** Reines HTML/JavaScript mit Canvas — eine einzelne Datei `broccoli-quest.html`.
- **Keine externen Abhängigkeiten:** keine Libraries, keine Installation, keine externen Bilddateien.
- **Start:** Doppelklick auf die HTML-Datei → läuft in jedem modernen Browser.
- **Grafikstil:** Simple Canvas-Formen (Rechtecke, Kreise) kombiniert mit Emojis (🥦🚀🔥🌟 usw.) für Charakter, Kostüme, Gegner und Deko. Bunt und sofort erkennbar.
- **Ansicht:** Seitenansicht (2D), Kamera folgt dem Broccoli horizontal.

---

## 3. Steuerung

| Taste | Aktion |
|---|---|
| ← / → oder A / D | Laufen |
| Leertaste / ↑ / W | Springen (bzw. Kostüm-Sprung-Fähigkeit) |
| F | Waffe abfeuern (wechselt automatisch mit dem Kostüm) |

- Die Kostüm-**Fähigkeit** ist an Bewegung/Sprung gekoppelt (z. B. Astronaut springt automatisch höher; Taucher steuert im Wasser frei hoch/runter).
- Die Kostüm-**Waffe** liegt auf einer eigenen Taste (F) mit kurzer Abkling­zeit (Cooldown), damit kein Dauerfeuer möglich ist. **Keine** Munitionsverwaltung (frustfrei).

---

## 4. Spielregeln

- **3 Herzen** ❤️❤️❤️ pro Level.
- **Treffer** (seitliche Gegnerberührung) oder **Sturz** in einen Abgrund → 1 Herz verloren, Respawn am **letzten Checkpoint** 🚩.
- **0 Herzen** → das ganze Level startet neu (Herzen voll aufgefüllt).
- **Ziel:** rechts das 🏁 Ziel-Beet erreichen → nächstes Level (mit neuem Kostüm).
- **Sterne** 🌟 optional einsammeln → Punkte / Highscore.
- Besiegte Gegner geben Punkte, evtl. lassen sie einen 🌟 fallen.

---

## 5. Die 5 Levels

Jedes Level = Kostüm + Thema + Fähigkeit + Waffe + eigene Gegner. Schwierigkeit steigt sanft an.

| # | Kostüm | Level-Thema | Fähigkeit | Waffe (F) | Gegner | Hindernisse |
|---|--------|-------------|-----------|-----------|--------|-------------|
| 1 | 🧢 Basis-Broccoli | Der Garten (Tutorial) | Laufen + Springen | 🧂 Salz-Streuer (kurze Salzwolke) | 🐌 Schnecken, 🐛 Raupen | Erdklumpen, kleine Löcher, hüpfende Schnecken |
| 2 | 🚀 Astronaut | Weltraum-Station | Niedrige Schwerkraft (hohe, schwebende Sprünge) | 🔫 Laser-Pistole (gerader Strahl) | 👾 Weltraum-Slugs, 🛸 Mini-UFOs | Schwebeplattformen, Laser-Barrieren, Meteoriten von oben |
| 3 | 🤿 Taucher | Korallen-Riff (Unterwasser) | Schwimmen (frei hoch/runter steuerbar) | 🫧 Harpune / Blasen-Kanone | 🐚 Beiss-Muscheln, 🪼 Quallen | Strömungen, Seeigel (Stacheln), schnappende Muscheln |
| 4 | 🔥 Feuerwehr-Broccoli | Vulkan-Höhle | Feuerfest + kurzer Wasser-Dash | 💦 Wasserstrahl (kurze Reichweite, dauerhaft) | 🦎 Lava-Molche, 🔥 Feuer-Schnecken | Lavaseen, fallende Felsen, Feuerfontänen |
| 5 | 🥷 Ninja | Bambus-Tempel (Finale) | Wandsprung + Doppelsprung | ⭐ Wurfstern / Shuriken (schnell, weit) | 🥷 Schatten-Schnecken, 🦂 Skorpione | Sägeblätter, bewegliche Spikes, Abgründe |

---

## 6. Gegner & Kampf

- **Waffe abfeuern** mit Taste F; die Waffe wechselt automatisch mit dem Kostüm (Projektiltyp, Reichweite, Cooldown sind pro Kostüm als Daten definiert).
- **Getroffene Gegner** werden besiegt/verjagt → Punkte, evtl. 🌟-Drop.
- **Seitliche Berührung** eines Gegners kostet 1 Herz (Respawn am Checkpoint).
- **Draufspringen** ist optional möglich (kann später ergänzt werden), primär läuft der Kampf über die Kostüm-Waffe.
- Gegner haben einfache Bewegung (patrouillieren / hüpfen / schweben).

---

## 7. Code-Struktur (grob)

- **Ein Game-Loop** (requestAnimationFrame): Update → Kollision → Render.
- **Levels als Daten:** jedes Level ist ein Objekt mit Listen von Plattformen, Hindernissen, Gegnern, Checkpoints, Sternen, Start-/Zielpunkt (alles als Koordinaten). → Levels leicht anpass- und erweiterbar.
- **Player-Objekt** mit austauschbarem **Kostüm-Modul** pro Level: bündelt Fähigkeit (z. B. Schwerkraft-Wert, Doppelsprung, Schwimmen) und Waffe (Projektiltyp, Reichweite, Cooldown) als Daten.
- **Gegner** als eigene, wiederverwendbare Einheit mit Position, Bewegungsmuster und „besiegbar"-Status.
- **Projektile** als leichte Objekte mit Richtung, Reichweite, Schaden.
- **Rendering** komplett über Canvas-Formen + Emojis (per `fillText`).

Ziel: jede Einheit (Player, Gegner, Projektil, Level-Loader) hat eine klare, isoliert testbare Aufgabe. Neue Kostüme/Levels = neue Daten, kein Umbau der Kern-Logik.

---

## 8. Umfang (Version 1)

- 5 spielbare Levels mit je eigenem Kostüm, Fähigkeit, Waffe und Gegnern.
- Herz-/Checkpoint-System, Sterne/Punkte, Level-Übergänge, einfacher Start- und Gewinn-Bildschirm.
- **Nicht in V1 (YAGNI):** Level-Editor, Speicherstände, Sound (kann später ergänzt werden), Endgegner (offen — evtl. später in Level 5).

---

## 9. Speicherort

- Projektordner: `Projekte/Broccoli-Quest/`
- Spieldatei: `Projekte/Broccoli-Quest/broccoli-quest.html`
- Diese Spec: `Projekte/Broccoli-Quest/2026-08-14-broccoli-quest-design.md`
