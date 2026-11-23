# ✦ Lumen

Ein schöner, moderner Bildschirmschoner für macOS – geschrieben in Swift & SwiftUI.

- **5 animierte Hintergründe:** Aurora, Farbfluss (Mesh-Gradient), Sternenflug, Ozean, Lichter
- **Widgets:** Uhr, Datum, Batterie, Bibelvers – je in 4 Stilen (Glas, Minimal, Kräftig, Mono), auf 9 Positionen platzierbar
- **Dauer wählbar:** 1–60 Minuten Inaktivität oder nur manuell
- Apple-artiges Onboarding, Live-Vorschau, Menüleisten-App, Start beim Anmelden, mehrere Bildschirme, Burn-in-Schutz

## Installation
1. `Lumen-x.y.z.dmg` aus den [Releases](../../releases) laden
2. Lumen in den Programme-Ordner ziehen
3. Beim ersten Start: Rechtsklick → **Öffnen** (App ist ad-hoc signiert, nicht notarisiert)
   oder `xattr -dr com.apple.quarantine /Applications/Lumen.app`

Benötigt macOS 15 oder neuer.

## Selbst bauen
```sh
./scripts/build.sh   # → build/Lumen.app + build/Lumen-1.0.0.dmg
```
