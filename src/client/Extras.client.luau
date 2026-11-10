-- Kristall-Imperium: Menü, Haustiere, Glücksrad, Tägliche Belohnung, Casino, Skins,
-- Robux-Shop, Golem-Anzeige und Haustiere, die den Spielern folgen.

local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateEvent = remotes:WaitForChild("State")
local petAction = remotes:WaitForChild("PetAction")
local claimDaily = remotes:WaitForChild("ClaimDaily")
local spinWheel = remotes:WaitForChild("SpinWheel")
local playSlots = remotes:WaitForChild("PlaySlots")
local skinRemote = remotes:WaitForChild("Skin")
local teleport = remotes:WaitForChild("Teleport")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local toastBindable = playerGui:WaitForChild("KristallToast")
local format = Config.format

local function toast(message, kind)
	toastBindable:Fire(message, kind)
end

local state = nil
stateEvent.OnClientEvent:Connect(function(newState)
	state = newState
end)

-- Farben und UI-Helfer ----------------------------------------------------

local C = {
	panel = Color3.fromRGB(18, 20, 38),
	card = Color3.fromRGB(34, 38, 66),
	text = Color3.fromRGB(240, 244, 255),
	muted = Color3.fromRGB(160, 168, 200),
	cyan = Color3.fromRGB(90, 200, 255),
	gold = Color3.fromRGB(255, 205, 60),
	green = Color3.fromRGB(60, 200, 110),
	grey = Color3.fromRGB(80, 84, 110),
	purple = Color3.fromRGB(170, 110, 255),
	red = Color3.fromRGB(230, 70, 80),
	pink = Color3.fromRGB(255, 80, 140),
}

local function create(className, props, parent)
	local inst = Instance.new(className)
	for key, value in props do
		inst[key] = value
	end
	inst.Parent = parent
	return inst
end

local function corner(parent, radius)
	create("UICorner", { CornerRadius = UDim.new(0, radius or 12) }, parent)
end

