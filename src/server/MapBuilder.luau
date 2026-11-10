-- Baut die Welt: schwebende Inseln mit Riesenkristall und Sockeln für die Helfer.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local MapBuilder = {}
MapBuilder.plots = {}
MapBuilder.ISLAND_SIZE = 96

local CRYSTAL_COLOR = Color3.fromRGB(90, 200, 255)
local GOLD = Color3.fromRGB(255, 205, 60)
local STONE = Color3.fromRGB(120, 120, 135)
local DARK_STONE = Color3.fromRGB(70, 70, 85)
local GRASS = Color3.fromRGB(100, 190, 90)
local ROCK = Color3.fromRGB(120, 95, 75)
local WOOD = Color3.fromRGB(120, 80, 50)

local SLOT_RADIUS = 22
local ISLAND_SIZE = 96

----------------------------------------------------------------------
-- Helfer
----------------------------------------------------------------------

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

-- Zylinder mit senkrechter Achse (Roblox-Zylinder liegen sonst auf der X-Achse)
local function vCylinder(parent, height, diameter, cframe, color, material)
	return makePart(parent, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, diameter, diameter),
		CFrame = cframe * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
	})
end

local function ball(parent, diameter, cframe, color, material)
	return makePart(parent, {
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(diameter, diameter, diameter),
		CFrame = cframe,
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
	})
end

local function billboard(parent, widthStuds, heightStuds, offsetY, maxDistance)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(widthStuds, 0, heightStuds, 0) -- in Studs: wird mit Entfernung kleiner
	gui.StudsOffset = Vector3.new(0, offsetY, 0)
	gui.MaxDistance = maxDistance or 120
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.Parent = gui
	gui.Parent = parent
	return label
end

-- Facettierter Kristall: Prisma mit Spitze oben und unten (Würfel auf der Ecke).
-- Gibt das mittlere Teil zurück.
local TIP_ROTATION = CFrame.Angles(0, 0, math.rad(35.264)) * CFrame.Angles(math.rad(-45), 0, 0)

local function crystalShape(parent, cf, width, height, color, material, transparency)
	local props = { Color = color, Material = material or Enum.Material.Neon, Transparency = transparency or 0 }
	local function withProps(extra)
		for key, value in props do
			extra[key] = value
		end
		return extra
	end
	local core = makePart(parent, withProps({
		Name = "Core",
		Size = Vector3.new(width, height, width),
		CFrame = cf * CFrame.Angles(0, math.rad(45), 0),
	}))
	local tip = width * 0.74
	for _, direction in { 1, -1 } do
		makePart(parent, withProps({
			Name = "Tip",
			Size = Vector3.new(tip, tip, tip),
			CFrame = cf * CFrame.new(0, direction * height / 2, 0) * TIP_ROTATION,
		}))
	end
	return core
end

----------------------------------------------------------------------
-- Natürliches Gelände (Roblox-Terrain) statt eckiger Teile
----------------------------------------------------------------------

local Terrain = workspace.Terrain

-- Schwebende Insel: flache Grasdecke mit unregelmäßigem Rand, felsige Unterseite
local function terrainIsland(center, radius, rng)
	Terrain:FillCylinder(CFrame.new(center + Vector3.new(0, -3, 0)), 6, radius, Enum.Material.Grass)
	-- unregelmäßiger Rand
	for _ = 1, 16 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = radius * rng:NextNumber(0.9, 1.02)
		Terrain:FillBall(center + Vector3.new(math.cos(a) * r, -5, math.sin(a) * r), rng:NextNumber(4, 6), Enum.Material.Grass)
	end
	-- Unterseite: nach unten schmaler werdende Erd- und Felsschichten
	for i = 1, 5 do
		local layerRadius = radius * (1 - i * 0.16)
		local material = (i == 1) and Enum.Material.Ground or Enum.Material.Rock
		Terrain:FillCylinder(CFrame.new(center + Vector3.new(0, -3 - i * 6, 0)), 6, layerRadius, material)
	end
	-- Felsbrocken für eine natürliche, zerklüftete Form
	for _ = 1, 22 do
		local a = rng:NextNumber(0, math.pi * 2)
		local spread = rng:NextNumber(0.15, 0.85)
		local ballRadius = rng:NextNumber(5, 10)
		local depth = 6 + (1 - spread) * rng:NextNumber(8, 26)
		local material = rng:NextNumber() < 0.7 and Enum.Material.Rock or Enum.Material.Slate
		Terrain:FillBall(center + Vector3.new(math.cos(a) * radius * spread, -depth - ballRadius * 0.4, math.sin(a) * radius * spread), ballRadius, material)
	end
	Terrain:FillBall(center + Vector3.new(0, -38, 0), 7, Enum.Material.Rock)
end

-- Cartoon-Baum: Stamm mit runden, weichen Kronen (oder eine Tanne)
local function softBall(parent, size, cframe, color)
	local p = makePart(parent, { Size = size, CFrame = cframe, Color = color, CanCollide = false })
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

