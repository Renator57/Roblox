-- Hub-Insel in der Mitte: Brücken zu allen Inseln, Eier, Casino, Glücksrad,
-- tägliche Belohnung, Likes und der Kristallgolem.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Hub = {}

local DARK = Color3.fromRGB(70, 70, 85)
local WOOD = Color3.fromRGB(150, 105, 65)
local GOLD = Color3.fromRGB(255, 205, 60)
local CYAN = Color3.fromRGB(90, 200, 255)

local HUB_SPAWN = CFrame.lookAt(Vector3.new(0, 4, 26), Vector3.new(0, 4, 0))

function Hub.init(ctx)
	local h = ctx.MapBuilder.helpers
	local makePart, vCylinder, ball, billboard, crystalShape = h.makePart, h.vCylinder, h.ball, h.billboard, h.crystalShape

	local root = Instance.new("Folder")
	root.Name = "Hub"
	root.Parent = workspace

	local R = Config.HUB_RADIUS

	------------------------------------------------------------------
	-- Insel
	------------------------------------------------------------------
	-- Natürliches Gelände mit gepflastertem Platz in der Mitte
	local terrain = workspace.Terrain
	local rng = Random.new(2024)
	h.terrainIsland(Vector3.zero, R, rng)
	terrain:FillCylinder(CFrame.new(0, -1, 0), 2, R - 10, Enum.Material.Pavement)
	-- Bäume nur dort, wo keine Brücke und keine Station ist
	for _, deg in { 67.5, 157.5, 247.5, 337.5 } do
		local a = math.rad(deg)
		h.terrainTree(root, Vector3.new(math.cos(a) * (R - 6), 0, math.sin(a) * (R - 6)), rng)
	end
	vCylinder(root, 0.2, 30, CFrame.new(0, 0.1, 0), CYAN, Enum.Material.Neon)
	vCylinder(root, 0.25, 28, CFrame.new(0, 0.15, 0), DARK, Enum.Material.Slate)

	local signAnchor = makePart(root, { Size = Vector3.one, CFrame = CFrame.new(0, 30, 0), Transparency = 1, CanCollide = false })
	billboard(signAnchor, 30, 7, 0, 600).Text = "🌐 HUB-INSEL"

	------------------------------------------------------------------
	-- Brücken zu allen Spieler-Inseln
	------------------------------------------------------------------
	local islandRadius = ctx.MapBuilder.ISLAND_SIZE / 2
	for _, plot in ctx.MapBuilder.plots do
		local dir = Vector3.new(plot.center.X, 0, plot.center.Z).Unit
		local a = dir * (R - 2)
		local b = plot.center - dir * (islandRadius - 2)
		local length = (b - a).Magnitude
		local mid = (a + b) / 2
		local cf = CFrame.lookAt(mid, b)
		makePart(root, {
			Name = "Bridge",
			Size = Vector3.new(7, 0.6, length),
			CFrame = cf * CFrame.new(0, -0.3, 0),
			Color = WOOD,
			Material = Enum.Material.WoodPlanks,
		})
		for _, x in { -3.4, 3.4 } do
			makePart(root, {
				Size = Vector3.new(0.4, 0.4, length),
				CFrame = cf * CFrame.new(x, 1.3, 0),
				Color = CYAN,
				Material = Enum.Material.Neon,
			})
		end
		-- Schild am Brückenanfang mit dem Namen des Besitzers
		local signPart = makePart(root, { Size = Vector3.one, CFrame = CFrame.new(a + dir * 3 + Vector3.new(0, 6, 0)), Transparency = 1, CanCollide = false })
		local label = billboard(signPart, 7, 1.6, 0, 120)
		local function refresh()
			local owner = plot.owner
			label.Text = owner and ("🏝️ " .. owner.DisplayName) or "🏝️ Freie Insel"
		end
		refresh()
		plot.folder:GetAttributeChangedSignal("OwnerId"):Connect(refresh)
	end

	------------------------------------------------------------------
	-- Stationen (öffnen Fenster auf dem Bildschirm)
	------------------------------------------------------------------
	local function prompt(parent, actionText, objectText, openUI, extra)
		local p = Instance.new("ProximityPrompt")
		p.ActionText = actionText
		p.ObjectText = objectText
		p.HoldDuration = 0
		p.MaxActivationDistance = 12
		p.RequiresLineOfSight = false
		p:SetAttribute("OpenUI", openUI)
		if extra then
			p:SetAttribute("Extra", extra)
		end
		p.Parent = parent
		return p
	end

	local function stationCF(angleDeg, radius)
		local a = math.rad(angleDeg)
		local pos = Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius)
		return CFrame.lookAt(pos, Vector3.new(0, 0, 0))
	end

	-- Eier
	do
		local base = stationCF(22.5, 30)
		for i, egg in Config.EGGS do
			local cf = base * CFrame.new((i - 2) * 6, 0, 0)
			vCylinder(root, 1.5, 4.5, cf * CFrame.new(0, 0.75, 0), DARK, Enum.Material.Slate)
			local eggPart = makePart(root, {
				Name = "Egg",
				Size = Vector3.new(3, 4, 3),
				CFrame = cf * CFrame.new(0, 3.6, 0),
				Color = egg.color,
				Material = Enum.Material.SmoothPlastic,
			})
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = eggPart
			local light = Instance.new("PointLight")
			light.Color = egg.color
			light.Range = 10
			light.Parent = eggPart
			local label = billboard(eggPart, 7, 2.4, 3.4, 80)
			label.Text = egg.icon .. " " .. egg.name .. "\n💎 " .. Config.format(egg.cost)
			prompt(eggPart, "Ei öffnen", egg.name, "pets", egg.id)
		end
	end

	-- Glücksautomat (Casino)
	do
		local cf = stationCF(112.5, 30)
		makePart(root, { Size = Vector3.new(5, 7, 3.5), CFrame = cf * CFrame.new(0, 3.5, 0), Color = Color3.fromRGB(200, 40, 60), Material = Enum.Material.Metal })
		makePart(root, { Size = Vector3.new(5.6, 1, 4), CFrame = cf * CFrame.new(0, 7.5, 0), Color = GOLD, Material = Enum.Material.Neon })
		local screen = makePart(root, { Size = Vector3.new(4, 2.2, 0.2), CFrame = cf * CFrame.new(0, 4.8, -1.8), Color = Color3.fromRGB(20, 20, 30) })
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.CanvasSize = Vector2.new(300, 160)
		gui.Parent = screen
		local reel = Instance.new("TextLabel")
		reel.Size = UDim2.fromScale(1, 1)
		reel.BackgroundTransparency = 1
		reel.TextScaled = true
		reel.Text = "💎⭐🍀"
		reel.Parent = gui
		vCylinder(root, 3, 0.4, cf * CFrame.new(3, 5, 0), Color3.fromRGB(200, 200, 210), Enum.Material.Metal)
		ball(root, 1, cf * CFrame.new(3, 6.8, 0), Color3.fromRGB(255, 50, 50), Enum.Material.Neon)
		local label = billboard(screen, 10, 2.4, 5, 80)
		label.Text = "🎰 Glücksautomat"
		prompt(screen, "Spielen", "Glücksautomat", "casino")
	end

	-- Glücksrad
	do
		local cf = stationCF(202.5, 30)
		local wheelCF = cf * CFrame.new(0, 7, 0) * CFrame.Angles(0, math.rad(90), 0)
		makePart(root, {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.8, 11, 11),
			CFrame = wheelCF,
			Color = Color3.fromRGB(40, 40, 60),
			Material = Enum.Material.Metal,
		})
		for k, segment in Config.WHEEL do
			makePart(root, {
				Size = Vector3.new(0.1, 4.6, 3.4),
				CFrame = wheelCF * CFrame.Angles((k - 1) / #Config.WHEEL * math.pi * 2, 0, 0) * CFrame.new(0.45, 2.7, 0),
				Color = segment.color,
				Material = Enum.Material.Neon,
			})
		end
		ball(root, 1.6, wheelCF * CFrame.new(0.6, 0, 0), GOLD, Enum.Material.Neon)
		for _, x in { -2.5, 2.5 } do
			makePart(root, { Size = Vector3.new(0.8, 7, 0.8), CFrame = cf * CFrame.new(x, 3.5, 0.8), Color = DARK, Material = Enum.Material.Metal })
		end
		local pointer = makePart(root, { Size = Vector3.new(1, 1.4, 1), CFrame = cf * CFrame.new(0, 13, -0.5), Color = Color3.fromRGB(255, 60, 60), Material = Enum.Material.Neon })
		local label = billboard(pointer, 10, 2.4, 3, 80)
		label.Text = "🎡 Glücksrad"
		prompt(pointer, "Drehen", "Glücksrad", "wheel").MaxActivationDistance = 16
	end

	-- Tägliche Belohnung (Geschenk)
	do
		local cf = stationCF(292.5, 30)
		local box = makePart(root, { Size = Vector3.new(4.5, 4.5, 4.5), CFrame = cf * CFrame.new(0, 2.25, 0), Color = Color3.fromRGB(170, 90, 255) })
		makePart(root, { Size = Vector3.new(4.7, 4.7, 1), CFrame = cf * CFrame.new(0, 2.25, 0), Color = GOLD, Material = Enum.Material.Neon })
		makePart(root, { Size = Vector3.new(1, 4.7, 4.7), CFrame = cf * CFrame.new(0, 2.25, 0), Color = GOLD, Material = Enum.Material.Neon })
		ball(root, 1.6, cf * CFrame.new(0, 5, 0), GOLD, Enum.Material.Neon)
		local label = billboard(box, 10, 2.4, 5, 80)
		label.Text = "🎁 Tägliche Belohnung"
		prompt(box, "Abholen", "Tägliche Belohnung", "daily")
	end

	------------------------------------------------------------------
	-- Teleport zwischen Hub und eigener Insel
	------------------------------------------------------------------
	local teleport = ctx.remote("RemoteEvent", "Teleport")
	teleport.OnServerEvent:Connect(function(player, where)
		local session = ctx.sessions[player]
		local character = player.Character
		if not (session and character) then
			return
		end
		if where == "hub" then
			character:PivotTo(HUB_SPAWN)
		elseif where == "home" then
			character:PivotTo(session.plot.spawnCF)
		end
	end)

	------------------------------------------------------------------
	-- Likes: Herz auf jeder Insel
	------------------------------------------------------------------
	local lastLike = {}
	for _, plot in ctx.MapBuilder.plots do
		local pos = plot.spawnCF * CFrame.new(7, -1.5, 0)
		local heart = ball(plot.folder, 2.6, CFrame.new(pos.Position), Color3.fromRGB(255, 60, 100), Enum.Material.Neon)
		heart.Name = "LikeHeart"
		vCylinder(plot.folder, 1, 3, CFrame.new(pos.Position - Vector3.new(0, 1.8, 0)), DARK, Enum.Material.Slate)
		local likePrompt = prompt(heart, "Insel liken ❤️", "Like", "none")
		likePrompt.Triggered:Connect(function(player)
			local owner = plot.owner
			if not owner then
				ctx.notify(player, "Diese Insel ist noch frei.", "info")
				return
			end
			if owner == player then
				ctx.notify(player, "Das ist deine eigene Insel! Lass sie von anderen liken ❤️", "info")
				return
			end
			local key = player.UserId .. ":" .. owner.UserId
			if lastLike[key] and os.clock() - lastLike[key] < Config.LIKE_COOLDOWN then
				local wait = math.ceil((Config.LIKE_COOLDOWN - (os.clock() - lastLike[key])) / 60)
				ctx.notify(player, "Du kannst diese Insel in " .. wait .. " Min wieder liken.", "error")
				return
			end
			local ownerSession = ctx.sessions[owner]
			local likerSession = ctx.sessions[player]
			if not (ownerSession and likerSession) then
				return
			end
			lastLike[key] = os.clock()

			ownerSession.data.likes += 1
			ownerSession.likeEnd = ctx.now() + Config.LIKE_BOOST_DURATION
			ctx.PlayerData.updateLeaderstats(owner)
			ctx.notify(owner, "❤️ " .. player.DisplayName .. " hat deine Insel geliked! +25 % Produktion für 5 Min", "build")

			local thanks = math.max(100, Config.perSecond(likerSession.data) * 60)
			ctx.earn(likerSession, thanks)
			ctx.notify(player, "❤️ Danke fürs Liken! Du bekommst +" .. Config.format(thanks) .. " 💎", "gold")
			ctx.sendState(owner)
			ctx.sendState(player)
		end)
	end

	------------------------------------------------------------------
	-- Kristallgolem (Gemeinschafts-Boss)
	------------------------------------------------------------------
	local golem = nil

	local function buildGolem()
		local custom = h.customModel("Golem", 18, CFrame.new(0, 0.5, 0))
		local model = custom or Instance.new("Model")
		model.Name = "KristallGolem"
		local head
		if custom then
			-- Unsichtbarer Punkt über dem Modell für die Lebensleiste
			local boxCF, size = custom:GetBoundingBox()
			head = makePart(custom, { Name = "Head", Size = Vector3.one, CFrame = boxCF * CFrame.new(0, size.Y / 2, 0), Transparency = 1, CanCollide = false })
		else
			local rock = Color3.fromRGB(95, 90, 110)
			local base = CFrame.new(0, 0.5, 0)
			for _, x in { -2.5, 2.5 } do
				makePart(model, { Size = Vector3.new(3, 6, 3), CFrame = base * CFrame.new(x, 3, 0), Color = rock, Material = Enum.Material.Slate })
			end
			makePart(model, { Size = Vector3.new(9, 8, 5), CFrame = base * CFrame.new(0, 10, 0), Color = rock, Material = Enum.Material.Slate })
			ball(model, 2.6, base * CFrame.new(0, 10.5, 2.4), CYAN, Enum.Material.Neon)
			head = makePart(model, { Name = "Head", Size = Vector3.new(5, 4, 4.5), CFrame = base * CFrame.new(0, 16, 0), Color = rock, Material = Enum.Material.Slate })
			for _, x in { -1.1, 1.1 } do
				makePart(model, { Size = Vector3.new(0.9, 0.6, 0.2), CFrame = base * CFrame.new(x, 16.5, 2.3), Color = Color3.fromRGB(255, 60, 60), Material = Enum.Material.Neon })
			end
			for _, x in { -6, 6 } do
				makePart(model, { Size = Vector3.new(2.6, 9, 2.6), CFrame = base * CFrame.new(x, 9.5, 0), Color = rock, Material = Enum.Material.Slate })
				crystalShape(model, base * CFrame.new(x, 15.5, 0) * CFrame.Angles(0, 0, x > 0 and -0.4 or 0.4), 1.6, 3, CYAN, Enum.Material.Neon, 0)
			end
			model.WorldPivot = base
		end
		local click = Instance.new("ClickDetector")
		click.MaxActivationDistance = 120
		click.Parent = model

		-- Lebensleiste
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.new(16, 0, 2.4, 0)
		gui.StudsOffset = Vector3.new(0, 5, 0)
		gui.AlwaysOnTop = true
		gui.MaxDistance = 250
		local back = Instance.new("Frame")
		back.Size = UDim2.fromScale(1, 1)
		back.BackgroundColor3 = Color3.fromRGB(30, 10, 15)
		back.Parent = gui
		Instance.new("UICorner").Parent = back
		local fill = Instance.new("Frame")
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
		fill.BorderSizePixel = 0
		fill.Parent = back
		Instance.new("UICorner").Parent = fill
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.TextScaled = true
		text.Font = Enum.Font.FredokaOne
		text.TextColor3 = Color3.new(1, 1, 1)
		text.TextStrokeTransparency = 0.3
		text.ZIndex = 2
		text.Parent = back
		gui.Parent = head
		return model, click, fill, text
	end

	local function endGolem(defeated)
		local g = golem
		if not g then
			return
		end
		golem = nil
		local pos = g.model:GetPivot().Position + Vector3.new(0, 8, 0)
		g.model:Destroy()

		if not defeated then
			ctx.notifyAll("💨 Der Kristallgolem ist entkommen! Beim nächsten Mal schneller sein.", "info")
			return
		end

		local boom = Instance.new("Explosion")
		boom.Position = pos
		boom.BlastPressure = 0
		boom.DestroyJointRadiusPercent = 0
		boom.BlastRadius = 12
		boom.Parent = workspace

		local total, participants, mvp, mvpDamage = 0, 0, nil, 0
		for player, damage in g.damage do
			total += damage
			participants += 1
			if damage > mvpDamage then
				mvp, mvpDamage = player, damage
			end
		end
		for player, damage in g.damage do
			local session = ctx.sessions[player]
			if session then
				local data = session.data
				local share = damage / math.max(total, 1)
				local reward = math.max(Config.perSecond(data) * Config.GOLEM_REWARD_SECONDS, Config.clickValue(data) * 300, 200) * (0.5 + share)
				ctx.earn(session, reward)
				data.golemKills += 1
				local message = "⚔️ Golem besiegt! Deine Beute: +" .. Config.format(reward) .. " 💎"
				if player == mvp and participants >= 2 then
					data.stardust += 1
					message ..= " und +1 ✨ (MVP!)"
				end
				ctx.notify(player, message, "gold")
				ctx.sendState(player)
			end
		end
		if mvp then
			ctx.notifyAll("🏆 Der Kristallgolem wurde besiegt! MVP: " .. mvp.DisplayName, "frenzy")
		end
	end

	local function spawnGolem()
		local totalClick = 0
		for _, session in ctx.sessions do
			totalClick += Config.clickValue(session.data)
		end
		local maxHp = math.max(100, totalClick * Config.GOLEM_HP_CLICKS * 0.6)
		local model, click, fill, text = buildGolem()
		golem = { model = model, hp = maxHp, maxHp = maxHp, damage = {} }
		local g = golem

		local function updateBar()
			fill.Size = UDim2.fromScale(math.clamp(g.hp / g.maxHp, 0, 1), 1)
			text.Text = "⚔️ " .. Config.format(math.max(g.hp, 0)) .. " / " .. Config.format(g.maxHp)
			model:SetAttribute("HP", g.hp)
		end
		model:SetAttribute("MaxHP", maxHp)
		model:SetAttribute("EndsAt", ctx.now() + Config.GOLEM_DURATION)
		updateBar()
		model.Parent = root
		CollectionService:AddTag(model, "Golem")

		click.MouseClick:Connect(function(player)
			local session = ctx.sessions[player]
			if golem ~= g or not session or session.tokens < 1 then
				return
			end
			session.tokens -= 1
			local damage = Config.clickValue(session.data) * ctx.boost(session)
			g.hp -= damage
			g.damage[player] = (g.damage[player] or 0) + damage
			updateBar()
			if g.hp <= 0 then
				endGolem(true)
			end
		end)

		ctx.notifyAll("⚠️ Ein KRISTALLGOLEM greift die Hub-Insel an! Besiegt ihn gemeinsam!", "frenzy")
		task.delay(Config.GOLEM_DURATION, function()
			if golem == g then
				endGolem(false)
			end
		end)
	end

	task.spawn(function()
		while true do
			task.wait(Config.GOLEM_INTERVAL)
			if not golem and next(ctx.sessions) then
				spawnGolem()
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		if golem then
			golem.damage[player] = nil
		end
	end)
end

return Hub
