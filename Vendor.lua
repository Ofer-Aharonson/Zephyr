local _, ns = ...

local Vendor = {}
ns.Vendor = Vendor

local POOR = (Enum.ItemQuality and Enum.ItemQuality.Poor) or 0
local FIRST_BAG = 0
local LAST_BAG = 4

local merchantOpen = false
local repairedThisVisit = false
local brokePrinted = false
local confirmHooked = false

local function ItemInfo(linkOrID)
	if not linkOrID then
		return
	end
	if C_Item and C_Item.GetItemInfo then
		return C_Item.GetItemInfo(linkOrID)
	end
	if GetItemInfo then
		return GetItemInfo(linkOrID)
	end
end

local function ContainerInfo(bag, slot)
	local info = C_Container.GetContainerItemInfo(bag, slot)
	if type(info) == "table" then
		return info
	end
	local link = C_Container.GetContainerItemLink(bag, slot)
	local itemID = C_Container.GetContainerItemID(bag, slot)
	if not itemID and not link then
		return nil
	end
	return { hyperlink = link, itemID = itemID }
end

local function IsBlizzardJunk(bag, slot)
	local info = ContainerInfo(bag, slot)
	if not info or info.isLocked then
		return false
	end
	local itemID = info.itemID
	local link = info.hyperlink
	if not itemID and link then
		itemID = tonumber(link:match("item:(%d+)"))
	end
	if not itemID or ns.db.vendor.neverSell[itemID] then
		return false
	end
	local name, _, quality, _, _, _, _, _, _, _, sellPrice = ItemInfo(link or itemID)
	quality = quality or info.quality
	if quality ~= POOR then
		return false
	end
	if info.hasNoValue then
		return false
	end
	if name and sellPrice and sellPrice <= 0 then
		return false
	end
	return true, itemID, link or name
end

function Vendor:Evaluate(bag, slot)
	local info = ContainerInfo(bag, slot)
	if not info then
		return false, "empty"
	end
	local itemID = info.itemID
	local link = info.hyperlink
	if not itemID and link then
		itemID = tonumber(link:match("item:(%d+)"))
	end
	if itemID and ns.db.vendor.alwaysSell[itemID] then
		local name, _, _, _, _, _, _, _, _, _, sellPrice = ItemInfo(link or itemID)
		if name and sellPrice and sellPrice > 0 then
			return true, "always-sell", itemID, link or name
		end
	end
	if IsBlizzardJunk(bag, slot) then
		return true, "junk", itemID, link
	end
	return false, "skip"
end

local function ClickIfReady(button)
	if not button or not button.IsShown or not button:IsShown() then
		return false
	end
	if button.IsEnabled and not button:IsEnabled() then
		return false
	end
	button:Click()
	return true
end

local function ConfirmJunkPopup()
	local needle = _G.SELL_ALL_JUNK_ITEMS_POPUP or _G.SELL_ALL_JUNK_ITEMS
	for i = 1, STATICPOPUP_NUMDIALOGS or 4 do
		local popup = _G["StaticPopup" .. i]
		if popup and popup:IsShown() and popup.button1 then
			local data = popup.data
			local text = popup.text and popup.text.GetText and popup.text:GetText()
			local match = false
			if type(data) == "table" and needle and data.text == needle then
				match = true
			elseif type(data) == "string" and needle and data == needle then
				match = true
			elseif text and needle and text:find(needle, 1, true) then
				match = true
			elseif popup.which and tostring(popup.which):find("JUNK", 1, true) then
				match = true
			end
			if match then
				popup.button1:Click()
				ns:Debug("confirmed sell-all-junk popup")
				return
			end
		end
	end
end

local function HookJunkConfirm()
	if confirmHooked then
		return
	end
	confirmHooked = true
	for i = 1, STATICPOPUP_NUMDIALOGS or 4 do
		local popup = _G["StaticPopup" .. i]
		if popup then
			popup:HookScript("OnShow", function()
				if ns.enabled.sell and merchantOpen then
					ConfirmJunkPopup()
					C_Timer.After(0, ConfirmJunkPopup)
				end
			end)
		end
	end
	hooksecurefunc("StaticPopup_Show", function(which)
		if merchantOpen and ns.enabled.sell and which and tostring(which):find("JUNK", 1, true) then
			ConfirmJunkPopup()
			C_Timer.After(0, ConfirmJunkPopup)
		end
	end)
end