local function terrainTree(parent, pos, rng)
	local leaf = Color3.fromHSV(rng:NextNumber(0.24, 0.36), rng:NextNumber(0.55, 0.7), rng:NextNumber(0.6, 0.8))
	local leafLight = leaf:Lerp(Color3.fromRGB(230, 255, 180), 0.25)
	local pine = rng:NextNumber() < 0.3
	local height = rng:NextNumber(5, 7)
	makePart(parent, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, 1.3, 1.3),
		CFrame = CFrame.new(pos + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = WOOD,
		Material = Enum.Material.Wood,
	})
	local top = pos + Vector3.new(0, height, 0)
	if pine then
		local dark = leaf:Lerp(Color3.fromRGB(20, 60, 40), 0.35)
		for i, size in { 7, 5.2, 3.4 } do
			softBall(parent, Vector3.new(size, 3.2, size), CFrame.new(top + Vector3.new(0, (i - 1) * 2.2, 0)), dark)
		end
	else
		softBall(parent, Vector3.new(7, 6, 7), CFrame.new(top + Vector3.new(0, 1.5, 0)), leaf)
		for k = 1, 3 do
			local a = k / 3 * math.pi * 2 + rng:NextNumber(0, 1)
			softBall(parent, Vector3.new(4.2, 3.8, 4.2), CFrame.new(top + Vector3.new(math.cos(a) * 2.6, rng:NextNumber(0.2, 2.2), math.sin(a) * 2.6)), k == 1 and leafLight or leaf)
		end
	end
end

----------------------------------------------------------------------
-- Eigene 3D-Modelle: Lege Modelle in ReplicatedStorage > Modelle
-- (Name = ID, z. B. "Pickaxe", "Golem"). Sonst werden einfache Modelle gebaut.
----------------------------------------------------------------------

local function customModel(name, targetSize, cframe)
	local folder = ReplicatedStorage:FindFirstChild("Modelle")
	local template = folder and folder:FindFirstChild(name)
	if not (template and template:IsA("Model")) then
		return nil
	end
	local model = template:Clone()
	for _, inst in model:GetDescendants() do
		if inst:IsA("LuaSourceContainer") then
			inst:Destroy() -- Skripte aus Toolbox-Modellen nie mitlaufen lassen
		elseif inst:IsA("BasePart") then
			inst.Anchored = true
			inst.CanCollide = false
		end
	end
	local boxCF, size = model:GetBoundingBox()
	local biggest = math.max(size.X, size.Y, size.Z)
	if biggest > 0 then
		model.WorldPivot = boxCF
		model:ScaleTo(model:GetScale() * targetSize / biggest)
	end
	local _, newSize = model:GetBoundingBox()
	model:PivotTo(cframe * CFrame.new(0, newSize.Y / 2, 0))
	return model
end

----------------------------------------------------------------------
-- Die 3D-Modelle der Helfer. `cf` = Oberseite des Sockels, Blick zur Inselmitte.
----------------------------------------------------------------------

local MODEL_BUILDERS = {}

MODEL_BUILDERS.Pickaxe = function(m, cf)
	local handleCF = cf * CFrame.new(0, 2.6, 0) * CFrame.Angles(0, 0, math.rad(70))
	makePart(m, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(5, 0.5, 0.5),
		CFrame = handleCF,
		Color = WOOD,
		Material = Enum.Material.Wood,
	})
	makePart(m, {
		Size = Vector3.new(0.7, 0.7, 3.8),
		CFrame = handleCF * CFrame.new(2.3, 0, 0),
		Color = Color3.fromRGB(190, 195, 205),
		Material = Enum.Material.Metal,
	})
	ball(m, 1, cf * CFrame.new(1.4, 0.5, 0.8), CRYSTAL_COLOR, Enum.Material.Neon)
end

MODEL_BUILDERS.Dwarf = function(m, cf)
	vCylinder(m, 2.4, 2.4, cf * CFrame.new(0, 1.2, 0), Color3.fromRGB(70, 110, 200))
	makePart(m, { Size = Vector3.new(2.5, 0.4, 2.5), CFrame = cf * CFrame.new(0, 1.6, 0), Color = Color3.fromRGB(90, 60, 40) })
	ball(m, 1.9, cf * CFrame.new(0, 3.2, 0), Color3.fromRGB(240, 195, 160))
	makePart(m, { Size = Vector3.new(1.4, 1.4, 0.5), CFrame = cf * CFrame.new(0, 2.6, -0.75), Color = Color3.fromRGB(240, 240, 240) })
	ball(m, 0.55, cf * CFrame.new(0, 3.25, -0.95), Color3.fromRGB(230, 150, 130))
	vCylinder(m, 0.3, 2.3, cf * CFrame.new(0, 3.95, 0), Color3.fromRGB(200, 40, 50))
	makePart(m, {
		Size = Vector3.new(1.2, 1.2, 1.2),
		CFrame = cf * CFrame.new(0, 4.5, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)),
		Color = Color3.fromRGB(200, 40, 50),
	})
end

