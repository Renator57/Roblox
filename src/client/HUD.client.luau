-- Kristall-Imperium: Oberfläche, Shop, Effekte (Client).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local mineEvent = remotes:WaitForChild("Mine")
local stateEvent = remotes:WaitForChild("State")
local notifyEvent = remotes:WaitForChild("Notify")
local buyFunction = remotes:WaitForChild("Buy")
local rebirthFunction = remotes:WaitForChild("Rebirth")

local player = Players.LocalPlayer
local format = Config.format

-- Farben ---------------------------------------------------------------

local C = {
	panel = Color3.fromRGB(18, 20, 38),
	card = Color3.fromRGB(34, 38, 66),
	cardLocked = Color3.fromRGB(26, 28, 46),
	text = Color3.fromRGB(240, 244, 255),
	muted = Color3.fromRGB(160, 168, 200),
	cyan = Color3.fromRGB(90, 200, 255),
	gold = Color3.fromRGB(255, 205, 60),
	green = Color3.fromRGB(60, 200, 110),
	grey = Color3.fromRGB(80, 84, 110),
	purple = Color3.fromRGB(170, 110, 255),
	red = Color3.fromRGB(255, 90, 80),
	orange = Color3.fromRGB(255, 140, 40),
}

-- Zustand vom Server -----------------------------------------------------

local state = nil
local stateClock = 0
local clientTokens = Config.CLICKS_PER_SECOND

local function frenzyLeft()
	if not state then
		return 0
	end
	return math.max(0, (state.frenzyEnd or 0) - workspace:GetServerTimeNow())
end

local function frenzyMult()
	return frenzyLeft() > 0 and Config.FRENZY_MULTIPLIER or 1
end

local function perSecond()
	return state and Config.perSecond(state) * frenzyMult() or 0
end

-- Kristalle inkl. Vorhersage seit dem letzten Server-Update
local function currentCrystals()
	if not state then
		return 0
	end
	return state.crystals + perSecond() * (os.clock() - stateClock)
end

-- Sounds (eingebaute Roblox-Sounds) --------------------------------------

local function makeSound(id, volume)
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = volume
	sound.Parent = script
	return sound
end
local sounds = {
	click = makeSound("rbxasset://sounds/clickfast.wav", 0.35),
	buy = makeSound("rbxasset://sounds/electronicpingshort.wav", 0.45),
	big = makeSound("rbxasset://sounds/swoosh.wav", 0.6),
}
local function play(name)
	SoundService:PlayLocalSound(sounds[name])
end

-- UI-Helfer ---------------------------------------------------------------

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
	create("UIStroke", {
		Color = color,
		Thickness = thickness or 2,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function padding(parent, px)
	create("UIPadding", {
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
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

local function hex(color)
	local function byte(x)
		return math.clamp(math.floor(x * 255 + 0.5), 0, 255)
	end
	return string.format("#%02X%02X%02X", byte(color.R), byte(color.G), byte(color.B))
end

-- Fortschrittsbalken: gibt Funktion set(Anteil, Text) zurück
local function progressBar(props, parent, fillColor)
	local bar = create("Frame", props, parent)
	bar.BackgroundColor3 = Color3.fromRGB(12, 14, 26)
	corner(bar, 8)
	local fill = create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = fillColor,
		BorderSizePixel = 0,
	}, bar)
	corner(fill, 8)
	local label = text({
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.GothamBold,
		ZIndex = 2,
	}, bar)
	create("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2) }, label)
	return function(alpha, caption)
		fill.Size = UDim2.fromScale(math.clamp(alpha, 0, 1), 1)
		label.Text = caption
	end, bar
end

-- Bildschirm -------------------------------------------------------------

local gui = create("ScreenGui", {
	Name = "KristallHUD",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, player:WaitForChild("PlayerGui"))

-- Alles passt sich der Bildschirmgröße an (auch Handy)
local scaled = {}
local function autoScale(guiObject)
	table.insert(scaled, create("UIScale", {}, guiObject))
end

---------------------------------------------------------------------------
-- Oben: Kristallanzeige
---------------------------------------------------------------------------

local top = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 12),
	Size = UDim2.fromOffset(440, 100),
	BackgroundColor3 = C.panel,
	BackgroundTransparency = 0.1,
}, gui)
corner(top, 18)
stroke(top, C.cyan, 2, 0.4)
autoScale(top)

local crystalLabel = text({
	Position = UDim2.fromOffset(12, 6),
	Size = UDim2.new(1, -24, 0, 54),
	Font = Enum.Font.FredokaOne,
	Text = "💎 0",
}, top)
local perSecondLabel = text({
	Position = UDim2.fromOffset(12, 62),
	Size = UDim2.new(1, -24, 0, 26),
	Font = Enum.Font.GothamBold,
	TextColor3 = C.cyan,
	Text = "0 pro Sekunde",
}, top)

local frenzyBanner = text({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 1, 8),
	Size = UDim2.fromOffset(380, 38),
	BackgroundTransparency = 0,
	BackgroundColor3 = C.orange,
	Font = Enum.Font.FredokaOne,
	Visible = false,
}, top)
corner(frenzyBanner, 12)