local function stroke(parent, color, thickness, transparency)
	return create("UIStroke", {
		Color = color,
		Thickness = thickness or 2,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function text(props, parent)
	local base = {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextColor3 = C.text,
		TextScaled = true,
		RichText = true,
	}
	for key, value in props do
		base[key] = value
	end
	return create("TextLabel", base, parent)
end

local function button(props, parent)
	local base = {
		Font = Enum.Font.FredokaOne,
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		AutoButtonColor = true,
		BackgroundColor3 = C.green,
	}
	for key, value in props do
		base[key] = value
	end
	local b = create("TextButton", base, parent)
	corner(b, 10)
	return b
end

local function pad(parent, px)
	create("UIPadding", {
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
	}, parent)
end

local function hex(color)
	local function byte(x)
		return math.clamp(math.floor(x * 255 + 0.5), 0, 255)
	end
	return string.format("#%02X%02X%02X", byte(color.R), byte(color.G), byte(color.B))
end

local function clock(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
end

local function serverNow()
	return workspace:GetServerTimeNow()
end

local gui = create("ScreenGui", {
	Name = "KristallExtras",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 5,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local scaled = {}
local function autoScale(guiObject)
	table.insert(scaled, create("UIScale", {}, guiObject))
end

---------------------------------------------------------------------------
-- Fenster-System
---------------------------------------------------------------------------

local window = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(620, 470),
	BackgroundColor3 = C.panel,
	Visible = false,
	ZIndex = 10,
}, gui)
corner(window, 18)
stroke(window, C.purple, 3, 0.2)
autoScale(window)
local windowTitle = text({
	Position = UDim2.fromOffset(16, 10),
	Size = UDim2.new(1, -80, 0, 36),
	Font = Enum.Font.FredokaOne,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 11,
}, window)
local closeButton = button({
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -10, 0, 10),
	Size = UDim2.fromOffset(38, 38),
	BackgroundColor3 = C.red,
	Text = "X",
	ZIndex = 11,
}, window)
local content = create("Frame", {
	Position = UDim2.fromOffset(14, 56),
	Size = UDim2.new(1, -28, 1, -70),
	BackgroundTransparency = 1,
	ZIndex = 11,
}, window)

local currentWindow = nil
local windowRefresh = nil
local WINDOWS = {}

local function closeWindow()
	window.Visible = false
	currentWindow = nil
	windowRefresh = nil
	content:ClearAllChildren()
end
closeButton.Activated:Connect(closeWindow)

local function openWindow(id, extra)
	local def = WINDOWS[id]
	if not def then
		return
	end
	content:ClearAllChildren()
	windowTitle.Text = def.title
	currentWindow = id
	windowRefresh = def.build(content, extra)
	window.Visible = true
	if windowRefresh and state then
		windowRefresh()
	end
end

-- Alle Elemente im Fenster liegen über dem restlichen HUD
local function z(inst)
	if inst:IsA("GuiObject") then
		inst.ZIndex = 12
	end
	for _, child in inst:GetDescendants() do
		if child:IsA("GuiObject") then
			child.ZIndex = 12
		end
	end
	return inst
end

local function scroller(parent, props)
	local base = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = C.purple,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}
	for key, value in props do
		base[key] = value
	end
	return create("ScrollingFrame", base, parent)
end

local busy = false
local function invoke(remote, ...)
	if busy then
		return false, "Moment..."
	end
	busy = true
	local results = table.pack(pcall(remote.InvokeServer, remote, ...))
	busy = false
	if not results[1] then
		return false, "Verbindungsfehler, versuch es nochmal."
	end
	return table.unpack(results, 2, results.n)
end

---------------------------------------------------------------------------
-- Haustiere
---------------------------------------------------------------------------

local function rarityColor(pet)
	return Config.RARITIES[pet.rarity].color
end

local function petLabel(entry)
	local pet, golden = Config.parsePet(entry)
	if not pet then
		return "?", "?"
	end
	return pet.icon, (golden and "⭐ " or "") .. pet.name
end

WINDOWS.pets = {
	title = "🐾 Haustiere",
	build = function(root, eggId)
		local tab = eggId and "eggs" or "inventory"
		local releaseMode = false
		local lastSignature = ""

		local tabRow = create("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 }, root)
		create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, tabRow)
		local eggTab = button({ Size = UDim2.fromOffset(150, 36), Text = "🥚 Eier", BackgroundColor3 = C.card }, tabRow)
		local invTab = button({ Size = UDim2.fromOffset(220, 36), Text = "🎒 Inventar", BackgroundColor3 = C.card }, tabRow)
		pad(eggTab, 6)
		pad(invTab, 6)

		local eggPage = create("Frame", { Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 1, -46), BackgroundTransparency = 1 }, root)
		local invPage = create("Frame", { Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 1, -46), BackgroundTransparency = 1 }, root)

		-- Schlüpf-Animation
		local hatchOverlay = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.panel, Visible = false }, root)
		corner(hatchOverlay, 14)
		local hatchIcon = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromOffset(160, 160), Font = Enum.Font.GothamBold }, hatchOverlay)
		local hatchName = text({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.68), Size = UDim2.fromOffset(460, 40), Font = Enum.Font.FredokaOne }, hatchOverlay)
		local hatchInfo = text({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.8), Size = UDim2.fromOffset(460, 28), Font = Enum.Font.GothamBold, TextColor3 = C.muted }, hatchOverlay)

		local function playHatch(egg, petId)
			hatchOverlay.Visible = true
			hatchName.Text = "..."
			hatchInfo.Text = ""
			hatchIcon.Text = egg.icon
			hatchIcon.Rotation = 0
			for i = 1, 8 do
				hatchIcon.Rotation = (i % 2 == 0) and 15 or -15
				task.wait(0.09 + i * 0.015)
			end
			hatchIcon.Rotation = 0
			local pet = Config.PETS_BY_ID[petId]
			hatchIcon.Text = pet.icon
			hatchIcon.Size = UDim2.fromOffset(60, 60)
			TweenService:Create(hatchIcon, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(160, 160) }):Play()
			local rarity = Config.RARITIES[pet.rarity]
			hatchName.Text = pet.name .. '  <font color="' .. hex(rarity.color) .. '">(' .. rarity.name .. ")</font>"
			hatchInfo.Text = "+" .. math.floor(pet.boost * 100) .. " % Produktion & Klicks"
			task.wait(2.2)
			hatchOverlay.Visible = false
		end

		-- Eier-Seite
		local eggList = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, eggPage)
		create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10) }, eggList)
		local eggButtons = {}
		for _, egg in Config.EGGS do
			local card = create("Frame", { Size = UDim2.new(1 / 3, -7, 1, 0), BackgroundColor3 = C.card }, eggList)
			corner(card, 14)
			stroke(card, egg.color, 2, 0.3)
			text({ Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 50), Text = egg.icon }, card)
			text({ Position = UDim2.fromOffset(6, 60), Size = UDim2.new(1, -12, 0, 24), Text = egg.name, Font = Enum.Font.FredokaOne }, card)
			local lines = {}
			for _, option in egg.pets do
				local pet = Config.PETS_BY_ID[option.pet]
				table.insert(lines, pet.icon .. ' <font color="' .. hex(rarityColor(pet)) .. '">' .. pet.name .. "</font>  " .. option.chance .. " %")
			end
			text({
				Position = UDim2.fromOffset(8, 90),
				Size = UDim2.new(1, -16, 1, -150),
				Text = table.concat(lines, "\n"),
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			}, card)
			local buy = button({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.new(1, -16, 0, 44), Text = "💎 " .. format(egg.cost) }, card)
			pad(buy, 8)
			eggButtons[egg.id] = buy
			buy.Activated:Connect(function()
				local ok, result = invoke(petAction, "hatch", egg.id)
				if ok then
					task.spawn(playHatch, egg, result)
				else
					toast(result, "error")
				end
			end)
		end

		-- Inventar-Seite
		local info = text({ Size = UDim2.new(1, 0, 0, 24), Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left }, invPage)
		local actionRow = create("Frame", { Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 }, invPage)
		create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, actionRow)
		local bestButton = button({ Size = UDim2.fromOffset(180, 36), Text = "⭐ Beste ausrüsten", BackgroundColor3 = C.cyan }, actionRow)
		local mergeButton = button({ Size = UDim2.fromOffset(170, 36), Text = "✨ Verschmelzen", BackgroundColor3 = C.gold }, actionRow)
		local releaseButton = button({ Size = UDim2.fromOffset(200, 36), Text = "🗑️ Freilassen: AUS", BackgroundColor3 = C.grey }, actionRow)
		for _, b in { bestButton, mergeButton, releaseButton } do
			pad(b, 7)
		end
		local grid = scroller(invPage, { Position = UDim2.fromOffset(0, 74), Size = UDim2.new(1, 0, 1, -74) })
		create("UIGridLayout", { CellSize = UDim2.fromOffset(104, 118), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, grid)

		bestButton.Activated:Connect(function()
			local ok, message = invoke(petAction, "best")
			toast(message, ok and "build" or "error")
		end)
		mergeButton.Activated:Connect(function()
			local ok, message = invoke(petAction, "merge")
			toast(message, ok and "gold" or "error")
		end)
		releaseButton.Activated:Connect(function()
			releaseMode = not releaseMode
			releaseButton.Text = releaseMode and "🗑️ Freilassen: AN" or "🗑️ Freilassen: AUS"
			releaseButton.BackgroundColor3 = releaseMode and C.red or C.grey
		end)

		local function rebuildGrid()
			for _, child in grid:GetChildren() do
				if child:IsA("GuiButton") then
					child:Destroy()
				end
			end
			local list = {}
			for uid, entry in state.pets do
				table.insert(list, { uid = uid, entry = entry, boost = Config.petBoost(entry), equipped = table.find(state.equipped, uid) ~= nil })
			end
			table.sort(list, function(a, b)
				if a.equipped ~= b.equipped then
					return a.equipped
				end
				return a.boost > b.boost
			end)
			for order, item in list do
				local pet, golden = Config.parsePet(item.entry)
				if pet then
					local tile = create("TextButton", {
						LayoutOrder = order,
						Text = "",
						AutoButtonColor = true,
						BackgroundColor3 = item.equipped and Color3.fromRGB(40, 110, 70) or C.card,
					}, grid)
					corner(tile, 12)
					stroke(tile, golden and C.gold or rarityColor(pet), golden and 3 or 2, 0.1)
					text({ Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 46), Text = pet.icon }, tile)
					local icon, name = petLabel(item.entry)
					local _ = icon
					text({ Position = UDim2.fromOffset(4, 56), Size = UDim2.new(1, -8, 0, 20), Text = name, Font = Enum.Font.GothamBold }, tile)
					text({ Position = UDim2.fromOffset(4, 78), Size = UDim2.new(1, -8, 0, 18), Text = "+" .. format(item.boost * 100) .. " %", TextColor3 = C.gold, Font = Enum.Font.FredokaOne }, tile)
					text({ Position = UDim2.fromOffset(4, 97), Size = UDim2.new(1, -8, 0, 15), Text = item.equipped and "✓ Ausgerüstet" or "", TextColor3 = C.green, Font = Enum.Font.GothamBold }, tile)
					tile.Activated:Connect(function()
						if releaseMode then
							local ok, message = invoke(petAction, "release", item.uid)
							toast(message, ok and "info" or "error")
						else
							local ok, message = invoke(petAction, "equip", item.uid)
							if not ok then
								toast(message, "error")
							end
						end
					end)
				end
			end
			z(grid)
		end

		local function setTab(id)
			tab = id
			eggPage.Visible = id == "eggs"
			invPage.Visible = id == "inventory"
			eggTab.BackgroundColor3 = id == "eggs" and C.purple or C.card
			invTab.BackgroundColor3 = id == "inventory" and C.purple or C.card
		end
		eggTab.Activated:Connect(function()
			setTab("eggs")
		end)
		invTab.Activated:Connect(function()
			setTab("inventory")
		end)
		setTab(tab)
		z(root)
		-- Die Schlüpf-Animation liegt über allem anderen im Fenster
		hatchOverlay.ZIndex = 20
		for _, child in hatchOverlay:GetDescendants() do
			if child:IsA("GuiObject") then
				child.ZIndex = 21
			end
		end

		return function()
			local count = 0
			for _ in state.pets do
				count += 1
			end
			invTab.Text = "🎒 Inventar (" .. count .. "/" .. Config.MAX_PETS .. ")"
			info.Text = "Ausgerüstet " .. #state.equipped .. "/" .. Config.maxEquipped(state) .. "  •  Haustier-Bonus: x" .. string.format("%.2f", Config.petMultiplier(state))
			for _, egg in Config.EGGS do
				eggButtons[egg.id].BackgroundColor3 = state.crystals >= egg.cost and C.green or C.grey
			end
			local parts = {}
			for uid, entry in state.pets do
				table.insert(parts, uid .. "=" .. entry)
			end
			table.sort(parts)
			local signature = table.concat(parts, ",") .. "|" .. table.concat(state.equipped, ",")
			if signature ~= lastSignature then
				lastSignature = signature
				rebuildGrid()
			end
		end
	end,
}