MODEL_BUILDERS.Drill = function(m, cf)
	local copper = Color3.fromRGB(200, 120, 70)
	vCylinder(m, 2, 3.6, cf * CFrame.new(0, 1, 0), DARK_STONE, Enum.Material.Metal)
	vCylinder(m, 1.8, 2.8, cf * CFrame.new(0, 2.9, 0), copper, Enum.Material.Metal)
	vCylinder(m, 1.6, 1.8, cf * CFrame.new(0, 4.6, 0), copper, Enum.Material.Metal)
	vCylinder(m, 1, 0.8, cf * CFrame.new(0, 5.9, 0), Color3.fromRGB(220, 220, 230), Enum.Material.Metal)
	vCylinder(m, 3, 0.8, cf * CFrame.new(1.9, 3, 0), DARK_STONE, Enum.Material.Metal)
	ball(m, 0.9, cf * CFrame.new(1.9, 4.6, 0), Color3.fromRGB(255, 140, 60), Enum.Material.Neon)
end

MODEL_BUILDERS.Mine = function(m, cf)
	for _, x in { -1.9, 1.9 } do
		makePart(m, { Size = Vector3.new(1.4, 4, 1.6), CFrame = cf * CFrame.new(x, 2, 0), Color = ROCK, Material = Enum.Material.Slate })
	end
	makePart(m, { Size = Vector3.new(5.4, 1, 2), CFrame = cf * CFrame.new(0, 4.5, 0), Color = WOOD, Material = Enum.Material.Wood })
	makePart(m, { Size = Vector3.new(2.4, 3.6, 0.4), CFrame = cf * CFrame.new(0, 1.8, 0.4), Color = Color3.fromRGB(20, 20, 25) })
	makePart(m, { Size = Vector3.new(1.8, 1, 1.3), CFrame = cf * CFrame.new(0, 0.5, -1.8), Color = STONE, Material = Enum.Material.Metal })
	for i = -1, 1 do
		ball(m, 0.7, cf * CFrame.new(i * 0.5, 1.15, -1.8), CRYSTAL_COLOR, Enum.Material.Neon)
	end
end

MODEL_BUILDERS.Laser = function(m, cf)
	makePart(m, { Size = Vector3.new(2.8, 1, 2.8), CFrame = cf * CFrame.new(0, 0.5, 0), Color = DARK_STONE, Material = Enum.Material.Metal })
	vCylinder(m, 6, 1.2, cf * CFrame.new(0, 4, 0), Color3.fromRGB(200, 200, 215), Enum.Material.Metal)
	vCylinder(m, 0.3, 2.8, cf * CFrame.new(0, 5.6, 0), DARK_STONE, Enum.Material.Metal)
	local orb = ball(m, 1.7, cf * CFrame.new(0, 7.4, 0), Color3.fromRGB(255, 60, 80), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 60, 80)
	light.Range = 10
	light.Parent = orb
end

MODEL_BUILDERS.Portal = function(m, cf)
	local violet = Color3.fromRGB(170, 90, 255)
	makePart(m, { Size = Vector3.new(4, 1, 2), CFrame = cf * CFrame.new(0, 0.5, 0), Color = DARK_STONE, Material = Enum.Material.Slate })
	local center = cf * CFrame.new(0, 3.8, 0)
	for k = 0, 11 do
		local angle = k / 12 * math.pi * 2
		makePart(m, {
			Size = Vector3.new(1, 1, 1),
			CFrame = center * CFrame.new(math.cos(angle) * 2.7, math.sin(angle) * 2.7, 0) * CFrame.Angles(0, 0, angle),
			Color = violet,
			Material = Enum.Material.Neon,
		})
	end
	makePart(m, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, 4.8, 4.8),
		CFrame = center * CFrame.Angles(0, math.rad(90), 0),
		Color = Color3.fromRGB(120, 60, 220),
		Material = Enum.Material.Neon,
		Transparency = 0.45,
	})
end

MODEL_BUILDERS.Forge = function(m, cf)
	local iron = Color3.fromRGB(60, 60, 70)
	makePart(m, { Size = Vector3.new(2.2, 1.2, 1.6), CFrame = cf * CFrame.new(0, 0.6, 0), Color = iron, Material = Enum.Material.Metal })
	makePart(m, { Size = Vector3.new(1.1, 1, 1), CFrame = cf * CFrame.new(0, 1.7, 0), Color = iron, Material = Enum.Material.Metal })
	makePart(m, { Size = Vector3.new(3.4, 0.8, 1.5), CFrame = cf * CFrame.new(0, 2.6, 0), Color = iron, Material = Enum.Material.Metal })
	makePart(m, { Size = Vector3.new(1.3, 0.3, 0.7), CFrame = cf * CFrame.new(0, 3.15, 0), Color = Color3.fromRGB(255, 130, 40), Material = Enum.Material.Neon })
	local star = ball(m, 1.2, cf * CFrame.new(0, 5, 0), Color3.fromRGB(255, 230, 90), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 200, 80)
	light.Range = 12
	light.Parent = star
