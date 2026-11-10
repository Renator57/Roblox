-- Hauptskript: verbindet Strecke, Spielerdaten und Spielregeln.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local MapBuilder = require(script.Parent.MapBuilder)
local PlayerData = require(script.Parent.PlayerData)

-- Remotes ---------------------------------------------------------------

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local buyItem = Instance.new("RemoteFunction")
buyItem.Name = "BuyItem"
buyItem.Parent = remotes
local notify = Instance.new("RemoteEvent")
notify.Name = "Notify"
notify.Parent = remotes
remotes.Parent = ReplicatedStorage

-- Welt ------------------------------------------------------------------

Lighting.ClockTime = 14.5
Lighting.Brightness = 2
Players.CharacterAutoLoads = false

local course = MapBuilder.build()
local checkpoints = course.checkpoints

-- Hilfsfunktionen -------------------------------------------------------

local function playerFromHit(hit)
	local character = hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return nil
	end
	return player, humanoid
end

local function applyItems(player, character)
	local data = PlayerData.get(player)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (data and humanoid) then
		return
	end
	local items = data.Items

	humanoid.WalkSpeed = Config.BASE_WALKSPEED + (items.Speed and Config.SPEED_BONUS or 0)
	humanoid.UseJumpPower = true
	humanoid.JumpPower = Config.BASE_JUMPPOWER + (items.Jump and Config.JUMP_BONUS or 0)

	local root = character:FindFirstChild("HumanoidRootPart")
	if items.Glow and root and not root:FindFirstChild("GlowLight") then
		local light = Instance.new("PointLight")
		light.Name = "GlowLight"
		light.Color = Color3.fromRGB(255, 220, 90)
		light.Range = 14
		light.Brightness = 2
		light.Parent = root
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = Color3.fromRGB(255, 220, 90)
		sparkles.Parent = root
	end
end

local function respawn(player)
	if player.Parent == Players then
		player:LoadCharacter()
	end
end

-- Spieler ---------------------------------------------------------------

local function onCharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	character:WaitForChild("HumanoidRootPart")
	applyItems(player, character)

	humanoid.Died:Connect(function()
		task.delay(Config.RESPAWN_TIME, function()
			if player.Character == character then
				respawn(player)
			end
		end)
	end)

	-- Am letzten erreichten Checkpoint absetzen, Blick Richtung Strecke
	task.wait()
	local data = PlayerData.get(player)
	local checkpoint = (data and checkpoints[data.Stage]) or checkpoints[0]
	local position = checkpoint.Position + Vector3.new(0, 4, 0)
	if character.Parent then
		character:PivotTo(CFrame.lookAt(position, position + Vector3.xAxis))
	end
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	PlayerData.load(player)
	respawn(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
PlayerData.startAutosave()

-- Münzen ----------------------------------------------------------------

for _, coin in CollectionService:GetTagged("Coin") do
	coin.Touched:Connect(function(hit)
		if not coin:GetAttribute("Active") then
			return
		end
		local player = playerFromHit(hit)
		local data = player and PlayerData.get(player)
		if not data then
			return
		end
		coin:SetAttribute("Active", false)
		coin.Transparency = 1
		local value = Config.COIN_VALUE * (data.Items.Double and 2 or 1)
		PlayerData.add(player, "Coins", value)
		task.delay(Config.COIN_RESPAWN_TIME, function()
			coin.Transparency = 0
			coin:SetAttribute("Active", true)
		end)
	end)
end

-- Lava ------------------------------------------------------------------

for _, part in CollectionService:GetTagged("Lava") do
	part.Touched:Connect(function(hit)
		local _, humanoid = playerFromHit(hit)
		if humanoid then
			humanoid.Health = 0
		end
	end)
end

-- Verschwindende Plattformen -------------------------------------------

for _, part in CollectionService:GetTagged("Vanish") do
	local originalColor = part.Color
	part.Touched:Connect(function(hit)
		if part:GetAttribute("Busy") or not playerFromHit(hit) then
			return
		end
		part:SetAttribute("Busy", true)
		part.Color = Color3.fromRGB(255, 90, 90)
		task.wait(0.6)
		local fade = TweenService:Create(part, TweenInfo.new(0.3), { Transparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		part.CanCollide = false
		task.wait(2.5)
		part.CanCollide = true
		part.Transparency = 0
		part.Color = originalColor
		part:SetAttribute("Busy", false)
	end)
end

-- Drehende Balken -------------------------------------------------------

local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Include

RunService.Heartbeat:Connect(function(dt)
	local characters = {}
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(characters, player.Character)
		end
	end
	overlap.FilterDescendantsInstances = characters

	for _, spinner in course.spinners do
		spinner.angle += spinner.speed * dt
		spinner.part.CFrame = spinner.pivot * CFrame.Angles(0, spinner.angle, 0)
		if #characters > 0 then
			for _, hit in workspace:GetPartsInPart(spinner.part, overlap) do
				local _, humanoid = playerFromHit(hit)
				if humanoid then
					humanoid.Health = 0
				end
			end
		end
	end
end)

-- Checkpoints -----------------------------------------------------------

for _, checkpoint in CollectionService:GetTagged("Checkpoint") do
	local stage = checkpoint:GetAttribute("Stage")
	checkpoint.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		local data = player and PlayerData.get(player)
		if data and stage > data.Stage then
			PlayerData.set(player, "Stage", stage)
			notify:FireClient(player, "✅ Checkpoint " .. stage .. " erreicht!")
		end
	end)
end

-- Ziel ------------------------------------------------------------------

local finishing = {}

course.finish.Touched:Connect(function(hit)
	local player = playerFromHit(hit)
	local data = player and PlayerData.get(player)
	if not data or finishing[player] or data.Stage < Config.STAGE_COUNT - 1 then
		return
	end
	finishing[player] = true

	PlayerData.add(player, "Wins", 1)
	PlayerData.add(player, "Coins", Config.FINISH_BONUS)
	PlayerData.set(player, "Stage", 0)
	notify:FireAllClients("🏆 " .. player.DisplayName .. " hat das Ziel erreicht!")
	notify:FireClient(player, "+" .. Config.FINISH_BONUS .. " Bonus-Münzen! Auf geht's zur nächsten Runde.")
	task.spawn(PlayerData.save, player)

	task.delay(4, function()
		finishing[player] = nil
		respawn(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	finishing[player] = nil
end)

-- Shop ------------------------------------------------------------------

buyItem.OnServerInvoke = function(player, itemId)
	if type(itemId) ~= "string" then
		return false, "Ungültiger Artikel."
	end
	local item = Config.ITEMS_BY_ID[itemId]
	local data = PlayerData.get(player)
	if not (item and data) then
		return false, "Ungültiger Artikel."
	end
	if data.Items[itemId] then
		return false, "Du besitzt " .. item.name .. " schon."
	end
	if data.Coins < item.price then
		return false, "Dir fehlen noch " .. (item.price - data.Coins) .. " Münzen."
	end

	PlayerData.add(player, "Coins", -item.price)
	PlayerData.grantItem(player, itemId)
	applyItems(player, player.Character)
	return true, "🛒 " .. item.name .. " gekauft!"
end
