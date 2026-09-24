local _, ns = ...

local Delete = {}
ns.Delete = Delete

local POOR = (Enum.ItemQuality and Enum.ItemQuality.Poor) or 0

local function CursorQuality()
	local infoType, _, link = GetCursorInfo()
	if infoType ~= "item" or not link then
		return nil
	end
	return select(3, C_Item.GetItemInfo(link))
end

local function ConfirmGreyDelete()
	if not ns.db.delete.enabled or ns:Waits() then
		return
	end
	local quality = CursorQuality()
	if quality ~= POOR then
		return
	end
	for i = 1, STATICPOPUP_NUMDIALOGS or 4 do
		local popup = _G["StaticPopup" .. i]
		if popup and popup:IsShown() and popup.which and tostring(popup.which):find("DELETE", 1, true) then
			local edit = popup.editBox or (popup.GetEditBox and popup:GetEditBox()) or popup.EditBox or (popup.GetName and _G[popup:GetName() .. "EditBox"])
			if edit and edit.IsShown and edit:IsShown() and DELETE_ITEM_CONFIRM_STRING then
				edit:SetText(DELETE_ITEM_CONFIRM_STRING)
			end
			if popup.button1 and popup.button1:IsEnabled() then
				popup.button1:Click()
				ns:Debug("confirmed grey delete")
				return
			end
		end
	end
end

local function TryConfirm(tries)
	tries = tries or 0
	if CursorQuality() == nil and tries < 5 then
		C_Timer.After(0.2, function()
			TryConfirm(tries + 1)
		end)
		return
	end
	ConfirmGreyDelete()
end

function Delete:Start()
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("DELETE_ITEM_CONFIRM")
	frame:SetScript("OnEvent", function(_, _, _, quality)
		if quality == nil or quality == POOR or CursorQuality() == nil or CursorQuality() == POOR then
			C_Timer.After(0, function()
				TryConfirm(0)
			end)
		end
	end)

	hooksecurefunc("StaticPopup_Show", function(which)
		if which and tostring(which):find("DELETE", 1, true) then
			C_Timer.After(0, ConfirmGreyDelete)
		end
	end)
end