end

MODEL_BUILDERS.Core = function(m, cf)
	local center = cf * CFrame.new(0, 4, 0)
	makePart(m, { Size = Vector3.new(2, 1, 2), CFrame = cf * CFrame.new(0, 0.5, 0), Color = DARK_STONE, Material = Enum.Material.Metal })
	local glass = ball(m, 4.2, center, Color3.fromRGB(40, 50, 120), Enum.Material.Glass)
	glass.Transparency = 0.45
	ball(m, 2.2, center, Color3.fromRGB(255, 110, 220), Enum.Material.Neon)
	for _, tilt in { 20, -35 } do
		makePart(m, {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.15, 6.4, 6.4),
			CFrame = center * CFrame.Angles(math.rad(tilt), 0, math.rad(90)),
			Color = Color3.fromRGB(110, 220, 255),
			Material = Enum.Material.Neon,
			Transparency = 0.5,
		})
	end
end

local function buildGeneratorModel(slot, gen)
	local custom = customModel(gen.id, 6, slot.top)
	if custom then
		custom.Name = gen.id
		custom.WorldPivot = slot.top
		custom.Parent = slot.folder
		CollectionService:AddTag(custom, "GenModel")
		return custom
	end
	local model = Instance.new("Model")
	model.Name = gen.id
	MODEL_BUILDERS[gen.id](model, slot.top)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CastShadow = true
		end
	end
	model.WorldPivot = slot.top
	model.Parent = slot.folder
	CollectionService:AddTag(model, "GenModel")
	return model
end

----------------------------------------------------------------------
-- Ausbaustufen der Insel (Config.ISLAND_LEVELS). Jede Funktion baut eine Stufe.
----------------------------------------------------------------------

local function spinModel(parent, name)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

