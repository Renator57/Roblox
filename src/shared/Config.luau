-- Kristall-Imperium: Einstellungen und Spielmathematik.
-- Wird von Server UND Client benutzt, damit beide gleich rechnen.

local Config = {}

Config.GAME_NAME = "Kristall-Imperium"

-- Welt
Config.PLOT_COUNT = 8 -- Anzahl Inseln (= max. Spieler pro Server)
Config.PLOT_RADIUS = 150 -- Abstand der Inseln vom Weltmittelpunkt

-- Wirtschaft
Config.COST_GROWTH = 1.15 -- jeder gekaufte Helfer macht den nächsten 15 % teurer
Config.MILESTONES = { 10, 25, 50, 100, 150, 200, 250, 300, 400, 500 } -- jeweils Produktion x2
Config.CLICKS_PER_SECOND = 20 -- Schutz gegen Autoklicker

-- Goldene Kristalle (Zufallsereignis)
Config.GOLDEN_MIN_DELAY = 40
Config.GOLDEN_MAX_DELAY = 90
Config.GOLDEN_LIFETIME = 15
Config.FRENZY_DURATION = 20
Config.FRENZY_MULTIPLIER = 7

-- Wiedergeburt
Config.REBIRTH_BASE = 1e6 -- ab so vielen gesammelten Kristallen gibt es Sternenstaub
Config.STARDUST_BONUS = 0.10 -- +10 % Produktion pro Sternenstaub

-- Offline-Einnahmen
Config.OFFLINE_MAX_SECONDS = 8 * 3600
Config.OFFLINE_FACTOR = 0.5

-- Speichern
Config.DATASTORE_NAME = "KristallImperium_v1"
Config.AUTOSAVE_INTERVAL = 90

-- Helfer: produzieren automatisch Kristalle pro Sekunde
Config.GENERATORS = {
	{ id = "Pickaxe", name = "Spitzhacke", icon = "⛏️", baseCost = 15, baseRate = 0.2 },
	{ id = "Dwarf", name = "Bergbau-Zwerg", icon = "🧔", baseCost = 100, baseRate = 1 },
	{ id = "Drill", name = "Dampfbohrer", icon = "🔩", baseCost = 1100, baseRate = 8 },
	{ id = "Mine", name = "Kristallmine", icon = "⛰️", baseCost = 12000, baseRate = 47 },
	{ id = "Laser", name = "Laserturm", icon = "🔦", baseCost = 130000, baseRate = 260 },
	{ id = "Portal", name = "Magieportal", icon = "🌀", baseCost = 1.4e6, baseRate = 1400 },
	{ id = "Forge", name = "Sternenschmiede", icon = "⭐", baseCost = 2e7, baseRate = 7800 },
	{ id = "Core", name = "Galaxiekern", icon = "🌌", baseCost = 3.3e8, baseRate = 44000 },
}

-- Einmalige Upgrades
-- kind: click (Klick x mult), clickPercent (Klick + value * Produktion),
--       global (alle Helfer x mult), luck, goldenReward, offline
Config.UPGRADES = {
	{ id = "Gloves", name = "Arbeitshandschuhe", icon = "🧤", desc = "Klicks x2", cost = 100, kind = "click", mult = 2 },
	{ id = "Coffee", name = "Zwergenkaffee", icon = "☕", desc = "Alle Helfer +50 %", cost = 2500, kind = "global", mult = 1.5 },
	{ id = "Hammer", name = "Diamanthammer", icon = "🔨", desc = "Klicks x3", cost = 10000, kind = "click", mult = 3 },
	{ id = "Luck", name = "Glücksklee", icon = "🍀", desc = "Goldene Kristalle doppelt so oft", cost = 50000, kind = "luck" },
	{ id = "Resonance", name = "Kristallresonanz", icon = "🔔", desc = "Klicks + 5 % deiner Produktion", cost = 100000, kind = "clickPercent", value = 0.05 },
	{ id = "TimeCrystal", name = "Zeitkristall", icon = "⏳", desc = "Volle Offline-Einnahmen statt 50 %", cost = 500000, kind = "offline" },
	{ id = "Moon", name = "Mondlicht", icon = "🌙", desc = "Alle Helfer x2", cost = 1e6, kind = "global", mult = 2 },
	{ id = "GoldVein", name = "Goldader", icon = "💰", desc = "Goldene Kristalle geben x3", cost = 2.5e6, kind = "goldenReward" },
	{ id = "Echo", name = "Echo-Kristall", icon = "🔮", desc = "Klicks + 10 % deiner Produktion", cost = 1e7, kind = "clickPercent", value = 0.10 },
	{ id = "Titan", name = "Titanfaust", icon = "👊", desc = "Klicks x5", cost = 1e8, kind = "click", mult = 5 },
	{ id = "Nova", name = "Supernova", icon = "💥", desc = "Alle Helfer x3", cost = 1e9, kind = "global", mult = 3 },
	{ id = "Infinity", name = "Unendlichkeit", icon = "♾️", desc = "Alle Helfer x5", cost = 1e11, kind = "global", mult = 5 },
}

