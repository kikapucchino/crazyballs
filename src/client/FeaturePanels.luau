local Marketplace=game:GetService("MarketplaceService")
local Players=game:GetService("Players")
local TextChatService=game:GetService("TextChatService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Cloudpop")
local PetBuilder=require(Shared.PetBuilder)
local Features={}
function Features.new(body,settings,ui,config,request)
	local self={pages={},heights={Pets=580,Chest=270,Records=820},state=nil,seenSerial=0,queue={},nextMessage=0,price=nil,priceId=nil}
	local make,label,button=ui.make,ui.label,ui.button
	local function page(name,height)
		local frame=make("Frame",name,body,{Size=UDim2.new(1,-6,0,height),BackgroundTransparency=1,Visible=false})
		self.pages[name]=frame;return frame
	end
	local pets=page("Pets",580)
	local petButtons={}
	local petIndex=0
	for _,item in ipairs(config.Catalog) do
		if item.category~="pet" then continue end
		local y=petIndex*172;petIndex+=1
		local preview=make("ViewportFrame",item.id.."Preview",pets,{Size=UDim2.fromOffset(98,106),Position=UDim2.fromOffset(0,y),BackgroundTransparency=1,
			Ambient=Color3.fromRGB(220,230,255),LightColor=Color3.fromRGB(255,250,230)})
		local world=make("WorldModel","PreviewWorld",preview)
		local model=PetBuilder.build(item.id);model.Parent=world
		local camera=make("Camera","PreviewCamera",preview,{CFrame=CFrame.lookAt(Vector3.new(3,1.8,-5),Vector3.new(0,0,0)),FieldOfView=36})
		preview.CurrentCamera=camera
		label(item.id.."Name",pets,item.name,UDim2.new(1,-104,0,30),UDim2.fromOffset(104,y),16)
		label(item.id.."Description",pets,item.description or "Cosmetic companion",UDim2.new(1,-104,0,74),UDim2.fromOffset(104,y+30),13)
		petButtons[item.id]=button(item.id,pets,item.price.." Pesos",UDim2.new(1,0,0,48),UDim2.fromOffset(0,y+112),function() request("Cosmetic",item.id) end)
	end
	button("UnequipPet",pets,"Unequip pet",UDim2.new(1,0,0,44),UDim2.fromOffset(0,524),function() request("UnequipPet") end)
	local chest=page("Chest",270)
	label("ChestTitle",chest,"FREE DAILY CHEST",UDim2.new(1,0,0,32),UDim2.fromOffset(0,0),17)
	label("ChestDetails",chest,"Permanent upgrade · no paid keys or resets. Missing a day never removes earned progress. Probability effect awaits confirmed rules.",UDim2.new(1,0,0,102),UDim2.fromOffset(0,36),14)
	local chestStatus=label("ChestStatus",chest,"",UDim2.new(1,0,0,76),UDim2.fromOffset(0,140),13)
	local claim=button("ClaimChest",chest,"Rules pending",UDim2.new(1,0,0,44),UDim2.fromOffset(0,220),function()
		if self.state and self.state.chest and self.state.chest.canClaim then request("ClaimChest") end
	end)
	local records=page("Records",820)
	label("TopPayoutTitle",records,"Highest payout — last 24 hours",UDim2.new(1,0,0,48),UDim2.fromOffset(0,0),17)
	local top=label("TopPayout",records,"Loading global payout records",UDim2.new(1,0,0,142),UDim2.fromOffset(0,50),14)
	label("RecentTitle",records,"Recent bonuses · this server",UDim2.new(1,0,0,42),UDim2.fromOffset(0,198),17)
	local recent=label("RecentBonuses",records,"No completed bonus events yet.",UDim2.new(1,0,0,570),UDim2.fromOffset(0,246),13)
	recent.TextYAlignment=Enum.TextYAlignment.Top
	recent.AutomaticSize=Enum.AutomaticSize.Y
	self.recordsText=recent
	label("PassTitle",settings,"PERMANENT AUTO MARK",UDim2.new(1,0,0,32),UDim2.fromOffset(0,410),16)
	local passStatus=label("PassStatus",settings,"Pass ID not configured",UDim2.new(1,0,0,86),UDim2.fromOffset(0,446),13)
	local buy=button("BuyAutoMark",settings,"Unavailable",UDim2.new(1,0,0,44),UDim2.fromOffset(0,540),function()
		local pass=self.state and self.state.pass
		if pass and pass.configured and not pass.owned and self.price and self.priceId==pass.id then
			pcall(function() Marketplace:PromptGamePassPurchase(Players.LocalPlayer,pass.id) end)
		end
	end)
	local toggle=button("ToggleAutoMark",settings,"Auto Mark · Off",UDim2.new(1,0,0,44),UDim2.fromOffset(0,590),function()
		if self.state and self.state.pass and self.state.pass.owned then request("Setting","autoMark",not self.state.settings.autoMark) end
	end)
	button("RefreshPass",settings,"Refresh pass ownership / price",UDim2.new(1,0,0,44),UDim2.fromOffset(0,640),function()
		self.priceId=nil;self.price=nil;request("RefreshPass")
	end)
	label("PassEffect",settings,"Marks called matching numbers only. Manual marking is free. Cards, draws, multipliers and bonus odds do not change.",UDim2.new(1,0,0,80),UDim2.fromOffset(0,692),13)
	function self:show(name)
		for key,frame in pairs(self.pages) do frame.Visible=key==name end
	end
	function self:render(state)
		self.state=state
		for _,item in ipairs(config.Catalog) do
			if item.category=="pet" then
				petButtons[item.id].Text=item.name.." · "..(if state.equipped.pet==item.id then "Equipped" elseif state.owned[item.id] then "Equip · owned" else item.price.." Pesos")
			end
		end
		local pass=state.pass
		if pass then
			if pass.configured and self.priceId~=pass.id then
				self.priceId,self.price=pass.id,nil
				task.spawn(function()
					local ok,info=pcall(function() return Marketplace:GetProductInfoAsync(pass.id,Enum.InfoType.GamePass) end)
					if self.priceId~=pass.id then return end
					self.price=if ok and info.IsForSale and type(info.PriceInRobux)=="number" then info.PriceInRobux else nil
					self:render(self.state)
				end)
			end
			buy.Text=if pass.owned then "Owned" elseif not pass.configured then "Pass ID not configured" elseif self.price then "Buy · "..self.price.." Robux" else "Platform price unavailable"
			passStatus.Text=pass.status..(if self.price and self.price~=pass.intendedPrice then "\nPrice differs from intended "..pass.intendedPrice.." Robux (regional pricing may apply)." else "\nIntended price: "..pass.intendedPrice.." Robux. Roblox confirms the final price.")
			toggle.Text="Auto Mark · "..(if state.settings.autoMark and pass.owned then "On" else "Off")..(if not pass.owned then " · pass required" else "")
		end
		local status=state.chest
		if status then
			chestStatus.Text=if not status.configured then status.reason elseif status.canClaim then "Your free chest is ready." else "Next claim: "..os.date("!%d %b %H:%M UTC",status.readyAt)
			claim.Text=if status.canClaim then "Claim free chest" elseif status.configured then "On cooldown" else "Rules pending"
		end
		local payout=state.topPayout
		if payout then
			local winner=payout.leader
			top.Text=if winner then winner.playerName.." · "..winner.pesos.." Pesos\n"..winner.source.." · "..winner.multiplier.."×\n"..os.date("!%d %b %H:%M:%S UTC",winner.at).."\n"..payout.status
				elseif string.sub(payout.status,1,7)=="Updated" then "No qualifying payouts in the last 24 hours." else payout.status
		end
		local lines={}
		for _,event in ipairs(state.recentBonuses or {}) do
			table.insert(lines,event.name.." · "..os.date("!%H:%M:%S UTC",event.at))
			for _,result in ipairs(event.results) do
				table.insert(lines,result.playerName.." · "..result.multiplier.."× · "..(if result.pesos>0 then "+" else "")..result.pesos.." Pesos")
			end
			table.insert(lines,"")
		end
		recent.Text=if #lines>0 then table.concat(lines,"\n") else "No completed bonus events yet."
		for _,message in ipairs(state.systemMessages or {}) do
			if message.serial>self.seenSerial then
				self.seenSerial=message.serial
				if os.time()-message.at<=30 then table.insert(self.queue,message.text) end
			end
		end
		while #self.queue>12 do table.remove(self.queue,1) end
	end
	function self:update(now)
		if #self.queue==0 or now<self.nextMessage then return end
		local channels=TextChatService:FindFirstChild("TextChannels")
		local channel=channels and (channels:FindFirstChild("RBXSystem") or channels:FindFirstChild("RBXGeneral"))
		if not channel then return end
		local message=table.remove(self.queue,1)
		local escaped=string.gsub(string.gsub(string.gsub(message,"&","&amp;"),"<","&lt;"),">","&gt;")
		channel:DisplaySystemMessage("[Cloudpop System] "..escaped)
		self.nextMessage=now+5
	end
	return self
end
return Features
