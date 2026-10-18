-- One music voice with sequential fade-out/fade-in; effects use a small reusable pool.
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Audio = {}
function Audio.new(config)
	local music = Instance.new("Sound")
	music.Name, music.Looped, music.Volume, music.Parent = "CloudpopMusic", true, 0, SoundService
	local effects = {}
	for index = 1, 4 do
		local sound = Instance.new("Sound")
		sound.Name, sound.Parent = "CloudpopEffect" .. index, SoundService
		effects[index] = sound
	end
	local self = { musicVolume = 0.5, sfxVolume = 0.7, track = nil, generation = 0, nextEffect = 0 }
	local fade
	local function transition(volume)
		if fade then fade:Cancel() end
		fade = TweenService:Create(music, TweenInfo.new(0.35), { Volume = volume })
		fade:Play()
	end
	local function asset(value)
		if type(value) == "string" and string.match(value, "^rbxassetid://%d+$") then return value end
		return ""
	end
	function self:setVolumes(settings)
		self.musicVolume, self.sfxVolume = settings.musicVolume or 0.5, settings.sfxVolume or 0.7
		if music.IsPlaying then transition(self.musicVolume) end
	end
	function self:setTrack(key)
		if self.track == key then return end
		self.track, self.generation = key, self.generation + 1
		local generation = self.generation
		transition(0)
		task.delay(0.36, function()
			if generation ~= self.generation then return end
			music:Stop()
			music.SoundId = asset(config.Music[key])
			if music.SoundId == "" then return end -- explicitly empty licensed-audio slot
			music.Volume = 0
			music:Play()
			transition(self.musicVolume)
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
	return self
end
return Audio
