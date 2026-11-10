-- Kristall-Imperium: Hauptskript (Server).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local MapBuilder = require(script.Parent.MapBuilder)
local PlayerData = require(script.Parent.PlayerData)
local Hub = require(script.Parent.Hub)
local Pets = require(script.Parent.Pets)
local Fun = require(script.Parent.Fun)

-- Remotes ---------------------------------------------------------------

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local function remote(className, name)
	local r = Instance.new(className)
	r.Name = name
	r.Parent = remotes
	return r
end
local mineEvent = remote("RemoteEvent", "Mine")
local stateEvent = remote("RemoteEvent", "State")
local notifyEvent = remote("RemoteEvent", "Notify")
local buyFunction = remote("RemoteFunction", "Buy")
local rebirthFunction = remote("RemoteFunction", "Rebirth")
remotes.Parent = ReplicatedStorage

MapBuilder.build()
Players.CharacterAutoLoads = false

-- Sitzungen -------------------------------------------------------------

-- sessions[player] = { data, plot, tokens, frenzyEnd, nextGolden, golden, lastLevel }
local sessions = {}

local function now()
	return workspace:GetServerTimeNow()
end

-- Kristallrausch und Like-Boost
local function frenzyMultiplier(session)
	return Config.tempMultiplier(session, now())
end

local function notify(player, text, kind)
	notifyEvent:FireClient(player, text, kind)
end

local function sendState(player)
	local session = sessions[player]
	if not session then
		return
	end
	local data = session.data
	stateEvent:FireClient(player, {
		crystals = data.crystals,
		runTotal = data.runTotal,
		allTime = data.allTime,
		gens = data.gens,
		upgrades = data.upgrades,
		star = data.star,
		stardust = data.stardust,
		stardustSpent = data.stardustSpent,
		rebirths = data.rebirths,
		frenzyEnd = session.frenzyEnd,
		likeEnd = session.likeEnd,
		pets = data.pets,
		equipped = data.equipped,
		skins = data.skins,
		skin = data.skin,
		likes = data.likes,
		golemKills = data.golemKills,
		dailyDay = data.dailyDay,
		dailyStreak = data.dailyStreak,
		lastSpin = data.lastSpin,
		passes = data.passes,
	})
end

local function scheduleGolden(session)
	local delay = Config.GOLDEN_MIN_DELAY + math.random() * (Config.GOLDEN_MAX_DELAY - Config.GOLDEN_MIN_DELAY)
	session.nextGolden = os.clock() + delay * Config.goldenDelayFactor(session.data)
end

local function earn(session, amount)
	local data = session.data
	data.crystals += amount
	data.runTotal += amount
	data.allTime += amount
end

-- Prüft, ob die Insel eine neue Ausbaustufe erreicht hat
local function checkIslandLevel(player, session)
	local level = Config.islandLevel(session.data.allTime)
	if level > session.lastLevel then
		session.lastLevel = level
		MapBuilder.updatePlot(session.plot, session.data)
		notify(player, "🏗️ Deine Insel wächst: " .. Config.ISLAND_LEVELS[level].name .. "!", "build")
	end
end

-- Spieler betreten / verlassen ------------------------------------------

local function onCharacterAdded(player, character)
	local session = sessions[player]
	if not session then
		return
	end
	local humanoid = character:WaitForChild("Humanoid")
	character:WaitForChild("HumanoidRootPart")
	humanoid.Died:Connect(function()
		task.delay(2, function()
			if player.Parent == Players and player.Character == character then
				player:LoadCharacter()
			end
		end)
	end)
	task.wait()
	if character.Parent then
		character:PivotTo(session.plot.spawnCF)
	end
end

local function onPlayerAdded(player)
	local plot = MapBuilder.claimPlot(player)
	if not plot then
		player:Kick("Dieser Server ist voll. Bitte versuch es auf einem anderen Server.")
		return
	end

	local data = PlayerData.load(player)
	if player.Parent ~= Players then
		MapBuilder.releasePlot(plot)
		PlayerData.release(player)
		return
	end

	local session = {
		data = data,
		plot = plot,
		tokens = Config.CLICKS_PER_SECOND,
		frenzyEnd = 0,
		likeEnd = 0,
		nextGolden = 0,
		golden = nil,
		lastLevel = Config.islandLevel(data.allTime),
	}
	sessions[player] = session
	scheduleGolden(session)
	MapBuilder.updatePlot(plot, data)
	Pets.onJoin(player, session)

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	player:LoadCharacter()

	-- Offline-Einnahmen
	local offlineSeconds = data.lastSeen > 0 and math.clamp(os.time() - data.lastSeen, 0, Config.OFFLINE_MAX_SECONDS) or 0
	local factor = Config.hasUpgrade(data, "offline") and 1 or Config.OFFLINE_FACTOR
	local offlineGain = Config.perSecond(data) * offlineSeconds * factor
	sendState(player)
	task.delay(3, function()
		if sessions[player] ~= session then
			return
		end
		if offlineGain >= 1 then
			earn(session, offlineGain)
			notify(player, "😴 Während du weg warst, haben deine Helfer " .. Config.format(offlineGain) .. " 💎 gesammelt!", "gold")
			checkIslandLevel(player, session)
		else
			notify(player, "Willkommen bei " .. Config.GAME_NAME .. "! Klick den Kristall 💎", "info")
		end
	end)