---------------------------------------------------------------------------
-- Glücksrad
---------------------------------------------------------------------------

WINDOWS.wheel = {
	title = "🎡 Glücksrad",
	build = function(root)
		local tiles = {}
		local count = #Config.WHEEL
		local center = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1 }, root)
		for i, segment in Config.WHEEL do
			local angle = (i - 1) / count * math.pi * 2 - math.pi / 2
			local tile = text({
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(5 + math.cos(angle) * 230, 5 + math.sin(angle) * 150),
				Size = UDim2.fromOffset(120, 54),
				BackgroundTransparency = 0,
				BackgroundColor3 = segment.color,
				Text = segment.label,
				Font = Enum.Font.FredokaOne,
			}, center)
			corner(tile, 12)
			pad(tile, 8)
			tiles[i] = { label = tile, stroke = stroke(tile, Color3.new(1, 1, 1), 0, 0) }
		end
		local spin = button({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(200, 70), BackgroundColor3 = C.gold, TextColor3 = Color3.fromRGB(60, 40, 0) }, root)
		pad(spin, 12)
		local spinning = false

		local function highlight(index)
			for i, tile in tiles do
				tile.stroke.Thickness = (i == index) and 5 or 0
				tile.label.BackgroundTransparency = (i == index) and 0 or 0.45
			end
		end
		highlight(0)

		spin.Activated:Connect(function()
			if spinning or not state then
				return
			end
			spinning = true
			local ok, message, index = invoke(spinWheel)
			if not ok then
				toast(message, "error")
				spinning = false
				return
			end
			local steps = count * 3 + index
			for step = 1, steps do
				highlight((step - 1) % count + 1)
				task.wait(0.04 + (step / steps) ^ 3 * 0.35)
			end
			toast(message, "gold")
			task.wait(1)
			spinning = false
		end)
		z(root)

		return function()
			local left = Config.WHEEL_COOLDOWN - (os.time() - state.lastSpin)
			if spinning then
				spin.Text = "🎡 ..."
			elseif left > 0 then
				spin.Text = "⏳ " .. clock(left)
				spin.BackgroundColor3 = C.grey
			else
				spin.Text = "🎡 DREHEN!"
				spin.BackgroundColor3 = C.gold
			end
		end
	end,
}

---------------------------------------------------------------------------
-- Tägliche Belohnung
---------------------------------------------------------------------------

