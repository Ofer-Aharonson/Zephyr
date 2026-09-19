local _, ns = ...

local Stand = {}
ns.Stand = Stand

local mountErrors = {
	ERR_NOT_WHILE_MOUNTED,
	ERR_ATTACK_MOUNTED,
	ERR_TAXIPLAYERALREADYMOUNTED,
	SPELL_FAILED_NOT_MOUNTED,
	ERR_MOUNT_LOOTING,
}

local standErrors = {
	ERR_LOOT_NOTSTANDING,
	ERR_TAXINOTSTANDING,
	SPELL_FAILED_NOT_STANDING,
	ERR_CANTATTACK_NOTSTANDING,
	ERR_NOT_WHILE_SITTING,
}

local function Matches(list, message)
	if not message then
		return false
	end
	for i = 1, #list do
		if list[i] and message == list[i] then
			return true
		end
	end
	return false
end

function Stand:Start()
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("UI_ERROR_MESSAGE")
	frame:SetScript("OnEvent", function(_, _, _, message)
		if not ns.db.stand.enabled then
			return
		end
		if Matches(mountErrors, message) then
			if IsMounted and IsMounted() then
				ns:Debug("dismount")
				Dismount()
			end
			return
		end
		if Matches(standErrors, message) then
			ns:Debug("stand")
			if DoEmote then
				DoEmote("STAND")
			end
		end
	end)
end
