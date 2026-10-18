-- Injected MarketplaceService makes ownership checks testable without simulated purchases.
local Pass = {}
function Pass.new(marketplace, config, clock)
	local self={states={}}
	local function configured() return type(config.Id)=="number" and config.Id%1==0 and config.Id>0 end
	function self:check(player, force)
		local state=self.states[player] or {owned=false,checkedAt=-math.huge,status="Checking ownership"}
		self.states[player]=state
		if not configured() then state.status="Pass ID not configured"; return state end
		if state.checking or (not force and clock()-state.checkedAt<15) then return state end
		state.checking=true
		local ok,owned=pcall(function() return marketplace:UserOwnsGamePassAsync(player.UserId,config.Id) end)
		state.checking,state.checkedAt=false,clock()
		if ok then state.owned=owned==true;state.status=if owned then "Owned" else "Not owned"
		else state.status="Ownership check unavailable; retry shortly" end
		return state
	end
	function self:view(player)
		local state=self.states[player]
		return {id=config.Id,intendedPrice=config.IntendedPrice,configured=configured(),owned=state and state.owned==true,status=state and state.status or "Checking ownership"}
	end
	function self:owns(player) return self.states[player] and self.states[player].owned==true end
	function self:forget(player) self.states[player]=nil end
	return self
end
return Pass
