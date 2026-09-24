local _, ns = ...

local Vendor = {}
ns.Vendor = Vendor

local POOR = (Enum.ItemQuality and Enum.ItemQuality.Poor) or 0
local FIRST_BAG = 0
local LAST_BAG = 4

local merchantOpen = false
local repairedThisVisit = false
local brokePrinted = false
local sellHalted = false
local sellWaves = 0

local function PaceSell(sellOne)
	sellWaves = sellWaves + 1
	local tries = 0
	local function step()
		if not merchantOpen or sellHalted or tries >= 40 then
			sellWaves = sellWaves - 1
			return
		end
		tries = tries + 1
		if sellOne() then
			C_Timer.After(0.2, step)
		else
			sellWaves = sellWaves - 1
		end
	end
	step()
end

local function WhenSellingDone(done)
	if sellWaves > 0 and merchantOpen then
		C_Timer.After(0.2, function()
			WhenSellingDone(done)
		end)
		return
	end
	C_Timer.After(0.6, done)
end
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

local function BagHasKeptPoor()
	for bag = FIRST_BAG, LAST_BAG do
		local slots = C_Container.GetContainerNumSlots(bag) or 0
		for slot = 1, slots do
			local info = ContainerInfo(bag, slot)
			local itemID = info and info.itemID
			if itemID and ns.db.vendor.neverSell[itemID] then
				local _, _, quality = ItemInfo(info.hyperlink or itemID)
				quality = quality or info.quality
				if quality == nil or quality == POOR then
					return true
				end
			end
		end
	end
	return false
end

local function SellOneKeptSafeJunk()
	for bag = FIRST_BAG, LAST_BAG do
		local slots = C_Container.GetContainerNumSlots(bag) or 0
		for slot = 1, slots do
			if IsBlizzardJunk(bag, slot) then
				if C_Container.UseContainerItem then
					C_Container.UseContainerItem(bag, slot)
				end
				return true
			end
		end
	end
	return false
end

local function SellJunkRespectingKeep()
	PaceSell(SellOneKeptSafeJunk)
end

local function SellBlizzardJunk()
	if BagHasKeptPoor() then
		ns:Debug("selling junk around the keep list")
		SellJunkRespectingKeep()
		return true
	end
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