local function SellBlizzardJunk()
	if C_MerchantFrame and C_MerchantFrame.SellAllJunkItems then
		local enabled = true
		if C_MerchantFrame.IsSellAllJunkEnabled then
			enabled = C_MerchantFrame.IsSellAllJunkEnabled()
		end
		if enabled then
			C_MerchantFrame.SellAllJunkItems()
			ns:Debug("SellAllJunkItems()")
			ConfirmJunkPopup()
			C_Timer.After(0, ConfirmJunkPopup)
			return true
		end
	end
	if ClickIfReady(_G.MerchantSellAllJunkButton) then
		ns:Debug("clicked MerchantSellAllJunkButton")
		ConfirmJunkPopup()
		C_Timer.After(0, ConfirmJunkPopup)
		return true
	end
	ns:Debug("blizzard junk sell not available")
	return false
end

local function SellAlwaysList()
	if not ns.enabled.sell then
		return
	end
	for bag = FIRST_BAG, LAST_BAG do
		local slots = C_Container.GetContainerNumSlots(bag) or 0
		for slot = 1, slots do
			local info = ContainerInfo(bag, slot)
			local itemID = info and info.itemID
			if itemID and ns.db.vendor.alwaysSell[itemID] and not ns.db.vendor.neverSell[itemID] then
				local name, _, quality, _, _, _, _, _, _, _, sellPrice = ItemInfo(info.hyperlink or itemID)
				if quality ~= POOR and name and sellPrice and sellPrice > 0 then
					ns:Debug("selling always-sell " .. (info.hyperlink or name))
					if C_Container.UseContainerItem then
						C_Container.UseContainerItem(bag, slot)
					end
				end
			end
		end
	end
end

function Vendor:RepairNow(quiet)
	if repairedThisVisit then
		return
	end
	if not ns.enabled.repair then
		ns:Debug("repair skipped: module off")
		return
	end
	if not merchantOpen then
		ns:Debug("repair skipped: merchant closed")
		return
	end

	local cost = GetRepairAllCost and (GetRepairAllCost() or 0) or 0
	if ClickIfReady(_G.MerchantRepairAllButton) then
		repairedThisVisit = true
		ns:Debug("clicked MerchantRepairAllButton cost=" .. tostring(cost))
		return
	end

	if CanMerchantRepair and not CanMerchantRepair() then
		ns:Debug("repair skipped: merchant cannot repair")
		return
	end
	if cost <= 0 then
		ns:Debug("repair skipped: nothing to repair")
		return
	end
	if GetMoney() < cost then
		if not quiet and not brokePrinted then
			brokePrinted = true
			local costText = GetCoinTextureString and GetCoinTextureString(cost) or tostring(cost)
			ns:Print("cannot afford repair (" .. costText .. ")")
		end
		ns:Debug("repair skipped: not enough gold, cost " .. cost)
		return
	end
	repairedThisVisit = true
	RepairAllItems()
	ns:Debug("RepairAllItems() cost=" .. cost)
end

local function StartVendorPass()
	if not merchantOpen then
		return
	end
	if IsShiftKeyDown() then
		ns:Debug("vendor pass skipped: shift")
		return
	end
	ns:RefreshEnabled()
	if not ns.enabled.sell and not ns.enabled.repair then
		ns:Debug("vendor pass skipped: sell and repair off")
		return
	end

	ns:Debug("vendor pass start sell=" .. tostring(ns.enabled.sell) .. " repair=" .. tostring(ns.enabled.repair))

	if ns.enabled.sell then
		SellBlizzardJunk()
		SellAlwaysList()
	end
	Vendor:RepairNow(true)
	C_Timer.After(0, function()
		if not merchantOpen then
			return
		end
		ConfirmJunkPopup()
		Vendor:RepairNow()
	end)
end

function Vendor:OnMerchantShow()
	if merchantOpen then
		return
	end
	merchantOpen = true
	repairedThisVisit = false
	brokePrinted = false
	HookJunkConfirm()
	ns:Debug("merchant opened")
	C_Timer.After(0, StartVendorPass)
end

function Vendor:OnMerchantClosed()
	merchantOpen = false
	ns:Debug("merchant closed")
	if ns.Marks then
		ns.Marks:Update()
	end
end

function Vendor:Start()
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("MERCHANT_SHOW")
	frame:RegisterEvent("MERCHANT_CLOSED")
	if Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.Merchant then
		frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
	end
	frame:SetScript("OnEvent", function(_, event, arg1)
		if event == "MERCHANT_SHOW" then
			self:OnMerchantShow()
		elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" and arg1 == Enum.PlayerInteractionType.Merchant then
			self:OnMerchantShow()
		elseif event == "MERCHANT_CLOSED" then
			self:OnMerchantClosed()
		end
	end)
end