end

local function onPlayerRemoving(player)
	local session = sessions[player]
	sessions[player] = nil
	if session then
		if session.golden then
			session.golden:Destroy()
		end
		MapBuilder.releasePlot(session.plot)
	end
	PlayerData.release(player)
end

-- Zusatz-Module (Hub-Insel, Haustiere, Robux, Glücksrad, Casino, Skins) ----

local ctx = {
	sessions = sessions,
	now = now,
	earn = earn,
	notify = notify,
	notifyAll = function(text, kind)
		notifyEvent:FireAllClients(text, kind)
	end,
	sendState = sendState,
	remote = remote,
	PlayerData = PlayerData,
	MapBuilder = MapBuilder,
	boost = frenzyMultiplier,
}
Hub.init(ctx)
Pets.init(ctx)
Fun.init(ctx)

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
PlayerData.startAutosave()

-- Klicken ---------------------------------------------------------------

mineEvent.OnServerEvent:Connect(function(player)
	local session = sessions[player]
	if not session or session.tokens < 1 then
		return
	end
	session.tokens -= 1
	earn(session, Config.clickValue(session.data) * frenzyMultiplier(session))
end)

-- Goldene Kristalle -----------------------------------------------------

local function collectGolden(player, session)
	local golden = session.golden
	if not golden then
		return
	end
	session.golden = nil
	golden:Destroy()

	local data = session.data
	local rewardMult = Config.hasUpgrade(data, "goldenReward") and 3 or 1
	if math.random() < 0.55 then
		local amount = math.max(Config.perSecond(data) * 90, Config.clickValue(data) * 40, 50) * rewardMult
		earn(session, amount)
		notify(player, "🍀 Glücksfund! +" .. Config.format(amount) .. " 💎", "gold")
	else
		local duration = Config.FRENZY_DURATION * rewardMult
		session.frenzyEnd = now() + duration
		notify(player, "🔥 KRISTALLRAUSCH! Alles x" .. Config.FRENZY_MULTIPLIER .. " für " .. duration .. " Sekunden!", "frenzy")
	end
	sendState(player)
end

local function spawnGolden(player, session)
	local golden, click, core = MapBuilder.spawnGolden(session.plot)
	session.golden = golden
	click.MouseClick:Connect(function(clicker)
		if clicker == player and sessions[player] == session and session.golden == golden then
			collectGolden(player, session)
		end
	end)
	core.Touched:Connect(function(hit)
		local character = player.Character
		if character and hit:IsDescendantOf(character) and session.golden == golden then
			collectGolden(player, session)
		end
	end)
	notify(player, "✨ Ein goldener Kristall ist auf deiner Insel erschienen!", "gold")
	task.delay(Config.GOLDEN_LIFETIME, function()
		if session.golden == golden then
			session.golden = nil
			golden:Destroy()
		end
	end)
end

-- Spielschleife ---------------------------------------------------------

local sendTimer, slowTimer = 0, 0

RunService.Heartbeat:Connect(function(dt)
	sendTimer += dt
	slowTimer += dt
	local sendNow = sendTimer >= 0.25
	local slowNow = slowTimer >= 1
	if sendNow then
		sendTimer = 0
	end
	if slowNow then
		slowTimer = 0
	end

	for player, session in sessions do
		-- Sicherheitsnetz: Wer von der Insel fällt, kommt zurück zum Startpunkt
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root.Position.Y < -40 then
			root.AssemblyLinearVelocity = Vector3.zero
			character:PivotTo(session.plot.spawnCF)
		end

		session.tokens = math.min(Config.CLICKS_PER_SECOND, session.tokens + Config.CLICKS_PER_SECOND * dt)
		earn(session, Config.perSecond(session.data) * frenzyMultiplier(session) * dt)

		if not session.golden and os.clock() >= session.nextGolden then
			scheduleGolden(session)
			spawnGolden(player, session)
		end
		if sendNow then
			sendState(player)
		end
		if slowNow then
			checkIslandLevel(player, session)
			PlayerData.updateLeaderstats(player)
			session.plot.sign.Text = "🏝️ " .. player.DisplayName .. "\n💎 " .. Config.format(Config.perSecond(session.data)) .. "/Sek  •  ❤️ " .. session.data.likes
		end
	end
end)

