-- Benutzeroberfläche: Münzanzeige, Fortschritt, Shop, Meldungen und drehende Münzen.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local buyItem = remotes:WaitForChild("BuyItem")
local notify = remotes:WaitForChild("Notify")

local player = Players.LocalPlayer

local GOLD = Color3.fromRGB(255, 205, 40)
local DARK = Color3.fromRGB(25, 25, 35)
local GREEN = Color3.fromRGB(60, 200, 110)
local GREY = Color3.fromRGB(110, 110, 120)

-- Drehende Münzen (nur optisch, auf dem Client) ------------------------

local coins = {}
local function trackCoin(coin)
	if coin:IsA("BasePart") then
		coins[coin] = coin.CFrame
	end
end
for _, coin in CollectionService:GetTagged("Coin") do
	trackCoin(coin)
end
CollectionService:GetInstanceAddedSignal("Coin"):Connect(trackCoin)
CollectionService:GetInstanceRemovedSignal("Coin"):Connect(function(coin)
	coins[coin] = nil
end)

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for coin, base in coins do
		coin.CFrame = base * CFrame.new(0, math.sin(t * 2 + base.X) * 0.3, 0) * CFrame.Angles(0, t * 2, 0)
	end
end)

-- UI-Helfer --------------------------------------------------------------

local function create(className, props, parent)
	local inst = Instance.new(className)
	for key, value in props do
		inst[key] = value
	end
	inst.Parent = parent
	return inst
end

local function round(parent, radius)
	create("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, parent)
end

local function label(props, parent)
	local base = {
		BackgroundTransparency = 1,
		Font = Enum.Font.FredokaOne,
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
	}
	for key, value in props do
		base[key] = value
	end
	return create("TextLabel", base, parent)
end

-- Grundgerüst ------------------------------------------------------------

local gui = create("ScreenGui", {
	Name = "MuenzjaegerHUD",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, player:WaitForChild("PlayerGui"))

-- Statusanzeige oben links
local stats = create("Frame", {
	Position = UDim2.fromOffset(16, 16),
	Size = UDim2.fromOffset(220, 84),
	BackgroundColor3 = DARK,
	BackgroundTransparency = 0.2,
}, gui)
round(stats, 12)
create("UIPadding", {
	PaddingLeft = UDim.new(0, 12),
	PaddingRight = UDim.new(0, 12),
	PaddingTop = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 8),
}, stats)

local coinLabel = label({
	Size = UDim2.new(1, 0, 0.55, 0),
	Text = "🪙 0",
	TextColor3 = GOLD,
	TextXAlignment = Enum.TextXAlignment.Left,
}, stats)
local coinScale = create("UIScale", {}, coinLabel)

local stageLabel = label({
	Position = UDim2.fromScale(0, 0.6),
	Size = UDim2.new(1, 0, 0.4, 0),
	Text = "Abschnitt 1 / " .. Config.STAGE_COUNT,
	TextXAlignment = Enum.TextXAlignment.Left,
}, stats)

-- Meldung oben in der Mitte
local toast = label({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 20),
	Size = UDim2.fromOffset(460, 44),
	BackgroundColor3 = DARK,
	BackgroundTransparency = 0.15,
	Visible = false,
	Text = "",
}, gui)
round(toast, 12)
create("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, toast)

local toastToken = 0
local function showToast(text)
	toastToken += 1
	local token = toastToken
	toast.Text = text
	toast.Visible = true
	task.delay(3, function()
		if token == toastToken then
			toast.Visible = false
		end
	end)
end
notify.OnClientEvent:Connect(showToast)

-- Shop -------------------------------------------------------------------

local shopButton = create("TextButton", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 16, 1, -16),
	Size = UDim2.fromOffset(130, 50),
	BackgroundColor3 = GOLD,
	Font = Enum.Font.FredokaOne,
	Text = "🛒 Shop",
	TextColor3 = DARK,
	TextScaled = true,
}, gui)
round(shopButton, 12)