local DECOR_BUILDERS = {
	-- 1 Steinweg: Ring aus Kopfsteinpflaster um den Kristall
	function(_, plot)
		Terrain:FillCylinder(CFrame.new(plot.center + Vector3.new(0, -1, 0)), 2, 16.5, Enum.Material.Cobblestone)
		Terrain:FillCylinder(CFrame.new(plot.center + Vector3.new(0, -1, 0)), 2, 11.5, Enum.Material.Grass)
	end,

	-- 2 Laternen zwischen den Sockeln
	function(folder, plot)
		for k = 0, 7 do
			local a = (k + 0.5) / 8 * math.pi * 2
			local pos = plot.center + Vector3.new(math.cos(a) * 30, 0, math.sin(a) * 30)
			vCylinder(folder, 6, 0.6, CFrame.new(pos + Vector3.new(0, 3, 0)), Color3.fromRGB(40, 40, 50), Enum.Material.Metal)
			local lamp = ball(folder, 1.4, CFrame.new(pos + Vector3.new(0, 6.6, 0)), Color3.fromRGB(255, 220, 140), Enum.Material.Neon)
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 210, 130)
			light.Range = 14
			light.Brightness = 1.5
			light.Parent = lamp
		end
	end,

	-- 3 Blumenwiese
	function(folder, plot)
		local rng = Random.new(plot.index * 31)
		local colors = {
			Color3.fromRGB(255, 90, 120), Color3.fromRGB(255, 220, 80), Color3.fromRGB(180, 120, 255),
			Color3.fromRGB(255, 255, 255), Color3.fromRGB(90, 180, 255),
		}
		for _ = 1, 45 do
			local a = rng:NextNumber(0, math.pi * 2)
			local r = rng:NextNumber(26, 34)
			local pos = plot.center + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			vCylinder(folder, 1.2, 0.2, CFrame.new(pos + Vector3.new(0, 0.6, 0)), Color3.fromRGB(60, 140, 60)).CanCollide = false
			ball(folder, 0.8, CFrame.new(pos + Vector3.new(0, 1.3, 0)), colors[rng:NextInteger(1, #colors)]).CanCollide = false
		end
	end,

	-- 4 Wasserfälle: kleine Teiche am Rand, Wasser stürzt als Gischt in die Tiefe
	function(folder, plot)
		for k = 0, 3 do
			local a = k / 4 * math.pi * 2 + 0.4
			local dir = Vector3.new(math.cos(a), 0, math.sin(a))
			local pond = plot.center + dir * 38
			Terrain:FillCylinder(CFrame.new(pond + Vector3.new(0, -1, 0)), 2, 5, Enum.Material.Water)
			local edge = plot.center + dir * (ISLAND_SIZE / 2 + 1)
			local emitterPart = makePart(folder, {
				Size = Vector3.new(6, 0.2, 2),
				CFrame = CFrame.lookAt(edge, edge + dir),
				Transparency = 1,
				CanCollide = false,
				CanQuery = false,
			})
			local water = Instance.new("ParticleEmitter")
			water.Color = ColorSequence.new(Color3.fromRGB(170, 220, 255), Color3.fromRGB(230, 245, 255))
			water.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 5) })
			water.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
			water.Lifetime = NumberRange.new(2, 2.6)
			water.Rate = 70
			water.Speed = NumberRange.new(2, 4)
			water.Acceleration = Vector3.new(0, -25, 0)
			water.SpreadAngle = Vector2.new(10, 10)
			water.EmissionDirection = Enum.NormalId.Front
			water.LightEmission = 0.3
			water.Parent = emitterPart
		end
	end,

	-- 5 Kristalltürme
	function(folder, plot)
		for k = 0, 3 do
			local a = k / 4 * math.pi * 2 + math.pi / 4
			local pos = plot.center + Vector3.new(math.cos(a) * 33, 0, math.sin(a) * 33)
			for j, h in { 18, 11, 8 } do
				local offset = (j == 1) and Vector3.zero or Vector3.new(math.cos(a + j) * 2.5, 0, math.sin(a + j) * 2.5)
				makePart(folder, {
					Size = Vector3.new(3 - j * 0.5, h, 3 - j * 0.5),
					CFrame = CFrame.new(pos + offset + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, math.rad(45), (j - 1) * 0.2),
					Color = Color3.fromRGB(150, 230, 255),
					Material = Enum.Material.Glass,
					Transparency = 0.25,
				})
			end
		end
	end,

	-- 6 Schwebende Mini-Inseln
	function(folder, plot)
		for k = 0, 2 do
			local a = k / 3 * math.pi * 2
			local pos = plot.center + Vector3.new(math.cos(a) * 30, 26 + k * 4, math.sin(a) * 30)
			local model = spinModel(folder, "MiniIsland")
			vCylinder(model, 1.5, 9, CFrame.new(pos), GRASS, Enum.Material.Grass)
			vCylinder(model, 3, 6, CFrame.new(pos - Vector3.new(0, 2, 0)), ROCK, Enum.Material.Rock)
			makePart(model, {
				Size = Vector3.new(1.5, 4, 1.5),
				CFrame = CFrame.new(pos + Vector3.new(0, 2.7, 0)) * CFrame.Angles(0, math.rad(45), 0),
				Color = CRYSTAL_COLOR,
				Material = Enum.Material.Neon,
			})
			model.WorldPivot = CFrame.new(pos)
			CollectionService:AddTag(model, "GenModel")
		end
	end,

	-- 7 Sternenringe um den Kristall
	function(folder, plot)
		for r, height in { [12] = 16, [15] = 21 } do
			local model = spinModel(folder, "StarRing")
			local c = CFrame.new(plot.center + Vector3.new(0, height, 0))
			for k = 0, 23 do
				local a = k / 24 * math.pi * 2
				makePart(model, {
					Size = Vector3.new(0.6, 0.6, 3.4),
					CFrame = c * CFrame.Angles(0, a, 0) * CFrame.new(r, 0, 0),
					Color = Color3.fromRGB(255, 230, 120),
					Material = Enum.Material.Neon,
					CanCollide = false,
				})
			end
			model.WorldPivot = c
			CollectionService:AddTag(model, "GenModel")
		end
	end,

	-- 8 Regenbogen über der Insel
	function(folder, plot)
		local colors = {
			Color3.fromRGB(255, 70, 70), Color3.fromRGB(255, 160, 50), Color3.fromRGB(255, 235, 70),
			Color3.fromRGB(80, 220, 100), Color3.fromRGB(70, 150, 255), Color3.fromRGB(160, 90, 255),
		}
		local toCenter = (Vector3.zero - plot.center).Unit
		local side = Vector3.new(-toCenter.Z, 0, toCenter.X)
		local base = CFrame.fromMatrix(plot.center, side, Vector3.yAxis)
		for band, color in colors do
			local radius = 46 - band * 1.6
			for k = 0, 23 do
				local a = (k + 0.5) / 24 * math.pi
				makePart(folder, {
					Size = Vector3.new(1.6, radius * math.pi / 24 + 0.3, 1.2),
					CFrame = base * CFrame.new(math.cos(a) * radius, math.sin(a) * radius, 0) * CFrame.Angles(0, 0, a),
					Color = color,
					Material = Enum.Material.Neon,
					Transparency = 0.25,
					CanCollide = false,
				})
			end
		end
	end,

	-- 9 Kristallkrone über dem Kristall
	function(folder, plot)
		local model = spinModel(folder, "Crown")
		local c = CFrame.new(plot.center + Vector3.new(0, 26, 0))
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2
			makePart(model, {
				Size = Vector3.new(1.2, 4, 1.2),
				CFrame = c * CFrame.Angles(0, a, 0) * CFrame.new(5, 1.5, 0) * CFrame.Angles(0, math.rad(45), 0),
				Color = GOLD,
				Material = Enum.Material.Neon,
				CanCollide = false,
			})
			ball(model, 1.1, c * CFrame.Angles(0, a, 0) * CFrame.new(5, 4, 0), Color3.fromRGB(255, 80, 160), Enum.Material.Neon).CanCollide = false
		end
		vCylinder(model, 1, 11, c, GOLD, Enum.Material.Neon).CanCollide = false
		model.WorldPivot = c
		CollectionService:AddTag(model, "GenModel")
	end,
}

