--!strict
-- Zentrale Einstellungen für "Münzjäger". Hier kannst du das Spiel anpassen.

local Config = {}

Config.GAME_NAME = "Münzjäger"

-- Strecke
Config.STAGE_COUNT = 10 -- Anzahl der Abschnitte (jeder beginnt mit einem Checkpoint)
Config.STAGE_LENGTH = 44 -- Länge eines Abschnitts in Studs
Config.STAGE_RISE = 3 -- Höhenzuwachs pro Abschnitt

-- Belohnungen
Config.COIN_VALUE = 1
Config.COIN_RESPAWN_TIME = 20 -- Sekunden, bis eine Münze wieder erscheint
Config.FINISH_BONUS = 25 -- Münzen fürs Erreichen des Ziels

-- Spieler
Config.RESPAWN_TIME = 1.5
Config.BASE_WALKSPEED = 16
Config.BASE_JUMPPOWER = 50
Config.SPEED_BONUS = 8
Config.JUMP_BONUS = 12

-- Speichern
Config.DATASTORE_NAME = "MuenzjaegerData_v1"
Config.AUTOSAVE_INTERVAL = 120

-- Shop
export type Item = { id: string, name: string, desc: string, price: number }

Config.ITEMS = {
	{ id = "Glow", name = "Leuchtaura", desc = "Du leuchtest und funkelst.", price = 10 },
	{ id = "Speed", name = "Turbo-Schuhe", desc = "Schneller laufen.", price = 20 },
	{ id = "Jump", name = "Sprungfedern", desc = "Höher springen.", price = 35 },
	{ id = "Double", name = "Goldfinger", desc = "Jede Münze zählt doppelt.", price = 60 },
} :: { Item }

Config.ITEMS_BY_ID = {} :: { [string]: Item }
for _, item in Config.ITEMS do
	Config.ITEMS_BY_ID[item.id] = item
end

return Config
