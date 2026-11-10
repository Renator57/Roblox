# 🪙 Münzjäger – ein Roblox-Obby

Ein eigenes Roblox-Spiel: Lauf über eine Hindernisstrecke, sammle Münzen,
erreiche Checkpoints und kauf dir im Shop Upgrades.

## Features

- **10 Abschnitte** mit steigender Schwierigkeit, die Strecke wird beim Start per Code gebaut
- **5 Hindernis-Typen:** Sprungplattformen, schmale Zickzack-Balken, Lava mit Trittsteinen,
  verschwindende Glasplattformen und drehende Laser-Balken
- **Checkpoints:** nach dem Tod geht es am letzten Checkpoint weiter
- **Münzen**, die sich drehen und nach 20 Sekunden wieder auftauchen
- **Ziel** mit Bonus-Münzen und Sieg-Zähler (`Wins`)
- **Shop:** Leuchtaura, Turbo-Schuhe, Sprungfedern, Goldfinger (doppelte Münzen)
- **Speicherstand** über DataStore (Münzen, Checkpoint, Siege, gekaufte Items)
- Bestenliste über `leaderstats` (Coins / Stage / Wins)

## Projektstruktur

```
default.project.json         Rojo-Projekt
src/shared/Config.luau       Einstellungen (Strecke, Preise, Belohnungen) → ReplicatedStorage.Shared
src/server/Main.server.luau  Spielregeln, Shop, Respawn               → ServerScriptService.Server
src/server/MapBuilder.luau   Baut die Strecke
src/server/PlayerData.luau   Laden/Speichern, leaderstats
src/client/HUD.client.luau   Anzeige, Shop-Fenster, Meldungen        → StarterPlayerScripts.Client
```

## Starten

### Mit Rojo (empfohlen)

1. [Rojo](https://rojo.space) installieren und das Rojo-Plugin in Roblox Studio aktivieren.
2. Place-Datei bauen und in Studio öffnen:

   ```bash
   rojo build -o Muenzjaeger.rbxlx
   ```

   Oder live synchronisieren: `rojo serve` ausführen und im Studio-Plugin auf **Connect** klicken.
3. In Studio auf **Play** drücken.

### Ohne Rojo (von Hand in Studio)

1. In **ReplicatedStorage** einen Ordner `Shared` anlegen und darin ein **ModuleScript** `Config`
   mit dem Inhalt von `src/shared/Config.luau`.
2. In **ServerScriptService** einen Ordner `Server` anlegen mit:
   - **Script** `Main` ← `src/server/Main.server.luau`
   - **ModuleScript** `MapBuilder` ← `src/server/MapBuilder.luau`
   - **ModuleScript** `PlayerData` ← `src/server/PlayerData.luau`
3. In **StarterPlayer → StarterPlayerScripts** ein **LocalScript** `HUD` ← `src/client/HUD.client.luau`.
4. **Play** drücken.

> Damit das Speichern in Studio funktioniert: *Game Settings → Security →
> Enable Studio Access to API Services* einschalten (das Spiel muss dafür veröffentlicht sein).
> Ohne diese Einstellung läuft das Spiel trotzdem, nur ohne Speicherstand.

## Anpassen

Alle wichtigen Werte stehen in `src/shared/Config.luau`, z. B. die Anzahl der Abschnitte
(`STAGE_COUNT`), der Ziel-Bonus (`FINISH_BONUS`) oder die Shop-Preise (`ITEMS`).
