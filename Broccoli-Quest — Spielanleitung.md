# 🥦 Broccoli-Quest

> Ein kleines 2D-Jump'n'Run: Ein Broccoli-Männchen absolviert 5 Levels und wechselt in jedem Level sein Kostüm — mit eigener Fähigkeit und Waffe.

## ▶ Spiel starten

**[▶ Broccoli-Quest starten](broccoli-quest.html)**

Alternativ per Doppelklick auf die Datei:
`C:\Users\TTUAFST1\Claude_Projects\Meine AI Projekte\Projekte\Broccoli-Quest\broccoli-quest.html`

Das Spiel läuft in jedem modernen Browser — **keine Installation, kein Internet nötig**. Auf dem Startbildschirm **[Enter]** drücken.

---

## Projekt-Zusammenfassung

| | |
|---|---|
| **Was** | Browser-Spiel (2D-Jump'n'Run) in einer einzigen HTML-Datei |
| **Technik** | Reines HTML + JavaScript + Canvas, keine Bibliotheken, kein Build |
| **Umfang** | 5 Levels, 5 Kostüme mit je eigener Fähigkeit + Waffe + Gegnern |
| **Grafik** | Canvas-Formen + Emojis (bunt, ohne externe Bilddateien) |
| **Status** | ✅ Fertig & spielbar (finales Review: „bereit zur Übergabe") |
| **Ordner** | `Projekte/Broccoli-Quest/` |

Das Spiel wurde schrittweise („subagent-driven") in 11 Aufgaben gebaut, jede einzeln im Browser verifiziert. Der komplette Verlauf liegt als Git-Historie im Projektordner.

**Verwandte Notizen:** [[2026-08-14-broccoli-quest-design]] (Design-Spec) · [[2026-08-14-broccoli-quest-plan]] (Umsetzungsplan)

---

## Kurzanleitung

### Ziel
Bringe den Broccoli 🥦 von links nach rechts durch jedes Level bis zum **🏁 Ziel-Beet**. Danach folgt automatisch das nächste Level mit einem neuen Kostüm. Nach Level 5 erscheint der **🏆 Sieg-Bildschirm**.

### Steuerung
| Taste | Aktion |
|---|---|
| **← →** oder **A / D** | Laufen |
| **Leertaste / ↑ / W** | Springen |
| **↑ / ↓** | Im Wasser hoch/runter schwimmen (Level 3) |
| **F** | Kostüm-Waffe abfeuern |
| **Enter** | Spiel starten / nach dem Sieg neu beginnen |

### Regeln
- Du hast **3 Herzen ❤️** pro Level.
- Ein Treffer durch einen Gegner oder ein Sturz in einen Abgrund kostet **1 Herz** — du erscheinst am letzten **🚩 Checkpoint** wieder.
- Bei **0 Herzen** startet das Level neu.
- **🌟 Sterne** einsammeln bringt Punkte.
- Gegner lassen sich mit der **Kostüm-Waffe (F)** besiegen; seitliche Berührung schadet dir.

### Die 5 Levels
| # | Kostüm | Level | Fähigkeit | Waffe |
|---|--------|-------|-----------|-------|
| 1 | 🧢 Basis | Der Garten | Laufen + Springen | 🧂 Salz-Streuer |
| 2 | 🚀 Astronaut | Weltraum-Station | Niedrige Schwerkraft (hohe Sprünge) | ⚡ Laser |
| 3 | 🤿 Taucher | Korallen-Riff | Schwimmen (frei hoch/runter) | 🫧 Blasen-Kanone |
| 4 | 🔥 Feuerwehr | Vulkan-Höhle | **Feuerfest** — läuft über Lava | 💦 Wasserstrahl |
| 5 | 🥷 Ninja | Bambus-Tempel | Doppelsprung + Wandsprung | ⭐ Wurfstern |

### Tipps
- **Astronaut:** Die weit auseinanderliegenden Plattformen erreichst du nur mit den hohen, schwebenden Sprüngen.
- **Taucher:** Mit ↑/↓ frei schwimmen, um Quallen und Seeigeln auszuweichen.
- **Feuerwehr:** Lauf ruhig über die Lava — nur die Feuerwehr kann das!
- **Ninja:** In der Luft nochmals springen (Doppelsprung); an einer Wand + Sprungtaste stösst du dich seitlich ab (Wandsprung), um hohe Wände zu überwinden.

---

## Ideen für später (optional)
- Endgegner in Level 5
- Sound-Effekte
- Highscore-Speicherung (localStorage)
- Mehr Gegner- und Hindernistypen pro Level-Thema