---------------------------------------------------------------------------
-- Links: Insel-Fortschritt und Sternenstaub
---------------------------------------------------------------------------

local info = create("Frame", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 12, 1, -18),
	Size = UDim2.fromOffset(290, 130),
	BackgroundColor3 = C.panel,
	BackgroundTransparency = 0.1,
}, gui)
corner(info, 16)
stroke(info, C.green, 2, 0.5)
padding(info, 12)
autoScale(info)

local islandTitle = text({ Size = UDim2.new(1, 0, 0, 26), Font = Enum.Font.FredokaOne, TextXAlignment = Enum.TextXAlignment.Left }, info)
local islandNext = text({
	Position = UDim2.fromOffset(0, 30),
	Size = UDim2.new(1, 0, 0, 18),
	Font = Enum.Font.GothamMedium,
	TextColor3 = C.muted,
	TextXAlignment = Enum.TextXAlignment.Left,
}, info)
local setIslandBar = progressBar({ Position = UDim2.fromOffset(0, 52), Size = UDim2.new(1, 0, 0, 20) }, info, C.green)
local stardustLabel = text({
	Position = UDim2.fromOffset(0, 80),
	Size = UDim2.new(1, 0, 0, 24),
	Font = Enum.Font.FredokaOne,
	TextColor3 = C.gold,
	TextXAlignment = Enum.TextXAlignment.Left,
}, info)

---------------------------------------------------------------------------
-- Unten: großer Abbau-Knopf
---------------------------------------------------------------------------

local mineButton = button({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -18),
	Size = UDim2.fromOffset(280, 74),
	BackgroundColor3 = C.cyan,
	Text = "",
}, gui)
stroke(mineButton, Color3.new(1, 1, 1), 3, 0.3)
autoScale(mineButton)
local mineTitle = text({
	Position = UDim2.fromOffset(0, 6),
	Size = UDim2.new(1, 0, 0, 38),
	Font = Enum.Font.FredokaOne,
	Text = "⛏️ ABBAUEN",
	TextColor3 = Color3.fromRGB(10, 30, 60),
}, mineButton)
local mineValue = text({
	Position = UDim2.fromOffset(0, 44),
	Size = UDim2.new(1, 0, 0, 22),
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.fromRGB(10, 30, 60),
	Text = "+1",
}, mineButton)
local _ = mineTitle

---------------------------------------------------------------------------
-- Meldungen
---------------------------------------------------------------------------

local toastHolder = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 170),
	Size = UDim2.fromOffset(520, 200),
	BackgroundTransparency = 1,
}, gui)
autoScale(toastHolder)
create("UIListLayout", {
	Padding = UDim.new(0, 6),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
}, toastHolder)

