-- Tägliche Belohnung, Glücksrad, Glücksautomat (nur Kristalle) und Kristall-Skins.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Pets = require(script.Parent.Pets)

local Fun = {}

local function minutesOfProduction(data, minutes)
	return math.max(Config.DAILY_MIN, Config.perSecond(data) * 60 * minutes)
end

local function today()
	return math.floor(os.time() / 86400)
end

function Fun.init(ctx)
	------------------------------------------------------------------
	-- Tägliche Belohnung
	------------------------------------------------------------------
	local daily = ctx.remote("RemoteFunction", "ClaimDaily")
	daily.OnServerInvoke = function(player)
		local session = ctx.sessions[player]
		if not session then
			return false, "Fehler."
		end
		local data = session.data
		local day = today()
		if data.dailyDay == day then
			return false, "Heute schon abgeholt. Komm morgen wieder! 🌙"
		end
		local streak = (data.dailyDay == day - 1) and (data.dailyStreak % #Config.DAILY_REWARDS) + 1 or 1
		local amount = minutesOfProduction(data, Config.DAILY_REWARDS[streak])
		ctx.earn(session, amount)
		local message = "🎁 Tag " .. streak .. ": +" .. Config.format(amount) .. " 💎"
		if streak == #Config.DAILY_REWARDS then
			data.stardust += 1
			message ..= " und +1 ✨ Sternenstaub!"
		end
		data.dailyDay = day
		data.dailyStreak = streak
		ctx.sendState(player)
		return true, message
	end

	------------------------------------------------------------------
	-- Glücksrad (kostenlos alle paar Stunden)
	------------------------------------------------------------------
	local wheel = ctx.remote("RemoteFunction", "SpinWheel")
	wheel.OnServerInvoke = function(player)
		local session = ctx.sessions[player]
		if not session then
			return false, "Fehler."
		end
		local data = session.data
		local left = Config.WHEEL_COOLDOWN - (os.time() - data.lastSpin)
		if left > 0 then
			return false, "Nächster Dreh in " .. math.ceil(left / 60) .. " Min."
		end
		data.lastSpin = os.time()

		local total = 0
		for _, segment in Config.WHEEL do
			total += segment.weight
		end
		local roll = math.random() * total
		local index = #Config.WHEEL
		for i, segment in Config.WHEEL do
			roll -= segment.weight
			if roll <= 0 then
				index = i
				break
			end
		end

		local segment = Config.WHEEL[index]
		local message
		if segment.kind == "minutes" then
			local amount = minutesOfProduction(data, segment.value)
			ctx.earn(session, amount)
			message = "🎡 Gewonnen: +" .. Config.format(amount) .. " 💎"
		elseif segment.kind == "frenzy" then
			session.frenzyEnd = math.max(session.frenzyEnd, ctx.now()) + segment.value
			message = "🎡 Gewonnen: Kristallrausch für " .. segment.value .. " Sekunden! 🔥"
		elseif segment.kind == "egg" then
			local ok, petId = Pets.hatch(player, session, segment.value, true)
			if ok then
				local pet = Config.PETS_BY_ID[petId]
				message = "🎡 Gewonnen: " .. pet.icon .. " " .. pet.name .. "!"
			else
				local amount = minutesOfProduction(data, 15)
				ctx.earn(session, amount)
				message = "🎡 Inventar voll – stattdessen +" .. Config.format(amount) .. " 💎"
			end
		elseif segment.kind == "stardust" then
			data.stardust += segment.value
			message = "🎡 Gewonnen: +" .. segment.value .. " ✨ Sternenstaub!"
		end
		if segment.kind == "minutes" and segment.value >= 180 then
			ctx.notifyAll("🎰 " .. player.DisplayName .. " hat den JACKPOT am Glücksrad geknackt!", "frenzy")
		end
		ctx.sendState(player)
		return true, message, index
	end

	------------------------------------------------------------------
	-- Glücksautomat: Einsatz in Kristallen, ca. 95 % Auszahlung
	------------------------------------------------------------------
	local lastSlot = {}
	local slots = ctx.remote("RemoteFunction", "PlaySlots")
	slots.OnServerInvoke = function(player, fraction)
		local session = ctx.sessions[player]
		if not session or not table.find(Config.SLOT_BETS, fraction) then
			return false, "Fehler."
		end
		if lastSlot[player] and os.clock() - lastSlot[player] < 1.5 then
			return false, "Nicht so schnell! 🎰"
		end
		local data = session.data
		local bet = math.floor(data.crystals * fraction)
		if bet < Config.SLOT_MIN_BET then
			return false, "Du brauchst mindestens " .. Config.SLOT_MIN_BET .. " 💎 Einsatz."
		end
		lastSlot[player] = os.clock()

		local symbols = {}
		for i = 1, 3 do
			symbols[i] = Config.SLOT_SYMBOLS[math.random(1, #Config.SLOT_SYMBOLS)]
		end
		local multiplier = 0
		if symbols[1] == symbols[2] and symbols[2] == symbols[3] then
			multiplier = Config.SLOT_TRIPLE[symbols[1]]
		elseif symbols[1] == symbols[2] or symbols[2] == symbols[3] or symbols[1] == symbols[3] then
			multiplier = Config.SLOT_PAIR
		end
		local payout = math.floor(bet * multiplier)
		-- Gewinne zählen nicht für Wiedergeburt oder Insel-Ausbau
		data.crystals += payout - bet

		local message
		if multiplier >= 8 then
			message = "🎉 MEGA-GEWINN! +" .. Config.format(payout) .. " 💎"
			ctx.notifyAll("🎰 " .. player.DisplayName .. " hat am Glücksautomaten " .. Config.format(payout) .. " 💎 gewonnen!", "frenzy")
		elseif multiplier > 0 then
			message = "Gewonnen: " .. Config.format(payout) .. " 💎 (x" .. multiplier .. ")"
		else
			message = "Leider nichts. -" .. Config.format(bet) .. " 💎"
		end
		ctx.sendState(player)
		return true, message, symbols, payout - bet
	end

	------------------------------------------------------------------
	-- Skins: freischalten und ausrüsten
	------------------------------------------------------------------
	local skinRemote = ctx.remote("RemoteFunction", "Skin")
	skinRemote.OnServerInvoke = function(player, skinId)
		local session = ctx.sessions[player]
		local skin = type(skinId) == "string" and Config.SKINS_BY_ID[skinId]
		if not (session and skin) then
			return false, "Fehler."
		end
		local data = session.data
		if not Config.skinUnlocked(data, skin) then
			local unlock = skin.unlock
			if unlock.kind == "crystals" then
				if data.crystals < unlock.cost then
					return false, "Nicht genug Kristalle."
				end
				data.crystals -= unlock.cost
			elseif unlock.kind == "robux" then
				return false, "Diesen Skin gibt es im 🛍️ Robux-Shop."
			else
				return false, "Noch gesperrt: " .. Config.skinRequirement(skin)
			end
		end
		data.skins[skin.id] = true
		data.skin = skin.id
		ctx.MapBuilder.updatePlot(session.plot, data)
		ctx.sendState(player)
		return true, skin.icon .. " " .. skin.name .. " ist jetzt aktiv!"
	end
end

return Fun
