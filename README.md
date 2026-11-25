# ✦ Lumen

Ein Uhren-Bildschirmschoner für macOS – geschrieben in Swift & SwiftUI.

- **16 Zifferblätter:** Klassisch, Gestapelt, Klappzahlen, Worte (deutsche Wortuhr), Analog, Analog Kräftig, Punktmatrix, Segment, Binär, Ringe, Tagesbalken, Geteilt, Editorial, Kapseln, Orbit, Röhre
- **16 animierte Hintergründe:** Aurora, Farbfluss, Pastell, Spektrum, Lava, Mitternacht, Sternenflug, Netz, Sonar, Synthwave, Ozean, Regen, Lichter, Glühwürmchen, Dämmerung, eigene Fotos – Tempo, Farbton und Helligkeit regelbar
- **Frei kombinierbar** mit 6 Schriften und 10 Farben; Sekunden, 12/24 h, Datum und Live-Wetter zuschaltbar
- **Verhalten:** Dauer 1–60 Min. oder manuell, pausiert bei Videos/Präsentationen, schaltet den Bildschirm optional aus, Start beim Anmelden, mehrere Bildschirme, Burn-in-Schutz

## Installation
1. `Lumen-x.y.z.dmg` aus den [Releases](../../releases) laden
2. Lumen in den Programme-Ordner ziehen
3. Beim ersten Start: Rechtsklick → **Öffnen** (App ist ad-hoc signiert, nicht notarisiert)
   oder `xattr -dr com.apple.quarantine /Applications/Lumen.app`

Benötigt macOS 15 oder neuer.

## Selbst bauen
```sh
./scripts/build.sh   # → build/Lumen.app + build/Lumen-3.0.0.dmg
```

### Entwickler-Flags
`Lumen.app/Contents/MacOS/Lumen --face 2 --bg 9 --preview` wählt Zifferblatt und Hintergrund und startet sofort die Vorschau.
