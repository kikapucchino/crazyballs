local Mock = require("./mock")
local loadWorkshop = require("./.generated/WorkshopHarness")
local Plan = require("../src/server/LobbyPlan")
local Layout = require("../src/shared/CardLayout")
local new, all = Mock.instances()
local g = Mock.globals()
local world, lighting = new("Workspace"), new("Lighting")
local workshop = loadWorkshop({GetService=function() return lighting end}, world, {new=new},g.Vector3,g.Color3,g.Enum,g.Vector2,g.UDim2,
	function() return Plan end,{Parent={LobbyPlan="LobbyPlan"}})
local passed=0
local function test(name,callback)
	local ok,problem=pcall(callback); assert(ok,name..": "..tostring(problem)); passed+=1; print("PASS "..name)
end
workshop.build()
local function contains(part,x,y,z,margin)
	local p,s=part.Position,part.Size
	if not p or not s then return false end
	return math.abs(x-p.X)<=s.X/2+(margin or 0) and math.abs(y-p.Y)<=s.Y/2 and math.abs(z-p.Z)<=s.Z/2+(margin or 0)
end
local function solidAt(x,y,z)
	for _,part in ipairs(all) do if part.CanCollide~=false and contains(part,x,y,z,0) then return true end end
	return false
end
test("all three rooms have continuous floors and ceilings",function()
	for _,room in ipairs(Plan.Rooms) do
		assert(world.CloudpopWorkshop:FindFirstChild(room.id.."Floor"))
		assert(world.CloudpopWorkshop:FindFirstChild(room.id.."Ceiling"))
		for x=room.x1+2,room.x2-2,4 do for z=room.z1+2,room.z2-2,4 do
			assert(solidAt(x,0,z) and solidAt(x,Plan.Height,z))
		end end
	end
end)
test("exterior glazing and walls enclose all four sides without gaps",function()
	for x=-64,144,2 do for y=2,26,2 do assert(solidAt(x,y,-56) and solidAt(x,y,56)) end end
	for z=-56,56,2 do for y=2,26,2 do assert(solidAt(-64,y,z) and solidAt(144,y,z)) end end
end)
test("a 3.6-stud-wide route reaches both side rooms from the spawn",function()
	local blockers={}
	for _,part in ipairs(all) do
		if part.Position and part.Size and part.CanCollide~=false and part.Position.Y+part.Size.Y/2>2.5 and part.Position.Y-part.Size.Y/2<5 then table.insert(blockers,part) end
	end
	local function clear(x,z)
		if x<=-62 or x>=142 or z<=-54 or z>=54 then return false end
		for _,part in ipairs(blockers) do
			local p,s=part.Position,part.Size
			if math.abs(x-p.X)<s.X/2+1.8 and math.abs(z-p.Z)<s.Z/2+1.8 then return false end
		end
		return true
	end
	local queue,seen,at={{0,30}},{["0:30"]=true},1
	while at<=#queue do
		local item=queue[at];at+=1
		for _,offset in ipairs({{2,0},{-2,0},{0,2},{0,-2}}) do
			local x,z=item[1]+offset[1],item[2]+offset[2]
			local key=x..":"..z
			if not seen[key] and clear(x,z) then seen[key]=true;table.insert(queue,{x,z}) end
		end
	end
	assert(seen["104:-10"] and seen["136:30"],"Furniture or partitions block the rooms")
end)
test("stage character, café, seats and second shared viewing screen exist",function()
	local model=world.CloudpopWorkshop
	assert(model.Presenter.Head and model.Presenter.Humanoid and model.CafeMenu and model.ViewingDisplay)
	local seats=0
	for _,item in ipairs(all) do if item.ClassName=="Seat" then seats+=1 end end
	assert(seats>=60)
end)
test("expanded lobby has 64 native seat surfaces and bounded static decoration",function()
	local parts,seats,lights=0,0,0
	for _,item in ipairs(all) do
		if item.ClassName=="Part" or item.ClassName=="Seat" or item.ClassName=="SpawnLocation" then
			parts+=1;assert(item.Anchored and item.CastShadow==false)
		end
		if item.ClassName=="Seat" then seats+=1;assert(item.CanCollide~=false and item.CanTouch~=false) end
		if item.Name=="SeatCushion" then assert(not item.CanCollide and not item.CanTouch) end
		if item.ClassName=="SurfaceLight" then lights+=1;assert(not item.Shadows) end
		assert(item.ClassName~="ParticleEmitter")
	end
	assert(parts<700 and seats==64 and lights==6)
	local area=0;for _,room in ipairs(Plan.Rooms) do area+=(room.x2-room.x1)*(room.z2-room.z1) end
	assert(area==23296 and world.CloudpopWorkshop.BoutiqueCounter.RobuxShopPrompt)
end)
test("desktop fits horizontal main cards with the adjacent two-column bonus group",function()
	local box=Layout.compute(1920,1080,false,2)
	assert(box.bonusX==512 and box.contentWidth==908 and box.width>=box.contentWidth)
	assert(box.height+box.footer<1080/2)
end)
test("phone layouts preserve cell size, scrollable content and room for movement controls",function()
	for _,size in ipairs({{390,760},{844,340},{320,568},{1024,700}}) do
		local box=Layout.compute(size[1],size[2],true,2)
		assert(box.width<=size[1] and box.width>0 and box.height+box.footer<size[2])
		assert(box.contentWidth==908 and box.height<=392)
		if size[1]>size[2] then assert((size[1]-box.width)/2>=150) else assert(box.footer>=170) end
	end
end)
print("Lobby/layout: "..passed.." tests passed (geometry, not rendered navigation)")
