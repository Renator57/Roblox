-- Baut die komplette Obby-Strecke per Code auf (keine Place-Datei nötig).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local MapBuilder = {}

local PALETTE = {
	Color3.fromRGB(80, 160, 255),
	Color3.fromRGB(120, 220, 120),
	Color3.fromRGB(255, 170, 60),
	Color3.fromRGB(255, 110, 160),
	Color3.fromRGB(170, 120, 255),
}
local LAVA_COLOR = Color3.fromRGB(255, 70, 30)
local COIN_COLOR = Color3.fromRGB(255, 205, 40)
local CHECKPOINT_COLOR = Color3.fromRGB(60, 200, 110)
local STONE_COLOR = Color3.fromRGB(90, 90, 100)
local VANISH_COLOR = Color3.fromRGB(200, 140, 255)

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function makePart(parent, props, className)
	local p = Instance.new(className or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		p[key] = value
	end
	p.Parent = parent
	return p
end

-- Plattform, deren Oberseite genau auf Höhe `top` liegt
local function platform(parent, x, top, z, sx, sz, color, name)
	return makePart(parent, {
		Name = name or "Platform",
		Size = Vector3.new(sx, 1, sz),
		Position = Vector3.new(x, top - 0.5, z),
		Color = color,
	})
end

local function lava(parent, size, position)
	local p = makePart(parent, {
		Name = "Lava",
		Size = size,
		Position = position,
		Color = LAVA_COLOR,
		Material = Enum.Material.Neon,
	})
	CollectionService:AddTag(p, "Lava")
	return p
end

local function addLabel(part, text, color, offsetY)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(220, 50)
	gui.StudsOffset = Vector3.new(0, offsetY or 4, 0)
	gui.MaxDistance = 150
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Parent = gui
	gui.Parent = part
end

local function addCoin(parent, position)
	local coin = makePart(parent, {
		Name = "Coin",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 2.2, 2.2),
		CFrame = CFrame.new(position),
		Color = COIN_COLOR,
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
	coin:SetAttribute("Active", true)
	CollectionService:AddTag(coin, "Coin")
	return coin
end

----------------------------------------------------------------------
-- Hindernis-Typen. ctx = { parent, coins, a, b, y0, y1, d, color, result }
-- a/b: Start/Ende in X, y0/y1: Höhe am Anfang/Ende, d: Schwierigkeit 0..1
----------------------------------------------------------------------

local function buildJumps(ctx)
	local count = 4
	local size = 6 - 2 * ctx.d
	for k = 1, count do
		local t = (k - 0.5) / count
		local x = lerp(ctx.a, ctx.b, t)
		local top = lerp(ctx.y0, ctx.y1, t)
		local z = (k % 2 == 0) and 3 or -3
		platform(ctx.parent, x, top, z, size, size, ctx.color)
		addCoin(ctx.coins, Vector3.new(x, top + 3, z))
	end
end

local function buildBeams(ctx)
	local w = 2.2 - ctx.d
	local span = ctx.b - ctx.a
	local points = {
		Vector3.new(ctx.a - 1, ctx.y0, 0),
		Vector3.new(ctx.a + span / 3, lerp(ctx.y0, ctx.y1, 1 / 3), -4),
		Vector3.new(ctx.a + 2 * span / 3, lerp(ctx.y0, ctx.y1, 2 / 3), 4),
		Vector3.new(ctx.b + 1, ctx.y1, 0),
	}
	local down = Vector3.new(0, 0.5, 0)
	for k = 1, #points - 1 do
		local p1, p2 = points[k], points[k + 1]
		local length = (p2 - p1).Magnitude + w
		local mid = (p1 + p2) / 2
		makePart(ctx.parent, {
			Name = "Beam",
			Size = Vector3.new(w, 1, length),
			CFrame = CFrame.lookAt(mid - down, p2 - down),
			Color = ctx.color,
		})
		addCoin(ctx.coins, mid + Vector3.new(0, 3, 0))
	end
end

local function buildLava(ctx)
	local span = ctx.b - ctx.a
	lava(ctx.parent, Vector3.new(span, 1, 14), Vector3.new(ctx.a + span / 2, ctx.y0 - 1.5, 0))
	local count = 5
	local size = 4.5 - 1.5 * ctx.d
	for k = 1, count do
		local t = (k - 0.5) / count
		local x = lerp(ctx.a, ctx.b, t)
		local top = lerp(ctx.y0, ctx.y1, t)
		local z = (k % 2 == 0) and 2.5 or -2.5
		platform(ctx.parent, x, top, z, size, size, STONE_COLOR, "Stone")
		addCoin(ctx.coins, Vector3.new(x, top + 3, z))
	end
end

local function buildVanish(ctx)
	local count = 5
	local size = 5 - ctx.d
	for k = 1, count do
		local t = (k - 0.5) / count
		local x = lerp(ctx.a, ctx.b, t)
		local top = lerp(ctx.y0, ctx.y1, t)
		local z = (k % 2 == 0) and 2 or -2
		local p = platform(ctx.parent, x, top, z, size, size, VANISH_COLOR, "VanishPlatform")
		p.Material = Enum.Material.Glass
		CollectionService:AddTag(p, "Vanish")
		addCoin(ctx.coins, Vector3.new(x, top + 3, z))
	end
end

local function buildSpinner(ctx)
	local down = Vector3.new(0, 0.5, 0)
	local p1 = Vector3.new(ctx.a - 0.5, ctx.y0, 0) - down
	local p2 = Vector3.new(ctx.b + 0.5, ctx.y1, 0) - down
	makePart(ctx.parent, {
		Name = "Ramp",
		Size = Vector3.new(12, 1, (p2 - p1).Magnitude),
		CFrame = CFrame.lookAt((p1 + p2) / 2, p2),
		Color = ctx.color,
	})
	for k = 1, 2 do
		local t = k / 3
		local x = lerp(ctx.a, ctx.b, t)
		local top = lerp(ctx.y0, ctx.y1, t)
		makePart(ctx.parent, {
			Name = "Pole",
			Size = Vector3.new(1, 1.6, 1),
			Position = Vector3.new(x, top + 0.8, 0),
			Color = STONE_COLOR,
		})
		local pivot = CFrame.new(x, top + 1.5, 0)
		local bar = makePart(ctx.parent, {
			Name = "Spinner",
			Size = Vector3.new(11, 0.8, 0.8),
			CFrame = pivot,
			Color = LAVA_COLOR,
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
		local direction = (k % 2 == 0) and -1 or 1
		table.insert(ctx.result.spinners, {
			part = bar,
			pivot = pivot,
			angle = k,
			speed = (1.4 + 1.6 * ctx.d) * direction,
		})
		addCoin(ctx.coins, Vector3.new(x + 4, top + 3, 3))
		addCoin(ctx.coins, Vector3.new(x - 4, top + 3, -3))
	end
end

local STAGE_TYPES = { buildJumps, buildBeams, buildLava, buildVanish, buildSpinner }

----------------------------------------------------------------------

function MapBuilder.build()
	local old = workspace:FindFirstChild("Course")
	if old then
		old:Destroy()
	end

	local course = Instance.new("Folder")
	course.Name = "Course"
	course.Parent = workspace
	local coins = Instance.new("Folder")
	coins.Name = "Coins"
	coins.Parent = course

	local N, L, R = Config.STAGE_COUNT, Config.STAGE_LENGTH, Config.STAGE_RISE
	local result = { folder = course, checkpoints = {}, spinners = {}, finish = nil }

	local function topAt(i)
		return i * R
	end

	-- Startplattform
	local spawn = makePart(course, {
		Name = "Checkpoint0",
		Size = Vector3.new(20, 1, 16),
		Position = Vector3.new(-2, -0.5, 0),
		Color = CHECKPOINT_COLOR,
		Neutral = true,
		Duration = 0,
	}, "SpawnLocation")
	spawn:SetAttribute("Stage", 0)
	CollectionService:AddTag(spawn, "Checkpoint")
	result.checkpoints[0] = spawn
	addLabel(spawn, "🪙 " .. Config.GAME_NAME .. " 🪙", COIN_COLOR, 7)

	-- Checkpoints und Hindernisse
	for i = 0, N - 1 do
		if i > 0 then
			local cp = platform(course, i * L + 4, topAt(i), 0, 8, 14, CHECKPOINT_COLOR, "Checkpoint" .. i)
			cp:SetAttribute("Stage", i)
			CollectionService:AddTag(cp, "Checkpoint")
			result.checkpoints[i] = cp
			addLabel(cp, "Checkpoint " .. i, Color3.new(1, 1, 1), 5)
		end

		-- Lava-Becken unter jedem Abschnitt (schnelleres Zurücksetzen)
		lava(course, Vector3.new(L, 1, 40), Vector3.new(i * L + L / 2, topAt(i) - 10, 0))

		local build = STAGE_TYPES[(i % #STAGE_TYPES) + 1]
		build({
			parent = course,
			coins = coins,
			a = i * L + 8,
			b = (i + 1) * L,
			y0 = topAt(i),
			y1 = topAt(i + 1),
			d = (N > 1) and i / (N - 1) or 0,
			color = PALETTE[(i % #PALETTE) + 1],
			result = result,
		})
	end

	-- Ziel
	local finishTop = topAt(N)
	local finishX = N * L + 7
	local finish = platform(course, finishX, finishTop, 0, 14, 18, COIN_COLOR, "Finish")
	finish.Material = Enum.Material.Neon
	CollectionService:AddTag(finish, "Finish")
	result.finish = finish
	for _, z in { -8, 8 } do
		makePart(course, {
			Name = "ArchPillar",
			Size = Vector3.new(1.5, 12, 1.5),
			Position = Vector3.new(finishX, finishTop + 6, z),
			Color = Color3.fromRGB(255, 255, 255),
		})
	end
	local archTop = makePart(course, {
		Name = "ArchTop",
		Size = Vector3.new(1.5, 1.5, 17.5),
		Position = Vector3.new(finishX, finishTop + 12.75, 0),
		Color = Color3.fromRGB(255, 255, 255),
	})
	addLabel(archTop, "🏆 ZIEL 🏆", COIN_COLOR, 3)

	-- Großer Lava-Boden als Sicherheitsnetz
	lava(course, Vector3.new(N * L + 200, 1, 400), Vector3.new(N * L / 2, -25, 0))

	return result
end

return MapBuilder