local TOAST_COLORS = { info = C.card, gold = Color3.fromRGB(150, 110, 20), frenzy = Color3.fromRGB(200, 80, 30), build = Color3.fromRGB(40, 130, 80), error = Color3.fromRGB(150, 40, 50) }
local toastCount = 0

local function toast(message, kind)
	toastCount += 1
	local children = {}
	for _, child in toastHolder:GetChildren() do
		if child:IsA("TextLabel") then
			table.insert(children, child)
		end
	end
	if #children >= 3 then
		table.sort(children, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		children[1]:Destroy()
	end
	local label = text({
		LayoutOrder = toastCount,
		Size = UDim2.fromOffset(500, 42),
		BackgroundTransparency = 0.05,
		BackgroundColor3 = TOAST_COLORS[kind or "info"] or C.card,
		Font = Enum.Font.GothamBold,
		Text = message,
	}, toastHolder)
	corner(label, 12)
	create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, label)
	task.delay(3.5, function()
		if label.Parent then
			local fade = TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1, BackgroundTransparency = 1 })
			fade:Play()
			fade.Completed:Wait()
			label:Destroy()
		end
	end)
end

notifyEvent.OnClientEvent:Connect(function(message, kind)
	toast(message, kind)
	if kind == "gold" or kind == "frenzy" or kind == "build" then
		play("big")
	end
end)

---------------------------------------------------------------------------
-- Schwebende Zahlen beim Klicken
---------------------------------------------------------------------------

local function popup(message, screenPos, color)
	local label = text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(screenPos.X + math.random(-30, 30), screenPos.Y + math.random(-10, 10)),
		Size = UDim2.fromOffset(160, 40),
		Font = Enum.Font.FredokaOne,
		Text = message,
		TextColor3 = color or C.text,
		TextStrokeTransparency = 0.3,
		ZIndex = 20,
	}, gui)
	local tween = TweenService:Create(label, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = label.Position - UDim2.fromOffset(0, 90),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		label:Destroy()
	end)
end

---------------------------------------------------------------------------
-- Shop rechts
---------------------------------------------------------------------------

local shop = create("Frame", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 64),
	Size = UDim2.new(0, 400, 1, -76),
	BackgroundColor3 = C.panel,
	BackgroundTransparency = 0.08,
}, gui)
corner(shop, 18)
stroke(shop, C.purple, 2, 0.4)
padding(shop, 12)
local shopScale = create("UIScale", {}, shop)

local shopToggle = button({
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -12, 1, -18),
	Size = UDim2.fromOffset(120, 50),
	BackgroundColor3 = C.purple,
	Text = "🛒 Shop",
	Visible = false,
}, gui)
autoScale(shopToggle)

local closeShop = button({
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.fromScale(1, 0),
	Size = UDim2.fromOffset(36, 36),
	BackgroundColor3 = C.red,
	Text = "X",
}, shop)
closeShop.Activated:Connect(function()
	shop.Visible = false
	shopToggle.Visible = true
end)
shopToggle.Activated:Connect(function()
	shop.Visible = true
	shopToggle.Visible = false
end)

-- Reiter
local tabs = {}
local pages = {}
local currentTab = "gens"
local TAB_DEFS = { { id = "gens", label = "⛏️ Helfer" }, { id = "upgrades", label = "⚡ Upgrades" }, { id = "rebirth", label = "🌟 Rebirth" } }

local tabRow = create("Frame", { Size = UDim2.new(1, -44, 0, 36), BackgroundTransparency = 1 }, shop)
create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }, tabRow)

local function selectTab(id)
	currentTab = id
	for tabId, tab in tabs do
		tab.BackgroundColor3 = (tabId == id) and C.purple or C.card
	end
	for pageId, page in pages do
		page.Visible = pageId == id
	end
end

