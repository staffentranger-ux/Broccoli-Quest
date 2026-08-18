# 🥦 Broccoli-Quest

> Ein 2D-Jump'n'Run: Ein Broccoli-Männchen absolviert 10 Levels und wechselt in jedem Level sein Kostüm — mit eigener Fähigkeit und Waffe. Mit Online-Rangliste und Zeitbonus.

## ▶ Spiel starten

**[🌐 Online spielen (empfohlen)](https://staffentranger-ux.github.io/Broccoli-Quest/)** — dieser Link funktioniert auf jedem Gerät und teilt die gemeinsame Rangliste.

**[▶ Lokale Version starten](broccoli-quest.html)**

![[broccoli-quest.html]]

Das Spiel läuft in jedem modernen Browser — **keine Installation nötig**. Auf dem Startbildschirm **[Enter]** drücken.

> **Internet:** Das Spiel selbst läuft auch offline. Nur die 🏆 Online-Rangliste braucht eine Internetverbindung — ohne sie erscheint dort ein Hinweis, spielen kannst du trotzdem.

---

## Projekt-Zusammenfassung

| | |
|---|---|
| **Was** | Browser-Spiel (2D-Jump'n'Run) in einer einzigen HTML-Datei |
| **Technik** | Reines HTML + JavaScript + Canvas, keine Bibliotheken, kein Build |
| **Umfang** | 10 Levels, 10 Kostüme mit je eigener Fähigkeit + Waffe |
| **Gegner** | 5 Bewegungstypen · **Hindernisse:** 6 Typen |
| **Extras** | Online-Rangliste (Supabase), Zeitbonus, Sound, Gekocht-Animation |
| **Grafik** | Canvas-Formen + Emojis (bunt, ohne externe Bilddateien) |
| **Status** | ✅ Fertig & spielbar |
| **Online** | https://staffentranger-ux.github.io/Broccoli-Quest/ |

---

## Kurzanleitung

### Ziel
Bringe den Broccoli 🥦 von links nach rechts durch jedes Level bis zum **🏁 Ziel-Beet**. Danach folgt automatisch das nächste Level mit einem neuen Kostüm. Nach Level 10 erscheint der **🏆 Sieg-Bildschirm**, wo du deinen Namen für die Rangliste einträgst.

### Steuerung
| Taste | Aktion |
|---|---|
| **← →** oder **A / D** | Laufen |
| **Leertaste / ↑ / W** | Springen (halten = gleiten, wo möglich) |
| **↑ / ↓** | Im Wasser hoch/runter schwimmen (Level 3) |
| **F** | Kostüm-Waffe abfeuern |
| **M** | Sound an/aus 🔊 / 🔇 |
| **Enter** | Spiel starten · Namen bestätigen · zurück zum Start |
| **R** | Rangliste neu laden (Start-Bildschirm) |

### Punkte
| Aktion | Punkte |
|---|---|
| 🌟 Stern einsammeln | **+10** |
| Gegner besiegen | **+20** |
| ⏱ Zeitbonus | **+3 pro Sekunde** unter der Par-Zeit |
| 💀 Sterben | **−15** (nie unter 0) |

Die Uhr im HUD ist **grün**, solange du unter der Par-Zeit liegst — dann gibt es am Levelende Bonuspunkte. Der Bonus wird in der Einblendung des nächsten Levels angezeigt.

### Regeln
- Du hast **3 Herzen ❤️** pro Level.
- Ein Treffer oder Sturz kostet **1 Herz** — der Broccoli wird **gekocht** 🍲 und erscheint am letzten **🚩 Checkpoint** wieder.
- Bei **0 Herzen** landet er im Topf und das Level startet neu.
- Gegner lassen sich mit der **Kostüm-Waffe (F)** besiegen; seitliche Berührung schadet dir.

---

## Die 10 Levels

| # | Kostüm | Level | Fähigkeit | Waffe | Par-Zeit |
|---|--------|-------|-----------|-------|---------|
| 1 | 🧢 Basis | Der Garten | Laufen + Springen | 🧂 Salz-Streuer | 45s |
| 2 | 🚀 Astronaut | Weltraum-Station | Niedrige Schwerkraft (hohe Sprünge) | ⚡ Laser | 55s |
| 3 | 🤿 Taucher | Korallen-Riff | Schwimmen (frei hoch/runter) | 🫧 Blasen-Kanone | 55s |
| 4 | 🔥 Feuerwehr | Vulkan-Höhle | **Feuerfest** — läuft über Lava (max. 3s am Stück) | 💦 Wasserstrahl | 60s |
| 5 | 🥷 Ninja | Bambus-Tempel | Doppelsprung + Wandsprung | ⭐ Wurfstern | 70s |
| 6 | 🧲 Magnet | Schrottplatz | Zieht Sterne magnetisch an | 🔩 Schraube | 55s |
| 7 | 🪂 Gleiter | Windschlucht | **Gleiten** (Sprungtaste halten) | 🍃 Blattwirbel | 65s |
| 8 | ❄️ Eis | Gletscher | Rutschige Physik (Trägheit) | 🧊 Eiszapfen | 70s |
| 9 | ⚡ Blitz | Gewitterturm | 1,7× Lauftempo | ⚡ Blitzschlag | 60s |
| 10 | 👑 Meister | Gemüse-Palast | Doppelsprung **+** Gleiten (Finale) | 🌟 Sternenblitz | 90s |

---

## Gegner & Hindernisse

**Gegner-Typen:** patrouillierend · 🐸 hüpfend · 🪼 schwebend · 🦎 verfolgend (in Reichweite) · 🥷 schiessend

**Hindernisse:** Lava · ▲ Stacheln · ⚙️ Kreissäge (fährt hin und her) · 🔥 Feuerfontäne (rhythmisch) · ☄️ herabfallende Brocken · ein-/ausfahrende Spikes

**Umgebungs-Effekte:** Weltraum-Drift (Level 2) · Strömungen (Level 3) · Hitze-Auftrieb (Level 4) · Rückenwind (Level 7)

---

## Tipps

- **Astronaut:** Die weit auseinanderliegenden Plattformen erreichst du nur mit den hohen, schwebenden Sprüngen.
- **Taucher:** Mit ↑/↓ frei schwimmen, um Quallen und Seeigeln auszuweichen.
- **Feuerwehr:** Du kannst über Lava laufen — aber der Anzug hält nur **3 Sekunden**! Eine Leiste oben zeigt, wie lange noch. Ausserhalb der Lava kühlt er doppelt so schnell wieder ab, also zwischendurch auf festen Boden retten. Feuerfontänen schaden dir trotzdem sofort.
- **Ninja:** In der Luft nochmals springen (Doppelsprung); an einer Wand + Sprungtaste stösst du dich seitlich ab, um hohe Wände zu überwinden.
- **Magnet:** Sterne kommen von selbst — lauf einfach nah genug vorbei.
- **Gleiter:** Sprungtaste **gedrückt halten**, um weite Schluchten zu überqueren. Ohne Gleiten schaffst du sie nicht.
- **Eis:** Früh bremsen! Der Broccoli rutscht nach — sonst landest du in den Stacheln.
- **Blitz:** Sehr schnell, aber schwerer zu stoppen. Vor schmalen Plattformen rechtzeitig loslassen.
- **Meister:** Doppelsprung **und** Gleiten kombinieren — erst doppelt springen, dann gleiten.
- **Zeitbonus:** Sterne einsammeln kostet Zeit. Überlege, ob der Umweg die 10 Punkte wert ist, wenn die Uhr läuft.

---

## Rangliste

Nach dem Sieg tippst du deinen Namen ein (max. 12 Zeichen) und **[Enter]** trägt dich in die **gemeinsame Online-Bestenliste** ein. Alle Spieler, die den Online-Link nutzen, sehen dieselbe Top-10-Liste auf dem Startbildschirm.

---

## Verwandte Notizen

- 📐 [[2026-08-14-broccoli-quest-design]] — Design-Spezifikation (Grundspiel)
- 🛠️ [[2026-08-14-broccoli-quest-plan]] — Umsetzungsplan Grundspiel
- 🏆 [[2026-08-17-broccoli-quest-online-rangliste-design]] — Design Online-Rangliste
- ⚔️ [[2026-08-17-broccoli-quest-erweiterung-a-design]] — Design Gefahren/Gegner/Sound

## Ideen für später
- **Projekt B:** FPV-Ego-Perspektive + Blöcke abbauen/platzieren (eigenes 3D-Projekt)
- Endgegner im Finale
- Mehr Gegner- und Hindernistypen