----------------------------------------------------------------------
-- Insel
----------------------------------------------------------------------

local function buildPlot(index, root)
	local angle = (index - 1) / Config.PLOT_COUNT * math.pi * 2
	local center = Vector3.new(math.cos(angle) * Config.PLOT_RADIUS, 0, math.sin(angle) * Config.PLOT_RADIUS)
	local centerCF = CFrame.new(center)
	local rng = Random.new(index * 7919)

	local folder = Instance.new("Folder")
	folder.Name = "Plot" .. index
	folder:SetAttribute("OwnerId", 0)
	folder.Parent = root

	-- Insel aus natürlichem Gelände
	terrainIsland(center, ISLAND_SIZE / 2, rng)

	-- Bäume am Rand (nicht auf dem Weg zur Brücke)
	local toHub = math.atan2(-center.Z, -center.X)
	for k = 1, 8 do
		local a = toHub + 0.5 + (k - 1) / 8 * (math.pi * 2 - 1)
		local r = rng:NextNumber(37, 42)
		terrainTree(folder, center + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r), rng)
	end
	-- ein paar Felsen
	for _ = 1, 4 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(30, 40)
		Terrain:FillBall(center + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r), rng:NextNumber(1.8, 3), Enum.Material.Rock)
	end

	-- Sockel und Kristall in der Mitte
	vCylinder(folder, 1.5, 16, centerCF * CFrame.new(0, 0.75, 0), STONE, Enum.Material.Slate)
	vCylinder(folder, 1, 12, centerCF * CFrame.new(0, 2, 0), DARK_STONE, Enum.Material.Slate)

	-- Der große Kristall (Modell aus mehreren Teilen, schwebt über dem Sockel)
	local crystal = Instance.new("Model")
	crystal.Name = "Crystal"
	local crystalCF = centerCF * CFrame.new(0, 11, 0)
	local core = crystalShape(crystal, crystalCF, 6, 9, CRYSTAL_COLOR, Enum.Material.Neon, 0.05)
	crystal.WorldPivot = crystalCF
	crystal.Parent = folder
	CollectionService:AddTag(crystal, "MainCrystal")
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 300
	click.Parent = crystal
	local light = Instance.new("PointLight")
	light.Color = CRYSTAL_COLOR
	light.Range = 26
	light.Brightness = 2
	light.Parent = core

	local burst = Instance.new("ParticleEmitter")
	burst.Name = "Burst"
	burst.Rate = 0
	burst.Color = ColorSequence.new(CRYSTAL_COLOR, Color3.new(1, 1, 1))
	burst.LightEmission = 1
	burst.Size = NumberSequence.new(0.8, 0)
	burst.Lifetime = NumberRange.new(0.5, 0.9)
	burst.Speed = NumberRange.new(14, 24)
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.Parent = core

	local ambient = Instance.new("ParticleEmitter")
	ambient.Name = "Ambient"
	ambient.Rate = 4
	ambient.Color = ColorSequence.new(CRYSTAL_COLOR)
	ambient.LightEmission = 1
	ambient.Size = NumberSequence.new(0.4, 0)
	ambient.Lifetime = NumberRange.new(2, 3)
	ambient.Speed = NumberRange.new(1, 3)
	ambient.SpreadAngle = Vector2.new(180, 180)
	ambient.Parent = core

	-- Kleine Begleitkristalle am Sockel
	for k = 0, 5 do
		local a = k * math.pi / 3
		local tilt = CFrame.Angles(math.sin(a) * 0.45, 0, -math.cos(a) * 0.45)
		local size = (k % 2 == 0) and 1 or 0.75
		crystalShape(folder, centerCF * CFrame.new(math.cos(a) * 5.2, 3.6 * size + 1.2, math.sin(a) * 5.2) * tilt,
			1.8 * size, 3.5 * size, CRYSTAL_COLOR, Enum.Material.Glass, 0.15)
	end

	local signAnchor = makePart(folder, {
		Name = "Sign",
		Size = Vector3.new(1, 1, 1),
		CFrame = centerCF * CFrame.new(0, 18, 0),
		Transparency = 1,
		CanCollide = false,
	})
	local sign = billboard(signAnchor, 14, 3.5, 4, 400)
	sign.Text = "🏝️ Freie Insel"
	sign.Parent.Enabled = false

	-- Sockel für die Helfer im Kreis um den Kristall
	local slots = {}
	for i, gen in Config.GENERATORS do
		local a = (i - 1) / #Config.GENERATORS * math.pi * 2
		local pos = center + Vector3.new(math.cos(a) * SLOT_RADIUS, 0, math.sin(a) * SLOT_RADIUS)
		local base = vCylinder(folder, 1, 9, CFrame.new(pos + Vector3.new(0, 0.5, 0)), DARK_STONE, Enum.Material.Slate)
		local ring = vCylinder(folder, 0.2, 9.6, CFrame.new(pos + Vector3.new(0, 0.1, 0)), STONE, Enum.Material.Neon)
		local top = CFrame.lookAt(pos + Vector3.new(0, 1, 0), center + Vector3.new(0, 1, 0))
		local labelAnchor = makePart(folder, {
			Size = Vector3.new(1, 1, 1),
			CFrame = top * CFrame.new(0, 9, 0),
			Transparency = 1,
			CanCollide = false,
		})
		local label = billboard(labelAnchor, 10, 3, 0, 90)
		local slotFolder = Instance.new("Folder")
		slotFolder.Name = gen.id
		slotFolder.Parent = folder
		slots[gen.id] = { base = base, ring = ring, top = top, label = label, folder = slotFolder, model = nil }
	end

	-- Spawnpunkt am Inselrand mit Blick zum Kristall
	local spawnPos = center + (Vector3.zero - center).Unit * 36 + Vector3.new(0, 4, 0)
	local spawnCF = CFrame.lookAt(spawnPos, center + Vector3.new(0, 4, 0))

	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = folder

	return {
		index = index,
		decor = decor,
		islandLevel = 0,
		rebirths = -1,
		crystalCF = crystalCF,
		core = core,
		folder = folder,
		center = center,
		spawnCF = spawnCF,
		crystal = crystal,
		sign = sign,
		slots = slots,
		owner = nil,
	}