for _, def in TAB_DEFS do
	local tab = button({ Size = UDim2.new(1 / 3, -4, 1, 0), BackgroundColor3 = C.card, Text = def.label, Font = Enum.Font.GothamBold }, tabRow)
	create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, tab)
	tabs[def.id] = tab
	tab.Activated:Connect(function()
		selectTab(def.id)
	end)
end

local function makePage(id, topOffset)
	local page = create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, topOffset),
		Size = UDim2.new(1, 0, 1, -topOffset),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = C.purple,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, shop)
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
	create("UIPadding", { PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }, page)
	pages[id] = page
	return page
end

-- Menge x1 / x10 / Max (nur Helfer-Reiter)
local buyAmount = 1
local amountRow = create("Frame", { Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 }, shop)
create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Right }, amountRow)
text({ Size = UDim2.new(0, 90, 0.8, 0), Text = "Menge:", TextColor3 = C.muted, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right }, amountRow)
local amountButtons = {}
for _, amount in { 1, 10, "max" } do
	local b = button({ Size = UDim2.fromOffset(64, 30), BackgroundColor3 = C.card, Text = amount == "max" and "Max" or ("x" .. amount), Font = Enum.Font.GothamBold }, amountRow)
	create("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, b)
	amountButtons[amount] = b
	b.Activated:Connect(function()
		buyAmount = amount
		for a, other in amountButtons do
			other.BackgroundColor3 = (a == amount) and C.cyan or C.card
		end
	end)
end
amountButtons[1].BackgroundColor3 = C.cyan

local genPage = makePage("gens", 82)
local upgradePage = makePage("upgrades", 44)
local rebirthPage = makePage("rebirth", 44)

local function updateAmountRowVisibility()
	amountRow.Visible = currentTab == "gens"
end

-- Kaufen
local busy = false
local function purchase(kind, id, amount)
	if busy then
		return
	end
	busy = true
	local ok, success, message = pcall(buyFunction.InvokeServer, buyFunction, kind, id, amount)
	busy = false
	if ok and success then
		play("buy")
		toast(message, "build")
	else
		toast(ok and message or "Kauf fehlgeschlagen.", "error")
	end
end

-- Zeilen für Helfer
local genRows = {}
for index, gen in Config.GENERATORS do
	local row = create("Frame", { LayoutOrder = index, Size = UDim2.new(1, 0, 0, 96), BackgroundColor3 = C.card }, genPage)
	corner(row, 12)
	local icon = text({ Position = UDim2.fromOffset(8, 18), Size = UDim2.fromOffset(56, 56), Font = Enum.Font.GothamBold }, row)
	local name = text({ Position = UDim2.fromOffset(72, 8), Size = UDim2.new(1, -200, 0, 24), Font = Enum.Font.FredokaOne, TextXAlignment = Enum.TextXAlignment.Left }, row)
	local detail = text({ Position = UDim2.fromOffset(72, 36), Size = UDim2.new(1, -200, 0, 16), Font = Enum.Font.GothamMedium, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Left }, row)
	local setBar, bar = progressBar({ Position = UDim2.fromOffset(72, 62), Size = UDim2.new(1, -200, 0, 22) }, row, C.gold)
	local buy = button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(112, 76), Text = "" }, row)
	local buyTop = text({ Position = UDim2.fromOffset(4, 8), Size = UDim2.new(1, -8, 0, 22), Font = Enum.Font.FredokaOne, Text = "Kaufen" }, buy)
	local buyCost = text({ Position = UDim2.fromOffset(4, 36), Size = UDim2.new(1, -8, 0, 30), Font = Enum.Font.FredokaOne }, buy)
	buy.Activated:Connect(function()
		purchase("gen", gen.id, buyAmount)
	end)
	genRows[gen.id] = { row = row, icon = icon, name = name, detail = detail, setBar = setBar, bar = bar, buy = buy, buyTop = buyTop, buyCost = buyCost, index = index }
end