local function dailyStatus()
	local day = math.floor(os.time() / 86400)
	local canClaim = state.dailyDay ~= day
	local nextStreak = canClaim and ((state.dailyDay == day - 1) and (state.dailyStreak % #Config.DAILY_REWARDS) + 1 or 1) or state.dailyStreak
	return canClaim, nextStreak, day
end

WINDOWS.daily = {
	title = "🎁 Tägliche Belohnung",
	build = function(root)
		text({ Size = UDim2.new(1, 0, 0, 44), Font = Enum.Font.GothamMedium, TextColor3 = C.muted, TextWrapped = true, Text = "Komm jeden Tag wieder! Je länger deine Serie, desto größer die Belohnung. An Tag 7 gibt es zusätzlich Sternenstaub ✨" }, root)
		local row = create("Frame", { Position = UDim2.fromOffset(0, 60), Size = UDim2.new(1, 0, 0, 150), BackgroundTransparency = 1 }, root)
		create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center }, row)
		local cards = {}
		for day, minutes in Config.DAILY_REWARDS do
			local card = create("Frame", { Size = UDim2.fromOffset(76, 150), BackgroundColor3 = C.card }, row)
			corner(card, 12)
			local s = stroke(card, C.gold, 0, 0)
			text({ Position = UDim2.fromOffset(4, 8), Size = UDim2.new(1, -8, 0, 24), Text = "Tag " .. day, Font = Enum.Font.FredokaOne }, card)
			text({ Position = UDim2.fromOffset(4, 40), Size = UDim2.new(1, -8, 0, 40), Text = day == #Config.DAILY_REWARDS and "🎁" or "💎" }, card)
			text({ Position = UDim2.fromOffset(4, 86), Size = UDim2.new(1, -8, 0, 36), Text = minutes .. " Min" .. (day == #Config.DAILY_REWARDS and "\n+1 ✨" or ""), Font = Enum.Font.GothamBold, TextColor3 = C.muted }, card)
			local check = text({ Position = UDim2.fromOffset(4, 124), Size = UDim2.new(1, -8, 0, 20), Text = "", TextColor3 = C.green }, card)
			cards[day] = { card = card, stroke = s, check = check }
		end
		local claim = button({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 236), Size = UDim2.fromOffset(300, 66), BackgroundColor3 = C.gold, TextColor3 = Color3.fromRGB(60, 40, 0) }, root)
		pad(claim, 12)
		claim.Activated:Connect(function()
			local ok, message = invoke(claimDaily)
			toast(message, ok and "gold" or "error")
		end)
		z(root)

		return function()
			local canClaim, nextStreak, day = dailyStatus()
			for i, c in cards do
				local claimed = canClaim and i < nextStreak or (not canClaim and i <= nextStreak)
				c.check.Text = claimed and "✓" or ""
				c.stroke.Thickness = (canClaim and i == nextStreak) and 4 or 0
				c.card.BackgroundColor3 = claimed and Color3.fromRGB(40, 90, 60) or C.card
			end
			if canClaim then
				claim.Text = "🎁 Tag " .. nextStreak .. " abholen!"
				claim.BackgroundColor3 = C.gold
			else
				claim.Text = "🌙 Morgen wieder (" .. clock((day + 1) * 86400 - os.time()) .. ")"
				claim.BackgroundColor3 = C.grey
			end
		end
	end,
}

---------------------------------------------------------------------------
-- Casino: Glücksautomat
---------------------------------------------------------------------------

WINDOWS.casino = {
	title = "🎰 Glücksautomat",
	build = function(root)
		local fraction = Config.SLOT_BETS[1]
		local reels = {}
		local reelRow = create("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(360, 120), BackgroundColor3 = Color3.fromRGB(10, 10, 20) }, root)
		corner(reelRow, 16)
		stroke(reelRow, C.gold, 3, 0)
		create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center }, reelRow)
		for i = 1, 3 do
			local reel = text({ Size = UDim2.fromOffset(100, 100), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(240, 240, 250), Text = Config.SLOT_SYMBOLS[i] }, reelRow)
			corner(reel, 12)
			pad(reel, 10)
			reels[i] = reel
		end

		local betLabel = text({ Position = UDim2.fromOffset(0, 130), Size = UDim2.new(1, 0, 0, 26), Font = Enum.Font.FredokaOne }, root)
		local betRow = create("Frame", { Position = UDim2.fromOffset(0, 162), Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 }, root)
		create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center }, betRow)
		local betButtons = {}
		for _, f in Config.SLOT_BETS do
			local b = button({ Size = UDim2.fromOffset(110, 40), BackgroundColor3 = C.card, Text = f >= 1 and "ALLES" or (math.floor(f * 100) .. " %") }, betRow)
			pad(b, 8)
			betButtons[f] = b
			b.Activated:Connect(function()
				fraction = f
			end)
		end

		local spin = button({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 214), Size = UDim2.fromOffset(280, 64), BackgroundColor3 = C.pink, Text = "🎰 DREHEN" }, root)
		pad(spin, 12)
		text({
			Position = UDim2.fromOffset(0, 290),
			Size = UDim2.new(1, 0, 0, 60),
			Font = Enum.Font.GothamMedium,
			TextColor3 = C.muted,
			TextWrapped = true,
			Text = "💎💎💎 x" .. Config.SLOT_TRIPLE["💎"] .. "  •  ⭐⭐⭐ x" .. Config.SLOT_TRIPLE["⭐"] .. "  •  3 gleiche x4  •  2 gleiche x" .. Config.SLOT_PAIR
				.. "\nNur mit Kristallen gespielt – kein echtes Geld. Gewinne zählen nicht für Wiedergeburt.",
		}, root)

		local spinning = false
		spin.Activated:Connect(function()
			if spinning then
				return
			end
			spinning = true
			local result = nil
			task.spawn(function()
				result = table.pack(invoke(playSlots, fraction))
			end)
			local started = os.clock()
			while not result or os.clock() - started < 1 do
				for _, reel in reels do
					reel.Text = Config.SLOT_SYMBOLS[math.random(1, #Config.SLOT_SYMBOLS)]
				end
				task.wait(0.07)
			end
			local ok, message, symbols, net = result[1], result[2], result[3], result[4]
			if ok then
				for i = 1, 3 do
					for _ = 1, 4 + i * 2 do
						for j = i, 3 do
							reels[j].Text = Config.SLOT_SYMBOLS[math.random(1, #Config.SLOT_SYMBOLS)]
						end
						task.wait(0.07)
					end
					reels[i].Text = symbols[i]
				end
				toast(message, net > 0 and "gold" or "error")
			else
				toast(message, "error")
			end
			spinning = false
		end)
		z(root)

		return function()
			for f, b in betButtons do
				b.BackgroundColor3 = (f == fraction) and C.gold or C.card
				b.TextColor3 = (f == fraction) and Color3.fromRGB(60, 40, 0) or Color3.new(1, 1, 1)
			end
			betLabel.Text = "Einsatz: 💎 " .. format(math.floor(state.crystals * fraction))
		end
	end,
}

---------------------------------------------------------------------------
-- Skins
---------------------------------------------------------------------------

WINDOWS.skins = {
	title = "💎 Kristall-Skins",
	build = function(root)
		local grid = scroller(root, { Size = UDim2.fromScale(1, 1) })
		create("UIGridLayout", { CellSize = UDim2.fromOffset(180, 120), CellPadding = UDim2.fromOffset(10, 10) }, grid)
		local cards = {}
		for _, skin in Config.SKINS do
			local card = create("TextButton", { Text = "", BackgroundColor3 = C.card, AutoButtonColor = true }, grid)
			corner(card, 12)
			local s = stroke(card, C.gold, 0, 0)
			local swatch = create("Frame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(44, 44), BackgroundColor3 = skin.color or C.cyan }, card)
			corner(swatch, 22)
			text({ Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(44, 44), Text = skin.icon }, card)
			text({ Position = UDim2.fromOffset(62, 14), Size = UDim2.new(1, -70, 0, 26), Text = skin.name, Font = Enum.Font.FredokaOne, TextXAlignment = Enum.TextXAlignment.Left }, card)
			local status = text({ Position = UDim2.fromOffset(10, 64), Size = UDim2.new(1, -20, 0, 44), Font = Enum.Font.GothamBold, TextWrapped = true }, card)
			cards[skin.id] = { card = card, stroke = s, status = status }
			card.Activated:Connect(function()
				local ok, message = invoke(skinRemote, skin.id)
				toast(message, ok and "build" or "error")
			end)
		end
		z(root)

		return function()
			for _, skin in Config.SKINS do
				local c = cards[skin.id]
				local active = state.skin == skin.id
				local unlocked = Config.skinUnlocked(state, skin)
				c.stroke.Thickness = active and 4 or 0
				if active then
					c.status.Text = "✓ Aktiv"
					c.status.TextColor3 = C.green
				elseif unlocked then
					c.status.Text = "Klicken zum Auswählen"
					c.status.TextColor3 = C.text
				else
					c.status.Text = "🔒 " .. Config.skinRequirement(skin)
					c.status.TextColor3 = C.muted
				end
			end
		end
	end,
}

---------------------------------------------------------------------------
-- Robux-Shop
---------------------------------------------------------------------------

local priceCache = {}
local function fetchPrice(id, infoType, label)
	if id <= 0 then
		label.Text = "Bald"
		return
	end
	local key = tostring(infoType) .. id
	if priceCache[key] then
		label.Text = priceCache[key]
		return
	end
	task.spawn(function()
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, infoType)
		if ok and info and info.PriceInRobux then
			priceCache[key] = "R$ " .. info.PriceInRobux
			if label.Parent then
				label.Text = priceCache[key]
			end
		end
	end)
end

WINDOWS.shop = {
	title = "🛍️ Robux-Shop",
	build = function(root)
		local list = scroller(root, { Size = UDim2.fromScale(1, 1) })
		create("UIListLayout", { Padding = UDim.new(0, 8) }, list)
		local passButtons = {}

		local function row(icon, name, desc, color)
			local r = create("Frame", { Size = UDim2.new(1, -10, 0, 76), BackgroundColor3 = C.card }, list)
			corner(r, 12)
			stroke(r, color, 2, 0.3)
			text({ Position = UDim2.fromOffset(8, 12), Size = UDim2.fromOffset(52, 52), Text = icon }, r)
			text({ Position = UDim2.fromOffset(70, 10), Size = UDim2.new(1, -210, 0, 26), Text = name, Font = Enum.Font.FredokaOne, TextXAlignment = Enum.TextXAlignment.Left }, r)
			text({ Position = UDim2.fromOffset(70, 40), Size = UDim2.new(1, -210, 0, 24), Text = desc, Font = Enum.Font.GothamMedium, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Left }, r)
			local b = button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(120, 50), BackgroundColor3 = C.green, Text = "..." }, r)
			pad(b, 10)
			return b
		end

		text({ Size = UDim2.new(1, -10, 0, 26), Text = "👑 Gamepässe (für immer)", Font = Enum.Font.FredokaOne, TextColor3 = C.gold, TextXAlignment = Enum.TextXAlignment.Left }, list)
		for _, pass in Config.GAMEPASSES do
			local b = row(pass.icon, pass.name, pass.desc, C.gold)
			passButtons[pass.key] = b
			fetchPrice(pass.passId, Enum.InfoType.GamePass, b)
			b.Activated:Connect(function()
				if state and state.passes and state.passes[pass.key] then
					toast("Du hast " .. pass.name .. " schon! 👑", "info")
				elseif pass.passId <= 0 then
					toast("Dieser Pass ist noch nicht eingerichtet (siehe README).", "error")
				else
					MarketplaceService:PromptGamePassPurchase(player, pass.passId)
				end
			end)
		end

		text({ Size = UDim2.new(1, -10, 0, 26), Text = "🐾 Exklusive Haustiere & Extras", Font = Enum.Font.FredokaOne, TextColor3 = C.pink, TextXAlignment = Enum.TextXAlignment.Left }, list)
		for _, product in Config.PRODUCTS do
			local b = row(product.icon, product.name, product.desc, C.pink)
			fetchPrice(product.productId, Enum.InfoType.Product, b)
			b.Activated:Connect(function()
				if product.reward.kind == "skin" and state and state.skins[product.reward.skin] then
					toast("Diesen Skin hast du schon! Wähle ihn unter 💎 Skins.", "info")
				elseif product.productId <= 0 then
					toast("Dieser Artikel ist noch nicht eingerichtet (siehe README).", "error")
				else
					MarketplaceService:PromptProductPurchase(player, product.productId)
				end
			end)
		end
		z(root)

		return function()
			for key, b in passButtons do
				if state.passes and state.passes[key] then
					b.Text = "✓ Aktiv"
					b.BackgroundColor3 = C.grey
				end
			end
		end
	end,
}

---------------------------------------------------------------------------
-- Menü links
---------------------------------------------------------------------------

local menu = create("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 12, 0.5, 0),
	Size = UDim2.fromOffset(148, 296),
	BackgroundTransparency = 1,
}, gui)
autoScale(menu)
create("UIGridLayout", { CellSize = UDim2.fromOffset(70, 68), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, menu)

local dots = {}
local MENU = {
	{ id = "pets", icon = "🐾", label = "Pets", color = C.green },
	{ id = "wheel", icon = "🎡", label = "Rad", color = C.gold },
	{ id = "daily", icon = "🎁", label = "Täglich", color = C.purple },
	{ id = "casino", icon = "🎰", label = "Casino", color = C.pink },
	{ id = "skins", icon = "💎", label = "Skins", color = C.cyan },
	{ id = "shop", icon = "🛍️", label = "Shop", color = Color3.fromRGB(255, 120, 60) },
	{ id = "hub", icon = "🌐", label = "Hub", color = Color3.fromRGB(70, 140, 255) },
	{ id = "home", icon = "🏝️", label = "Insel", color = Color3.fromRGB(80, 180, 90) },
}
for order, item in MENU do
	local b = button({ LayoutOrder = order, BackgroundColor3 = item.color, Text = "" }, menu)
	stroke(b, Color3.new(1, 1, 1), 2, 0.5)
	text({ Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 0, 38), Text = item.icon }, b)
	text({ Position = UDim2.fromOffset(2, 44), Size = UDim2.new(1, -4, 0, 18), Text = item.label, Font = Enum.Font.FredokaOne }, b)
	local dot = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.92, 0.08), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Color3.fromRGB(255, 50, 50), Visible = false }, b)
	corner(dot, 8)
	dots[item.id] = dot
	b.Activated:Connect(function()
		if item.id == "hub" or item.id == "home" then
			teleport:FireServer(item.id)
			closeWindow()
		elseif currentWindow == item.id then
			closeWindow()
		else
			openWindow(item.id)
		end
	end)