-- Sternen-Shop: dauerhafte Upgrades, bezahlt mit Sternenstaub (bleiben bei Wiedergeburt)
-- Kosten pro Stufe: baseCost * 2 ^ Stufe
Config.STAR_UPGRADES = {
	{ id = "StarClick", name = "Sternenfaust", icon = "✊", desc = "Klicks x2 pro Stufe", baseCost = 1, maxLevel = 10 },
	{ id = "Drone", name = "Kristall-Drohne", icon = "🛸", desc = "Klickt automatisch 2x pro Sekunde je Stufe", baseCost = 2, maxLevel = 10 },
	{ id = "StarEngine", name = "Sternenmotor", icon = "🚀", desc = "Alle Helfer x1.5 pro Stufe", baseCost = 2, maxLevel = 20 },
	{ id = "Discount", name = "Sternenrabatt", icon = "🏷️", desc = "Helfer 6 % billiger pro Stufe", baseCost = 3, maxLevel = 8 },
	{ id = "HeadStart", name = "Startkapital", icon = "🎒", desc = "Starte jede Runde mit mehr Kristallen", baseCost = 1, maxLevel = 8 },
	{ id = "GoldRush", name = "Goldregen", icon = "🌟", desc = "Goldene Kristalle 15 % öfter pro Stufe", baseCost = 3, maxLevel = 5 },
}

-- Ausbaustufen der Insel. Hängen von ALLEN je gesammelten Kristallen ab
-- und bleiben deshalb auch nach einer Wiedergeburt stehen.
Config.ISLAND_LEVELS = {
	{ total = 500, name = "Steinweg" },
	{ total = 5000, name = "Laternen" },
	{ total = 50000, name = "Blumenwiese" },
	{ total = 5e5, name = "Wasserfälle" },
	{ total = 5e6, name = "Kristalltürme" },
	{ total = 5e7, name = "Schwebende Inseln" },
	{ total = 5e8, name = "Sternenringe" },
	{ total = 5e9, name = "Regenbogen" },
	{ total = 5e10, name = "Kristallkrone" },
}

-- Farbe des großen Kristalls je nach Anzahl Wiedergeburten
Config.REBIRTH_COLORS = {
	Color3.fromRGB(90, 200, 255),
	Color3.fromRGB(90, 255, 160),
	Color3.fromRGB(180, 110, 255),
	Color3.fromRGB(255, 110, 200),
	Color3.fromRGB(255, 200, 60),
	Color3.fromRGB(255, 90, 80),
	Color3.fromRGB(240, 245, 255),
}

----------------------------------------------------------------------
-- Hub-Insel, Likes und Kristallgolem
----------------------------------------------------------------------

Config.HUB_RADIUS = 42
Config.LIKE_COOLDOWN = 600 -- Sekunden, bis man dieselbe Insel wieder liken kann
Config.LIKE_BOOST = 1.25 -- Besitzer bekommt +25 % ...
Config.LIKE_BOOST_DURATION = 300 -- ... für 5 Minuten

Config.GOLEM_INTERVAL = 180 -- alle 3 Minuten kommt ein Golem
Config.GOLEM_DURATION = 90 -- so lange hat man Zeit, ihn zu besiegen
Config.GOLEM_HP_CLICKS = 120 -- Lebenspunkte = so viele Klicks pro Spieler
Config.GOLEM_REWARD_SECONDS = 180 -- Belohnung = so viele Sekunden Produktion

----------------------------------------------------------------------
-- Haustiere
----------------------------------------------------------------------

