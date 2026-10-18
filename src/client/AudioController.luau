-- One looping music voice, one queued human-voice channel, four effect voices.
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local Audio = {}
function Audio.new(config, manifest)
	local music = Instance.new("Sound")
	music.Name, music.Looped, music.Volume, music.Parent = "CloudpopMusic", true, 0, SoundService
	local voice = Instance.new("Sound")
	voice.Name, voice.Volume, voice.Parent = "CloudpopVoice", 0.8, SoundService
	local effects = {}
	for index = 1, 4 do
		local sound = Instance.new("Sound")
		sound.Name, sound.Parent = "CloudpopEffect" .. index, SoundService
		effects[index] = sound
	end
	local self = { musicVolume = 0.5, voiceVolume = 0.8, sfxVolume = 0.7, track = nil, generation = 0, nextEffect = 0 }
	local fade, switching, speaking = nil, false, false
	local queue, lastId, current, subtitle = {}, 0, nil, ""
	local function asset(value)
		return if type(value) == "string" and string.match(value, "^rbxassetid://%d+$") then value else ""
	end
	local preloaded, ids, known = {}, {}, {}
	local function collect(id)
		id = asset(id)
		if id ~= "" and not known[id] then known[id] = true; table.insert(ids,id) end
	end
	for _, id in pairs(config.Music) do collect(id) end
	for _, id in pairs(config.SFX) do collect(id) end
	for _, entry in pairs(manifest or {}) do collect(entry.assetId) end
	if #ids > 0 then
		task.spawn(function()
			local ok = pcall(function()
				ContentProvider:PreloadAsync(ids,function(id,status)
					if status == Enum.AssetFetchStatus.Success then preloaded[id] = true end
				end)
			end)
			if not ok then warn("Cloudpop audio preload failed; unloaded voice cues use subtitles.") end
		end)
	end
	local function transition(volume)
		if fade then fade:Cancel() end
		fade = TweenService:Create(music, TweenInfo.new(0.25), { Volume = volume })
		fade:Play()
	end
	local function targetVolume()
		return if switching then 0 else self.musicVolume * (if speaking and self.voiceVolume > 0 then 0.22 else 1)
	end
	local function stopVoice()
		voice:Stop()
		speaking = false
		transition(targetVolume())
	end
	voice.Ended:Connect(function()
		speaking = false
		transition(targetVolume())
	end)
	function self:setVolumes(settings)
		local musicValue, voiceValue = settings.musicVolume or 0.5, settings.voiceVolume or 0.8
		local changed = self.musicVolume ~= musicValue or self.voiceVolume ~= voiceValue
		self.musicVolume, self.voiceVolume, self.sfxVolume = musicValue, voiceValue, settings.sfxVolume or 0.7
		voice.Volume = voiceValue
		if changed then transition(targetVolume()) end
	end
	function self:setTrack(key)
		-- With an unfilled bonus slot, a supplied lobby track continues rather than cutting to silence.
		if asset(config.Music[key]) == "" then key = "lobby" end
		if self.track == key then return end
		self.track, self.generation, switching = key, self.generation + 1, true
		local generation = self.generation
		transition(0)
		task.delay(0.26, function()
			if generation ~= self.generation then return end
			music:Stop()
			music.SoundId, switching = asset(config.Music[key]), false
			if music.SoundId == "" then return end -- Missing licensed track: do not invent one.
			music.Volume = 0
			music:Play()
			transition(targetVolume())
		end)
	end
	function self:play(key)
		local id = asset(config.SFX[key])
		if id == "" or self.sfxVolume == 0 then return end
		self.nextEffect = self.nextEffect % #effects + 1
		local sound = effects[self.nextEffect]
		sound:Stop()
		sound.SoundId, sound.Volume = id, self.sfxVolume
		sound:Play()
	end
	function self:announce(event, now)
		if not event or event.id <= lastId then return end
		lastId = event.id
		if now >= event.at + event.duration then return end -- Late joins do not replay old draws.
		if #queue < 8 then table.insert(queue, event) end
		self:update(now)
	end
	function self:update(now)
		if current and now >= current.at + current.duration then
			stopVoice()
			current, subtitle = nil, ""
		end
		while not current and #queue > 0 do
			local event = queue[1]
			if event.at > now then break end
			table.remove(queue, 1)
			if now >= event.at + event.duration then continue end
			current, subtitle = event, event.text
			local entry = manifest and manifest[event.key]
			local id = entry and asset(entry.assetId) or ""
			-- Start a fresh recording only near its reveal. Late arrivals get the correct subtitle.
			if id ~= "" and preloaded[id] and self.voiceVolume > 0 and now - event.at <= 0.5 then
				voice.SoundId, voice.TimePosition, voice.Volume = id, 0, self.voiceVolume
				speaking = true
				voice:Play()
				transition(targetVolume())
			end
		end
		return subtitle
	end
	return self
end
return Audio
