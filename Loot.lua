local _, ns = ...

local Loot = {}
ns.Loot = Loot

local SLOT_NONE = (Enum.LootSlotType and Enum.LootSlotType.None) or 0
local SLOT_ITEM = (Enum.LootSlotType and Enum.LootSlotType.Item) or 1
local SLOT_MONEY = (Enum.LootSlotType and Enum.LootSlotType.Money) or 2
local SLOT_CURRENCY = (Enum.LootSlotType and Enum.LootSlotType.Currency) or 3

local REAGENT_BAG = 5
local KEYRING = Enum.BagIndex and Enum.BagIndex.Keyring

local holder = CreateFrame("Frame")
holder:SetToplevel(true)
holder:Hide()

local state = {
	active = false,
	hidden = false,
	shown = false,
	snap = nil,
	intended = {},
	looted = {},
	fishingPlayed = false,
}

local function ResetState()
	state.active = false
	state.hidden = false
	state.shown = false
	state.snap = nil
	state.fishingPlayed = false
	wipe(state.intended)
	wipe(state.looted)
end

local function ResetLootFrame()
	if LootFrame then
		LootFrame:SetParent(UIParent)
	end
	state.hidden = false
end

local function HideLootFrame()
	if not LootFrame then
		return
	end
	LootFrame:SetParent(holder)
	state.hidden = true
	state.shown = false
end

local function ShowLootFrame()
	if not LootFrame then
		return
	end
	LootFrame:SetParent(UIParent)
	LootFrame:SetFrameStrata("HIGH")
	LootFrame:Show()
	state.hidden = false
	state.shown = true
end

local function GetLootMethod()
	if C_PartyInfo and C_PartyInfo.GetLootMethod then
		return C_PartyInfo.GetLootMethod()
	end
	if _G.GetLootMethod then
		return _G.GetLootMethod()
	end
	return nil
end

local function IsFreeForAll()
	if not IsInGroup() then
		return true
	end
	local method = GetLootMethod()
	if Enum.LootMethod then
		if method == Enum.LootMethod.Group
			or method == Enum.LootMethod.Needbeforegreed
			or method == Enum.LootMethod.Masterlooter
			or method == Enum.LootMethod.Roundrobin then
			return false
		end
		local ffa = Enum.LootMethod.Freeforall or Enum.LootMethod.FreeForAll or Enum.LootMethod.Personal
		if ffa and method == ffa then
			return true
		end
	end
	if method == "freeforall" or method == "personal" then
		return true
	end
	if method == "group" or method == "needbeforegreed" or method == "master" or method == "roundrobin" then
		return false
	end
	return false
end

local function ShouldAutoloot(autoLoot)
	return autoLoot or (GetCVarBool("autoLootDefault") ~= IsModifiedClick("AUTOLOOTTOGGLE"))
end

local function SnapshotBags()
	local snap = {
		stackSpace = {},
		genericFree = 0,
		familyFree = {},
		reagentFree = 0,
		keyringFree = 0,
	}

	local lastBag = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4
	for bag = 0, lastBag do
		local numSlots = C_Container.GetContainerNumSlots(bag) or 0
		local free, bagFamily = C_Container.GetContainerNumFreeSlots(bag)
		free = free or 0
		bagFamily = bagFamily or 0

		if bag == REAGENT_BAG then
			snap.reagentFree = snap.reagentFree + free
		elseif bagFamily == 0 then
			snap.genericFree = snap.genericFree + free
		else
			snap.familyFree[bagFamily] = (snap.familyFree[bagFamily] or 0) + free
		end

		for slot = 1, numSlots do
			local info = C_Container.GetContainerItemInfo(bag, slot)
			if info and info.itemID and info.stackCount then
				local maxStack = select(8, C_Item.GetItemInfo(info.hyperlink or info.itemID))
				if maxStack and maxStack > 1 and info.stackCount < maxStack then
					snap.stackSpace[info.itemID] = (snap.stackSpace[info.itemID] or 0) + (maxStack - info.stackCount)
				end
			end
		end
	end

	if KEYRING then
		snap.keyringFree = C_Container.GetContainerNumFreeSlots(KEYRING) or 0
	end

	return snap
end

local function ConsumeSlots(snap, slotsNeeded, itemFamily, isCraftingReagent)
	if slotsNeeded <= 0 then
		return true
	end

	if itemFamily == 256 and snap.keyringFree >= slotsNeeded then
		snap.keyringFree = snap.keyringFree - slotsNeeded
		return true
	end

	if isCraftingReagent and snap.reagentFree >= slotsNeeded then
		snap.reagentFree = snap.reagentFree - slotsNeeded
		return true
	end

	if itemFamily and itemFamily > 0 then
		for bagFamily, count in pairs(snap.familyFree) do
			if count >= slotsNeeded and bit.band(itemFamily, bagFamily) > 0 then
				snap.familyFree[bagFamily] = count - slotsNeeded
				return true
			end
		end
	end

	if snap.genericFree >= slotsNeeded then
		snap.genericFree = snap.genericFree - slotsNeeded
		return true
	end

	return false
end