Config.MAX_EQUIPPED = 3
Config.MAX_PETS = 60
Config.GOLDEN_PET_FACTOR = 3 -- goldene Haustiere (aus 3 gleichen) haben x3 Bonus

Config.RARITIES = {
	Common = { name = "Gewöhnlich", color = Color3.fromRGB(190, 190, 205), order = 1 },
	Rare = { name = "Selten", color = Color3.fromRGB(80, 160, 255), order = 2 },
	Epic = { name = "Episch", color = Color3.fromRGB(185, 95, 255), order = 3 },
	Legendary = { name = "Legendär", color = Color3.fromRGB(255, 200, 40), order = 4 },
	Exclusive = { name = "Exklusiv", color = Color3.fromRGB(255, 80, 130), order = 5 },
}

-- boost: 0.10 = +10 % auf Produktion und Klicks
-- style: Tierart für das 3D-Modell (mouse, cat, bunny, fox, wolf, dragon, frog, hedgehog, owl, spirit, phoenix, jelly, unicorn, griffin)
Config.PETS = {
	{ id = "Mouse", name = "Kristallmaus", icon = "🐭", rarity = "Common", boost = 0.10, color = Color3.fromRGB(175, 175, 195), style = "mouse" },
	{ id = "Cat", name = "Steinkatze", icon = "🐱", rarity = "Common", boost = 0.15, color = Color3.fromRGB(150, 140, 130), style = "cat" },
	{ id = "Bunny", name = "Glitzerhase", icon = "🐰", rarity = "Rare", boost = 0.30, color = Color3.fromRGB(255, 200, 230), style = "bunny" },
	{ id = "Fox", name = "Edelsteinfuchs", icon = "🦊", rarity = "Epic", boost = 0.75, color = Color3.fromRGB(255, 140, 50), style = "fox" },
	{ id = "Dragon", name = "Diamantdrache", icon = "🐲", rarity = "Legendary", boost = 2.0, color = Color3.fromRGB(90, 220, 255), style = "dragon" },

	{ id = "Frog", name = "Moosfrosch", icon = "🐸", rarity = "Common", boost = 0.4, color = Color3.fromRGB(100, 200, 90), style = "frog" },
	{ id = "Hedgehog", name = "Pilzigel", icon = "🦔", rarity = "Common", boost = 0.6, color = Color3.fromRGB(150, 100, 70), style = "hedgehog" },
	{ id = "Owl", name = "Waldeule", icon = "🦉", rarity = "Rare", boost = 1.2, color = Color3.fromRGB(160, 120, 80), style = "owl" },
	{ id = "Spirit", name = "Baumgeist", icon = "🌳", rarity = "Epic", boost = 3, color = Color3.fromRGB(120, 255, 160), style = "spirit" },
	{ id = "Phoenix", name = "Phönix", icon = "🔥", rarity = "Legendary", boost = 8, color = Color3.fromRGB(255, 110, 40), style = "phoenix" },

	{ id = "Jelly", name = "Sternenqualle", icon = "🪼", rarity = "Common", boost = 2, color = Color3.fromRGB(200, 140, 255), style = "jelly" },
	{ id = "Comet", name = "Kometenkatze", icon = "☄️", rarity = "Common", boost = 3, color = Color3.fromRGB(80, 90, 160), style = "cat" },
	{ id = "Wolf", name = "Mondwolf", icon = "🐺", rarity = "Rare", boost = 6, color = Color3.fromRGB(200, 210, 235), style = "wolf" },
	{ id = "Nebula", name = "Nebeldrache", icon = "🐉", rarity = "Epic", boost = 15, color = Color3.fromRGB(150, 60, 220), style = "dragon" },
	{ id = "Unicorn", name = "Galaxie-Einhorn", icon = "🦄", rarity = "Legendary", boost = 50, color = Color3.fromRGB(255, 120, 230), style = "unicorn" },

	-- Exklusiv: nur im Robux-Shop
	{ id = "RainbowUnicorn", name = "Regenbogen-Einhorn", icon = "🌈", rarity = "Exclusive", boost = 10, color = Color3.fromRGB(255, 255, 255), style = "unicorn" },
	{ id = "ShadowGriffin", name = "Schattengreif", icon = "🦅", rarity = "Exclusive", boost = 30, color = Color3.fromRGB(60, 50, 90), style = "griffin" },
}

