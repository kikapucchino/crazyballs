-- Three original geometric companions, no external models or franchise assets.
local Pet = {}
function Pet.build(id)
	local model=Instance.new("Model")
	model.Name=id
	local function part(name,size,position,color,shape)
		local item=Instance.new("Part")
		item.Name,item.Size,item.Position=name,Vector3.new(table.unpack(size)),Vector3.new(table.unpack(position))
		item.Color,item.Material=Color3.fromRGB(table.unpack(color)),Enum.Material.SmoothPlastic
		item.Anchored,item.CanCollide,item.CanTouch,item.CanQuery,item.CastShadow=true,false,false,false,false
		if shape then item.Shape=shape end
		item.Parent=model
		return item
	end
	local primary
	if id=="pet_lumen" then
		primary=part("Body",{1.8,1,1.2},{0,0,0},{131,223,239})
		part("Crown",{0.7,0.4,0.7},{0,0.7,0},{246,223,139})
		for _,side in ipairs({-1,1}) do part("Sail",{0.25,0.9,0.7},{side*1.1,0.2,0},{219,242,255}) end
	elseif id=="pet_prism" then
		primary=part("Body",{1.2,1.2,1.2},{0,0,0},{179,176,244})
		for index=1,3 do
			local orb=part("Orbit"..index,{0.45,0.45,0.45},{math.cos(index*2.1)*1.05,0.5,math.sin(index*2.1)*0.6},{150,225,243},Enum.PartType.Ball)
			orb.Transparency=0.1
		end
	elseif id=="pet_tassel" then
		primary=part("Body",{1.2,1.5,1.1},{0,0.2,0},{127,201,183},Enum.PartType.Ball)
		for _,side in ipairs({-1,0,1}) do part("Ribbon",{0.2,0.8,0.25},{side*0.4,-0.75,0},{206,243,235}) end
	else error("Unknown pet") end
	for _,side in ipairs({-1,1}) do part("Eye",{0.13,0.16,0.09},{side*0.28,0.15,-0.61},{20,36,64}) end
	part("Smile",{0.25,0.06,0.08},{0,-0.12,-0.62},{20,36,64})
	model.PrimaryPart=primary
	return model
end
return Pet