-- Zeilen für Upgrades
local function simpleRow(parent, order, iconText, title, desc, onBuy)
	local row = create("Frame", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 74), BackgroundColor3 = C.card }, parent)
	corner(row, 12)
	text({ Position = UDim2.fromOffset(8, 12), Size = UDim2.fromOffset(50, 50), Text = iconText, Font = Enum.Font.GothamBold }, row)
	local titleLabel = text({ Position = UDim2.fromOffset(66, 10), Size = UDim2.new(1, -190, 0, 24), Text = title, Font = Enum.Font.FredokaOne, TextXAlignment = Enum.TextXAlignment.Left }, row)
	local descLabel = text({ Position = UDim2.fromOffset(66, 38), Size = UDim2.new(1, -190, 0, 26), Text = desc, Font = Enum.Font.GothamMedium, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true }, row)
	local buy = button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(112, 54), Font = Enum.Font.FredokaOne }, row)
	create("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, buy)
	buy.Activated:Connect(onBuy)
	return { row = row, title = titleLabel, desc = descLabel, buy = buy }
end

local upgradeRows = {}
for index, upgrade in Config.UPGRADES do
	upgradeRows[upgrade.id] = simpleRow(upgradePage, index, upgrade.icon, upgrade.name, upgrade.desc, function()
		purchase("upgrade", upgrade.id)
	end)
	upgradeRows[upgrade.id].index = index
end

-- Rebirth-Seite
local rebirthCard = create("Frame", { LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 250), BackgroundColor3 = Color3.fromRGB(44, 34, 80) }, rebirthPage)
corner(rebirthCard, 14)
stroke(rebirthCard, C.gold, 2, 0.3)
padding(rebirthCard, 12)
text({ Size = UDim2.new(1, 0, 0, 30), Text = "🌟 Wiedergeburt", Font = Enum.Font.FredokaOne, TextColor3 = C.gold }, rebirthCard)
text({
	Position = UDim2.fromOffset(0, 36),
	Size = UDim2.new(1, 0, 0, 54),
	Font = Enum.Font.GothamMedium,
	TextColor3 = C.muted,
	TextWrapped = true,
	Text = "Fang neu an und bekomme <b>Sternenstaub</b>: +" .. math.floor(Config.STARDUST_BONUS * 100)
		.. " % Produktion pro Stück für immer! Deine Insel und der Sternen-Shop bleiben erhalten.",
}, rebirthCard)
local rebirthGainLabel = text({ Position = UDim2.fromOffset(0, 96), Size = UDim2.new(1, 0, 0, 28), Font = Enum.Font.FredokaOne }, rebirthCard)
local setRebirthBar = progressBar({ Position = UDim2.fromOffset(0, 130), Size = UDim2.new(1, 0, 0, 22) }, rebirthCard, C.gold)
local rebirthButton = button({ Position = UDim2.fromOffset(0, 162), Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = C.gold, TextColor3 = Color3.fromRGB(60, 40, 0) }, rebirthCard)
create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12) }, rebirthButton)

local starHeader = text({ LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 34), Font = Enum.Font.FredokaOne, TextColor3 = C.gold }, rebirthPage)
local starRows = {}
for index, upgrade in Config.STAR_UPGRADES do
	starRows[upgrade.id] = simpleRow(rebirthPage, 10 + index, upgrade.icon, upgrade.name, upgrade.desc, function()
		purchase("star", upgrade.id)
	end)
end

local confirmUntil = 0
rebirthButton.Activated:Connect(function()
	if not state or Config.stardustForRun(state.runTotal) < 1 then
		toast("Sammle erst " .. format(Config.REBIRTH_BASE) .. " 💎 in dieser Runde.", "error")
		return
	end
	if os.clock() > confirmUntil then
		confirmUntil = os.clock() + 3
		toast("Sicher? Klick nochmal zum Bestätigen!", "info")
		return
	end
	confirmUntil = 0
	local ok, success, message = pcall(rebirthFunction.InvokeServer, rebirthFunction)
	if ok and success then
		play("big")
		toast(message, "frenzy")
	else
		toast(ok and message or "Wiedergeburt fehlgeschlagen.", "error")
	end
end)

