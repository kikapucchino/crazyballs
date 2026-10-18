-- Original enclosed observatory, built only from Roblox primitives.
local Plan = require(script.Parent.LobbyPlan)
local Workshop = {}
function Workshop.build()
	if workspace:FindFirstChild("CloudpopWorkshop") then return end
	local model = Instance.new("Model")
	model.Name, model.Parent = "CloudpopWorkshop", workspace
	local navy, blue, ice, cyan = Color3.fromRGB(16, 30, 58), Color3.fromRGB(37, 76, 121), Color3.fromRGB(211, 232, 248), Color3.fromRGB(91, 214, 232)
	local function part(name, size, position, color, material, class, parent)
		local item = Instance.new(class or "Part")
		item.Name, item.Size, item.Position = name, size, position
		item.Anchored, item.Color = true, color
		item.Material = material or Enum.Material.SmoothPlastic
		item.TopSurface, item.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		item.Parent = parent or model
		return item
	end
	local function sign(parent, name, text, size, face)
		local surface = Instance.new("SurfaceGui")
		surface.Name, surface.Face, surface.CanvasSize = name, face or Enum.NormalId.Back, Vector2.new(1000, 350)
		surface.Parent = parent
		local label = Instance.new("TextLabel")
		label.Name, label.Size = "Text", UDim2.fromScale(1, 1)
		label.BackgroundTransparency, label.TextColor3 = 1, ice
		label.Font, label.TextSize, label.TextWrapped = Enum.Font.GothamBold, size or 64, true
		label.Text, label.Parent = text, surface
		return label
	end
	part("Foundation", Vector3.new(158, 5, 84), Vector3.new(29, -3, 0), navy, Enum.Material.Slate)
	for _,x in ipairs({-40,98}) do
		for _,z in ipairs({-30,30}) do
			part("MarineSupport",Vector3.new(4,10,4),Vector3.new(x,-9.5,z),navy,Enum.Material.Metal)
		end
	end
	for _, room in ipairs(Plan.Rooms) do
		local center = Vector3.new((room.x1 + room.x2) / 2, 0, (room.z1 + room.z2) / 2)
		part(room.id .. "Floor", Vector3.new(room.x2-room.x1, 1, room.z2-room.z1), center, blue, Enum.Material.Marble)
		part(room.id .. "Ceiling", Vector3.new(room.x2-room.x1, 1, room.z2-room.z1), Vector3.new(center.X, Plan.Height, center.Z), navy)
		for _, offset in ipairs({ -8, 8 }) do
			local lamp = part("CeilingLight", Vector3.new(14, 0.2, 1.2), Vector3.new(center.X, Plan.Height - 0.6, center.Z + offset), ice, Enum.Material.Neon)
			local light = Instance.new("SurfaceLight")
			light.Face, light.Brightness, light.Range, light.Angle, light.Shadows = Enum.NormalId.Bottom, 1.2, 35, 130, false
			light.Color, light.Parent = ice, lamp
		end
	end
	local function wallPiece(name, axis, fixed, low, high, y, height, color, material)
		if high <= low then return nil end
		local size = if axis == "x" then Vector3.new(high-low, height, 1) else Vector3.new(1, height, high-low)
		local position = if axis == "x" then Vector3.new((low+high)/2, y, fixed) else Vector3.new(fixed, y, (low+high)/2)
		return part(name, size, position, color, material)
	end
	-- All exterior walls are closed: opaque sill/lintel + collidable glazing between.
	for _, wall in ipairs({ {"x",-40,-48,106}, {"x",40,-48,106}, {"z",-48,-40,40}, {"z",106,-40,40} }) do
		local axis, fixed, low, high = table.unpack(wall)
		wallPiece("ExteriorSill", axis, fixed, low, high, 2.5, 5, navy)
		wallPiece("ExteriorLintel", axis, fixed, low, high, 23.5, 5, navy)
		local glass = wallPiece("Window", axis, fixed, low, high, 13, 16, ice, Enum.Material.Glass)
		glass.Transparency = 0.68
		wallPiece("WindowTrim", axis, fixed, low, high, 5, 0.25, cyan, Enum.Material.Metal)
		wallPiece("Cornice", axis, fixed, low, high, 25.2, 0.5, blue, Enum.Material.Metal)
		for at = low, high, 12 do wallPiece("WindowMullion", axis, fixed, at, math.min(at+0.5, high), 13, 16, blue, Enum.Material.Metal) end
	end
	for _, wall in ipairs(Plan.Doors) do
		local cursor = wall.start
		for _, center in ipairs(wall.centers) do
			local left, right = center-wall.width/2, center+wall.width/2
			wallPiece("InteriorWall", wall.axis, wall.fixed, cursor, left, Plan.Height/2, Plan.Height, navy)
			wallPiece("DoorLintel", wall.axis, wall.fixed, left, right, (Plan.Height+wall.height)/2, Plan.Height-wall.height, navy)
			for _, edge in ipairs({left, right}) do wallPiece("DoorTrim", wall.axis, wall.fixed, edge-0.2, edge+0.2, wall.height/2, wall.height, cyan, Enum.Material.Metal) end
			cursor = right
		end
		wallPiece("InteriorWall", wall.axis, wall.fixed, cursor, wall.finish, Plan.Height/2, Plan.Height, navy)
	end
	for _,entry in ipairs({{-17,"SOCIAL LOUNGE · SKY CAFÉ"},{17,"VIEWING ROOM"}}) do
		local plaque=part("Wayfinding",Vector3.new(0.3,2.4,14),Vector3.new(47.35,14.5,entry[1]),blue)
		sign(plaque,"Directions",entry[2],48,Enum.NormalId.Left)
	end
	part("CentralWalkway", Vector3.new(16, 0.06, 66), Vector3.new(0, 0.54, 0), ice)
	for _, x in ipairs({ -8.1, 8.1 }) do part("PathLight", Vector3.new(0.16, 0.08, 66), Vector3.new(x, 0.56, 0), cyan, Enum.Material.Neon) end
	part("PresenterStage", Vector3.new(36, 0.6, 20), Vector3.new(0, 0.8, -25), navy)
	part("StageStep", Vector3.new(36, 0.3, 2), Vector3.new(0, 0.65, -14), blue)
	local machine = part("MachinePedestal", Vector3.new(14, 3, 10), Vector3.new(0, 2.6, -24), navy, Enum.Material.Metal)
	sign(machine, "Nameplate", "CLOUDPOP  /  COMMONS", 52)
	part("MachineTrim", Vector3.new(14.2, 0.25, 10.2), Vector3.new(0, 4.2, -24), cyan, Enum.Material.Neon)
	local globe = part("AirChamber", Vector3.new(10, 10, 10), Vector3.new(0, 9, -24), ice, Enum.Material.Glass)
	globe.Shape, globe.Transparency, globe.CanCollide = Enum.PartType.Ball, 0.72, false
	for index = 1, 16 do
		local angle = index * math.pi / 8
		local ball = part("DecorativeBall" .. index, Vector3.new(1.1, 1.1, 1.1), Vector3.new(math.cos(angle)*3, 7+index%4, -24+math.sin(angle)*3), if index%3==0 then ice else cyan)
		ball.Shape, ball.CanCollide, ball.CastShadow = Enum.PartType.Ball, false, false
	end
	local display = part("DrawDisplay", Vector3.new(26, 6, 0.5), Vector3.new(0, 19, -36), navy)
	sign(display, "Readout", "WELCOME\n0 / 20", 90)
	local emerged = part("DrawnBall", Vector3.new(2.6, 2.6, 2.6), Vector3.new(0, 6, -17), ice)
	emerged.Shape, emerged.CanCollide = Enum.PartType.Ball, false
	local tag = Instance.new("BillboardGui")
	tag.Name, tag.Size, tag.AlwaysOnTop, tag.MaxDistance = "BallNumber", UDim2.fromOffset(64,64), false, 100
	tag.Parent = emerged
	local text = Instance.new("TextLabel")
	text.Name, text.Size, text.BackgroundTransparency = "Text", UDim2.fromScale(1,1), 1
	text.Font, text.TextSize, text.TextColor3, text.Text, text.Parent = Enum.Font.GothamBold, 36, navy, "—", tag
	-- Original stage character; geometric face/uniform, no downloaded avatar or voice.
	local presenter = Instance.new("Model")
	presenter.Name, presenter.Parent = "Presenter", model
	local skin = Color3.fromRGB(181, 126, 93)
	local torso = part("Torso", Vector3.new(2,2,1), Vector3.new(12,4.1,-25), blue, nil, nil, presenter)
	part("Head", Vector3.new(1.7,1.6,1.5), Vector3.new(12,5.9,-25), skin, nil, nil, presenter)
	for _, side in ipairs({-1,1}) do
		part(if side<0 then "Left Arm" else "Right Arm", Vector3.new(0.8,2,0.9), Vector3.new(12+side*1.45,4.1,-25), blue, nil, nil, presenter)
		part(if side<0 then "Left Leg" else "Right Leg", Vector3.new(0.8,2,0.9), Vector3.new(12+side*0.5,2.1,-25), navy, nil, nil, presenter)
		part("Eye", Vector3.new(0.15,0.18,0.08), Vector3.new(12+side*0.35,6.05,-24.22), navy, nil, nil, presenter).CanCollide = false
	end
	part("Smile", Vector3.new(0.45,0.1,0.08), Vector3.new(12,5.55,-24.22), ice, nil, nil, presenter).CanCollide=false
	part("Hair", Vector3.new(1.85,0.5,1.65), Vector3.new(12,6.75,-25), navy, nil, nil, presenter)
	part("Lapel", Vector3.new(0.2,1.3,0.1), Vector3.new(12,4.15,-24.45), cyan, nil, nil, presenter)
	presenter.PrimaryPart = torso
	local humanoid = Instance.new("Humanoid")
	humanoid.RequiresNeck, humanoid.BreakJointsOnDeath = false, false
	humanoid.DisplayName, humanoid.DisplayDistanceType, humanoid.Parent = "Lumi", Enum.HumanoidDisplayDistanceType.None, presenter
	part("MicrophoneStand", Vector3.new(0.2,4.5,0.2), Vector3.new(11,3.35,-23), navy, Enum.Material.Metal)
	local microphone = part("Microphone", Vector3.new(0.6,0.35,0.8), Vector3.new(11,5.7,-23), ice, Enum.Material.Metal)
	microphone.CanCollide=false
	local function seat(x,z,rotation)
		local item = part("LoungeSeat", Vector3.new(3.4,0.8,3.4), Vector3.new(x,2,z), blue, Enum.Material.Fabric,"Seat")
		item.Orientation = Vector3.new(0,rotation,0)
		local offset = if rotation == 180 then -1.6 else 1.6
		part("SeatBack",Vector3.new(3.4,2.4,0.6),Vector3.new(x,3.1,z+offset),navy,Enum.Material.Fabric)
		part("SeatFoot",Vector3.new(2,1,2),Vector3.new(x,1,z),navy,Enum.Material.Metal)
	end
	local function tableAt(x,z)
		part("TableBase",Vector3.new(2,3,2),Vector3.new(x,2,z),navy,Enum.Material.Metal)
		part("TableTop",Vector3.new(10,0.45,7),Vector3.new(x,3.7,z),ice)
		seat(x,z-5.2,180); seat(x,z+5.2,0)
	end
	for _, x in ipairs({-28,28}) do for _, z in ipairs({-5,20}) do tableAt(x,z) end end
	-- Social room: conversation seating to the left; non-alcoholic café on its north wall.
	part("LoungeRug",Vector3.new(25,0.06,19),Vector3.new(70,0.55,-22),navy,Enum.Material.Fabric)
	for _, x in ipairs({62,67,72}) do seat(x,-29,180); seat(x,-14,0) end
	part("CoffeeTable",Vector3.new(12,1.5,5),Vector3.new(67,1.3,-21),ice)
	part("CafeCounter",Vector3.new(19,4,4),Vector3.new(92,2.5,-29),navy)
	part("CafeCounterTop",Vector3.new(20,0.3,4.5),Vector3.new(92,4.65,-29),ice,Enum.Material.Marble)
	part("CafeBackCabinet",Vector3.new(19,3,3),Vector3.new(92,2,-36),blue)
	part("CafeShelf",Vector3.new(19,0.4,3),Vector3.new(92,7,-36),ice)
	local menu = part("CafeMenu",Vector3.new(19,4,0.25),Vector3.new(92,11,-38),navy)
	sign(menu,"Menu","SKY CAFÉ\nTea · Cocoa · Fruit coolers",58)
	for _, x in ipairs({86,92,98}) do
		seat(x,-23,0)
		part("CafeCup",Vector3.new(0.6,0.8,0.6),Vector3.new(x,5.2,-29),cyan)
	end
	part("CoffeeMachine",Vector3.new(3,3,2),Vector3.new(99,5,-36),navy,Enum.Material.Metal)
	-- Separate viewing room, furnished and linked through its own hall door.
	local screen = part("ViewingDisplay",Vector3.new(25,8,0.5),Vector3.new(79,12,3),navy)
	sign(screen,"Readout","CLOUDPOP LIVE\n0 / 20",78)
	for _, z in ipairs({15,25}) do for _, x in ipairs({66,73,80,87}) do seat(x,z,0) end end
	part("MediaConsole",Vector3.new(25,2,3),Vector3.new(79,1.5,4),blue)
	for _, x in ipairs({60,99}) do
		part("DisplayPlinth",Vector3.new(3,4,3),Vector3.new(x,2.5,33),navy)
		local sculpture=part("OrbitSculpture",Vector3.new(2,2,2),Vector3.new(x,5.5,33),cyan,Enum.Material.Glass)
		sculpture.Shape=Enum.PartType.Ball
	end
	for _, location in ipairs({{-39,-29},{-39,29},{40,30},{56,-35},{99,-7},{99,32}}) do
		local x,z=location[1],location[2]
		part("Planter",Vector3.new(3,2,3),Vector3.new(x,1.5,z),navy)
		for i=1,3 do
			local leaf=part("CrystalFern",Vector3.new(0.5,3+i,1.5),Vector3.new(x+i-2,4,z),cyan)
			leaf.Orientation,leaf.CanCollide=Vector3.new(0,i*50,(i-2)*22),false
		end
	end
	-- Real scenery beyond the glazed envelope, with no exposed starter baseplate.
	part("ExteriorSea",Vector3.new(1100,2,1100),Vector3.new(20,-13,0),blue,Enum.Material.Glass)
	for _, location in ipairs({{-150,-110},{155,-110},{210,90},{-170,100}}) do
		local rock=part("DistantIsland",Vector3.new(65,32,55),Vector3.new(location[1],-5,location[2]),navy,Enum.Material.Slate)
		rock.Shape=Enum.PartType.Ball
		for index=1,3 do
			local cloud=part("DistantCloud",Vector3.new(25,10,16),Vector3.new(location[1]+index*12,37,location[2]),ice)
			cloud.Shape,cloud.CanCollide=Enum.PartType.Ball,false
		end
	end
	local spawn=part("WelcomeMat",Vector3.new(10,0.1,6),Vector3.new(0,0.65,31),blue,nil,"SpawnLocation")
	spawn.Neutral,spawn.Duration,spawn.Transparency=true,0,1
	local lighting=game:GetService("Lighting")
	lighting.ClockTime,lighting.Brightness=14,2
	lighting.Ambient,lighting.OutdoorAmbient=Color3.fromRGB(110,136,169),Color3.fromRGB(152,175,203)
	-- FallenPartsDestroyHeight stays in the place file, never in runtime code.
end
return Workshop
