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

local function SelectGossipQuests()
	local active = GossipTable(C_GossipInfo.GetActiveQuests)
	for _, quest in ipairs(active) do
		if quest.isComplete and quest.questID then
			ns:Debug("gossip select complete quest " .. quest.questID)
			C_GossipInfo.SelectActiveQuest(quest.questID)
			return true
		end
	end

	local available = GossipTable(C_GossipInfo.GetAvailableQuests)
	if #available == 1 and #active == 0 and available[1].questID then
		ns:Debug("gossip select only available quest " .. available[1].questID)
		C_GossipInfo.SelectAvailableQuest(available[1].questID)
		return true
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
	if #options == 1 and #available == 0 and #active == 0 then
		local option = options[1]
		if option.gossipOptionID then
			ns:Debug("gossip select only option " .. option.gossipOptionID)
			C_GossipInfo.SelectOption(option.gossipOptionID)
		elseif GossipFrame and GossipFrame.SelectGossipOption then
			GossipFrame:SelectGossipOption(1)
		end
	end
end

local function OnGossip()
	if ns:HoldSkip() then
		return
	end
	if ns.db.quest.enabled and SelectGossipQuests() then
		return
	end
	SelectSingleGossip()
end

local function OnGreeting()
	if not ns.db.quest.enabled or ns:HoldSkip() then
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
	if GetNumAvailableQuests() == 1 then
		ns:Debug("greeting select only available quest")
		SelectAvailableQuest(1)
	end
end

local function OnDetail()
	if not ns.db.quest.enabled or ns:HoldSkip() then
		return
	end
	if QuestGetAutoAccept and QuestGetAutoAccept() then
		CloseQuest()
		return
	end
	ns:Debug("accept quest")
	AcceptQuest()
end

local function OnConfirm()
	if not ns.db.quest.enabled or ns:HoldSkip() then
		return
	end
	ns:Debug("confirm shared quest")
	ConfirmAcceptQuest()
	if StaticPopup_Hide then
		StaticPopup_Hide("QUEST_ACCEPT")
	end
end

local function OnProgress()
	if not ns.db.quest.enabled or ns:HoldSkip() then
		return
	end
	if IsQuestCompletable and IsQuestCompletable() then
		ns:Debug("complete quest progress")
		CompleteQuest()
	end
end

local function OnComplete()
	if not ns.db.quest.enabled or ns:HoldSkip() then
		return
	end
	local choices = GetNumQuestChoices() or 0
	if choices <= 1 then
		ns:Debug("turn in quest choices=" .. choices)
		GetQuestReward(choices)
	else
		ns:Debug("quest reward picker left for you")
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
	frame:SetScript("OnEvent", function(_, event)
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