local shop = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(380, 90 + #Config.ITEMS * 78),
	BackgroundColor3 = DARK,
	BackgroundTransparency = 0.05,
	Visible = false,
}, gui)
round(shop, 16)
create("UISizeConstraint", { MaxSize = Vector2.new(380, 600) }, shop)
create("UIPadding", {
	PaddingLeft = UDim.new(0, 14),
	PaddingRight = UDim.new(0, 14),
	PaddingTop = UDim.new(0, 12),
	PaddingBottom = UDim.new(0, 12),
}, shop)

label({ Size = UDim2.new(1, -50, 0, 40), Text = "🛒 Münz-Shop", TextColor3 = GOLD }, shop)

local closeButton = create("TextButton", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.fromScale(1, 0),
	Size = UDim2.fromOffset(40, 40),
	BackgroundColor3 = Color3.fromRGB(220, 70, 70),
	Font = Enum.Font.FredokaOne,
	Text = "X",
	TextColor3 = Color3.new(1, 1, 1),
	TextScaled = true,
}, shop)
round(closeButton, 10)

local list = create("Frame", {
	Position = UDim2.fromOffset(0, 52),
	Size = UDim2.new(1, 0, 1, -52),
	BackgroundTransparency = 1,
}, shop)
create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)

for index, item in Config.ITEMS do
	local row = create("Frame", {
		LayoutOrder = index,
		Size = UDim2.new(1, 0, 0, 70),
		BackgroundColor3 = Color3.fromRGB(45, 45, 60),
	}, list)
	round(row, 10)

	label({
		Position = UDim2.fromOffset(10, 6),
		Size = UDim2.new(1, -130, 0, 30),
		Text = item.name,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	label({
		Position = UDim2.fromOffset(10, 38),
		Size = UDim2.new(1, -130, 0, 22),
		Font = Enum.Font.Gotham,
		Text = item.desc,
		TextColor3 = Color3.fromRGB(200, 200, 210),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local button = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(105, 44),
		BackgroundColor3 = GREEN,
		Font = Enum.Font.FredokaOne,
		Text = "🪙 " .. item.price,
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
	}, row)
	round(button, 10)

	local attribute = "Owned_" .. item.id
	local function refresh()
		if player:GetAttribute(attribute) then
			button.Text = "Gekauft ✓"
			button.BackgroundColor3 = GREY
			button.AutoButtonColor = false
		end
	end
	refresh()
	player:GetAttributeChangedSignal(attribute):Connect(refresh)

	local busy = false
	button.Activated:Connect(function()
		if busy or player:GetAttribute(attribute) then
			return
		end
		busy = true
		local ok, success, message = pcall(buyItem.InvokeServer, buyItem, item.id)
		busy = false
		if ok then
			showToast(message or (success and "Gekauft!" or "Kauf fehlgeschlagen."))
		else
			showToast("Kauf fehlgeschlagen, versuch es nochmal.")
		end
	end)
end

shopButton.Activated:Connect(function()
	shop.Visible = not shop.Visible
end)
closeButton.Activated:Connect(function()
	shop.Visible = false
end)

-- Werte aus den leaderstats anzeigen -----------------------------------

local leaderstats = player:WaitForChild("leaderstats")
local coinValue = leaderstats:WaitForChild("Coins")
local stageValue = leaderstats:WaitForChild("Stage")

local lastCoins = coinValue.Value
local function updateCoins()
	coinLabel.Text = "🪙 " .. coinValue.Value
	if coinValue.Value > lastCoins then
		coinScale.Scale = 1.25
		TweenService:Create(coinScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	lastCoins = coinValue.Value
end

local function updateStage()
	stageLabel.Text = "Abschnitt " .. (stageValue.Value + 1) .. " / " .. Config.STAGE_COUNT
end

coinValue.Changed:Connect(updateCoins)
stageValue.Changed:Connect(updateStage)
updateCoins()
updateStage()

showToast("Willkommen bei " .. Config.GAME_NAME .. "! Sammle Münzen und erreiche das Ziel 🏆")
