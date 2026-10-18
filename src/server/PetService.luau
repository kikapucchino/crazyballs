local PetService={}
function PetService.new(builder, world)
	local folder=Instance.new("Folder")
	folder.Name,folder.Parent="CloudpopPets",world
	local models={}
	local self={}
	function self:sync(player, id)
		local current=models[player]
		if current and current.Name==id then return end
		if current then current:Destroy();models[player]=nil end
		if not id then return end
		local model=builder.build(id)
		model:SetAttribute("OwnerUserId",player.UserId)
		local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		model:PivotTo(if root then root.CFrame*CFrame.new(3,1,3) else CFrame.new(0,-30,0))
		model.Parent=folder
		models[player]=model
	end
	function self:remove(player) self:sync(player,nil) end
	return self
end
return PetService
