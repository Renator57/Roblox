-- Haustiere (Eier, Ausrüsten, Verschmelzen) und Robux-Shop (Developer Products, Gamepässe).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Pets = {}
local ctx = nil

local function countPets(data)
	local n = 0
	for _ in data.pets do
		n += 1
	end
	return n
end

-- Zeigt die ausgerüsteten Haustiere allen Spielern (die Clients bauen die 3D-Modelle)
local function updateAttribute(player, data)
	local list = {}
	for _, uid in data.equipped do
		if data.pets[uid] then
			table.insert(list, data.pets[uid])
		end
	end
	player:SetAttribute("Pets", table.concat(list, ","))
end

local function changed(player, session)
	updateAttribute(player, session.data)
	ctx.PlayerData.updateLeaderstats(player)
	ctx.sendState(player)
end

local function addPet(data, entry)
	local uid = "p" .. data.nextPet
	data.nextPet += 1
	data.pets[uid] = entry
	return uid
end

local function unequip(data, uid)
	for i, equippedUid in data.equipped do
		if equippedUid == uid then
			table.remove(data.equipped, i)
			return true
		end
	end
	return false
end

local function isEquipped(data, uid)
	return table.find(data.equipped, uid) ~= nil
end

local function rollEgg(egg)
	local total = 0
	for _, option in egg.pets do
		total += option.chance
	end
	local roll = math.random() * total
	for _, option in egg.pets do
		roll -= option.chance
		if roll <= 0 then
			return option.pet
		end
	end
	return egg.pets[1].pet
end

-- Öffnet ein Ei. free = true für Belohnungen (Glücksrad).
function Pets.hatch(player, session, eggId, free)
	local egg = Config.EGGS_BY_ID[eggId]
	local data = session.data
	if not egg then
		return false, "Unbekanntes Ei."
	end
	if countPets(data) >= Config.MAX_PETS then
		return false, "Dein Inventar ist voll (" .. Config.MAX_PETS .. "). Lass ein paar Haustiere frei."
	end
	if not free then
		if data.crystals < egg.cost then
			return false, "Nicht genug Kristalle."
		end
		data.crystals -= egg.cost
	end
	local petId = rollEgg(egg)
	local uid = addPet(data, petId)
	-- Automatisch ausrüsten, wenn noch Platz ist
	if #data.equipped < Config.maxEquipped(data) then
		table.insert(data.equipped, uid)
	end
	local pet = Config.PETS_BY_ID[petId]
	if pet.rarity == "Legendary" then
		ctx.notifyAll("🌟 " .. player.DisplayName .. " hat " .. pet.icon .. " " .. pet.name .. " (Legendär) geschlüpft!", "frenzy")
	end
	changed(player, session)
	return true, petId
end

function Pets.give(player, session, petId)
	addPet(session.data, petId)
	changed(player, session)
end

function Pets.onJoin(player, session)
	local data = session.data
	-- Kaputte Einträge aufräumen
	for uid, entry in data.pets do
		if not Config.parsePet(entry) then
			data.pets[uid] = nil
		end
	end
	for i = #data.equipped, 1, -1 do
		if not data.pets[data.equipped[i]] then
			table.remove(data.equipped, i)
		end
	end

	-- Gamepässe neu prüfen
	data.passes = {}
	for _, pass in Config.GAMEPASSES do
		if pass.passId and pass.passId > 0 then
			local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.passId)
			if ok and owns then
				data.passes[pass.key] = true
			end
		end
	end
	while #data.equipped > Config.maxEquipped(data) do
		table.remove(data.equipped)
	end
	updateAttribute(player, data)
end

