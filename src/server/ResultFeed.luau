-- Only trusted award/bonus-completion code may call these methods. No client result remote exists.
local Feed={}
function Feed.new(clock)
	local self={recent={},messages={},seen={},seenOrder={},serial=0}
	function self:message(text,id)
		if self.seen[id] then return end
		self.seen[id]=true
		table.insert(self.seenOrder,id)
		if #self.seenOrder>256 then self.seen[table.remove(self.seenOrder,1)]=nil end
		self.serial+=1
		table.insert(self.messages,{id=id,serial=self.serial,text=text,at=clock()})
		while #self.messages>12 do table.remove(self.messages,1) end
	end
	function self:completeBonus(event)
		if self.seen["bonus:"..event.id] then return false end
		assert(type(event.results)=="table" and #event.results>0,"No confirmed results")
		-- Call only AFTER every listed result has actually been credited/debited.
		local recipients={}
		for _,result in ipairs(event.results) do
			assert(result.committed==true and type(result.pesos)=="number" and result.pesos==result.pesos and math.abs(result.pesos)<math.huge,"Uncommitted result")
			table.insert(recipients,result.playerName..": "..result.multiplier.."×, "..(if result.pesos>0 then "+" else "")..result.pesos.." Pesos")
		end
		table.insert(self.recent,1,{id=event.id,name=event.name,at=event.at,results=event.results})
		while #self.recent>4 do table.remove(self.recent) end
		local text=event.name.." completed — "..table.concat(recipients,"; ")
		if #text>400 then text=event.name.." completed for "..#recipients.." players. Full signed results in Records." end
		self:message(text,"bonus:"..event.id)
		return true
	end
	function self:record(record)
		self:message("Highest payout — last 24 hours: "..record.playerName.." received "..record.pesos.." Pesos from "..record.source.." ("..record.multiplier.."×).","record:"..record.id)
	end
	return self
end
return Feed
