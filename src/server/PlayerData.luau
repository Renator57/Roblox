-- Spielerdaten: laden, speichern und als leaderstats anzeigen.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local PlayerData = {}

local LEADERSTATS = { "Coins", "Stage", "Wins" }

local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DATASTORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[Münzjäger] DataStore nicht verfügbar, Fortschritt wird nicht gespeichert:", result)
	end
end

local profiles = {}

local function defaultData()
	return { Coins = 0, Stage = 0, Wins = 0, Items = {} }
end

local function keyFor(player)
	return "u_" .. player.UserId
end

function PlayerData.load(player)
	local data = defaultData()
	if store then
		local ok, saved = pcall(store.GetAsync, store, keyFor(player))
		if ok and type(saved) == "table" then
			for key, value in saved do
				data[key] = value
			end
		elseif not ok then
			warn("[Münzjäger] Laden fehlgeschlagen für", player.Name, saved)
		end
	end
	if type(data.Items) ~= "table" then
		data.Items = {}
	end
	data.Stage = math.clamp(tonumber(data.Stage) or 0, 0, Config.STAGE_COUNT - 1)

	profiles[player] = data

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	for _, name in LEADERSTATS do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Value = data[name]
		value.Parent = leaderstats
	end
	leaderstats.Parent = player

	for itemId in data.Items do
		player:SetAttribute("Owned_" .. itemId, true)
	end

	return data
end

function PlayerData.get(player)
	return profiles[player]
end

function PlayerData.set(player, key, value)
	local data = profiles[player]
	if not data then
		return
	end
	data[key] = value
	local leaderstats = player:FindFirstChild("leaderstats")
	local stat = leaderstats and leaderstats:FindFirstChild(key)
	if stat then
		stat.Value = value
	end
end

function PlayerData.add(player, key, amount)
	local data = profiles[player]
	if data then
		PlayerData.set(player, key, data[key] + amount)
	end
end

function PlayerData.grantItem(player, itemId)
	local data = profiles[player]
	if data then
		data.Items[itemId] = true
		player:SetAttribute("Owned_" .. itemId, true)
	end
end

function PlayerData.save(player)
	local data = profiles[player]
	if not (data and store) then
		return
	end
	local ok, err = pcall(store.SetAsync, store, keyFor(player), data)
	if not ok then
		warn("[Münzjäger] Speichern fehlgeschlagen für", player.Name, err)
	end
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

Players.PlayerRemoving:Connect(PlayerData.release)

return PlayerData