local function CoinText(amount)
	amount = math.floor(tonumber(amount) or 0)
	if amount < 0 then
		amount = 0
	end
	if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then
		local coins = C_CurrencyInfo.GetCoinTextureString(amount)
		if coins and coins ~= "" then
			return coins
		end
	end
	local gold = math.floor(amount / 10000)
	local silver = math.floor((amount % 10000) / 100)
	local copper = amount % 100
	local parts = {}
	if gold > 0 then
		parts[#parts + 1] = gold .. " gold"
	end
	if silver > 0 then
		parts[#parts + 1] = silver .. " silver"
	end
	if copper > 0 or #parts == 0 then
		parts[#parts + 1] = copper .. " copper"
	end
	return table.concat(parts, " ")
end

local function PlannedSales()
	local grouped = {}
	local order = {}
	local function add(itemID, label, count)
		if not grouped[itemID] then
			grouped[itemID] = { label = label, count = 0 }
			order[#order + 1] = itemID
		end
		grouped[itemID].count = grouped[itemID].count + (count or 1)
	end
	for bag = FIRST_BAG, LAST_BAG do
		local slots = C_Container.GetContainerNumSlots(bag) or 0
		for slot = 1, slots do
			local info = ContainerInfo(bag, slot)
			local junk, itemID, label = IsBlizzardJunk(bag, slot)
			if junk and itemID then
				add(itemID, label or ns:ItemLabel(itemID), info and info.stackCount or 1)
			elseif info and info.itemID and ns.db.vendor.alwaysSell[info.itemID] and not ns.db.vendor.neverSell[info.itemID] then
				local name, _, quality, _, _, _, _, _, _, _, sellPrice = ItemInfo(info.hyperlink or info.itemID)
				if quality ~= POOR and name and sellPrice and sellPrice > 0 then
					add(info.itemID, info.hyperlink or name, info.stackCount or 1)
				end
			end
		end
	end
	local parts = {}
	local shown = math.min(#order, 8)
	for i = 1, shown do
		local entry = grouped[order[i]]
		parts[i] = entry.label .. (entry.count > 1 and (" x" .. entry.count) or "")
	end
	if #order > shown then
		parts[#parts + 1] = "and " .. (#order - shown) .. " more"
	end
	return table.concat(parts, ", ")
end

local function SellOneAlways()
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
					return true
				end
			end
		end
	end
	return false
end

local function SellAlwaysList()
	if not ns.enabled.sell then
		return
	end
	PaceSell(SellOneAlways)
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
	if CanMerchantRepair and not CanMerchantRepair() then
		ns:Debug("repair skipped: merchant cannot repair")
		return
	end
	if cost <= 0 then
		ns:Debug("repair skipped: nothing to repair")
		return
	end
	if not Vendor:ShouldRepair() then
		ns:Debug("repair skipped: above threshold")
		return
	end
	if GetMoney() < cost then
		if not quiet and not brokePrinted then
			brokePrinted = true
			ns:Print("cannot afford repair (" .. CoinText(cost) .. ")")
		end
		ns:Debug("repair skipped: not enough gold, cost " .. cost)
		return
	end
	repairedThisVisit = true
	if RepairAllItems then
		RepairAllItems(false)
	elseif C_MerchantFrame and C_MerchantFrame.RepairAllItems then
		C_MerchantFrame.RepairAllItems()
	else
		ns:Debug("repair skipped: no repair API")
		return
	end
	ns:Print("Mended for " .. CoinText(cost))
	ns:Debug("RepairAllItems(player) cost=" .. cost)
end

function Vendor:ShouldRepair()
	local threshold = ns.db.vendor.repairBelow or 100
	local sum, count, broken = 0, 0, false
	for slot = 1, 18 do
		if GetInventoryItemDurability then
			local current, max = GetInventoryItemDurability(slot)
			if current and max and max > 0 then
				sum = sum + (current / max)
				count = count + 1
				if current <= 0 then
					broken = true
				end
			end
		end
	end
	if count == 0 then
		return false
	end
	if broken then
		return true
	end
	return (sum / count) * 100 < threshold
end

local function StartVendorPass()
	if not merchantOpen then
		return
	end
	if ns:Waits() then
		ns:Debug("vendor pass skipped: waiting")
		return
	end
	ns:RefreshEnabled()
	local restockOn = ns.db.vendor.restock and ns.db.vendor.restock.enabled ~= false and ns:RestockList()[1]
	if not ns.enabled.sell and not ns.enabled.repair and not restockOn then
		ns:Debug("vendor pass skipped: sell and repair off")
		return
	end

	ns:Debug("vendor pass start sell=" .. tostring(ns.enabled.sell) .. " repair=" .. tostring(ns.enabled.repair))

	local moneyBefore = GetMoney and GetMoney() or 0
	local soldText = ns.enabled.sell and PlannedSales() or ""
	if ns.enabled.sell then
		SellBlizzardJunk()
		SellAlwaysList()
	end
	WhenSellingDone(function()
		if not merchantOpen then
			return
		end
		local gained = (GetMoney and GetMoney() or 0) - moneyBefore
		if gained > 0 then
			if soldText ~= "" then
				ns:Print("Sold " .. soldText .. " for " .. CoinText(gained))
			else
				ns:Print("Sold for " .. CoinText(gained))
			end
		end
		Vendor:Restock()
		ConfirmJunkPopup()
		Vendor:RepairNow()
	end)
end

local function CountInBags(itemID)
	local count = 0
	for bag = FIRST_BAG, LAST_BAG do
		local slots = C_Container.GetContainerNumSlots(bag) or 0
		for slot = 1, slots do
			local info = ContainerInfo(bag, slot)
			if info and info.itemID == itemID then
				count = count + (info.stackCount or 1)
			end
		end
	end
	return count
end

local function MerchantItemInfo(index)
	if GetMerchantItemInfo then
		return GetMerchantItemInfo(index)
	end
	if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
		local info = C_MerchantFrame.GetItemInfo(index)
		if info then
			return info.name, info.texture, info.price, info.stackCount, info.numAvailable, info.isPurchasable, info.isUsable, info.hasExtendedCost
		end
	end
end

function Vendor:Restock()
	local restock = ns.db.vendor.restock
	if not restock or restock.enabled == false then
		return
	end
	if not GetMerchantNumItems or not GetMerchantItemID or not BuyMerchantItem then
		return
	end
	local num = GetMerchantNumItems() or 0
	for _, entry in ipairs(ns:RestockList()) do
		local itemID = entry.id
		local want = tonumber(entry.count) or 0
		if want > 0 and not ns.db.vendor.alwaysSell[itemID] then
			local need = want - CountInBags(itemID)
			for index = 1, num do
				if need <= 0 then
					break
				end
				if GetMerchantItemID(index) == itemID then
					local _, _, price, stack, available, _, _, extended = MerchantItemInfo(index)
					price = price or 0
					stack = (stack and stack > 0) and stack or 1
					if extended then
						break
					end
					local batches = math.ceil(need / stack)
					if type(available) == "number" and available >= 0 and available < batches then
						batches = available
					end
					if price > 0 then
						local affordable = math.floor(GetMoney() / price)
						if affordable < batches then
							batches = affordable
						end
					end
					if price <= 0 or batches < 1 then
						ns:Print("Cannot restock " .. ns:ItemLabel(itemID) .. " (" .. CoinText(price) .. ")")
						break
					end
					BuyMerchantItem(index, batches)
					local bought = math.min(need, batches * stack)
					ns:Print("Restocked " .. ns:ItemLabel(itemID) .. " x" .. bought .. " for " .. CoinText(price * batches))
					if bought < need then
						ns:Print("Cannot restock " .. ns:ItemLabel(itemID) .. " (" .. CoinText(price) .. ")")
					end
					break
				end
			end
		end
	end
end

function Vendor:OnMerchantShow()
	if merchantOpen then
		return
	end
	merchantOpen = true
	repairedThisVisit = false
	brokePrinted = false
	sellHalted = false
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

local hoveredMerchant

local function AddHoveredRestock()
	if not hoveredMerchant or not GetMerchantItemID then
		return
	end
	local itemID = GetMerchantItemID(hoveredMerchant)
	if not itemID then
		return
	end
	if ns:RestockCount(itemID) then
		ns:Print("Already restocking " .. ns:ItemLabel(itemID))
		return
	end
	local _, _, _, stack = MerchantItemInfo(hoveredMerchant)
	ns:SetRestock(itemID, (stack and stack > 0) and stack or 1)
	ns:Print("Will restock " .. ns:ItemLabel(itemID))
	if ns.Settings and ns.Settings.Refresh then
		ns.Settings:Refresh()
	end
end

local function HookMerchantRestock()
	if not MerchantFrame or MerchantFrame.ZephyrRestock then
		return
	end
	local button = CreateFrame("Button", nil, MerchantFrame, "UIPanelButtonTemplate")
	button:SetSize(120, 22)
	button:SetPoint("TOPRIGHT", MerchantFrame, "TOPRIGHT", -40, -32)
	button:SetText("Restock this")
	button:SetScript("OnClick", AddHoveredRestock)
	MerchantFrame.ZephyrRestock = button
	for i = 1, 12 do
		local slot = _G["MerchantItem" .. i .. "ItemButton"]
		if slot and not slot.ZephyrRestock then
			slot.ZephyrRestock = true
			slot:HookScript("OnEnter", function(self)
				local page = MerchantFrame.page or 1
				local per = MERCHANT_ITEMS_PER_PAGE or 10
				hoveredMerchant = self:GetID() + ((page - 1) * per)
			end)
		end
	end
end

function Vendor:Start()
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("MERCHANT_SHOW")
	frame:RegisterEvent("ADDON_LOADED")
	frame:RegisterEvent("MERCHANT_CLOSED")
	frame:RegisterEvent("UI_ERROR_MESSAGE")
	if Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.Merchant then
		frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
	end
	frame:SetScript("OnEvent", function(_, event, arg1, arg2)
		if event == "UI_ERROR_MESSAGE" then
			if merchantOpen and (arg2 == ERR_VENDOR_DOESNT_BUY or arg2 == ERR_TOO_MUCH_GOLD) then
				sellHalted = true
				ns:Debug("sell halted: vendor refused or gold capped")
			end
			return
		end
		if event == "ADDON_LOADED" and arg1 == "Blizzard_MerchantFrame" then
			HookMerchantRestock()
			return
		end
		if event == "MERCHANT_SHOW" then
			HookMerchantRestock()
			self:OnMerchantShow()
		elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" and arg1 == Enum.PlayerInteractionType.Merchant then
			self:OnMerchantShow()
		elseif event == "MERCHANT_CLOSED" then
			self:OnMerchantClosed()
		end
	end)
end
