-- Local visual interpolation of server-owned pets; no per-frame network updates or physics.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Pets={}
function Pets.start(reducedMotion)
	local pivots={}
	local elapsed=0
	RunService.RenderStepped:Connect(function(delta)
		elapsed+=delta
		if elapsed<1/30 then return end
		delta=elapsed;elapsed=0
		local folder=workspace:FindFirstChild("CloudpopPets")
		if not folder then return end
		local present={}
		for _,model in ipairs(folder:GetChildren()) do
			present[model]=true
			local ownerId=model:GetAttribute("OwnerUserId")
			local owner=if type(ownerId)=="number" then Players:GetPlayerByUserId(ownerId) else nil
			local root=owner and owner.Character and owner.Character:FindFirstChild("HumanoidRootPart")
			if not root then continue end
			local moving=root.AssemblyLinearVelocity.Magnitude>1
			local t=workspace:GetServerTimeNow()
			local bob=if reducedMotion() then 0 else math.sin(t*(if moving then 8 else 2.5))*0.14
			local target=root.CFrame*CFrame.new(3,0.1+bob,3)*CFrame.Angles(0,0,if reducedMotion() then 0 else math.sin(t*3)*0.06)
			local nextPivot=if pivots[model] then pivots[model]:Lerp(target,1-math.exp(-10*math.min(delta,0.1))) else target
			pivots[model]=nextPivot
			model:PivotTo(nextPivot)
		end
		for model in pairs(pivots) do if not present[model] then pivots[model]=nil end end
	end)
end
return Pets
