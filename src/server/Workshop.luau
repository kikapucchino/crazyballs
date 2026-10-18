-- A small original lobby made entirely from Roblox primitives; no external assets.
local Workshop = {}

function Workshop.build()
	if workspace:FindFirstChild("CloudpopWorkshop") then
		return
	end
	local model = Instance.new("Model")
	model.Name = "CloudpopWorkshop"
	model.Parent = workspace
	local function part(name, size, position, color, shape)
		local object = Instance.new("Part")
		object.Name = name
		object.Anchored = true
		object.Size = size
		object.Position = position
		object.Color = Color3.fromRGB(table.unpack(color))
		object.Material = Enum.Material.SmoothPlastic
		object.TopSurface = Enum.SurfaceType.Smooth
		object.BottomSurface = Enum.SurfaceType.Smooth
		if shape then object.Shape = shape end
		object.Parent = model
		return object
	end
	part("FloatingGarden", Vector3.new(90, 5, 70), Vector3.new(0, -3, 0), { 133, 193, 163 })
	part("WorkshopFloor", Vector3.new(62, 1, 44), Vector3.new(0, 0, 0), { 242, 223, 187 })
	for _, x in ipairs({ -29, 29 }) do
		for _, z in ipairs({ -20, 20 }) do
			part("Column", Vector3.new(2, 16, 2), Vector3.new(x, 8, z), { 79, 133, 132 })
		end
	end
	part("Canopy", Vector3.new(65, 2, 47), Vector3.new(0, 17, 0), { 243, 174, 131 })
	part("MachinePedestal", Vector3.new(12, 4, 10), Vector3.new(0, 2.5, -10), { 42, 112, 116 })
	local globe = part("AirChamber", Vector3.new(9, 9, 9), Vector3.new(0, 9, -10), { 177, 233, 227 }, Enum.PartType.Ball)
	globe.Transparency = 0.65
	globe.CanCollide = false
	for index = 1, 12 do
		local angle = index * math.pi / 6
		part("DecorativeBall", Vector3.new(1.4, 1.4, 1.4), Vector3.new(math.cos(angle) * 2.7, 7 + index % 4, -10 + math.sin(angle) * 2.7),
			if index % 2 == 0 then { 255, 199, 88 } else { 236, 128, 166 }, Enum.PartType.Ball).CanCollide = false
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "WelcomeMat"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(10, 1, 6)
	spawn.Position = Vector3.new(0, 1, 12)
	spawn.Color = Color3.fromRGB(255, 199, 88)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Parent = model
	for index = 1, 4 do
		local x = if index % 2 == 0 then 19 else -19
		local z = if index <= 2 then 5 else -9
		part("StampingStation", Vector3.new(8, 3, 5), Vector3.new(x, 2, z), { 255, 248, 232 })
	end
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 14
	lighting.Brightness = 2
	lighting.Ambient = Color3.fromRGB(160, 182, 191)
	-- FallenPartsDestroyHeight is set in default.project.json. Roblox permits
	-- changing it through Studio properties/plugins, not a running game script.
end

return Workshop
