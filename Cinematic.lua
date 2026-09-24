local _, ns = ...

local Cinematic = {}
ns.Cinematic = Cinematic

local function SkipCinematic()
	if not ns.db.cinematic.enabled or ns:Waits() then
		return
	end
	if CinematicFrame and CinematicFrame.isRealCinematic then
		if StopCinematic then
			ns:Debug("stop cinematic")
			StopCinematic()
		end
	elseif CanCancelScene and CanCancelScene() then
		ns:Debug("cancel scene")
		CancelScene()
	end
end

local function SkipMovie()
	if not ns.db.cinematic.enabled or ns:Waits() then
		return
	end
	if MovieFrame then
		MovieFrame:Hide()
		ns:Debug("hide movie")
	end
end

local function HideTalkingHead(frame)
	if not ns.db.cinematic.enabled or ns:Waits() then
		return
	end
	if frame and frame.Hide then
		frame:Hide()
		ns:Debug("hide talking head")
	end
end

local talkingHooked = false

local function HookTalkingHead()
	if talkingHooked or not TalkingHeadFrame then
		return
	end
	talkingHooked = true
	if TalkingHeadFrame.PlayCurrent then
		hooksecurefunc(TalkingHeadFrame, "PlayCurrent", function(self)
			HideTalkingHead(self)
		end)
	end
	TalkingHeadFrame:HookScript("OnShow", function(self)
		HideTalkingHead(self)
	end)
end

function Cinematic:Start()
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("CINEMATIC_START")
	frame:RegisterEvent("PLAY_MOVIE")
	frame:RegisterEvent("ADDON_LOADED")
	frame:SetScript("OnEvent", function(_, event, name)
		if event == "CINEMATIC_START" then
			SkipCinematic()
		elseif event == "PLAY_MOVIE" then
			SkipMovie()
		elseif event == "ADDON_LOADED" and name == "Blizzard_TalkingHeadUI" then
			HookTalkingHead()
		end
	end)
	HookTalkingHead()
end