selectTab("gens")
for _, tab in tabs do
	tab.Activated:Connect(updateAmountRowVisibility)
end

---------------------------------------------------------------------------
-- Anzeige aktualisieren
---------------------------------------------------------------------------

local function setBuyable(b, affordable)
	b.BackgroundColor3 = affordable and C.green or C.grey
	b.AutoButtonColor = affordable
end

local function refreshShop()
	if not state then
		return
	end
	local money = currentCrystals()

	-- Helfer
	for index, gen in Config.GENERATORS do
		local r = genRows[gen.id]
		local owned = state.gens[gen.id] or 0
		local unlocked = index == 1 or (state.gens[Config.GENERATORS[index - 1].id] or 0) > 0
		local previousVisible = index <= 2 or (state.gens[Config.GENERATORS[index - 2].id] or 0) > 0
		r.row.Visible = unlocked or previousVisible
		r.row.BackgroundColor3 = unlocked and C.card or C.cardLocked
		r.bar.Visible = unlocked
		r.buy.Visible = unlocked
		if unlocked then
			r.icon.Text = gen.icon
			r.name.Text = gen.name .. '  <font color="' .. hex(C.gold) .. '">x' .. owned .. "</font>"
			local unit = Config.unitRate(state, gen)
			r.detail.Text = "+" .. format(unit) .. "/s pro Stück  •  " .. format(unit * owned) .. "/s gesamt"

			local nextMilestone = Config.nextMilestone(owned)
			if nextMilestone then
				local previous = 0
				for _, t in Config.MILESTONES do
					if t < nextMilestone then
						previous = t
					end
				end
				r.setBar((owned - previous) / (nextMilestone - previous), "Meilenstein " .. owned .. "/" .. nextMilestone .. " → Produktion x2")
			else
				r.setBar(1, "Alle Meilensteine erreicht! 🏆")
			end

			local count = buyAmount == "max" and math.max(1, Config.maxAffordable(gen, owned, money, state)) or buyAmount
			local cost = Config.generatorCost(gen, owned, count, state)
			r.buyTop.Text = "Kaufen x" .. count
			r.buyCost.Text = "💎 " .. format(cost)
			setBuyable(r.buy, money >= cost)
		else
			r.icon.Text = "❓"
			r.name.Text = "???"
			r.detail.Text = "Kauf zuerst den Helfer darüber."
		end
	end

	-- Upgrades
	for index, upgrade in Config.UPGRADES do
		local r = upgradeRows[upgrade.id]
		if state.upgrades[upgrade.id] then
			r.row.LayoutOrder = 1000 + index
			r.row.BackgroundTransparency = 0.5
			r.buy.Text = "✓ Gekauft"
			r.buy.BackgroundColor3 = C.grey
			r.buy.AutoButtonColor = false
		else
			r.row.LayoutOrder = index
			r.row.BackgroundTransparency = 0
			r.buy.Text = "💎 " .. format(upgrade.cost)
			setBuyable(r.buy, money >= upgrade.cost)
		end
	end

	-- Wiedergeburt
	local gain = Config.stardustForRun(state.runTotal)
	local nextTotal = Config.runTotalForStardust(gain + 1)
	local prevTotal = Config.runTotalForStardust(gain)
	rebirthGainLabel.Text = "Du bekommst: <font color=\"" .. hex(C.gold) .. "\">+" .. gain .. " ✨</font>"
	setRebirthBar((state.runTotal - prevTotal) / (nextTotal - prevTotal), format(state.runTotal) .. " / " .. format(nextTotal) .. " für +" .. (gain + 1))
	rebirthButton.Text = gain >= 1 and ("🌟 Wiedergeburt (+" .. gain .. " ✨)") or "🔒 Noch nicht bereit"
	rebirthButton.BackgroundColor3 = gain >= 1 and C.gold or C.grey
	tabs.rebirth.TextColor3 = gain >= 1 and C.gold or Color3.new(1, 1, 1)

	local available = Config.availableStardust(state)
	starHeader.Text = "✨ Sternen-Shop  (verfügbar: " .. available .. ")"
	for _, upgrade in Config.STAR_UPGRADES do
		local r = starRows[upgrade.id]
		local level = Config.starLevel(state, upgrade.id)
		r.title.Text = upgrade.name .. '  <font color="' .. hex(C.gold) .. '">' .. level .. "/" .. upgrade.maxLevel .. "</font>"
		if level >= upgrade.maxLevel then
			r.buy.Text = "MAX"
			r.buy.BackgroundColor3 = C.grey
		else
			local cost = Config.starUpgradeCost(upgrade, level)
			r.buy.Text = "✨ " .. format(cost)
			setBuyable(r.buy, available >= cost)
		end
	end

	-- Insel und Sternenstaub links
	local level = Config.islandLevel(state.allTime)
	local levels = Config.ISLAND_LEVELS
	islandTitle.Text = "🏗️ Insel-Stufe " .. level .. "/" .. #levels
	if level < #levels then
		local nextLevel = levels[level + 1]
		local prev = level > 0 and levels[level].total or 0
		islandNext.Text = "Nächster Ausbau: <b>" .. nextLevel.name .. "</b>"
		setIslandBar((state.allTime - prev) / (nextLevel.total - prev), format(state.allTime) .. " / " .. format(nextLevel.total))
	else
		islandNext.Text = "Deine Insel ist komplett ausgebaut! 👑"
		setIslandBar(1, format(state.allTime))
	end
	stardustLabel.Text = "✨ " .. state.stardust .. " Sternenstaub  (+" .. math.floor(state.stardust * Config.STARDUST_BONUS * 100) .. " %)"
