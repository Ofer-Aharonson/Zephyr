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

local forcedStand = {
	ERR_LOOT_NOTSTANDING,
	ERR_TAXINOTSTANDING,
	SPELL_FAILED_NOT_STANDING,
	ERR_NOT_WHILE_SITTING,
}

local campStand = {
	ERR_CANTATTACK_NOTSTANDING,
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

local function HasCampRest()
	if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then
		return false
	end
	for i = 1, 40 do
		local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
		if not aura then
			break
		end
		local name = type(aura.name) == "string" and aura.name:lower() or ""
		if name == "welcoming campfire" then
			return true
		end
	end
	return false
end

function Stand:Start()
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("UI_ERROR_MESSAGE")
	frame:SetScript("OnEvent", function(_, _, _, message)
		if not ns.db.stand.enabled or ns:Waits() then
			return
		end
		if Matches(mountErrors, message) then
			if IsMounted and IsMounted() then
				ns:Debug("dismount")
				Dismount()
			end
			return
		end
		local stand = Matches(forcedStand, message)
		if not stand and Matches(campStand, message) and not HasCampRest() then
			stand = true
		end
		if stand then
			ns:Debug("stand")
			if DoEmote then
				DoEmote("STAND")
			end
		elseif Matches(campStand, message) then
			ns:Debug("camp rest left sitting")
		end
	end)
end
