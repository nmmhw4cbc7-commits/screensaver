# ✦ Lumen

Ein schöner, moderner Bildschirmschoner für macOS – geschrieben in Swift & SwiftUI.

- **12 animierte Hintergründe:** Aurora, Farbfluss, Spektrum, Lava, Sternenflug, Netz, Ozean, Regen, Lichter, Glühwürmchen, Dämmerung – oder eigene Fotos (Ken-Burns-Überblendung). Tempo, Farbton und Helligkeit regelbar.
- **14 Widgets:** Uhr, Analoguhr, Datum, Kalender, Wetter (Open-Meteo), Weltzeit, Countdown, Begrüßung, Zitat, eigener Text, Batterie, System (CPU/RAM), Fortschritt (Tag/Woche/Jahr), Mondphase
- **9 Stile × 8 Farben:** Glas, Minimal, Kräftig, Mono, Neon, Serif, Kontur, Karte, Farbe
- **Editor:** Widgets per Drag & Drop frei platzieren, skalieren, duplizieren; Mitte rastet ein
- **8 fertige Designs** mit einem Klick (auch direkt im Menüleisten-Menü)
- **Verhalten:** Dauer 1–60 Min. oder manuell, pausiert bei Videos/Präsentationen, schaltet den Bildschirm optional aus, Start beim Anmelden, mehrere Bildschirme, Burn-in-Schutz

## Installation
1. `Lumen-x.y.z.dmg` aus den [Releases](../../releases) laden
2. Lumen in den Programme-Ordner ziehen
3. Beim ersten Start: Rechtsklick → **Öffnen** (App ist ad-hoc signiert, nicht notarisiert)
   oder `xattr -dr com.apple.quarantine /Applications/Lumen.app`

Benötigt macOS 15 oder neuer.

## Selbst bauen
```sh
./scripts/build.sh   # → build/Lumen.app + build/Lumen-2.0.0.dmg
```

### Entwickler-Flags
`Lumen.app/Contents/MacOS/Lumen --preset 4 --preview` setzt ein Design und startet sofort die Vorschau.