end

----------------------------------------------------------------------
-- Öffentliche Funktionen
----------------------------------------------------------------------

function MapBuilder.build()
	-- Teile der Studio-Vorlage entfernen
	for _, child in workspace:GetChildren() do
		if child.Name == "Baseplate" or child:IsA("SpawnLocation") or child.Name == "Plots" then
			child:Destroy()
		end
	end

	-- Stimmungsvolles Licht
	Lighting.ClockTime = 16.8
	Lighting.Brightness = 2.2
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	local function ensure(className, props)
		local inst = Lighting:FindFirstChildOfClass(className) or Instance.new(className)
		for key, value in props do
			inst[key] = value
		end
		inst.Parent = Lighting
	end
	ensure("Atmosphere", { Density = 0.25, Offset = 0.2, Color = Color3.fromRGB(205, 225, 255), Decay = Color3.fromRGB(140, 160, 210), Glare = 0, Haze = 0.8 })
	ensure("BloomEffect", { Intensity = 0.25, Size = 16, Threshold = 2.6 })
	ensure("ColorCorrectionEffect", { Saturation = 0.15, Contrast = 0.05 })
	ensure("SunRaysEffect", { Intensity = 0.06, Spread = 0.6 })

	-- Kräftige, freundliche Gelände-Farben
	Terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(105, 200, 85))
	Terrain:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(70, 165, 70))
	Terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(130, 115, 105))
	Terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(120, 85, 60))
	Terrain:SetMaterialColor(Enum.Material.Cobblestone, Color3.fromRGB(170, 165, 155))
	Terrain:SetMaterialColor(Enum.Material.Pavement, Color3.fromRGB(185, 180, 170))

	local root = Instance.new("Folder")
	root.Name = "Plots"
	root.Parent = workspace

	for i = 1, Config.PLOT_COUNT do
		local plot = buildPlot(i, root)
		MapBuilder.plots[i] = plot
		MapBuilder.updatePlot(plot, nil)
	end

	-- Echte Roblox-Wolken
	local clouds = Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover = 0.6
	clouds.Density = 0.55
	clouds.Color = Color3.fromRGB(255, 250, 245)
	clouds.Parent = Terrain
end

function MapBuilder.claimPlot(player)
	for _, plot in MapBuilder.plots do
		if not plot.owner then
			plot.owner = player
			plot.folder:SetAttribute("OwnerId", player.UserId)
			plot.sign.Text = "🏝️ " .. player.DisplayName
			plot.sign.Parent.Enabled = true
			return plot
		end
	end
	return nil
end

function MapBuilder.releasePlot(plot)
	plot.owner = nil
	plot.folder:SetAttribute("OwnerId", 0)
	plot.sign.Text = "🏝️ Freie Insel"
	plot.sign.Parent.Enabled = false -- freie Inseln ohne Schild
	MapBuilder.updatePlot(plot, nil)
end

