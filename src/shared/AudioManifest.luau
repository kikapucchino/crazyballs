-- Supply ONLY actual licensed recordings of a consenting human voice.
-- Empty assetId means subtitles only. Duration includes the whole clip and must be <= 3 seconds.
-- Trim leading silence: the called number should begin when the ball appears.
local manifest = {
	upcoming = { assetId = "", duration = 2.5, text = "Your next round begins in fifteen seconds." },
	start = { assetId = "", duration = 1.5, text = "Let's begin! Watch for your numbers." },
	lastCall = { assetId = "", duration = 2.5, text = "All twenty numbers are called. Finish your marks." },
	results = { assetId = "", duration = 2.5, text = "Round complete. Here are your results." },
	coin = { assetId = "", duration = 2, text = "Coin flip is beginning!" },
	duck = { assetId = "", duration = 2, text = "Duck hunt is beginning!" },
	pacinki = { assetId = "", duration = 2, text = "Pačinki is beginning!" },
	crazy = { assetId = "", duration = 2, text = "Go CRazy is beginning!" },
}
for number = 1, 60 do
	manifest["number_" .. number] = { assetId = "", duration = 1.5, text = "Number " .. number .. "." }
end
return manifest
