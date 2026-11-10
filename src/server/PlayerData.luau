-- Spielerdaten: laden, speichern und in der Bestenliste anzeigen.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local PlayerData = {}

local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DATASTORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[Kristall-Imperium] DataStore nicht verfügbar, Fortschritt wird nicht gespeichert:", result)
	end
end

local profiles = {}

local function defaultData()
	return {
		crystals = 0,
		runTotal = 0, -- gesammelt seit der letzten Wiedergeburt
		allTime = 0, -- insgesamt je gesammelt (für die Insel-Ausbaustufen)
		gens = {},
		upgrades = {},
		star = {},
		stardust = 0,
		stardustSpent = 0,
		rebirths = 0,
		lastSeen = 0,
		-- Haustiere: pets = { [uid] = "Cat" / "Cat*" (golden) }, equipped = { uid, ... }
		pets = {},
		equipped = {},
		nextPet = 1,
		-- Skins, Likes, Golem
		skins = { Default = true },
		skin = "Default",
		likes = 0,
		golemKills = 0,
		-- Tägliche Belohnung und Glücksrad
		dailyDay = 0,
		dailyStreak = 0,
		lastSpin = 0,
		-- Robux: bereits verarbeitete Käufe, Gamepässe (werden bei jedem Start neu geprüft)
		receipts = {},
		passes = {},
	}
end

local function keyFor(player)
	return "u_" .. player.UserId
end

local function sanitize(data)
	local clean = defaultData()
	for key, default in clean do
		local value = data[key]
		if type(value) == type(default) then
			clean[key] = value
		end
	end
	return clean
end

function PlayerData.load(player)
	local data = defaultData()
	if store then
		local ok, saved = pcall(store.GetAsync, store, keyFor(player))
		if ok and type(saved) == "table" then
			data = sanitize(saved)
			data.skins.Default = true
		elseif not ok then
			warn("[Kristall-Imperium] Laden fehlgeschlagen für", player.Name, saved)
		end
	end
	profiles[player] = data

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local perSecond = Instance.new("StringValue")
	perSecond.Name = "💎/Sek"
	perSecond.Parent = leaderstats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = leaderstats
	local likes = Instance.new("IntValue")
	likes.Name = "❤️"
	likes.Parent = leaderstats
	leaderstats.Parent = player
	PlayerData.updateLeaderstats(player)

	return data
end

function PlayerData.get(player)
	return profiles[player]
end

function PlayerData.updateLeaderstats(player)
	local data = profiles[player]
	local leaderstats = player:FindFirstChild("leaderstats")
	if not (data and leaderstats) then
		return
	end
	leaderstats["💎/Sek"].Value = Config.format(Config.perSecond(data))
	leaderstats.Rebirths.Value = data.rebirths
	leaderstats["❤️"].Value = data.likes
end

-- Gibt true zurück, wenn gespeichert wurde (oder es keinen DataStore gibt)
function PlayerData.save(player)
	local data = profiles[player]
	if not data then
		return false
	end
	if not store then
		return true
	end
	data.lastSeen = os.time()
	local ok, err = pcall(store.SetAsync, store, keyFor(player), data)
	if not ok then
		warn("[Kristall-Imperium] Speichern fehlgeschlagen für", player.Name, err)
	end
	return ok
end

function PlayerData.release(player)
	PlayerData.save(player)
	profiles[player] = nil
end

function PlayerData.startAutosave()
	task.spawn(function()
		while true do
			task.wait(Config.AUTOSAVE_INTERVAL)
			for player in profiles do
				task.spawn(PlayerData.save, player)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				PlayerData.save(player)
				pending -= 1
			end)
		end
		local started = os.clock()
		while pending > 0 and os.clock() - started < 25 do
			task.wait(0.1)
		end
	end)
end

return PlayerData