end

-- Stationen auf der Hub-Insel öffnen die passenden Fenster
ProximityPromptService.PromptTriggered:Connect(function(prompt)
	local ui = prompt:GetAttribute("OpenUI")
	if ui and WINDOWS[ui] then
		openWindow(ui, prompt:GetAttribute("Extra"))
	end
end)

---------------------------------------------------------------------------
-- Kristallgolem: Anzeige und Treffer
---------------------------------------------------------------------------

local golemBanner = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -104),
	Size = UDim2.fromOffset(460, 50),
	BackgroundColor3 = Color3.fromRGB(150, 30, 40),
	Visible = false,
}, gui)
corner(golemBanner, 14)
stroke(golemBanner, Color3.fromRGB(255, 120, 120), 2, 0.2)
autoScale(golemBanner)
local golemText = text({ Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -170, 1, -16), Font = Enum.Font.FredokaOne, TextXAlignment = Enum.TextXAlignment.Left }, golemBanner)
local golemGo = button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(150, 38), BackgroundColor3 = C.gold, TextColor3 = Color3.fromRGB(60, 40, 0), Text = "⚔️ Zum Kampf!" }, golemBanner)
pad(golemGo, 6)
golemGo.Activated:Connect(function()
	teleport:FireServer("hub")
end)

local function popup(message, screenPos, color)
	local label = text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(screenPos.X + math.random(-30, 30), screenPos.Y),
		Size = UDim2.fromOffset(160, 40),
		Font = Enum.Font.FredokaOne,
		Text = message,
		TextColor3 = color,
		TextStrokeTransparency = 0.3,
		ZIndex = 20,
	}, gui)
	local tween = TweenService:Create(label, TweenInfo.new(0.8), { Position = label.Position - UDim2.fromOffset(0, 80), TextTransparency = 1, TextStrokeTransparency = 1 })
	tween:Play()
	tween.Completed:Connect(function()
		label:Destroy()
	end)
end

local golemShake = {}
local function hookGolem(model)
	golemShake[model] = { base = model:GetPivot(), hitAt = 0 }
	local detector = model:WaitForChild("ClickDetector", 10)
	if detector then
		detector.MouseClick:Connect(function()
			if not state then
				return
			end
			local damage = Config.clickValue(state) * Config.tempMultiplier(state, serverNow())
			popup("-" .. format(damage), UserInputService:GetMouseLocation(), Color3.fromRGB(255, 90, 90))
			if golemShake[model] then
				golemShake[model].hitAt = os.clock()
			end
		end)
	end
