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
		item.CastShadow = false
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
	part("Foundation", Vector3.new(212, 5, 116), Vector3.new(40, -3, 0), navy, Enum.Material.Slate)
	for _,x in ipairs({-56,136}) do
		for _,z in ipairs({-48,48}) do
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
	for _, wall in ipairs({ {"x",-56,-64,144}, {"x",56,-64,144}, {"z",-64,-56,56}, {"z",144,-56,56} }) do
		local axis, fixed, low, high = table.unpack(wall)
		wallPiece("ExteriorSill", axis, fixed, low, high, 2.5, 5, navy)
		wallPiece("ExteriorLintel", axis, fixed, low, high, 25.5, 5, navy)
		local glass = wallPiece("Window", axis, fixed, low, high, 14, 18, ice, Enum.Material.Glass)
		glass.Transparency = 0.68
		wallPiece("WindowTrim", axis, fixed, low, high, 5, 0.25, cyan, Enum.Material.Metal)
		wallPiece("Cornice", axis, fixed, low, high, 27.2, 0.5, blue, Enum.Material.Metal)
		for at = low, high, 12 do wallPiece("WindowMullion", axis, fixed, at, math.min(at+0.5, high), 14, 18, blue, Enum.Material.Metal) end
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
	for _,entry in ipairs({{-24,"SOCIAL LOUNGE · SKY CAFÉ"},{24,"VIEWING ROOM"}}) do
		local plaque=part("Wayfinding",Vector3.new(0.3,2.4,14),Vector3.new(63.35,16.5,entry[1]),blue)
		sign(plaque,"Directions",entry[2],48,Enum.NormalId.Left)
	end
	part("CentralWalkway", Vector3.new(16, 0.06, 100), Vector3.new(0, 0.54, 0), ice)
	for _, x in ipairs({ -8.1, 8.1 }) do part("PathLight", Vector3.new(0.16, 0.08, 100), Vector3.new(x, 0.56, 0), cyan, Enum.Material.Neon) end
	part("PresenterStage", Vector3.new(36, 0.6, 20), Vector3.new(0, 0.8, -41), navy)
	part("StageStep", Vector3.new(36, 0.3, 2), Vector3.new(0, 0.65, -30), blue)
	local machine = part("MachinePedestal", Vector3.new(14, 3, 10), Vector3.new(0, 2.6, -40), navy, Enum.Material.Metal)
	sign(machine, "Nameplate", "CLOUDPOP  /  COMMONS", 52)
	part("MachineTrim", Vector3.new(14.2, 0.25, 10.2), Vector3.new(0, 4.2, -40), cyan, Enum.Material.Neon)
	local globe = part("AirChamber", Vector3.new(10, 10, 10), Vector3.new(0, 9, -40), ice, Enum.Material.Glass)
	globe.Shape, globe.Transparency, globe.CanCollide = Enum.PartType.Ball, 0.72, false
	for index = 1, 16 do
		local angle = index * math.pi / 8
		local ball = part("DecorativeBall" .. index, Vector3.new(1.1, 1.1, 1.1), Vector3.new(math.cos(angle)*3, 7+index%4, -40+math.sin(angle)*3), if index%3==0 then ice else cyan)
		ball.Shape, ball.CanCollide, ball.CastShadow = Enum.PartType.Ball, false, false
	end
	local display = part("DrawDisplay", Vector3.new(26, 6, 0.5), Vector3.new(0, 19, -52), navy)
	sign(display, "Readout", "WELCOME\n0 / 20", 90)
	local emerged = part("DrawnBall", Vector3.new(2.6, 2.6, 2.6), Vector3.new(0, 6, -33), ice)
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
	local torso = part("Torso", Vector3.new(2,2,1), Vector3.new(12,4.1,-41), blue, nil, nil, presenter)
	part("Head", Vector3.new(1.7,1.6,1.5), Vector3.new(12,5.9,-41), skin, nil, nil, presenter)
	for _, side in ipairs({-1,1}) do
		part(if side<0 then "Left Arm" else "Right Arm", Vector3.new(0.8,2,0.9), Vector3.new(12+side*1.45,4.1,-41), blue, nil, nil, presenter)
		part(if side<0 then "Left Leg" else "Right Leg", Vector3.new(0.8,2,0.9), Vector3.new(12+side*0.5,2.1,-41), navy, nil, nil, presenter)
		part("Eye", Vector3.new(0.15,0.18,0.08), Vector3.new(12+side*0.35,6.05,-40.22), navy, nil, nil, presenter).CanCollide = false
	end
	part("Smile", Vector3.new(0.45,0.1,0.08), Vector3.new(12,5.55,-40.22), ice, nil, nil, presenter).CanCollide=false
	part("Hair", Vector3.new(1.85,0.5,1.65), Vector3.new(12,6.75,-41), navy, nil, nil, presenter)
	part("Lapel", Vector3.new(0.2,1.3,0.1), Vector3.new(12,4.15,-40.45), cyan, nil, nil, presenter)
	presenter.PrimaryPart = torso
	local humanoid = Instance.new("Humanoid")
	humanoid.RequiresNeck, humanoid.BreakJointsOnDeath = false, false
	humanoid.DisplayName, humanoid.DisplayDistanceType, humanoid.Parent = "Lumi", Enum.HumanoidDisplayDistanceType.None, presenter
	part("MicrophoneStand", Vector3.new(0.2,4.5,0.2), Vector3.new(11,3.35,-39), navy, Enum.Material.Metal)
	local microphone = part("Microphone", Vector3.new(0.6,0.35,0.8), Vector3.new(11,5.7,-39), ice, Enum.Material.Metal)
	microphone.CanCollide=false
	local function seat(x,z,rotation)
		local item = part("LoungeSeat", Vector3.new(3.4,0.8,3.4), Vector3.new(x,2,z), blue, Enum.Material.Fabric,"Seat")
		item.Orientation = Vector3.new(0,rotation,0)
		local offset = if rotation == 180 then -1.6 else 1.6
		part("SeatBack",Vector3.new(3.4,2.4,0.6),Vector3.new(x,3.1,z+offset),navy,Enum.Material.Fabric)
		part("SeatFoot",Vector3.new(2,1,2),Vector3.new(x,1,z),navy,Enum.Material.Metal)
	end
	local function decoration(name,size,position,color,material)
		local object=part(name,size,position,color,material)
		object.CanCollide,object.CanTouch,object.CanQuery=false,false,false
		return object
	end
	local function tableAt(x,z)
		part("TableBase",Vector3.new(2,3,2),Vector3.new(x,2,z),navy,Enum.Material.Metal)
		part("TableTop",Vector3.new(18,0.45,8),Vector3.new(x,3.7,z),ice)
		for _,dx in ipairs({-6,0,6}) do seat(x+dx,z-6.5,180);seat(x+dx,z+6.5,0) end
		decoration("TableRunner",Vector3.new(16,0.07,1.6),Vector3.new(x,3.97,z),blue,Enum.Material.Fabric)
		local bloom=decoration("TableBloom",Vector3.new(0.9,1,0.9),Vector3.new(x,4.5,z),cyan)
		bloom.Shape=Enum.PartType.Ball
	end
	for _, x in ipairs({-32,32}) do for _, z in ipairs({-14,18,44}) do
		decoration("DiningRug",Vector3.new(25,0.05,23),Vector3.new(x,0.54,z),navy,Enum.Material.Fabric)
		tableAt(x,z)
	end end
	-- Social lounge: six-place tables, low seating and a full non-alcoholic bar.
	for _,x in ipairs({84,124}) do
		decoration("LoungeRug",Vector3.new(26,0.06,25),Vector3.new(x,0.55,-23),navy,Enum.Material.Fabric)
		tableAt(x,-23)
	end
	part("CafeCounter",Vector3.new(28,4,4),Vector3.new(121,2.5,-44),navy)
	part("CafeCounterTop",Vector3.new(29,0.3,4.5),Vector3.new(121,4.65,-44),ice,Enum.Material.Marble)
	part("CafeBackCabinet",Vector3.new(28,3,3),Vector3.new(121,2,-52),blue)
	for _,y in ipairs({7,10}) do
		part("CafeShelf",Vector3.new(28,0.4,2.4),Vector3.new(121,y,-53),ice)
		for i=1,7 do decoration("ShelfCup",Vector3.new(0.6,0.8,0.6),Vector3.new(108+i*3,y+0.6,-53),if i%2==0 then cyan else ice) end
	end
	local menu=part("CafeMenu",Vector3.new(28,4,0.25),Vector3.new(121,15,-54),navy)
	sign(menu,"Menu","SKY CAFÉ\nTea · Cocoa · Fruit coolers",58)
	for _,x in ipairs({112,118,124,130}) do seat(x,-38,0);decoration("CafeCup",Vector3.new(0.6,0.8,0.6),Vector3.new(x,5.2,-44),cyan) end
	part("CoffeeMachine",Vector3.new(3,3,2),Vector3.new(132,5,-52),navy,Enum.Material.Metal)
	-- Separate guaranteed-cosmetic boutique beside the café, off the doorway route.
	part("BoutiqueCounter",Vector3.new(18,3,4),Vector3.new(82,2,-46),navy)
	local boutique=part("BoutiqueSign",Vector3.new(19,5,0.4),Vector3.new(82,11,-52),blue)
	sign(boutique,"ShopLabel","CLOUDPOP BOUTIQUE\nLegendary cosmetic markers",44)
	local prompt=Instance.new("ProximityPrompt")
	prompt.Name,prompt.ActionText,prompt.ObjectText="RobuxShopPrompt","Browse cosmetics","Cloudpop Boutique"
	prompt.HoldDuration,prompt.MaxActivationDistance,prompt.RequiresLineOfSight=0,12,false
	prompt.Parent=model.BoutiqueCounter
	for _,x in ipairs({78,86}) do
		local gem=decoration("BoutiqueDisplay",Vector3.new(1.6,1.6,1.6),Vector3.new(x,4.4,-46),cyan,Enum.Material.Glass)
		gem.Shape=Enum.PartType.Ball
	end
	-- Complete separate viewing room, with clear aisles on both sides.
	local screen=part("ViewingDisplay",Vector3.new(36,9,0.5),Vector3.new(108,13,3),navy)
	sign(screen,"Readout","CLOUDPOP LIVE\n0 / 20",78)
	part("MediaConsole",Vector3.new(36,2,3),Vector3.new(108,1.5,4),blue)
	decoration("ViewingRug",Vector3.new(54,0.06,36),Vector3.new(106,0.55,32),navy,Enum.Material.Fabric)
	for _,z in ipairs({24,40}) do for _,x in ipairs({84,92,100,112,120,128}) do seat(x,z,0) end end
	for _,location in ipairs({{-57,-47},{-57,3},{-57,48},{56,-47},{56,48},{73,-48},{137,-7},{137,48},{72,48}}) do
		local x,z=location[1],location[2]
		part("Planter",Vector3.new(3,2,3),Vector3.new(x,1.5,z),ice)
		for i=1,3 do
			local leaf=decoration("CrystalFern",Vector3.new(0.5,3+i,1.5),Vector3.new(x+i-2,4,z),cyan)
			leaf.Orientation=Vector3.new(0,i*50,(i-2)*22)
		end
	end
	-- Original constellation wall art, reading shelves and architectural details.
	for _,entry in ipairs({{-44,-54},{44,-54},{80,-54},{80,54},{130,54}}) do
		local x,z=entry[1],entry[2]
		part("ArtFrame",Vector3.new(14,7,0.4),Vector3.new(x,13,z),ice)
		decoration("ArtCanvas",Vector3.new(13.3,6.3,0.5),Vector3.new(x,13,z),blue)
		for i=1,5 do
			local star=decoration("ConstellationStar",Vector3.new(0.6,0.6,0.6),Vector3.new(x-5+i*1.8,12+(i%3),z+(if z<0 then 0.35 else -0.35)),cyan,Enum.Material.Neon)
			star.Shape=Enum.PartType.Ball
		end
	end
	for _,x in ipairs({-60,140}) do
		part("ReadingShelf",Vector3.new(2,0.4,18),Vector3.new(x,5,18),ice)
		for i=1,9 do decoration("Book",Vector3.new(1.4,1.5+(i%3)*0.3,0.7),Vector3.new(x,6,9+i*1.7),if i%2==0 then cyan else blue) end
	end
	for _,x in ipairs({-62,62,142}) do
		for _,z in ipairs({-54,54}) do
			part("CornerPilaster",Vector3.new(1,28,1),Vector3.new(x,14,z),ice)
			decoration("WallSconce",Vector3.new(1.2,3,1.2),Vector3.new(x,10,z),cyan,Enum.Material.Neon)
		end
	end
	-- Every Seat is a native Roblox Seat; visual cushions do not intercept seat contact.
	for _,item in ipairs(model:GetChildren()) do
		if item:IsA("Seat") then
			decoration("SeatCushion",Vector3.new(3.1,0.12,3.1),Vector3.new(item.Position.X,2.46,item.Position.Z),ice,Enum.Material.Fabric)
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
	local spawn=part("WelcomeMat",Vector3.new(10,0.1,6),Vector3.new(0,0.65,47),blue,nil,"SpawnLocation")
	spawn.Neutral,spawn.Duration,spawn.Transparency=true,0,1
	local lighting=game:GetService("Lighting")
	lighting.ClockTime,lighting.Brightness=14,2
	lighting.Ambient,lighting.OutdoorAmbient=Color3.fromRGB(110,136,169),Color3.fromRGB(152,175,203)
	-- FallenPartsDestroyHeight stays in the place file, never in runtime code.
end
return Workshop