end

stateEvent.OnClientEvent:Connect(function(newState)
	state = newState
	stateClock = os.clock()
end)

---------------------------------------------------------------------------
-- Kristall klicken
---------------------------------------------------------------------------

local punchStart = {}

local function punchCrystal(crystal)
	punchStart[crystal] = os.clock()
	local core = crystal:FindFirstChild("Core")
	local burst = core and core:FindFirstChild("Burst")
	if burst then
		burst:Emit(8)
	end
end

local function myCrystal()
	local plots = workspace:FindFirstChild("Plots")
	if not plots then
		return nil
	end
	for _, plot in plots:GetChildren() do
		if plot:GetAttribute("OwnerId") == player.UserId then
			return plot:FindFirstChild("Crystal")
		end
	end
	return nil
end

local function mine(screenPos)
	if not state or clientTokens < 1 then
		return
	end
	clientTokens -= 1
	mineEvent:FireServer()
	local value = Config.clickValue(state) * frenzyMult()
	state.crystals += value
	state.runTotal += value
	state.allTime += value
	popup("+" .. format(value), screenPos, frenzyMult() > 1 and C.orange or C.cyan)
	play("click")
	local crystal = myCrystal()
	if crystal then
		punchCrystal(crystal)
	end
end

mineButton.Activated:Connect(function()
	local pos = mineButton.AbsolutePosition + mineButton.AbsoluteSize / 2
	mine(Vector2.new(pos.X, pos.Y - 50))
end)

local function hookCrystal(crystal)
	local detector = crystal:WaitForChild("ClickDetector", 10)
	if not detector then
		return
	end
	detector.MouseClick:Connect(function()
		local plot = crystal.Parent
		if plot and plot:GetAttribute("OwnerId") == player.UserId then
			mine(UserInputService:GetMouseLocation())
		else
			toast("Das ist nicht deine Insel! 🏝️", "error")
		end
	end)