end
for _, model in CollectionService:GetTagged("Golem") do
	task.spawn(hookGolem, model)
end
CollectionService:GetInstanceAddedSignal("Golem"):Connect(hookGolem)
CollectionService:GetInstanceRemovedSignal("Golem"):Connect(function(model)
	golemShake[model] = nil
end)

---------------------------------------------------------------------------
-- Haustiere folgen ihren Besitzern (wird nur lokal gezeichnet)
---------------------------------------------------------------------------

local petFolder = Instance.new("Folder")
petFolder.Name = "LocalPets"
petFolder.Parent = workspace

local function petPart(model, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		p[key] = value
	end
	p.Parent = model
	return p
end

-- Niedliche Cartoon-Haustiere aus weichen Ellipsoiden -------------------------

local buildCutePet

-- Ellipsoid: Teil mit Kugel-Mesh, nimmt jede Größe an (weiche Formen statt Klötze)
local function ell(model, size, cf, color, props)
	local p = petPart(model, { Size = size, CFrame = cf, Color = color })
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	if props then
		for key, value in props do
			p[key] = value
		end
	end
	return p
end

local PINK = Color3.fromRGB(255, 150, 170)
local BLACK = Color3.fromRGB(25, 20, 30)
local WHITE = Color3.new(1, 1, 1)
local ORANGE = Color3.fromRGB(255, 160, 50)
local FLYING = { dragon = true, owl = true, phoenix = true, jelly = true, spirit = true, griffin = true }

-- Merkmale je Tierart. a = Akzentfarbe (Bauch, Innenohr), c = Grundfarbe
local FEATURES = {}

local function pointyEars(m, c, a)
	for _, x in { -1, 1 } do
		local ear = CFrame.new(x * 0.52, 1.72, -0.45) * CFrame.Angles(0, 0, -x * 0.35)
		ell(m, Vector3.new(0.5, 0.75, 0.28), ear, c)
		ell(m, Vector3.new(0.28, 0.45, 0.1), ear * CFrame.new(0, -0.05, -0.12), a)
	end
end

local function tail(m, c, size, cf)
	ell(m, size, cf, c)
end

FEATURES.cat = function(m, c, a)
	pointyEars(m, c, PINK)
	tail(m, c, Vector3.new(0.28, 0.28, 1.3), CFrame.new(0, 0.55, 1.35) * CFrame.Angles(0.7, 0, 0))
	for _, x in { -1, 1 } do -- Schnurrhaare
		for _, y in { 0.72, 0.82 } do
			petPart(m, { Size = Vector3.new(0.5, 0.03, 0.03), CFrame = CFrame.new(x * 0.75, y, -1.15) * CFrame.Angles(0, 0, x * (y - 0.77) * 3), Color = BLACK })
		end
	end
end

FEATURES.mouse = function(m, c, a)
	for _, x in { -1, 1 } do
		ell(m, Vector3.new(0.85, 0.85, 0.15), CFrame.new(x * 0.65, 1.65, -0.35), c)
		ell(m, Vector3.new(0.55, 0.55, 0.1), CFrame.new(x * 0.65, 1.65, -0.43), PINK)
	end
	tail(m, PINK, Vector3.new(0.12, 0.12, 1.4), CFrame.new(0, 0.1, 1.5) * CFrame.Angles(0.3, 0, 0))
	ell(m, Vector3.new(0.18, 0.15, 0.12), CFrame.new(0, 0.85, -1.3), PINK)
end

FEATURES.bunny = function(m, c, a)
	for _, x in { -1, 1 } do
		local ear = CFrame.new(x * 0.33, 2.2, -0.35) * CFrame.Angles(0.15, 0, -x * 0.12)
		ell(m, Vector3.new(0.38, 1.35, 0.25), ear, c)
		ell(m, Vector3.new(0.22, 1, 0.1), ear * CFrame.new(0, 0, -0.1), PINK)
	end
	ell(m, Vector3.new(0.55, 0.55, 0.55), CFrame.new(0, 0.2, 1.15), WHITE)
	ell(m, Vector3.new(0.16, 0.12, 0.1), CFrame.new(0, 0.85, -1.3), PINK)
end

local function bushyTail(m, c, tip)
	local cf = CFrame.new(0, 0.6, 1.5) * CFrame.Angles(0.6, 0, 0)
	ell(m, Vector3.new(0.75, 0.75, 1.5), cf, c)
	ell(m, Vector3.new(0.55, 0.55, 0.55), cf * CFrame.new(0, 0, 0.75), tip)
end

FEATURES.fox = function(m, c, a)
	pointyEars(m, c, BLACK)
	bushyTail(m, c, WHITE)
	ell(m, Vector3.new(0.7, 0.5, 0.5), CFrame.new(0, 0.72, -1.15), WHITE) -- Schnauze
	ell(m, Vector3.new(0.16, 0.12, 0.12), CFrame.new(0, 0.8, -1.42), BLACK)
end

FEATURES.wolf = function(m, c, a)
	pointyEars(m, c, a)
	bushyTail(m, c, a)
	ell(m, Vector3.new(0.7, 0.5, 0.5), CFrame.new(0, 0.72, -1.15), a)
	ell(m, Vector3.new(0.16, 0.12, 0.12), CFrame.new(0, 0.8, -1.42), BLACK)
end

local function wings(m, color, size)
	for _, x in { -1, 1 } do
		ell(m, size or Vector3.new(1.4, 0.8, 0.12), CFrame.new(x * 1.05, 0.55, 0.35) * CFrame.Angles(0.2, x * 0.4, x * 0.45), color)
	end
end

FEATURES.dragon = function(m, c, a)
	for _, x in { -1, 1 } do
		ell(m, Vector3.new(0.22, 0.75, 0.22), CFrame.new(x * 0.45, 1.75, -0.2) * CFrame.Angles(-0.6, 0, -x * 0.3), Color3.fromRGB(250, 240, 210))
	end
	wings(m, a)
	for i = 0, 2 do
		ell(m, Vector3.new(0.18, 0.4, 0.35), CFrame.new(0, 0.75 - i * 0.12, 0.2 + i * 0.45), a)
	end
	tail(m, c, Vector3.new(0.4, 0.4, 1.3), CFrame.new(0, 0, 1.45) * CFrame.Angles(0.35, 0, 0))
	for _, x in { -1, 1 } do -- Nasenlöcher
		ell(m, Vector3.new(0.08, 0.08, 0.05), CFrame.new(x * 0.15, 0.82, -1.28), BLACK)
	end
end

FEATURES.frog = function(m, c, a)
	for _, x in { -1, 1 } do
		ell(m, Vector3.new(0.6, 0.6, 0.6), CFrame.new(x * 0.45, 1.6, -0.75), c)
		ell(m, Vector3.new(0.42, 0.42, 0.2), CFrame.new(x * 0.45, 1.65, -1.0), WHITE)
		ell(m, Vector3.new(0.22, 0.26, 0.1), CFrame.new(x * 0.45, 1.65, -1.1), BLACK)
	end
	ell(m, Vector3.new(0.9, 0.08, 0.06), CFrame.new(0, 0.7, -1.28), BLACK)
end

FEATURES.hedgehog = function(m, c, a)
	local dark = c:Lerp(BLACK, 0.45)
	for i = 0, 11 do
		local angle = (i % 4) / 3 * 1.6 - 0.8
		local row = math.floor(i / 4)
		ell(m, Vector3.new(0.32, 0.32, 0.95), CFrame.new(math.sin(angle) * 0.6, 1.25 - row * 0.4, 0.1 + row * 0.35) * CFrame.Angles(0.9 - row * 0.3, angle, 0) * CFrame.new(0, 0, 0.3), dark)
	end
	ell(m, Vector3.new(0.2, 0.15, 0.15), CFrame.new(0, 0.8, -1.32), BLACK)
end

FEATURES.owl = function(m, c, a)
	for _, x in { -1, 1 } do
		ell(m, Vector3.new(0.65, 0.65, 0.15), CFrame.new(x * 0.4, 1.0, -1.18), a)
		ell(m, Vector3.new(0.25, 0.6, 0.2), CFrame.new(x * 0.55, 1.75, -0.4) * CFrame.Angles(0, 0, -x * 0.4), c)
	end
	ell(m, Vector3.new(0.22, 0.3, 0.25), CFrame.new(0, 0.75, -1.32), ORANGE)
	wings(m, c:Lerp(BLACK, 0.2), Vector3.new(0.3, 1.0, 0.9))
end

FEATURES.phoenix = function(m, c, a)
	wings(m, Color3.fromRGB(255, 200, 60))
	for i = -1, 1 do
		ell(m, Vector3.new(0.18, 0.7, 0.25), CFrame.new(i * 0.2, 1.85, -0.3) * CFrame.Angles(-0.3, 0, -i * 0.4), Color3.fromRGB(255, 220, 80), { Material = Enum.Material.Neon })
	end
	ell(m, Vector3.new(0.22, 0.3, 0.25), CFrame.new(0, 0.78, -1.32), ORANGE)
	local tailPart = ell(m, Vector3.new(0.5, 0.5, 1.2), CFrame.new(0, 0.3, 1.4) * CFrame.Angles(0.5, 0, 0), Color3.fromRGB(255, 80, 30), { Material = Enum.Material.Neon })
	local fire = Instance.new("Fire")
	fire.Size = 2
	fire.Heat = 4
	fire.Parent = tailPart
end

FEATURES.spirit = function(m, c, a)
	ell(m, Vector3.new(0.5, 0.15, 0.9), CFrame.new(0.15, 1.75, -0.3) * CFrame.Angles(0, 0.4, 0.3), Color3.fromRGB(90, 200, 90))
	petPart(m, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.1, 1.3, 1.3), CFrame = CFrame.new(0, 2.05, -0.4) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 240, 150), Material = Enum.Material.Neon, Transparency = 0.2 })
