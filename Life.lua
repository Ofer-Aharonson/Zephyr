local _, ns = ...

local Life = {}
ns.Life = Life

local function InBattleground()
	if UnitInBattleground and UnitInBattleground("player") then
		return true
	end
	if C_PvP then
		if C_PvP.IsBattleground and C_PvP.IsBattleground() then
			return true
		end
		if C_PvP.IsWarModeActive and C_PvP.IsWarModeActive() then
			return false
		end
	end
	return false
end

local function CanSelfResurrect()
	if HasSoulstone and HasSoulstone() then
		return true
	end
	return false
end

local function OnDeath()
	if not ns.db.life.releasePvP or ns:HoldSkip() then
		return
	end
	if not InBattleground() then
		ns:Debug("release skipped: not PvP")
		return
	end
	if CanSelfResurrect() then
		ns:Debug("release skipped: self-res available")
		return
	end
	ns:Debug("release in PvP")
	RepopMe()
end

local function OnResurrect(from)
	if not ns.db.life.acceptRes or ns:HoldSkip() then
		return
	end
	if InBattleground() then
		ns:Debug("rez skipped: PvP")
		return
	end
	if ns.db.life.skipCombatRes and from and UnitExists(from) and UnitAffectingCombat(from) then
		ns:Debug("rez skipped: combat rez from " .. tostring(from))
		return
	end
	ns:Debug("accept resurrect from " .. tostring(from))
	AcceptResurrect()
	if StaticPopup_Hide then
		StaticPopup_Hide("RESURRECT")
		StaticPopup_Hide("RESURRECT_NO_TIMER")
		StaticPopup_Hide("RESURRECT_NO_SICKNESS")
	end
end

function Life:Start()
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("PLAYER_DEAD")
	frame:RegisterEvent("RESURRECT_REQUEST")
	frame:SetScript("OnEvent", function(_, event, arg1)
		if event == "PLAYER_DEAD" then
			OnDeath()
		elseif event == "RESURRECT_REQUEST" then
			OnResurrect(arg1)
		end
	end)
end