end
for _, crystal in CollectionService:GetTagged("MainCrystal") do
	task.spawn(hookCrystal, crystal)
end
CollectionService:GetInstanceAddedSignal("MainCrystal"):Connect(hookCrystal)

---------------------------------------------------------------------------
-- Animationen: Kristalle schweben, Helfer drehen sich
---------------------------------------------------------------------------

local spinning = {}
local function trackModel(model)
	if model:IsA("Model") then
		spinning[model] = { pivot = model:GetPivot(), offset = math.random() * 10 }
	end
end
for _, model in CollectionService:GetTagged("GenModel") do
	trackModel(model)
end
CollectionService:GetInstanceAddedSignal("GenModel"):Connect(trackModel)
CollectionService:GetInstanceRemovedSignal("GenModel"):Connect(function(model)
	spinning[model] = nil
end)

local goldens = {}
local function trackGolden(model)
	goldens[model] = model:GetPivot()
end
CollectionService:GetInstanceAddedSignal("Golden"):Connect(trackGolden)
CollectionService:GetInstanceRemovedSignal("Golden"):Connect(function(model)
	goldens[model] = nil
end)
for _, model in CollectionService:GetTagged("Golden") do
	trackGolden(model)
end

RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	clientTokens = math.min(Config.CLICKS_PER_SECOND, clientTokens + Config.CLICKS_PER_SECOND * dt)

	for _, crystal in CollectionService:GetTagged("MainCrystal") do
		local base = crystal:GetAttribute("BaseCFrame")
		local baseScale = crystal:GetAttribute("BaseScale")
		if typeof(base) == "CFrame" and type(baseScale) == "number" and crystal:IsA("Model") then
			-- kurzes "Aufploppen" nach einem Klick
			local since = punchStart[crystal] and (t - punchStart[crystal]) or 1
			local pop = since < 0.25 and math.sin(since / 0.25 * math.pi) * 0.12 or 0
			local target = baseScale * (1 + pop)
			if math.abs(crystal:GetScale() - target) > 0.001 then
				crystal:ScaleTo(target)
			end
			crystal:PivotTo(CFrame.new(0, math.sin(t * 1.5) * 0.6, 0) * base * CFrame.Angles(0, t * 0.5, 0))
		end
	end
	for model, info in spinning do
		if model.Parent then
			model:PivotTo(info.pivot * CFrame.new(0, math.sin(t * 2 + info.offset) * 0.25, 0) * CFrame.Angles(0, t * 0.6 + info.offset, 0))
		end
	end
	for model, base in goldens do
		if model.Parent then
			model:PivotTo(base * CFrame.new(0, math.sin(t * 3) * 0.6, 0) * CFrame.Angles(0, t * 2, 0))
		end
	end

	if state then
		crystalLabel.Text = "💎 " .. format(math.floor(currentCrystals()))
		perSecondLabel.Text = "+" .. format(perSecond()) .. " pro Sekunde"
		mineValue.Text = "+" .. format(Config.clickValue(state) * frenzyMult()) .. " pro Klick"
		local left = frenzyLeft()
		frenzyBanner.Visible = left > 0
		if left > 0 then
			frenzyBanner.Text = "🔥 KRISTALLRAUSCH x" .. Config.FRENZY_MULTIPLIER .. "  –  " .. math.ceil(left) .. "s"
		end
	end
end)

-- Shop regelmäßig aktualisieren
task.spawn(function()
	while true do
		refreshShop()
		task.wait(0.15)
	end
end)

local function updateScale()
	local camera = workspace.CurrentCamera
	local height = camera and camera.ViewportSize.Y or 900
	local scale = math.clamp(height / 900, 0.55, 1.15)
	for _, s in scaled do
		s.Scale = scale
	end
	-- Der Shop füllt immer die ganze Bildschirmhöhe aus
	shopScale.Scale = scale
	shop.Size = UDim2.fromOffset(400, (height - 76) / scale)
end

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end
updateScale()