function Pets.init(context)
	ctx = context

	local petAction = ctx.remote("RemoteFunction", "PetAction")
	petAction.OnServerInvoke = function(player, action, arg)
		local session = ctx.sessions[player]
		if not session then
			return false, "Fehler."
		end
		local data = session.data

		if action == "hatch" and type(arg) == "string" then
			return Pets.hatch(player, session, arg, false)

		elseif action == "equip" and type(arg) == "string" then
			if not data.pets[arg] then
				return false, "Unbekanntes Haustier."
			end
			if isEquipped(data, arg) then
				unequip(data, arg)
				changed(player, session)
				return true, "Abgelegt."
			end
			if #data.equipped >= Config.maxEquipped(data) then
				return false, "Alle Plätze belegt (" .. Config.maxEquipped(data) .. "). Leg erst ein Haustier ab."
			end
			table.insert(data.equipped, arg)
			changed(player, session)
			return true, "Ausgerüstet!"

		elseif action == "best" then
			local list = {}
			for uid, entry in data.pets do
				table.insert(list, { uid = uid, boost = Config.petBoost(entry) })
			end
			table.sort(list, function(a, b)
				return a.boost > b.boost
			end)
			data.equipped = {}
			for i = 1, math.min(#list, Config.maxEquipped(data)) do
				table.insert(data.equipped, list[i].uid)
			end
			changed(player, session)
			return true, "Die besten Haustiere sind ausgerüstet!"

		elseif action == "release" and type(arg) == "string" then
			if not data.pets[arg] then
				return false, "Unbekanntes Haustier."
			end
			unequip(data, arg)
			data.pets[arg] = nil
			changed(player, session)
			return true, "Freigelassen. Tschüss! 👋"

		elseif action == "merge" then
			-- 3 gleiche normale Haustiere -> 1 goldenes
			local groups = {}
			for uid, entry in data.pets do
				local _, golden = Config.parsePet(entry)
				if not golden then
					groups[entry] = groups[entry] or {}
					table.insert(groups[entry], uid)
				end
			end
			local bestId, bestBoost = nil, -1
			for entry, uids in groups do
				if #uids >= 3 and Config.petBoost(entry) > bestBoost then
					bestId, bestBoost = entry, Config.petBoost(entry)
				end
			end
			if not bestId then
				return false, "Du brauchst 3 gleiche Haustiere zum Verschmelzen."
			end
			for i = 1, 3 do
				local uid = groups[bestId][i]
				unequip(data, uid)
				data.pets[uid] = nil
			end
			local newUid = addPet(data, bestId .. "*")
			if #data.equipped < Config.maxEquipped(data) then
				table.insert(data.equipped, newUid)
			end
			changed(player, session)
			local pet = Config.PETS_BY_ID[bestId]
			return true, "✨ Goldener " .. pet.name .. " erschaffen! (Bonus x" .. Config.GOLDEN_PET_FACTOR .. ")"
		end
		return false, "Fehler."
	end

	------------------------------------------------------------------
	-- Robux: Developer Products
	------------------------------------------------------------------
	local productsById = {}
	for _, product in Config.PRODUCTS do
		if product.productId and product.productId > 0 then
			productsById[product.productId] = product
		end
	end

	MarketplaceService.ProcessReceipt = function(receipt)
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		local session = player and ctx.sessions[player]
		local product = productsById[receipt.ProductId]
		if not (session and product) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local data = session.data
		if data.receipts[receipt.PurchaseId] then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		local reward = product.reward
		if reward.kind == "pet" then
			addPet(data, reward.pet)
			if #data.equipped < Config.maxEquipped(data) then
				local newest = "p" .. (data.nextPet - 1)
				table.insert(data.equipped, newest)
			end
		elseif reward.kind == "skin" then
			data.skins[reward.skin] = true
			data.skin = reward.skin
			ctx.MapBuilder.updatePlot(session.plot, data)
		elseif reward.kind == "frenzy" then
			session.frenzyEnd = math.max(session.frenzyEnd, ctx.now()) + reward.seconds
		end

		-- Kauf merken, damit er nie doppelt gutgeschrieben wird (max. 100 Einträge)
		data.receipts[receipt.PurchaseId] = os.time()
		local count, oldestId, oldestTime = 0, nil, math.huge
		for id, time in data.receipts do
			count += 1
			if time < oldestTime then
				oldestId, oldestTime = id, time
			end
		end
		if count > 100 and oldestId then
			data.receipts[oldestId] = nil
		end

		changed(player, session)
		ctx.notify(player, "🛍️ Danke für deinen Kauf: " .. product.icon .. " " .. product.name .. "!", "gold")
		if not ctx.PlayerData.save(player) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	------------------------------------------------------------------
	-- Robux: Gamepässe
	------------------------------------------------------------------
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local session = ctx.sessions[player]
		if not (purchased and session) then
			return
		end
		for _, pass in Config.GAMEPASSES do
			if pass.passId == passId then
				session.data.passes[pass.key] = true
				ctx.notify(player, "🎉 " .. pass.icon .. " " .. pass.name .. " ist jetzt aktiv!", "gold")
				changed(player, session)
			end
		end
	end)
end

return Pets