-- Shop ------------------------------------------------------------------

local function buyGenerator(player, session, id, amount)
	local gen = Config.GENERATORS_BY_ID[id]
	if not gen then
		return false, "Unbekannter Helfer."
	end
	local data = session.data
	local owned = data.gens[id] or 0
	local count
	if amount == "max" then
		count = Config.maxAffordable(gen, owned, data.crystals, data)
	elseif amount == 1 or amount == 10 or amount == 100 then
		count = amount
	else
		return false, "Ungültige Menge."
	end
	if count < 1 then
		return false, "Nicht genug Kristalle."
	end
	local cost = Config.generatorCost(gen, owned, count, data)
	if cost > data.crystals then
		return false, "Nicht genug Kristalle."
	end

	data.crystals -= cost
	data.gens[id] = owned + count
	MapBuilder.updatePlot(session.plot, data)

	local before, after = Config.milestonesReached(owned), Config.milestonesReached(owned + count)
	if after > before then
		notify(player, "🎉 Meilenstein! " .. gen.name .. " produziert jetzt x" .. Config.milestoneMultiplier(owned + count) .. "!", "build")
	end
	return true, gen.icon .. " +" .. count .. " " .. gen.name
end

local function buyUpgrade(session, id)
	local upgrade = Config.UPGRADES_BY_ID[id]
	local data = session.data
	if not upgrade then
		return false, "Unbekanntes Upgrade."
	end
	if data.upgrades[id] then
		return false, "Schon gekauft."
	end
	if data.crystals < upgrade.cost then
		return false, "Nicht genug Kristalle."
	end
	data.crystals -= upgrade.cost
	data.upgrades[id] = true
	if upgrade.kind == "luck" then
		scheduleGolden(session)
	end
	return true, upgrade.icon .. " " .. upgrade.name .. " gekauft!"
end

local function buyStarUpgrade(session, id)
	local upgrade = Config.STAR_UPGRADES_BY_ID[id]
	local data = session.data
	if not upgrade then
		return false, "Unbekanntes Upgrade."
	end
	local level = Config.starLevel(data, id)
	if level >= upgrade.maxLevel then
		return false, "Schon auf der höchsten Stufe."
	end
	local cost = Config.starUpgradeCost(upgrade, level)
	if Config.availableStardust(data) < cost then
		return false, "Nicht genug Sternenstaub."
	end
	data.stardustSpent += cost
	data.star[id] = level + 1
	return true, upgrade.icon .. " " .. upgrade.name .. " ist jetzt Stufe " .. (level + 1) .. "!"
end

buyFunction.OnServerInvoke = function(player, kind, id, amount)
	local session = sessions[player]
	if not session or type(id) ~= "string" then
		return false, "Fehler."
	end
	local ok, message
	if kind == "gen" then
		ok, message = buyGenerator(player, session, id, amount)
	elseif kind == "upgrade" then
		ok, message = buyUpgrade(session, id)
	elseif kind == "star" then
		ok, message = buyStarUpgrade(session, id)
	else
		return false, "Fehler."
	end
	sendState(player)
	return ok, message
end

-- Wiedergeburt ----------------------------------------------------------

rebirthFunction.OnServerInvoke = function(player)
	local session = sessions[player]
	if not session then
		return false, "Fehler."
	end
	local data = session.data
	local gain = Config.stardustForRun(data.runTotal)
	if gain < 1 then
		return false, "Sammle erst " .. Config.format(Config.REBIRTH_BASE) .. " 💎 in dieser Runde."
	end

	data.stardust += gain
	data.rebirths += 1
	data.runTotal = 0
	data.gens = {}
	data.upgrades = {}
	data.crystals = Config.startCrystals(data)
	session.frenzyEnd = 0

	MapBuilder.updatePlot(session.plot, data)
	PlayerData.updateLeaderstats(player)
	sendState(player)
	task.spawn(PlayerData.save, player)
	notifyEvent:FireAllClients("🌟 " .. player.DisplayName .. " ist wiedergeboren! (Rebirth " .. data.rebirths .. ")", "frenzy")
	return true, "✨ +" .. gain .. " Sternenstaub! Dein Kristall leuchtet in neuer Farbe."
end
