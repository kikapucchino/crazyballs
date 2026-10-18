-- The active economy uses exact bounded integers. Huge/signed bonus-ledger integration is pending.
local Rules={Window=86400}
function Rules.valid(record, now)
	return type(record)=="table" and type(record.id)=="string" and #record.id>0 and #record.id<=39
		and string.match(record.id,"^[%w_%-]+$")~=nil
		and type(record.userId)=="number" and record.userId%1==0 and record.userId>0
		and type(record.playerName)=="string" and #record.playerName<=30
		and string.match(record.playerName,"^[%w_]+$")~=nil
		and type(record.source)=="string" and #record.source>0 and #record.source<=60
		and type(record.multiplier)=="string" and #record.multiplier<=1025 and string.match(record.multiplier,"^%-?%d+$")~=nil
		and type(record.pesos)=="number" and record.pesos%1==0 and record.pesos>0 and record.pesos<=1000000000
		and type(record.at)=="number" and record.at%1==0 and record.at<=now and record.at>now-Rules.Window
		and record.test~=true
end
function Rules.better(a,b)
	if not b then return true end
	if a.pesos~=b.pesos then return a.pesos>b.pesos end
	if a.at~=b.at then return a.at<b.at end
	return a.id<b.id
end
function Rules.leader(records, now)
	local best,seen=nil,{}
	for _,record in ipairs(records) do
		if not seen[record.id] and Rules.valid(record,now) then
			seen[record.id]=true
			if Rules.better(record,best) then best=record end
		end
	end
	return best
end
return Rules
