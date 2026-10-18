local Marketplace=game:GetService("MarketplaceService")
local Players=game:GetService("Players")
local Shop={}
function Shop.new(parent,ui,config,request)
	local root=ui.make("Frame","Robux",parent,{Size=UDim2.new(1,-6,0,740),BackgroundTransparency=1,Visible=false})
	local self={root=root,state=nil,rows={}}
	local items={}
	for _,item in ipairs(config.Catalog) do if item.payment=="Robux" then table.insert(items,item) end end
	table.insert(items,{id="auto",name="Auto Mark",description="Permanent toggle for both main and bonus cards. Marks called matches; cards, multipliers and draws are unchanged."})
	self.height=#items*198+146
	root.Size=UDim2.new(1,-6,0,self.height)
	for index,item in ipairs(items) do
		local y=(index-1)*198
		local preview=ui.label(item.id.."Preview",root,item.glyph or "✓",UDim2.fromOffset(44,44),UDim2.fromOffset(0,y),32)
		if item.color then preview.TextColor3=Color3.fromRGB(table.unpack(item.color)) end
		ui.label(item.id.."Title",root,item.name,UDim2.new(1,-52,0,44),UDim2.fromOffset(52,y),16)
		ui.label(item.id.."Description",root,item.description,UDim2.new(1,0,0,64),UDim2.fromOffset(0,y+46),13)
		local status=ui.label(item.id.."Status",root,"Unavailable",UDim2.new(1,0,0,32),UDim2.fromOffset(0,y+110),12)
		local row={item=item,status=status}
		row.button=ui.button("Premium"..item.id,root,"Unavailable",UDim2.new(1,0,0,44),UDim2.fromOffset(0,y+146),function()
			local state=self.state;if not state then return end
			local pass=if item.id=="auto" then state.pass else state.premium and state.premium[item.id]
			if not pass then return end
			if pass.owned then
				if item.id=="auto" then request("Setting","autoMark",not state.settings.autoMark) else request("PremiumEquip",item.id) end
			elseif pass.configured and row.price and row.passId==pass.id then
				pcall(function() Marketplace:PromptGamePassPurchase(Players.LocalPlayer,pass.id) end)
			end
		end)
		self.rows[item.id]=row
	end
	ui.button("RefreshPremium",root,"Refresh ownership and prices",UDim2.new(1,0,0,44),UDim2.fromOffset(0,#items*198+10),function()
		for _,row in pairs(self.rows) do row.passId=nil;row.price=nil end
		request("RefreshPass")
	end)
	ui.label("BonusOffer",root,"Three-bonus offer unavailable. Its rules and purchase setup are not confirmed.",UDim2.new(1,0,0,74),UDim2.fromOffset(0,#items*198+62),13)
	function self:render(state)
		self.state=state
		for id,row in pairs(self.rows) do
			local pass=if id=="auto" then state.pass else state.premium and state.premium[id]
			if not pass then continue end
			if pass.configured and row.passId~=pass.id then
				row.passId,row.price=pass.id,nil
				task.spawn(function()
					local ok,info=pcall(function() return Marketplace:GetProductInfoAsync(pass.id,Enum.InfoType.GamePass) end)
					if row.passId~=pass.id then return end
					row.price=if ok and info.IsForSale and type(info.PriceInRobux)=="number" then info.PriceInRobux else nil
					self:render(self.state)
				end)
			end
			row.status.Text=pass.status..(if id=="auto" and row.price and row.price~=60 then " · price differs from intended 60 Robux" else "")
			row.button.Text=if pass.owned then (if id=="auto" then "Auto Mark · "..(if state.settings.autoMark then "On" else "Off") else "Equip · owned")
				elseif row.price then "Buy · "..row.price.." Robux" else "Unavailable · no platform price"
		end
	end
	return self
end
return Shop
