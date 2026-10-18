-- Original primitive-built observatory. No imported meshes or proprietary assets.
local Workshop = {}
function Workshop.build()
	if workspace:FindFirstChild("CloudpopWorkshop") then return end
	local model = Instance.new("Model")
	model.Name, model.Parent = "CloudpopWorkshop", workspace
	local navy, blue, ice, cyan = Color3.fromRGB(16, 30, 58), Color3.fromRGB(37, 76, 121), Color3.fromRGB(211, 232, 248), Color3.fromRGB(91, 214, 232)
	local function part(name, size, position, color, material, class)
		local item = Instance.new(class or "Part")
		item.Name, item.Size, item.Position = name, size, position
		item.Anchored, item.Color = true, color
		item.Material = material or Enum.Material.SmoothPlastic
		item.TopSurface, item.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		item.Parent = model
		return item
	end
	local function sign(parent, name, text, size)
		local surface = Instance.new("SurfaceGui")
		surface.Name, surface.Face, surface.CanvasSize = name, Enum.NormalId.Back, Vector2.new(1000, 350)
		surface.Parent = parent
		local label = Instance.new("TextLabel")
		label.Name, label.Size = "Text", UDim2.fromScale(1, 1)
		label.BackgroundTransparency, label.TextColor3 = 1, ice
		label.Font, label.TextSize, label.TextWrapped = Enum.Font.GothamBold, size or 64, true
		label.Text, label.Parent = text, surface
		return label
	end
	part("Foundation", Vector3.new(100, 5, 86), Vector3.new(0, -3, 0), navy, Enum.Material.Slate)
	part("AtriumFloor", Vector3.new(94, 1, 80), Vector3.new(0, 0, 0), blue, Enum.Material.Marble)
	part("CentralWalkway", Vector3.new(16, 0.06, 70), Vector3.new(0, 0.54, 0), ice)
	for _, x in ipairs({ -8.1, 8.1 }) do
		part("PathLight", Vector3.new(0.16, 0.08, 68), Vector3.new(x, 0.56, 0), cyan, Enum.Material.Neon)
	end
	for _, x in ipairs({ -46, 46 }) do
		part("SideWall", Vector3.new(1, 5, 80), Vector3.new(x, 2.5, 0), navy)
		part("Rail", Vector3.new(1.4, 0.3, 80), Vector3.new(x, 5.2, 0), cyan, Enum.Material.Metal)
		for _, z in ipairs({ -34, -10, 14, 34 }) do
			part("Pillar", Vector3.new(2, 24, 2), Vector3.new(x, 12, z), navy, Enum.Material.Metal)
			part("PillarInlay", Vector3.new(0.1, 13, 0.4), Vector3.new(x - math.sign(x) * 1.05, 11, z), cyan, Enum.Material.Neon)
		end
	end
	for _, z in ipairs({ -39, 39 }) do
		part("EndRail", Vector3.new(92, 4, 1), Vector3.new(0, 2, z), navy)
		part("Crossbeam", Vector3.new(96, 1, 2), Vector3.new(0, 24, z), blue, Enum.Material.Metal)
	end
	-- Open center preserves sky and camera clearance; side louvers frame the room.
	for _, x in ipairs({ -33, 33 }) do
		for z = -32, 32, 8 do
			part("CanopyLouver", Vector3.new(24, 0.5, 2), Vector3.new(x, 24, z), ice)
		end
	end
	local machine = part("MachinePedestal", Vector3.new(14, 3, 10), Vector3.new(0, 2, -20), navy, Enum.Material.Metal)
	sign(machine, "Nameplate", "CLOUDPOP  /  COMMONS", 52)
	part("MachineTrim", Vector3.new(14.2, 0.25, 10.2), Vector3.new(0, 3.6, -20), cyan, Enum.Material.Neon)
	local globe = part("AirChamber", Vector3.new(10, 10, 10), Vector3.new(0, 9, -20), ice, Enum.Material.Glass)
	globe.Shape, globe.Transparency, globe.CanCollide = Enum.PartType.Ball, 0.72, false
	for index = 1, 16 do
		local angle = index * math.pi / 8
		local ball = part("DecorativeBall" .. index, Vector3.new(1.1, 1.1, 1.1), Vector3.new(math.cos(angle) * 3, 7 + index % 4, -20 + math.sin(angle) * 3), if index % 3 == 0 then ice else cyan)
		ball.Shape, ball.CanCollide, ball.CastShadow = Enum.PartType.Ball, false, false
	end
	local display = part("DrawDisplay", Vector3.new(25, 7, 0.5), Vector3.new(0, 16, -28), navy)
	sign(display, "Readout", "WELCOME\n0 / 20", 90)
	local emerged = part("DrawnBall", Vector3.new(2.6, 2.6, 2.6), Vector3.new(0, 6, -13), ice)
	emerged.Shape, emerged.CanCollide = Enum.PartType.Ball, false
	local tag = Instance.new("BillboardGui")
	tag.Name, tag.Size, tag.AlwaysOnTop, tag.MaxDistance = "BallNumber", UDim2.fromOffset(64, 64), false, 100
	tag.Parent = emerged
	local text = Instance.new("TextLabel")
	text.Name, text.Size, text.BackgroundTransparency = "Text", UDim2.fromScale(1, 1), 1
	text.Font, text.TextSize, text.TextColor3, text.Text = Enum.Font.GothamBold, 36, navy, "—"
	text.Parent = tag
	for _, x in ipairs({ -27, 27 }) do
		for _, z in ipairs({ -9, 17 }) do
			part("TableBase", Vector3.new(2, 3, 2), Vector3.new(x, 2, z), navy, Enum.Material.Metal)
			part("TableTop", Vector3.new(10, 0.45, 7), Vector3.new(x, 3.7, z), ice)
			for _, offset in ipairs({ -5.2, 5.2 }) do
				local seat = part("LoungeSeat", Vector3.new(3.4, 0.8, 3.4), Vector3.new(x, 2, z + offset), blue, Enum.Material.Fabric, "Seat")
				seat.Orientation = Vector3.new(0, if offset < 0 then 180 else 0, 0)
				part("SeatBack", Vector3.new(3.4, 2.4, 0.6), Vector3.new(x, 3.1, z + offset + math.sign(offset) * 1.6), navy, Enum.Material.Fabric)
				part("SeatFoot", Vector3.new(2, 1, 2), Vector3.new(x, 1, z + offset), navy, Enum.Material.Metal)
			end
		end
	end
	for _, x in ipairs({ -39, 39 }) do
		for _, z in ipairs({ -28, 28 }) do
			part("Planter", Vector3.new(4, 2, 4), Vector3.new(x, 1.5, z), navy)
			for index = 1, 3 do
				local leaf = part("CrystalFern", Vector3.new(0.5, 3 + index, 1.8), Vector3.new(x + index - 2, 4, z), cyan)
				leaf.Orientation, leaf.CanCollide = Vector3.new(0, index * 50, (index - 2) * 22), false
			end
		end
	end
	local spawn = part("WelcomeMat", Vector3.new(10, 0.1, 6), Vector3.new(0, 0.65, 29), blue, nil, "SpawnLocation")
	spawn.Neutral, spawn.Duration, spawn.Transparency = true, 0, 1
	local lighting = game:GetService("Lighting")
	lighting.ClockTime, lighting.Brightness = 16, 2
	lighting.Ambient, lighting.OutdoorAmbient = Color3.fromRGB(96, 124, 163), Color3.fromRGB(152, 175, 203)
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name, atmosphere.Density, atmosphere.Haze = "CloudpopAir", 0.22, 1.3
	atmosphere.Color, atmosphere.Parent = ice, lighting
	-- FallenPartsDestroyHeight is a Studio-only property; configured in the Rojo project.
end
return Workshop
