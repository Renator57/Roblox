# 💎 Kristall-Imperium – ein Roblox-Incremental-Spiel

Jeder Spieler bekommt eine eigene schwebende Insel mit einem riesigen Kristall.
Klick den Kristall, kauf Helfer, die automatisch Kristalle sammeln, und bau deine
Insel immer weiter aus.

## So funktioniert das Spiel

- **Klicken:** Kristall anklicken oder den Knopf **⛏️ ABBAUEN** drücken.
- **8 Helfer** (Spitzhacke → Galaxiekern). Jeder gekaufte Helfer erscheint als 3D-Modell
  auf deiner Insel. Bei **Meilensteinen** (10, 25, 50, 100 …) verdoppelt sich die Produktion
  und das Modell wird größer.
- **12 Upgrades** für stärkere Klicks, mehr Produktion, Offline-Einnahmen und mehr.
- **Goldene Kristalle** tauchen zufällig auf: Glücksfund oder **Kristallrausch** (alles x7).
- **9 Insel-Ausbaustufen:** Steinweg, Laternen, Blumenwiese, Wasserfälle, Kristalltürme,
  Schwebende Inseln, Sternenringe, Regenbogen, Kristallkrone. Sie bleiben für immer.
- **Wiedergeburt (Rebirth):** Ab 1M gesammelten Kristallen neu starten und dafür
  **Sternenstaub** bekommen (+10 % Produktion pro Stück, für immer). Der Kristall bekommt
  eine neue Farbe.
- **Sternen-Shop:** Dauerhafte Upgrades mit Sternenstaub, z. B. die Kristall-Drohne
  (klickt automatisch), Sternenmotor, Rabatt und Startkapital.
- **Offline-Einnahmen** und **Speicherstand** per DataStore.

## Dateien

| Datei | In Roblox Studio | Typ |
|---|---|---|
| `src/shared/Config.luau` | ReplicatedStorage → `Shared` → `Config` | ModuleScript |
| `src/server/Main.server.luau` | ServerScriptService → `Server` → `Main` | Script |
| `src/server/MapBuilder.luau` | ServerScriptService → `Server` → `MapBuilder` | ModuleScript |
| `src/server/PlayerData.luau` | ServerScriptService → `Server` → `PlayerData` | ModuleScript |
| `src/client/HUD.client.luau` | StarterPlayer → StarterPlayerScripts → `HUD` | LocalScript |

Alle Werte (Preise, Helfer, Upgrades, Ausbaustufen) stehen in `Config.luau`.

## Starten

**Von Hand:** Die 5 Skripte wie in der Tabelle in Roblox Studio anlegen, den Code
hineinkopieren und **Play** drücken.

**Mit Rojo:** `rojo build -o KristallImperium.rbxlx` und die Datei in Studio öffnen.

Tipps:
- Unter *Spieleinstellungen → Sicherheit* „Enable Studio Access to API Services“
  einschalten, damit der Speicherstand funktioniert.
- Unter *Spieleinstellungen → Orte* die maximale Spielerzahl auf **8** stellen
  (es gibt 8 Inseln pro Server).
