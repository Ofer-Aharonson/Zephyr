local _, ns = ...

local Quest = {}
ns.Quest = Quest

local function GossipTable(getter)
	if not getter then
		return {}
	end
	local ok, result = pcall(getter)
	if ok and type(result) == "table" then
		return result
	end
	return {}
end

local SAFE_TYPES = {
	vendor = true,
	trainer = true,
	binder = true,
	banker = true,
	innkeeper = true,
	mailbox = true,
	mail = true,
	stable = true,
	stablemaster = true,
}

local DENY_TYPES = {
	taxi = true,
	battlemaster = true,
	healer = true,
	spirithealer = true,
}

local SAFE_ICON_INDEX = {
	[1] = true,
	[3] = true,
	[5] = true,
	[6] = true,
}

local DENY_ICON_INDEX = {
	[2] = true,
	[4] = true,
	[9] = true,
}

local SAFE_ICON_PATHS = {
	"Interface\\GossipFrame\\VendorGossipIcon",
	"Interface\\GossipFrame\\TrainerGossipIcon",
	"Interface\\GossipFrame\\BinderGossipIcon",
	"Interface\\GossipFrame\\BankerGossipIcon",
	"Interface\\GossipFrame\\InnGossipIcon",
	"Interface\\GossipFrame\\InnkeeperGossipIcon",
	"Interface\\GossipFrame\\MailboxGossipIcon",
	"Interface\\GossipFrame\\MailGossipIcon",
	"Interface\\GossipFrame\\StableGossipIcon",
	"Interface\\GossipFrame\\StablemasterGossipIcon",
}

local safeFileIDs

local function SafeFileIDs()
	if safeFileIDs then
		return safeFileIDs
	end
	safeFileIDs = {}
	if GetFileIDFromPath then
		for i = 1, #SAFE_ICON_PATHS do
			local path = SAFE_ICON_PATHS[i]
			local fileID = GetFileIDFromPath(path) or GetFileIDFromPath(path .. ".blp")
			if fileID then
				safeFileIDs[fileID] = true
			end
		end
	end
	return safeFileIDs
end

local function IsDenied(option)
	local kind = option.type
	if type(kind) == "string" and DENY_TYPES[kind:lower()] then
		return true
	end
	local icon = option.icon
	if type(icon) == "number" and icon <= 20 and DENY_ICON_INDEX[icon] then
		return true
	end
	return false
end

local function IsSafeService(option)
	if IsDenied(option) then
		return false
	end
	local kind = option.type or option.icon
	if type(kind) == "string" and SAFE_TYPES[kind:lower()] then
		return true
	end
	local icon = option.icon
	if type(icon) ~= "number" then
		icon = option.overrideIconID
	end
	if type(icon) ~= "number" then
		return false
	end
	if icon <= 20 and SAFE_ICON_INDEX[icon] then
		return true
	end
	if SafeFileIDs()[icon] then
		return true
	end
	if type(option.overrideIconID) == "number" and SafeFileIDs()[option.overrideIconID] then
		return true
	end
	return false
end

local goldStop = false

local function QuestWantsGold()
	return GetQuestMoneyToGet and (GetQuestMoneyToGet() or 0) > 0
end

local function SelectGossipQuests()
	local active = GossipTable(C_GossipInfo.GetActiveQuests)
	for _, quest in ipairs(active) do
		if quest.isComplete and quest.questID then
			ns:Debug("gossip select complete quest " .. quest.questID)
			C_GossipInfo.SelectActiveQuest(quest.questID)
			return true
		end
	end
	return false
end

local function SelectSingleGossip()
	if not ns.db.gossip.enabled then
		return
	end
	local options = GossipTable(C_GossipInfo.GetOptions)
	local available = GossipTable(C_GossipInfo.GetAvailableQuests)
	local active = GossipTable(C_GossipInfo.GetActiveQuests)
	if #options ~= 1 or #available > 0 or #active > 0 then
		return
	end
	local option = options[1]
	if not IsSafeService(option) then
		ns:Debug("gossip left up")
		return
	end
	if option.gossipOptionID then
		ns:Debug("gossip select service " .. option.gossipOptionID)
		C_GossipInfo.SelectOption(option.gossipOptionID)
	elseif GossipFrame and GossipFrame.SelectGossipOption then
		GossipFrame:SelectGossipOption(1)
	end
end

local function OnGossip()
	if ns:Waits() then
		return
	end
	if goldStop then
		ns:Debug("quest chain stopped: gold")
		return
	end
	if ns.db.quest.enabled and SelectGossipQuests() then
		return
	end
	SelectSingleGossip()
end

local function OnGreeting()
	if not ns.db.quest.enabled or ns:Waits() or goldStop then
		return
	end
	for i = 1, GetNumActiveQuests() do
		local _, isComplete = GetActiveTitle(i)
		if isComplete then
			ns:Debug("greeting select complete quest " .. i)
			SelectActiveQuest(i)
			return
		end
	end
end

local function OnDetail()
	ns:Debug("quest offer left up")
end

local function OnConfirm()
	ns:Debug("shared quest left up")
end

local function OnProgress()
	if not ns.db.quest.enabled or ns:Waits() then
		return
	end
	if QuestWantsGold() then
		goldStop = true
		ns:Debug("quest left up: costs gold")
		return
	end
	if IsQuestCompletable and IsQuestCompletable() then
		ns:Debug("complete quest progress")
		CompleteQuest()
	end
end

local function OnComplete()
	if not ns.db.quest.enabled or ns:Waits() then
		return
	end
	if QuestWantsGold() then
		goldStop = true
		ns:Debug("quest left up: costs gold")
		return
	end
	local choices = GetNumQuestChoices() or 0
	if choices > 1 then
		ns:Debug("quest reward picker left for you")
		return
	end
	ns:Debug("turn in quest choices=" .. choices)
	if choices == 1 then
		GetQuestReward(1)
	else
		GetQuestReward()
	end
end

function Quest:Start()
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("GOSSIP_SHOW")
	frame:RegisterEvent("QUEST_GREETING")
	frame:RegisterEvent("QUEST_DETAIL")
	frame:RegisterEvent("QUEST_ACCEPT_CONFIRM")
	frame:RegisterEvent("QUEST_PROGRESS")
	frame:RegisterEvent("QUEST_COMPLETE")
	frame:RegisterEvent("GOSSIP_CLOSED")
	frame:RegisterEvent("QUEST_FINISHED")
	frame:SetScript("OnEvent", function(_, event)
		if event == "GOSSIP_CLOSED" then
			goldStop = false
			return
		end
		if event == "QUEST_FINISHED" then
			local gossipUp = GossipFrame and GossipFrame.IsShown and GossipFrame:IsShown()
			local questUp = QuestFrame and QuestFrame.IsShown and QuestFrame:IsShown()
			if not gossipUp and not questUp then
				goldStop = false
			end
			return
		end
		if event == "GOSSIP_SHOW" then
			OnGossip()
		elseif event == "QUEST_GREETING" then
			OnGreeting()
		elseif event == "QUEST_DETAIL" then
			OnDetail()
		elseif event == "QUEST_ACCEPT_CONFIRM" then
			OnConfirm()
		elseif event == "QUEST_PROGRESS" then
			OnProgress()
		elseif event == "QUEST_COMPLETE" then
			OnComplete()
		end
	end)
end