local function ItemFits(snap, itemLink, quantity)
	if not itemLink then
		return false
	end

	local itemID = tonumber(itemLink:match("item:(%d+)"))
	local stackMax, _, _, _, _, _, _, _, _, isCraftingReagent = select(8, C_Item.GetItemInfo(itemLink))
	if not stackMax then
		return true
	end

	local remaining = quantity or 1
	local stackSpace = itemID and snap.stackSpace[itemID] or 0
	if stackSpace > 0 then
		local used = math.min(stackSpace, remaining)
		if itemID then
			snap.stackSpace[itemID] = stackSpace - used
		end
		remaining = remaining - used
	end
	if remaining <= 0 then
		return true
	end

	local slotsNeeded = math.ceil(remaining / stackMax)
	local family = C_Item.GetItemFamily(itemLink)
	if not ConsumeSlots(snap, slotsNeeded, family, isCraftingReagent) then
		if itemID and stackSpace > 0 then
			snap.stackSpace[itemID] = (snap.stackSpace[itemID] or 0) + math.min(stackSpace, quantity or 1)
		end
		return false
	end

	if itemID then
		local leftover = slotsNeeded * stackMax - remaining
		if leftover > 0 then
			snap.stackSpace[itemID] = (snap.stackSpace[itemID] or 0) + leftover
		end
	end

	return true
end

local function AnyIntendedRemaining()
	for slot, intended in pairs(state.intended) do
		if intended and LootSlotHasItem(slot) then
			return true
		end
	end
	return false
end

local function FinishPass(skippedNoSpace)
	if state.shown then
		return
	end
	if skippedNoSpace then
		ShowLootFrame()
		return
	end
	if not AnyIntendedRemaining() then
		CloseLoot()
	end
end

local function LootOneSlot(slot, takeItems)
	local slotType = GetLootSlotType(slot)
	if slotType == SLOT_NONE then
		return true
	end

	if slotType == SLOT_MONEY or slotType == SLOT_CURRENCY then
		state.intended[slot] = true
		LootSlot(slot)
		state.looted[slot] = true
		return true
	end

	local quantity, _, _, locked, isQuestItem = select(3, GetLootSlotInfo(slot))
	if locked then
		return true
	end

	if isQuestItem then
		state.intended[slot] = true
		LootSlot(slot)
		state.looted[slot] = true
		return true
	end

	if not takeItems then
		return true
	end

	if slotType ~= SLOT_ITEM then
		state.intended[slot] = true
		LootSlot(slot)
		state.looted[slot] = true
		return true
	end

	local itemLink = GetLootSlotLink(slot)
	if not ItemFits(state.snap, itemLink, quantity) then
		return false
	end

	state.intended[slot] = true
	LootSlot(slot)
	state.looted[slot] = true
	return true
end

local function ProcessLoot()
	if not ns.enabled.loot then
		return
	end

	local numItems = GetNumLootItems()
	if numItems == 0 then
		if state.hidden then
			CloseLoot()
		end
		return
	end

	if not state.snap then
		state.snap = SnapshotBags()
	end

	local takeItems = IsFreeForAll()
	local skippedNoSpace = false
	ns:Debug("autoloot " .. (takeItems and "all" or "coin+quest") .. " slots=" .. numItems)

	for slot = numItems, 1, -1 do
		if not LootOneSlot(slot, takeItems) then
			skippedNoSpace = true
		end
	end

	FinishPass(skippedNoSpace)
end

function Loot:OnLootReady(autoLoot)
	if not ns.enabled.loot then
		return
	end

	if not ShouldAutoloot(autoLoot) then
		ResetLootFrame()
		return
	end

	if not state.active then
		state.active = true
		HideLootFrame()
	end

	if IsFishingLoot() and not state.fishingPlayed then
		state.fishingPlayed = true
		PlaySound(SOUNDKIT.FISHING_REEL_IN, "master")
	end

	ProcessLoot()
end

function Loot:OnSlotChanged(slot)
	if not ns.enabled.loot or not state.active then
		return
	end
	if state.looted[slot] and LootSlotHasItem(slot) then
		LootSlot(slot)
	end
	if not state.shown and not AnyIntendedRemaining() then
		CloseLoot()
	end
end

function Loot:OnError(_, message)
	if not ns.enabled.loot or not state.active then
		return
	end
	if message == ERR_INV_FULL or message == ERR_ITEM_MAX_COUNT then
		ShowLootFrame()
	end
end

function Loot:OnLootClosed()
	ResetLootFrame()
	ResetState()
end

function Loot:Start()
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("LOOT_READY")
	frame:RegisterEvent("LOOT_CLOSED")
	frame:RegisterEvent("LOOT_SLOT_CHANGED")
	frame:RegisterEvent("UI_ERROR_MESSAGE")
	frame:SetScript("OnEvent", function(_, event, ...)
		if event == "LOOT_READY" then
			self:OnLootReady(...)
		elseif event == "LOOT_CLOSED" then
			self:OnLootClosed()
		elseif event == "LOOT_SLOT_CHANGED" then
			self:OnSlotChanged(...)
		elseif event == "UI_ERROR_MESSAGE" then
			self:OnError(...)
		end
	end)
end