-- Zeigt die gekauften Helfer als Modelle auf den Sockeln an
function MapBuilder.updatePlot(plot, data)
	for i, gen in Config.GENERATORS do
		local slot = plot.slots[gen.id]
		local owned = data and data.gens[gen.id] or 0
		if owned > 0 then
			if not slot.model then
				slot.model = buildGeneratorModel(slot, gen)
				slot.ring.Color = GOLD
				slot.scale = 1
				slot.baseScale = slot.model:GetScale()
			end
			-- Jeder Meilenstein lässt das Modell wachsen
			local scale = 1 + 0.12 * Config.milestonesReached(owned)
			if slot.scale ~= scale then
				slot.model:ScaleTo(slot.baseScale * scale)
				slot.scale = scale
			end
			slot.label.Text = gen.icon .. " " .. gen.name .. "\nx" .. owned
			slot.label.TextColor3 = Color3.new(1, 1, 1)
			slot.label.Parent.Enabled = true
		else
			if slot.model then
				slot.model:Destroy()
				slot.model = nil
			end
			slot.ring.Color = STONE
			local previousOwned = (i == 1) or (data and (data.gens[Config.GENERATORS[i - 1].id] or 0) > 0)
			slot.label.Text = "🔒 " .. gen.name
			slot.label.TextColor3 = Color3.fromRGB(190, 190, 200)
			slot.label.Parent.Enabled = previousOwned and true or false
		end
	end

	-- Ausbaustufen der Insel
	local level = data and Config.islandLevel(data.allTime) or 0
	if level < plot.islandLevel then
		plot.decor:ClearAllChildren()
		Terrain:FillCylinder(CFrame.new(plot.center + Vector3.new(0, -1, 0)), 2, 16.5, Enum.Material.Grass)
		plot.islandLevel = 0
	end
	for i = plot.islandLevel + 1, level do
		local stage = Instance.new("Folder")
		stage.Name = "Level" .. i
		DECOR_BUILDERS[i](stage, plot)
		stage.Parent = plot.decor
	end
	plot.islandLevel = level

	-- Der Kristall wächst mit der Insel, ändert bei Wiedergeburt die Farbe und zeigt den Skin
	local rebirths = data and data.rebirths or 0
	local skinId = data and data.skin or "Default"
	if plot.rebirths ~= rebirths or plot.crystalLevel ~= level or plot.skin ~= skinId then
		plot.rebirths = rebirths
		plot.crystalLevel = level
		plot.skin = skinId
		local skin = Config.SKINS_BY_ID[skinId] or Config.SKINS_BY_ID.Default
		local color = skin.color or Config.rebirthColor(rebirths)
		local material = skin.material == "Glass" and Enum.Material.Glass or Enum.Material.Neon
		local crystal = plot.crystal
		local scale = 1 + 0.07 * level
		crystal:PivotTo(plot.crystalCF)
		crystal:ScaleTo(scale)
		crystal:SetAttribute("BaseScale", scale)
		crystal:SetAttribute("BaseCFrame", plot.crystalCF * CFrame.new(0, 8.4 * (scale - 1), 0))
		crystal:SetAttribute("Rainbow", skin.effect == "rainbow")
		crystal:PivotTo(plot.crystalCF * CFrame.new(0, 8.4 * (scale - 1), 0))
		for _, part in crystal:GetDescendants() do
			if part:IsA("BasePart") then
				part.Color = color
				part.Material = material
				part.Transparency = (material == Enum.Material.Glass) and 0.25 or 0.05
			end
		end
		local core = plot.core
		core.PointLight.Color = color
		core.Burst.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
		core.Ambient.Color = ColorSequence.new(color)

		-- Spezialeffekte der Skins
		for _, name in { "SkinFire", "SkinSparkles" } do
			local old = core:FindFirstChild(name)
			if old then
				old:Destroy()
			end
		end
		if skin.effect == "fire" then
			local fire = Instance.new("Fire")
			fire.Name = "SkinFire"
			fire.Size = 10
			fire.Heat = 12
			fire.Color = Color3.fromRGB(255, 140, 40)
			fire.SecondaryColor = Color3.fromRGB(255, 60, 20)
			fire.Parent = core
		elseif skin.effect == "sparkles" or skin.effect == "rainbow" then
			local sparkles = Instance.new("Sparkles")
			sparkles.Name = "SkinSparkles"
			sparkles.SparkleColor = skin.effect == "rainbow" and Color3.new(1, 1, 1) or color
			sparkles.Parent = core
		end
	end
end

-- Goldener Kristall an einer zufälligen Stelle der Insel
function MapBuilder.spawnGolden(plot)
	local a = math.random() * math.pi * 2
	local r = 8 + math.random() * 26
	local pos = plot.center + Vector3.new(math.cos(a) * r, 3.5, math.sin(a) * r)
	local golden = Instance.new("Model")
	golden.Name = "GoldenCrystal"
	local core = crystalShape(golden, CFrame.new(pos), 2, 2.6, GOLD, Enum.Material.Neon, 0)
	for _, part in golden:GetChildren() do
		part.CanCollide = false
	end
	golden.WorldPivot = CFrame.new(pos)
	golden.Parent = plot.folder
	local light = Instance.new("PointLight")
	light.Color = GOLD
	light.Range = 16
	light.Brightness = 3
	light.Parent = core
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = GOLD
	sparkles.Parent = core
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 300
	click.Parent = golden
	CollectionService:AddTag(golden, "Golden")
	return golden, click, core
end

-- Bau-Helfer auch für andere Module (Hub-Insel)
MapBuilder.helpers = {
	makePart = makePart,
	vCylinder = vCylinder,
	ball = ball,
	billboard = billboard,
	crystalShape = crystalShape,
	terrainIsland = terrainIsland,
	terrainTree = terrainTree,
	customModel = customModel,
}

return MapBuilder