end

FEATURES.jelly = function(m, c, a)
	for i = 0, 5 do
		local angle = i / 6 * math.pi * 2
		ell(m, Vector3.new(0.18, 1.0, 0.18), CFrame.new(math.cos(angle) * 0.5, -0.3, math.sin(angle) * 0.5 - 0.2) * CFrame.Angles(math.sin(angle) * 0.2, 0, math.cos(angle) * 0.2), a, { Transparency = 0.3, Material = Enum.Material.Neon })
	end
end

FEATURES.unicorn = function(m, c, a)
	pointyEars(m, c, PINK)
	ell(m, Vector3.new(0.22, 1.0, 0.22), CFrame.new(0, 1.95, -0.85) * CFrame.Angles(-0.45, 0, 0), Color3.fromRGB(255, 215, 80), { Material = Enum.Material.Neon })
	local mane = { Color3.fromRGB(255, 120, 200), Color3.fromRGB(150, 120, 255), Color3.fromRGB(110, 210, 255) }
	for i, color in mane do
		ell(m, Vector3.new(0.35, 0.55, 0.55), CFrame.new(0, 1.7 - i * 0.3, -0.1 + i * 0.3), color)
	end
	tail(m, mane[1], Vector3.new(0.45, 0.45, 1.2), CFrame.new(0, 0.4, 1.4) * CFrame.Angles(0.6, 0, 0))
end

FEATURES.griffin = function(m, c, a)
	wings(m, a, Vector3.new(1.7, 0.9, 0.12))
	ell(m, Vector3.new(0.3, 0.3, 0.45), CFrame.new(0, 0.8, -1.38) * CFrame.Angles(0.4, 0, 0), Color3.fromRGB(255, 200, 60))
	for _, x in { -1, 1 } do
		ell(m, Vector3.new(0.25, 0.6, 0.2), CFrame.new(x * 0.5, 1.75, -0.35) * CFrame.Angles(-0.4, 0, -x * 0.3), a)
	end
	tail(m, c, Vector3.new(0.3, 0.3, 1.2), CFrame.new(0, 0.3, 1.4) * CFrame.Angles(0.4, 0, 0))
end

buildCutePet = function(pet, golden)
	local model = Instance.new("Model")
	model.Name = pet.id
	local species = pet.style
	local c = golden and C.gold or pet.color
	local a = c:Lerp(WHITE, 0.55)
	local shiny = golden or pet.rarity == "Legendary" or pet.rarity == "Exclusive"
	local glow = species == "jelly" or species == "spirit"
	local bodyProps = glow and { Material = Enum.Material.Neon, Transparency = 0.25 } or (shiny and { Material = Enum.Material.SmoothPlastic, Reflectance = 0.15 } or nil)

	-- Körper, Kopf, Bauch
	local body
	if species == "jelly" then
		body = ell(model, Vector3.new(1.9, 1.5, 1.9), CFrame.new(0, 0.9, -0.3), c, bodyProps)
	else
		body = ell(model, Vector3.new(1.5, 1.3, 1.7), CFrame.new(0, 0, 0.3), c, bodyProps)
		ell(model, Vector3.new(1.75, 1.55, 1.55), CFrame.new(0, 0.95, -0.45), c, bodyProps)
		ell(model, Vector3.new(1.0, 0.85, 0.3), CFrame.new(0, -0.05, -0.48), a)
		-- Füße
		if not FLYING[species] then
			for _, x in { -1, 1 } do
				for _, zPos in { -0.25, 0.8 } do
					ell(model, Vector3.new(0.45, 0.3, 0.55), CFrame.new(x * 0.45, -0.6, zPos), c:Lerp(BLACK, 0.15))
				end
			end
		end
	end
	model.PrimaryPart = body

	-- Gesicht: glänzende Kulleraugen, Bäckchen, Mund
	for _, x in { -1, 1 } do
		if species ~= "frog" then
			ell(model, Vector3.new(0.34, 0.44, 0.16), CFrame.new(x * 0.38, 1.05, -1.18), BLACK)
			ell(model, Vector3.new(0.13, 0.13, 0.06), CFrame.new(x * 0.34, 1.13, -1.26), WHITE, { Material = Enum.Material.Neon })
		end
		ell(model, Vector3.new(0.32, 0.18, 0.08), CFrame.new(x * 0.62, 0.78, -1.08), PINK, { Transparency = 0.15 })
	end
	if species ~= "frog" and species ~= "owl" and species ~= "phoenix" and species ~= "griffin" then
		ell(model, Vector3.new(0.18, 0.08, 0.05), CFrame.new(0, 0.7, -1.24), BLACK)
	end

	local feature = FEATURES[species]
	if feature then
		feature(model, c, a)
	end

	if shiny then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = golden and C.gold or c
		sparkles.Parent = body
		local light = Instance.new("PointLight")
		light.Color = c
		light.Range = 7
		light.Brightness = 1.2
		light.Parent = body
	end
	model:SetAttribute("Flying", FLYING[species] == true)
	model.Parent = petFolder
	return model