-- Eier: werden mit Kristallen gekauft, die Chancen stehen im Spiel
Config.EGGS = {
	{
		id = "Crystal", name = "Kristall-Ei", icon = "🥚", cost = 1000, color = Color3.fromRGB(120, 210, 255),
		pets = { { pet = "Mouse", chance = 50 }, { pet = "Cat", chance = 30 }, { pet = "Bunny", chance = 15 }, { pet = "Fox", chance = 4.5 }, { pet = "Dragon", chance = 0.5 } },
	},
	{
		id = "Forest", name = "Wald-Ei", icon = "🌿", cost = 1e6, color = Color3.fromRGB(110, 220, 110),
		pets = { { pet = "Frog", chance = 50 }, { pet = "Hedgehog", chance = 30 }, { pet = "Owl", chance = 15 }, { pet = "Spirit", chance = 4.5 }, { pet = "Phoenix", chance = 0.5 } },
	},
	{
		id = "Galaxy", name = "Galaxie-Ei", icon = "🌌", cost = 1e10, color = Color3.fromRGB(170, 100, 255),
		pets = { { pet = "Jelly", chance = 50 }, { pet = "Comet", chance = 30 }, { pet = "Wolf", chance = 15 }, { pet = "Nebula", chance = 4.5 }, { pet = "Unicorn", chance = 0.5 } },
	},
}

----------------------------------------------------------------------
-- Kristall-Skins
-- unlock.kind: free, crystals (cost), likes / golem / rebirths (amount), robux
----------------------------------------------------------------------

Config.SKINS = {
	{ id = "Default", name = "Standard", icon = "💎", desc = "Wechselt bei jeder Wiedergeburt die Farbe.", unlock = { kind = "free" } },
	{ id = "Ruby", name = "Rubin", icon = "❤️", color = Color3.fromRGB(255, 50, 80), unlock = { kind = "crystals", cost = 25000 } },
	{ id = "Emerald", name = "Smaragd", icon = "💚", color = Color3.fromRGB(40, 230, 120), unlock = { kind = "crystals", cost = 5e5 } },
	{ id = "Amethyst", name = "Amethyst", icon = "💜", color = Color3.fromRGB(170, 80, 255), unlock = { kind = "crystals", cost = 1e7 } },
	{ id = "Ice", name = "Eiskristall", icon = "❄️", color = Color3.fromRGB(200, 240, 255), material = "Glass", unlock = { kind = "likes", amount = 10 } },
	{ id = "Fire", name = "Feuerkristall", icon = "🔥", color = Color3.fromRGB(255, 120, 30), effect = "fire", unlock = { kind = "golem", amount = 5 } },
	{ id = "Gold", name = "Goldkristall", icon = "👑", color = Color3.fromRGB(255, 205, 60), effect = "sparkles", unlock = { kind = "rebirths", amount = 5 } },
	{ id = "Galaxy", name = "Galaxie", icon = "🌌", color = Color3.fromRGB(70, 30, 140), effect = "sparkles", unlock = { kind = "rebirths", amount = 15 } },
	{ id = "Rainbow", name = "Regenbogen", icon = "🌈", effect = "rainbow", unlock = { kind = "robux" } },
}

----------------------------------------------------------------------
-- Tägliche Belohnung, Glücksrad, Glücksautomat
----------------------------------------------------------------------

-- Tag 1-7: so viele Minuten deiner Produktion. Tag 7 gibt zusätzlich 1 Sternenstaub.
Config.DAILY_REWARDS = { 5, 10, 20, 30, 45, 60, 120 }
Config.DAILY_MIN = 500

Config.WHEEL_COOLDOWN = 4 * 3600
Config.WHEEL = {
	{ label = "5 Min 💎", kind = "minutes", value = 5, weight = 30, color = Color3.fromRGB(90, 200, 255) },
	{ label = "15 Min 💎", kind = "minutes", value = 15, weight = 20, color = Color3.fromRGB(60, 200, 110) },
	{ label = "Rausch 60s", kind = "frenzy", value = 60, weight = 15, color = Color3.fromRGB(255, 140, 40) },
	{ label = "Kristall-Ei", kind = "egg", value = "Crystal", weight = 15, color = Color3.fromRGB(120, 210, 255) },
	{ label = "1 Std 💎", kind = "minutes", value = 60, weight = 8, color = Color3.fromRGB(255, 205, 60) },
	{ label = "Wald-Ei", kind = "egg", value = "Forest", weight = 7, color = Color3.fromRGB(110, 220, 110) },
	{ label = "+1 ✨", kind = "stardust", value = 1, weight = 4, color = Color3.fromRGB(185, 95, 255) },
	{ label = "JACKPOT 3 Std", kind = "minutes", value = 180, weight = 1, color = Color3.fromRGB(255, 80, 130) },
}

