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
- **Hub-Insel** in der Mitte mit Brücken zu allen Inseln, Stationen für Eier, Casino,
  Glücksrad und tägliche Belohnung.
- **Likes:** Auf jeder Insel steht ein ❤️. Ein Like gibt dem Besitzer +25 % für 5 Minuten,
  der Liker bekommt eine kleine Belohnung.
- **Kristallgolem:** Alle 3 Minuten landet ein Boss auf der Hub-Insel. Alle klicken ihn
  gemeinsam kaputt, Beute je nach Schaden, der MVP bekommt Sternenstaub.
- **Haustiere:** 3 Eier mit offenen Chancen, 15 Haustiere in 4 Seltenheiten, die dir
  hinterherlaufen und Produktion + Klicks verstärken. 3 gleiche → 1 goldenes (x3).
- **Kristall-Skins:** 9 Skins (Rubin, Eis, Feuer, Galaxie, Regenbogen …).
- **Tägliche Belohnung** (7-Tage-Serie) und **Glücksrad** (alle 4 Stunden gratis).
- **Glücksautomat:** Einsatz nur in Kristallen, Auszahlung ca. 95 %.
- **Robux-Shop:** exklusive Haustiere, Regenbogen-Skin, Kristallrausch, Gamepässe
  (VIP x2, +2 Haustier-Plätze).

## Dateien

| Datei | In Roblox Studio | Typ |
|---|---|---|
| `src/shared/Config.luau` | ReplicatedStorage → `Shared` → `Config` | ModuleScript |
| `src/server/Main.server.luau` | ServerScriptService → `Server` → `Main` | Script |
| `src/server/MapBuilder.luau` | ServerScriptService → `Server` → `MapBuilder` | ModuleScript |
| `src/server/PlayerData.luau` | ServerScriptService → `Server` → `PlayerData` | ModuleScript |
| `src/server/Hub.luau` | ServerScriptService → `Server` → `Hub` | ModuleScript |
| `src/server/Pets.luau` | ServerScriptService → `Server` → `Pets` | ModuleScript |
| `src/server/Fun.luau` | ServerScriptService → `Server` → `Fun` | ModuleScript |
| `src/client/HUD.client.luau` | StarterPlayer → StarterPlayerScripts → `HUD` | LocalScript |
| `src/client/Extras.client.luau` | StarterPlayer → StarterPlayerScripts → `Extras` | LocalScript |

Alle Werte (Preise, Helfer, Upgrades, Ausbaustufen) stehen in `Config.luau`.

## Starten

**Am einfachsten:** `KristallImperium.rbxlx` herunterladen und in Studio mit
*Datei → Aus Datei öffnen* öffnen. Die Datei wird mit `python3 tools/build_place.py`
aus `src/` gebaut.

**Von Hand:** Die 5 Skripte wie in der Tabelle in Roblox Studio anlegen, den Code
hineinkopieren und **Play** drücken.

**Mit Rojo:** `rojo build -o KristallImperium.rbxlx` und die Datei in Studio öffnen.

Tipps:
- Unter *Spieleinstellungen → Sicherheit* „Enable Studio Access to API Services“
  einschalten, damit der Speicherstand funktioniert.
- Unter *Spieleinstellungen → Orte* die maximale Spielerzahl auf **8** stellen
  (es gibt 8 Inseln pro Server).

## Robux-Shop einrichten

Der Shop funktioniert erst, wenn du die Artikel bei Roblox anlegst:

1. Spiel veröffentlichen (*Datei → In Roblox veröffentlichen*).
2. Auf [create.roblox.com](https://create.roblox.com) dein Spiel öffnen →
   **Monetarisierung → Entwicklerprodukte**. Für jeden Eintrag in `Config.PRODUCTS`
   ein Produkt mit Name und Preis anlegen und die **Produkt-ID** kopieren.
3. Unter **Monetarisierung → Pässe** die Gamepässe aus `Config.GAMEPASSES` anlegen
   und die **Pass-ID** kopieren.
4. Die IDs in `Config.luau` bei `productId = 0` bzw. `passId = 0` eintragen.

Hinweise zu den Roblox-Regeln: Haustiere für Robux werden als feste Haustiere verkauft
(keine Zufalls-Eier für Echtgeld). Glücksautomat und Glücksrad laufen nur mit Kristallen,
die man nicht für Robux kaufen kann. Fülle den Fragebogen zur Altersfreigabe
(*Experience-Fragebogen*) ehrlich aus und gib dort das simulierte Glücksspiel an.

## Eigene 3D-Modelle (schöner als die eingebauten)

Ohne eigene Modelle baut das Spiel Helfer, Haustiere und den Golem aus einfachen Formen.
Schöner wird es mit Modellen aus der **Toolbox**:

1. In Studio **Toolbox** öffnen, z. B. nach „cute cat“ oder „pickaxe“ suchen und ein Modell einfügen.
2. Das Modell im Explorer nach **ReplicatedStorage → Modelle** ziehen.
3. Es **genau** wie die ID umbenennen:
   - Helfer: `Pickaxe`, `Dwarf`, `Drill`, `Mine`, `Laser`, `Portal`, `Forge`, `Core`
   - Haustiere: `Mouse`, `Cat`, `Bunny`, `Fox`, `Dragon`, `Frog`, `Hedgehog`, `Owl`, `Spirit`,
     `Phoenix`, `Jelly`, `Comet`, `Wolf`, `Nebula`, `Unicorn`, `RainbowUnicorn`, `ShadowGriffin`
   - Boss: `Golem`
   - Bäume: beliebig viele, Name beginnt mit `Baum` (z. B. `Baum1`, `Baum2`, `Baum3`)

Größe und Position passt das Spiel automatisch an. Einzelne MeshParts aus der Toolbox funktionieren auch. Skripte in Toolbox-Modellen werden
aus Sicherheitsgründen entfernt.