end

local function buildPetModel(entry)
	local pet, golden = Config.parsePet(entry)
	if not pet then
		return nil
	end
	-- Eigenes Modell aus ReplicatedStorage > Modelle (gleicher Name wie die Haustier-ID)
	local folder = ReplicatedStorage:FindFirstChild("Modelle")
	local template = folder and folder:FindFirstChild(pet.id)
	if template and (template:IsA("Model") or template:IsA("BasePart")) then
		local custom
		if template:IsA("Model") then
			custom = template:Clone()
		else
			custom = Instance.new("Model")
			template:Clone().Parent = custom
		end
		local firstPart = nil
		for _, inst in custom:GetDescendants() do
			if inst:IsA("LuaSourceContainer") then
				inst:Destroy()
			elseif inst:IsA("BasePart") then
				inst.Anchored = true
				inst.CanCollide = false
				inst.CanQuery = false
				inst.CanTouch = false
				firstPart = firstPart or inst
			end
		end
		if firstPart then
			local boxCF, size = custom:GetBoundingBox()
			custom.WorldPivot = boxCF
			custom:ScaleTo(custom:GetScale() * 2.6 / math.max(size.X, size.Y, size.Z))
			custom.PrimaryPart = custom.PrimaryPart or firstPart
			custom.WorldPivot = custom:GetBoundingBox()
			if golden then
				local sparkles = Instance.new("Sparkles")
				sparkles.SparkleColor = C.gold
				sparkles.Parent = firstPart
			end
			custom.Parent = petFolder
			return custom
		end
		custom:Destroy()
	end

	return buildCutePet(pet, golden)
end

local petViews = {}

local function rebuildPets(plr)
	local view = petViews[plr]
	if view then
		for _, m in view.models do
			m:Destroy()
		end
	end
	view = { models = {}, cframes = {}, rainbow = {} }
	petViews[plr] = view
	local list = plr:GetAttribute("Pets")
	if type(list) ~= "string" or list == "" then
		return
	end
	for entry in string.gmatch(list, "[^,]+") do
		local model = buildPetModel(entry)
		if model then
			table.insert(view.models, model)
			local pet = Config.parsePet(entry)
			table.insert(view.rainbow, pet.id == "RainbowUnicorn")
		end
	end
end

local function watchPlayer(plr)
	rebuildPets(plr)
	plr:GetAttributeChangedSignal("Pets"):Connect(function()
		rebuildPets(plr)
	end)
end
for _, plr in Players:GetPlayers() do
	watchPlayer(plr)
end
Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(function(plr)
	local view = petViews[plr]
	if view then
		for _, m in view.models do
			m:Destroy()
		end
	end
	petViews[plr] = nil
end)

---------------------------------------------------------------------------
-- Jedes Bild: Haustiere bewegen, Golem wackeln lassen
---------------------------------------------------------------------------

RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	for plr, view in petViews do
		local character = plr.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local n = #view.models
		for i, model in view.models do
			if root then
				local x = (i - (n + 1) / 2) * 3.2
				local moving = root.AssemblyLinearVelocity.Magnitude > 2
				local y
				if model:GetAttribute("Flying") then
					y = 0.6 + math.sin(t * 3 + i) * 0.4
				elseif moving then
					y = -2.15 + math.abs(math.sin(t * 9 + i)) * 0.9 -- hüpfen
				else
					y = -2.15 + math.abs(math.sin(t * 2 + i)) * 0.15
				end
				local target = root.CFrame * CFrame.new(x, y, 4.5)
				local current = view.cframes[i]
				if not current or (current.Position - target.Position).Magnitude > 60 then
					current = target
				end
				current = current:Lerp(target, math.min(1, dt * 8))
				view.cframes[i] = current
				model:PivotTo(current)
				if view.rainbow[i] then
					model.PrimaryPart.Color = Color3.fromHSV((t * 0.3 + i * 0.2) % 1, 0.7, 1)
				end
			end
		end
	end

	for model, shake in golemShake do
		if model.Parent then
			local since = t - shake.hitAt
			local offset = since < 0.15 and Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) * 0.6 or Vector3.zero
			model:PivotTo(shake.base * CFrame.new(offset + Vector3.new(0, math.sin(t * 2) * 0.3, 0)))
		end
	end
end)

---------------------------------------------------------------------------
-- Regelmäßig: Fenster aktualisieren, rote Punkte, Golem-Banner
---------------------------------------------------------------------------

task.spawn(function()
	while true do
		if state then
			if windowRefresh then
				local ok, err = pcall(windowRefresh)
				if not ok then
					warn("[Kristall-Imperium] Fenster-Fehler:", err)
				end
			end
			local canClaim = dailyStatus()
			dots.daily.Visible = canClaim
			dots.wheel.Visible = os.time() - state.lastSpin >= Config.WHEEL_COOLDOWN
		end

		local golem = CollectionService:GetTagged("Golem")[1]
		golemBanner.Visible = golem ~= nil
		if golem then
			local left = (golem:GetAttribute("EndsAt") or 0) - serverNow()
			local hp = golem:GetAttribute("HP") or 0
			local maxHp = golem:GetAttribute("MaxHP") or 1
			golemText.Text = "⚔️ KRISTALLGOLEM!  " .. math.floor(math.clamp(hp / maxHp, 0, 1) * 100) .. " %  •  " .. math.max(0, math.ceil(left)) .. "s"
		end
		task.wait(0.25)
	end
end)

local function updateScale()
	local camera = workspace.CurrentCamera
	local height = camera and camera.ViewportSize.Y or 900
	local scale = math.clamp(height / 900, 0.55, 1.15)
	for _, s in scaled do
		s.Scale = scale
	end
end
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end
updateScale()