-- Glücksautomat (nur mit Kristallen). Auszahlung ca. 95 %.
Config.SLOT_SYMBOLS = { "💎", "⭐", "🍀", "🔔", "🍒" }
Config.SLOT_TRIPLE = { ["💎"] = 15, ["⭐"] = 8, ["🍀"] = 4, ["🔔"] = 4, ["🍒"] = 4 }
Config.SLOT_PAIR = 1.4
Config.SLOT_BETS = { 0.1, 0.25, 0.5, 1 } -- Anteil deiner Kristalle
Config.SLOT_MIN_BET = 10

----------------------------------------------------------------------
-- Robux-Shop. Trage hier die IDs aus dem Creator Dashboard ein
-- (0 = noch nicht eingerichtet). Anleitung steht in der README.
----------------------------------------------------------------------

Config.PRODUCTS = {
	{ key = "RainbowUnicorn", productId = 0, name = "Regenbogen-Einhorn", icon = "🌈", desc = "Exklusives Haustier: +1000 %", reward = { kind = "pet", pet = "RainbowUnicorn" } },
	{ key = "ShadowGriffin", productId = 0, name = "Schattengreif", icon = "🦅", desc = "Exklusives Haustier: +3000 %", reward = { kind = "pet", pet = "ShadowGriffin" } },
	{ key = "RainbowSkin", productId = 0, name = "Regenbogen-Kristall", icon = "🌈", desc = "Dein Kristall leuchtet in allen Farben", reward = { kind = "skin", skin = "Rainbow" } },
	{ key = "Frenzy", productId = 0, name = "Kristallrausch 10 Min", icon = "🔥", desc = "Alles x7 für 10 Minuten", reward = { kind = "frenzy", seconds = 600 } },
}

Config.GAMEPASSES = {
	{ key = "VIP", passId = 0, name = "VIP: x2 Kristalle", icon = "👑", desc = "Alles bringt doppelt so viel – für immer" },
	{ key = "PetSlots", passId = 0, name = "+2 Haustier-Plätze", icon = "🐾", desc = "Rüste 5 statt 3 Haustiere aus" },
}

Config.PETS_BY_ID = {}
for _, pet in Config.PETS do
	Config.PETS_BY_ID[pet.id] = pet
end
Config.EGGS_BY_ID = {}
for _, egg in Config.EGGS do
	Config.EGGS_BY_ID[egg.id] = egg
end
Config.SKINS_BY_ID = {}
for _, skin in Config.SKINS do
	Config.SKINS_BY_ID[skin.id] = skin
end

Config.STAR_UPGRADES_BY_ID = {}
for _, upgrade in Config.STAR_UPGRADES do
	Config.STAR_UPGRADES_BY_ID[upgrade.id] = upgrade
end

Config.GENERATORS_BY_ID = {}
for _, gen in Config.GENERATORS do
	Config.GENERATORS_BY_ID[gen.id] = gen
end
Config.UPGRADES_BY_ID = {}
for _, upgrade in Config.UPGRADES do
	Config.UPGRADES_BY_ID[upgrade.id] = upgrade
end

----------------------------------------------------------------------
-- Zahlen schön anzeigen: 1234 -> 1.23K, 5600000 -> 5.60M
----------------------------------------------------------------------

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function Config.format(n)
	n = tonumber(n) or 0
	if n ~= n then
		return "0"
	end
	local sign = n < 0 and "-" or ""
	n = math.abs(n)
	if n < 1000 then
		if n < 10 and n ~= math.floor(n) then
			return sign .. string.format("%.1f", n)
		end
		return sign .. tostring(math.floor(n))
	end
	local tier = math.floor(math.log10(n) / 3)
	local scaled = n / 10 ^ (tier * 3)
	if scaled >= 999.5 then
		tier += 1
		scaled = n / 10 ^ (tier * 3)
	end
	if tier >= #SUFFIXES then
		return sign .. string.format("%.2e", n)
	end
	local text
	if scaled >= 100 then
		text = string.format("%.0f", scaled)
	elseif scaled >= 10 then
		text = string.format("%.1f", scaled)
	else
		text = string.format("%.2f", scaled)
	end
	return sign .. text .. SUFFIXES[tier + 1]
