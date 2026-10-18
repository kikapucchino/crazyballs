-- Cosmetic-only local animation: sixteen anchored balls, capped at 30 updates/sec.
-- Server snapshots control the displayed draw; this module never selects an outcome.
local RunService = game:GetService("RunService")
local Effects = {}
function Effects.new()
	local state, previousCount, elapsed, drawAt = nil, 0, 0, -100
	local balls, emerged, display, viewing, lastSecond
	local self = {}
	function self:update(snapshot)
		if snapshot.roundId ~= (state and state.roundId) then previousCount = 0 end
		if #snapshot.history > previousCount then
			drawAt = workspace:GetServerTimeNow()
			previousCount = #snapshot.history
		end
		state = snapshot
	end
	RunService.RenderStepped:Connect(function(delta)
		elapsed += delta
		if elapsed < 1 / 30 or not state then return end
		elapsed = 0
		if not balls then
			local model = workspace:FindFirstChild("CloudpopWorkshop")
			if not model then return end
			balls = {}
			for index = 1, 16 do
				local ball = model:FindFirstChild("DecorativeBall" .. index)
				if ball then table.insert(balls, ball) end
			end
			if #balls ~= 16 then balls = nil; return end
			emerged = model:FindFirstChild("DrawnBall")
			display,viewing=model:FindFirstChild("DrawDisplay"),model:FindFirstChild("ViewingDisplay")
		end
		local now = workspace:GetServerTimeNow()
		if state.phase == "Intermission" then
			local seconds = math.max(0,math.ceil(state.deadline-now))
			if seconds ~= lastSecond then
				for _,screen in ipairs({display,viewing}) do
					if screen then screen.Readout.Text.Text="NEXT ROUND IN "..seconds.."\n0 / 20" end
				end
				lastSecond=seconds
			end
		else lastSecond=nil end
		local reduced = state.settings.reducedMotion
		local moving = state.phase == "Drawing" and not reduced
		local time = if moving then now else 0
		for index, ball in ipairs(balls) do
			local angle = index * math.pi / 8 + time * (0.6 + index % 3 * 0.1)
			ball.Position = Vector3.new(math.cos(angle) * 3, 8.7 + math.sin(time * 1.8 + index * 1.7) * 2.1, -40 + math.sin(angle) * 3)
		end
		if emerged then
			local progress = math.clamp((now - drawAt) / 0.8, 0, 1)
			emerged.Position = Vector3.new(0, 6 + (if reduced then 0 else math.sin(progress * math.pi) * 3), -33)
		end
	end)
	return self
end
return Effects
