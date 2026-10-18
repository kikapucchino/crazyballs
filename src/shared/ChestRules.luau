-- Claim bookkeeping only; the probability effect remains separately disabled.
local Chest = {}
function Chest.configured(config)
	return config.ClaimRulesConfirmed == true and (config.ResetMode == "rolling" or config.ResetMode == "fixed")
		and config.RewardMode == "fixed" and type(config.RewardUnits) == "number" and config.RewardUnits % 1 == 0
		and config.RewardUnits > 0 and config.RewardUnits <= 1000
end
function Chest.status(data, config, now)
	if not Chest.configured(config) then return { configured=false, canClaim=false, reason="Chest reward and reset rules await confirmation." } end
	local key = if config.ResetMode == "rolling" then tostring(data.lastClaimAt) else tostring(math.floor((now-(config.ResetOffsetSeconds or 0))/86400))
	local readyAt = if config.ResetMode == "rolling" then data.lastClaimAt+86400 else (math.floor((now-(config.ResetOffsetSeconds or 0))/86400)+1)*86400+(config.ResetOffsetSeconds or 0)
	local available = data.claims == 0 or (if config.ResetMode == "rolling" then now>=readyAt else data.lastClaimKey~=key)
	return {configured=true,canClaim=available,readyAt=if available then now else readyAt,key=key,claims=data.claims,units=data.rewardUnits}
end
function Chest.claim(data, config, now)
	local status=Chest.status(data,config,now)
	if not status.canClaim then return false,status.reason or "Your free chest is on cooldown." end
	-- No yield between eligibility and receipt update: duplicate remote requests cannot both grant.
	data.lastClaimAt,data.lastClaimKey=now,status.key
	data.claims+=1
	data.rewardUnits+=config.RewardUnits
	return true,"Free chest claimed."
end
return Chest