end

----------------------------------------------------------------------
-- Spielmathematik. `data` hat die Felder:
-- crystals, runTotal, allTime, gens = {[id]=Anzahl}, upgrades = {[id]=true},
-- stardust (je gesammelt), stardustSpent, star = {[id]=Stufe}, rebirths
----------------------------------------------------------------------

function Config.milestonesReached(owned)
	local count = 0
	for _, threshold in Config.MILESTONES do
		if owned >= threshold then
			count += 1
		else
			break
		end
	end
	return count
end

function Config.milestoneMultiplier(owned)
	return 2 ^ Config.milestonesReached(owned)
end

function Config.starLevel(data, id)
	return data.star and data.star[id] or 0
end

function Config.starUpgradeCost(upgrade, level)
	return upgrade.baseCost * 2 ^ level
end

function Config.availableStardust(data)
	return (data.stardust or 0) - (data.stardustSpent or 0)
end

function Config.islandLevel(allTime)
	local level = 0
	for i, entry in Config.ISLAND_LEVELS do
		if (allTime or 0) >= entry.total then
			level = i
		end
	end
	return level
end

function Config.rebirthColor(rebirths)
	return Config.REBIRTH_COLORS[((rebirths or 0) % #Config.REBIRTH_COLORS) + 1]
end

function Config.costMultiplier(data)
	return 1 - 0.06 * Config.starLevel(data, "Discount")
end

function Config.startCrystals(data)
	local level = Config.starLevel(data, "HeadStart")
	return level > 0 and 1000 * 10 ^ (level - 1) or 0
end

function Config.goldenDelayFactor(data)
	local factor = 0.85 ^ Config.starLevel(data, "GoldRush")
	if Config.hasUpgrade(data, "luck") then
		factor *= 0.5
	end
	return factor
end

function Config.nextMilestone(owned)
	for _, threshold in Config.MILESTONES do
		if owned < threshold then
			return threshold
		end
	end
	return nil
end

function Config.generatorCost(gen, owned, amount, data)
	local g = Config.COST_GROWTH
	local mult = data and Config.costMultiplier(data) or 1
	return gen.baseCost * mult * g ^ owned * (g ^ amount - 1) / (g - 1)
end

function Config.maxAffordable(gen, owned, money, data)
	local g = Config.COST_GROWTH
	local first = Config.generatorCost(gen, owned, 1, data)
	if money < first then
		return 0
	end
	local n = math.floor(math.log(money * (g - 1) / first + 1) / math.log(g))
	-- Rundungsfehler abfangen
	while n > 0 and Config.generatorCost(gen, owned, n, data) > money do
		n -= 1
	end
	return n
end

function Config.hasUpgrade(data, kind)
	for id in data.upgrades do
		local upgrade = Config.UPGRADES_BY_ID[id]
		if upgrade and upgrade.kind == kind then
			return true
		end
	end
	return false
end

function Config.stardustMultiplier(data)
	return 1 + Config.STARDUST_BONUS * (data.stardust or 0)
end

function Config.globalMultiplier(data)
	local mult = 1
	for id in data.upgrades do
		local upgrade = Config.UPGRADES_BY_ID[id]
		if upgrade and upgrade.kind == "global" then
			mult *= upgrade.mult
		end
	end
	mult *= 1.5 ^ Config.starLevel(data, "StarEngine")
	return mult * Config.stardustMultiplier(data) * Config.bonusMultiplier(data)
end

-- Produktion eines einzelnen Helfers dieser Sorte (inkl. aller Boni)
function Config.unitRate(data, gen)
	local owned = data.gens[gen.id] or 0
	return gen.baseRate * Config.milestoneMultiplier(owned) * Config.globalMultiplier(data)
end

-- Kristalle pro Sekunde (ohne Kristallrausch)
function Config.production(data)
	local total = 0
	for _, gen in Config.GENERATORS do
		local owned = data.gens[gen.id] or 0
		if owned > 0 then
			total += gen.baseRate * owned * Config.milestoneMultiplier(owned)
		end
	end
	return total * Config.globalMultiplier(data)
end

-- Kristalle pro Klick (ohne Kristallrausch)
function Config.clickValue(data)
	local mult, percent = 1, 0
	for id in data.upgrades do
		local upgrade = Config.UPGRADES_BY_ID[id]
		if upgrade and upgrade.kind == "click" then
			mult *= upgrade.mult
		elseif upgrade and upgrade.kind == "clickPercent" then
			percent += upgrade.value
		end
	end
	mult *= 2 ^ Config.starLevel(data, "StarClick")
	return mult * Config.stardustMultiplier(data) * Config.bonusMultiplier(data) + Config.production(data) * percent
end

-- Automatische Klicks der Kristall-Drohne pro Sekunde
function Config.droneClicks(data)
	return 2 * Config.starLevel(data, "Drone")
end

-- Gesamte Kristalle pro Sekunde (Helfer + Drohne, ohne Kristallrausch)
function Config.perSecond(data)
	return Config.production(data) + Config.droneClicks(data) * Config.clickValue(data)
end

-- Haustiere: Eintrag "Cat" = normal, "Cat*" = golden
function Config.parsePet(entry)
	if type(entry) ~= "string" then
		return nil, false
	end
	local golden = string.sub(entry, -1) == "*"
	local id = golden and string.sub(entry, 1, -2) or entry
	return Config.PETS_BY_ID[id], golden
end

function Config.petBoost(entry)
	local pet, golden = Config.parsePet(entry)
	if not pet then
		return 0
	end
	return pet.boost * (golden and Config.GOLDEN_PET_FACTOR or 1)
end

function Config.maxEquipped(data)
	return Config.MAX_EQUIPPED + ((data.passes and data.passes.PetSlots) and 2 or 0)
end

function Config.petMultiplier(data)
	local total = 1
	if data.pets and data.equipped then
		for _, uid in data.equipped do
			total += Config.petBoost(data.pets[uid])
		end
	end
	return total
end

-- Haustiere und VIP-Pass
function Config.bonusMultiplier(data)
	local vip = (data.passes and data.passes.VIP) and 2 or 1
	return Config.petMultiplier(data) * vip
end

-- Zeitlich begrenzte Boosts (Kristallrausch, Like-Boost). `boosts` hat frenzyEnd und likeEnd.
function Config.tempMultiplier(boosts, serverTime)
	local mult = 1
	if (boosts.frenzyEnd or 0) > serverTime then
		mult *= Config.FRENZY_MULTIPLIER
	end
	if (boosts.likeEnd or 0) > serverTime then
		mult *= Config.LIKE_BOOST
	end
	return mult
end

function Config.skinUnlocked(data, skin)
	local unlock = skin.unlock
	if unlock.kind == "free" or (data.skins and data.skins[skin.id]) then
		return true
	elseif unlock.kind == "likes" then
		return (data.likes or 0) >= unlock.amount
	elseif unlock.kind == "golem" then
		return (data.golemKills or 0) >= unlock.amount
	elseif unlock.kind == "rebirths" then
		return (data.rebirths or 0) >= unlock.amount
	end
	return false
end

function Config.skinRequirement(skin)
	local unlock = skin.unlock
	if unlock.kind == "crystals" then
		return "💎 " .. Config.format(unlock.cost)
	elseif unlock.kind == "likes" then
		return "❤️ " .. unlock.amount .. " Likes erhalten"
	elseif unlock.kind == "golem" then
		return "⚔️ " .. unlock.amount .. " Golems besiegen"
	elseif unlock.kind == "rebirths" then
		return "🌟 " .. unlock.amount .. " Wiedergeburten"
	elseif unlock.kind == "robux" then
		return "🛍️ Robux-Shop"
	end
	return ""
end

function Config.stardustForRun(runTotal)
	return math.floor(math.sqrt((runTotal or 0) / Config.REBIRTH_BASE))
end

-- Wie viele Kristalle braucht man in diesem Durchlauf für `stardust` Sternenstaub?
function Config.runTotalForStardust(stardust)
	return stardust * stardust * Config.REBIRTH_BASE
end

return Config
