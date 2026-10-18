-- Durable transaction metadata + two UTC-day ordered indexes. Never aggregates players.
-- Injected services keep query/tie/expiry/retry behavior testable.
local Store={}
function Store.new(dataStoreService, rules, clock)
	local records=dataStoreService:GetDataStore("CloudpopPayoutTransactions_v1")
	local self={}
	local function index(day) return dataStoreService:GetOrderedDataStore("CloudpopPayoutDay_v1_"..day) end
	local function key(record) return string.format("%010d:%s",record.at,record.id) end
	function self:put(record)
		if not rules.valid(record,clock()) then return false,"Ineligible payout" end
		local ok,result=pcall(function()
			local persisted=records:UpdateAsync(record.id,function(old)
				if old then return old end
				return table.clone(record)
			end)
			if not persisted or persisted.userId~=record.userId or persisted.at~=record.at or persisted.pesos~=record.pesos
				or persisted.multiplier~=record.multiplier or persisted.source~=record.source or persisted.playerName~=record.playerName then
				error("Conflicting payout transaction ID")
			end
			index(math.floor(record.at/86400)):SetAsync(key(record),record.pesos)
			return true
		end)
		return ok and result==true, if ok then nil else tostring(result)
	end
	function self:read(id)
		local ok,result=pcall(function() return records:GetAsync(id) end)
		return if ok and rules.valid(result,clock()) then result else nil
	end
	function self:leader(at)
		local now,best=at or clock(),nil
		local ok,problem=pcall(function()
			for day=math.floor((now-86400)/86400),math.floor(now/86400) do
				local pages=index(day):GetSortedAsync(false,100,1)
				local candidate,done=nil,false
				local pageCount=0
				repeat
					pageCount+=1
					assert(pageCount<=20,"Payout query page budget reached; retrying")
					for _,entry in ipairs(pages:GetCurrentPage()) do
						local timestamp,id=string.match(entry.key,"^(%d+):([%w_%-]+)$")
						local at=tonumber(timestamp)
						if candidate and entry.value<candidate.pesos then done=true;break end
						if at and at>now-86400 and at<=now then
							local contender={id=id,at=at,pesos=entry.value}
							if rules.better(contender,candidate) then candidate=contender end
						end
					end
					if pages.IsFinished or done then break end
					-- Query work runs in a background coroutine; throttling fails closed and retries later.
					pages:AdvanceToNextPageAsync()
				until false
				if candidate then
					local record=records:GetAsync(candidate.id)
					assert(rules.valid(record,now) and record.id==candidate.id and record.pesos==candidate.pesos and record.at==candidate.at,"Incomplete payout metadata")
					if rules.better(record,best) then best=record end
				end
			end
		end)
		return if ok then best else nil, if ok then nil else tostring(problem)
	end
	function self:claimAnnouncement(id, token)
		local now=clock()
		local candidate=self:read(id)
		if not candidate or now-candidate.at>120 then return false end
		-- A replacement caused by expiry is not a newly awarded record.
		local atAward,problem=self:leader(candidate.at)
		if problem or not atAward or atAward.id~=id then return false end
		local ok,result=pcall(function()
			return records:UpdateAsync(id,function(old)
				if not rules.valid(old,now) or now-old.at>120 then return nil end
				if old.announcementToken then return old end
				local updated=table.clone(old);updated.announcementToken=token
				return updated
			end)
		end)
		return ok and result~=nil and result.announcementToken==token
	end
	return self
end
return Store
