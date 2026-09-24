local _, ns = ...

local SettingsUI = {}
ns.Settings = SettingsUI

local NAME_WIDTH = 168
local ROW_HEIGHT = 30
local INK = { 0.22, 0.12, 0.05 }
local INK_SOFT = { 0.40, 0.26, 0.13 }
local SAVE_NOTE = "WoW Forever beta has a bug and will not keep these settings after a reload.\nThey work for this session only. It will be fixed once the game is live."

local panel
local child
local listsAnchor
local restockAnchor
local listsCanvas
local restockCanvas
local profilesCanvas
local rows = {}
local sectionBits = {}
local page = "options"
local listRows = {}
local contentY = 0

local SECTIONS = {
	{
		title = "Loot and vendors",
		items = {
			{
				name = "Faster autoloot",
				tip = "Shift and a locked roll leave the window up.",
				get = function()
					return ns.db.loot.enabled
				end,
				set = function(value)
					ns.db.loot.enabled = value
				end,
			},
			{
				name = "Sell junk",
				tip = "A kept poor item is not sold.",
				get = function()
					return ns.db.vendor.sellJunk
				end,
				set = function(value)
					ns.db.vendor.sellJunk = value
				end,
			},
			{
				name = "Repair",
				tip = "",
				get = function()
					return ns.db.vendor.repair
				end,
				set = function(value)
					ns.db.vendor.repair = value
				end,
			},
			{
				name = "Mark always-sell",
				tip = "",
				get = function()
					return ns.db.vendor.bagMarks
				end,
				set = function(value)
					ns.db.vendor.bagMarks = value
				end,
			},
		},
	},
	{
		title = "Mail and quests",
		items = {
			{
				name = "Open mail",
				tip = "COD mail stays in the mailbox.",
				get = function()
					return ns.db.mail.enabled
				end,
				set = function(value)
					ns.db.mail.enabled = value
				end,
			},
			{
				name = "Quests",
				tip = "A new quest stays up. A turn-in that costs gold stays up.",
				get = function()
					return ns.db.quest.enabled
				end,
				set = function(value)
					ns.db.quest.enabled = value
				end,
			},
			{
				name = "Single gossip",
				tip = "A story line stays up.",
				get = function()
					return ns.db.gossip.enabled
				end,
				set = function(value)
					ns.db.gossip.enabled = value
				end,
			},
		},
	},
	{
		title = "Combat and travel",
		items = {
			{
				name = "Skip cinematics",
				tip = "Shift leaves a talking head up.",
				get = function()
					return ns.db.cinematic.enabled
				end,
				set = function(value)
					ns.db.cinematic.enabled = value
				end,
			},
			{
				name = "Dismount and stand",
				tip = "Welcoming Campfire keeps you seated.",
				get = function()
					return ns.db.stand.enabled
				end,
				set = function(value)
					ns.db.stand.enabled = value
				end,
			},
		},
	},
	{
		title = "Other",
		items = {
			{
				name = "Confirm grey deletes",
				tip = "Poor items only.",
				get = function()
					return ns.db.delete.enabled
				end,
				set = function(value)
					ns.db.delete.enabled = value
				end,
			},
			{
				name = "Debug",
				tip = "",
				get = function()
					return ns.db.debug
				end,
				set = function(value)
					ns.db.debug = value
				end,
			},
		},
	},
}

local function Ink(fontString, color)
	fontString:SetTextColor(color[1], color[2], color[3])
end

local function AddHeader(parent, text, y)
	local header = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	header:SetPoint("TOPLEFT", 8, y)
	header:SetText(text)
	sectionBits[#sectionBits + 1] = header

	local line = parent:CreateTexture(nil, "ARTWORK")
	line:SetColorTexture(1, 0.82, 0, 0.45)
	line:SetPoint("LEFT", header, "RIGHT", 12, 0)
	line:SetPoint("RIGHT", parent, "RIGHT", -12, 0)
	line:SetHeight(1)
	sectionBits[#sectionBits + 1] = line
	return 22
end

local function AddRow(parent, spec, y)
	local row = CreateFrame("Button", nil, parent)
	row:SetPoint("TOPLEFT", 0, y)
	row:SetPoint("RIGHT", -8, 0)
	row:SetHeight(ROW_HEIGHT)

	local hover = row:CreateTexture(nil, "BACKGROUND")
	hover:SetAllPoints()
	hover:SetColorTexture(0.45, 0.32, 0.12, 0.12)
	hover:Hide()

	local box = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
	box:SetPoint("LEFT", 2, 0)
	box:SetSize(26, 26)
	if box.Text then
		box.Text:SetText("")
		box.Text:Hide()
	end

	local name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	name:SetPoint("LEFT", box, "RIGHT", 6, 0)
	name:SetWidth(NAME_WIDTH)
	name:SetJustifyH("LEFT")
	name:SetWordWrap(false)
	name:SetText(spec.name)
	Ink(name, INK)

	local function Sync()
		if ns.db then
			box:SetChecked(spec.get() and true or false)
		end
	end

	local function Toggle()
		spec.set(not spec.get())
		Sync()
		ns:OnOptionsChanged()
	end

	box:SetScript("OnClick", function()
		spec.set(box:GetChecked() and true or false)
		ns:OnOptionsChanged()
	end)
	row:SetScript("OnClick", function()
		if box:IsMouseOver() then
			return
		end
		Toggle()
	end)
	row:SetScript("OnEnter", function()
		hover:Show()
		if spec.tip and spec.tip ~= "" then
			GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
			GameTooltip:SetText(spec.name)
			GameTooltip:AddLine(spec.tip, 1, 1, 1, true)
			GameTooltip:Show()
		end
	end)
	row:SetScript("OnLeave", function()
		hover:Hide()
		GameTooltip:Hide()
	end)

	row.Sync = Sync
	rows[#rows + 1] = row
	sectionBits[#sectionBits + 1] = row
	return ROW_HEIGHT
end

local function SortedIDs(tbl)
	local ids = {}
	for itemID in pairs(tbl) do
		ids[#ids + 1] = itemID
	end
	table.sort(ids)
	return ids
end

local function HideListRows()
	for i = 1, #listRows do
		listRows[i]:Hide()
	end
end

local function ListButton(index)
	local row = listRows[index]
	if row then
		return row
	end
	row = CreateFrame("Button", nil, listsAnchor)
	row:SetHeight(18)
	row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	row.text:SetAllPoints()
	row.text:SetJustifyH("LEFT")
	row.text:SetWordWrap(false)
	row:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	listRows[index] = row
	return row
end

local function ConfirmRemove(label, listName, apply)
	if not StaticPopupDialogs.ZEPHYR_REMOVE_LIST_ITEM then
		StaticPopupDialogs.ZEPHYR_REMOVE_LIST_ITEM = {
			text = "Remove %s from %s?",
			button1 = YES,
			button2 = CANCEL,
			OnAccept = function(dialog, data)
				data = data or (dialog and dialog.data)
				if data and data.apply then
					data.apply()
				end
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
	end
	StaticPopup_Show("ZEPHYR_REMOVE_LIST_ITEM", label, listName, { apply = apply })
end

local function ConfirmAsk(sentence, apply)
	if not StaticPopupDialogs.ZEPHYR_CONFIRM then
		StaticPopupDialogs.ZEPHYR_CONFIRM = {
			button1 = YES,
			button2 = CANCEL,
			OnAccept = function(dialog)
				local fn = StaticPopupDialogs.ZEPHYR_CONFIRM.apply
				if not fn and dialog and dialog.data then
					fn = dialog.data.apply
				end
				StaticPopupDialogs.ZEPHYR_CONFIRM.apply = nil
				if fn then
					fn()
				end
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
	end
	StaticPopupDialogs.ZEPHYR_CONFIRM.text = sentence
	StaticPopupDialogs.ZEPHYR_CONFIRM.apply = apply
	local dialog = StaticPopup_Show("ZEPHYR_CONFIRM")
	if dialog then
		dialog.data = { apply = apply }
	end
end

local function ShowItemLink(row, itemID, list, listName)
	local label = ns:ItemLabel(itemID)
	row.text:SetText(label)
	row:SetScript("OnEnter", function()
		local _, link = C_Item.GetItemInfo(itemID)
		GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
		if link then
			GameTooltip:SetHyperlink(link)
		else
			GameTooltip:SetText(label)
		end
		GameTooltip:AddLine("Right-click to remove.", INK_SOFT[1], INK_SOFT[2], INK_SOFT[3])
		GameTooltip:Show()
	end)
	row:SetScript("OnClick", function(_, button)
		if GetCursorInfo() == "item" then
			TakeCursor(list)
			return
		end
		local _, link = C_Item.GetItemInfo(itemID)
		if button == "LeftButton" and IsModifiedClick("CHATLINK") and link and ChatEdit_InsertLink then
			ChatEdit_InsertLink(link)
			return
		end
		if button ~= "RightButton" then
			return
		end
		ConfirmRemove(label, listName or "the list", function()
			list[itemID] = nil
			if ns.Marks then
				ns.Marks:Update()
			end
			SettingsUI:Refresh()
		end)
	end)
	if C_Item.RequestLoadItemDataByID then
		C_Item.RequestLoadItemDataByID(itemID)
	end
	row:Show()
end

local function ShowEmpty(row)
	row.text:SetText("(empty)")
	Ink(row.text, INK_SOFT)
	row:SetScript("OnEnter", nil)
	row:SetScript("OnClick", nil)
	row:Show()
end

local function TakeCursor(list)
	local infoType, itemID, link = GetCursorInfo()
	if infoType ~= "item" then
		return false
	end
	itemID = ns:ItemIDFromArg(link) or itemID
	if not itemID then
		return false
	end
	list[itemID] = true
	ClearCursor()
	if ns.Marks then
		ns.Marks:Update()
	end
	SettingsUI:Refresh()
	return true
end

local function FillList(title, list, y, index)
	local header = listsAnchor.headers[title]
	if not header then
		header = listsAnchor:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		listsAnchor.headers[title] = header
	end
	header:ClearAllPoints()
	header:SetPoint("TOPLEFT", 8, y)
	header:SetText(title)
	y = y - 20

	local ids = SortedIDs(list)
	if #ids == 0 then
		local row = ListButton(index)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 16, y)
		row:SetPoint("RIGHT", -12, 0)
		ShowEmpty(row)
		return y - 18, index + 1
	end

	for i = 1, #ids do
		local row = ListButton(index)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 16, y)
		row:SetPoint("RIGHT", -12, 0)
		ShowItemLink(row, ids[i], list, title)
		y = y - 18
		index = index + 1
	end
	return y, index
end

local function LayoutLists()
	if not listsAnchor or not ns.db then
		return
	end
	HideListRows()
	local y = -4
	if not listsAnchor.bagLabel then
		listsAnchor.bagLabel = listsAnchor:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		listsAnchor.bagLabel:SetText("In your bags")
	end
	listsAnchor.bagLabel:ClearAllPoints()
	listsAnchor.bagLabel:SetPoint("TOPLEFT", 8, y)
	y = y - 22
	local bags = {}
	local seen = {}
	for bag = 0, 4 do
		local slots = C_Container.GetContainerNumSlots(bag) or 0
		for slot = 1, slots do
			local info = C_Container.GetContainerItemInfo(bag, slot)
			if info and info.itemID then
				local entry = seen[info.itemID]
				if not entry then
					entry = { itemID = info.itemID, count = 0, texture = info.iconFileID }
					seen[info.itemID] = entry
					bags[#bags + 1] = entry
				end
				entry.count = entry.count + (info.stackCount or 1)
			end
		end
	end
	table.sort(bags, function(a, b)
		return a.itemID < b.itemID
	end)
	local size, gap, perRow = 36, 6, 8
	for i = 1, #bags do
		local entry = bags[i]
		local button = listsAnchor.bagButtons[i]
		if not button then
			button = CreateFrame("Button", nil, listsAnchor)
			button:SetSize(size, size)
			button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			button.icon = button:CreateTexture(nil, "ARTWORK")
			button.icon:SetAllPoints()
			button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
			button.count:SetPoint("BOTTOMRIGHT", -2, 2)
			button:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)
			listsAnchor.bagButtons[i] = button
		end
		local column = (i - 1) % perRow
		local rowIndex = math.floor((i - 1) / perRow)
		button.itemID = entry.itemID
		button.icon:SetTexture(entry.texture)
		button.count:SetText(entry.count)
		local kept = ns.db.vendor.neverSell[entry.itemID]
		local sold = ns.db.vendor.alwaysSell[entry.itemID]
		button.icon:SetDesaturated(kept or sold)
		button:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			local _, link = C_Item.GetItemInfo(self.itemID)
			if link then
				GameTooltip:SetHyperlink(link)
			else
				GameTooltip:SetText(ns:ItemLabel(self.itemID))
			end
			if kept then
				GameTooltip:AddLine("On Keep.", INK_SOFT[1], INK_SOFT[2], INK_SOFT[3])
			elseif sold then
				GameTooltip:AddLine("On Sell.", INK_SOFT[1], INK_SOFT[2], INK_SOFT[3])
			else
				GameTooltip:AddLine("Left-click to keep. Right-click to sell.", INK_SOFT[1], INK_SOFT[2], INK_SOFT[3])
			end
			GameTooltip:Show()
		end)
		button:SetScript("OnClick", function(self, mouseButton)
			local list = mouseButton == "RightButton" and ns.db.vendor.alwaysSell or ns.db.vendor.neverSell
			if list[self.itemID] then
				return
			end
			list[self.itemID] = true
			if ns.Marks then
				ns.Marks:Update()
			end
			SettingsUI:Refresh()
		end)
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", 16 + column * (size + gap), y - rowIndex * (size + gap))
		button:Show()
	end
	for i = #bags + 1, #listsAnchor.bagButtons do
		listsAnchor.bagButtons[i]:Hide()
	end
	local bagRows = math.ceil(#bags / perRow)
	if bagRows > 0 then
		y = y - bagRows * (size + gap)
	end
	y = y - 8
	listsAnchor.hint:ClearAllPoints()
	listsAnchor.hint:SetPoint("TOPLEFT", 8, y)
	listsAnchor.hint:SetPoint("RIGHT", listsAnchor, "RIGHT", -12, 0)
	y = y - 36
	if listsAnchor.addBox then
		listsAnchor.addBox:ClearAllPoints()
		listsAnchor.addBox:SetPoint("TOPLEFT", 16, y)
	end
	y = y - 28
	local index = 1
	y, index = FillList("Keep", ns.db.vendor.neverSell, y, index)
	y = y - 10
	y = FillList("Sell", ns.db.vendor.alwaysSell, y, index)
	listsAnchor:SetHeight(-y + 8)
	if listsCanvas and listsCanvas.inner then
		listsCanvas.inner:SetHeight((listsAnchor.canvasOffset or 0) + listsAnchor:GetHeight() + 16)
	end
	if child then
		child:SetHeight(-contentY + 12)
	end
end

local function PaintPaper(parent, withIcon)
	local parchment = parent:CreateTexture(nil, "BACKGROUND")
	parchment:SetPoint("TOPLEFT", 6, -6)
	parchment:SetPoint("BOTTOMRIGHT", -6, 6)
	parchment:SetTexture("Interface\\QuestFrame\\QuestBG")
	parchment:SetTexCoord(0, 0.5859375, 0, 0.65625)

	local border = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	border:SetAllPoints()
	border:SetFrameLevel((parent:GetFrameLevel() or 0) + 5)
	border:SetBackdrop({
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
		edgeSize = 24,
	})
	border:EnableMouse(false)

	if not withIcon then
		return
	end
	local portrait = parent:CreateTexture(nil, "ARTWORK")
	portrait:SetPoint("TOPLEFT", 18, -16)
	portrait:SetSize(52, 52)
	portrait:SetTexture("Interface\\AddOns\\Zephyr\\Media\\icon")
end

local function RefreshChecks()
	for i = 1, #rows do
		rows[i].Sync()
	end
end

local function LayoutRestock()
	if not restockAnchor or not ns.db then
		return
	end
	for i = 1, #restockAnchor.rows do
		restockAnchor.rows[i]:Hide()
	end
	local y = -78
	if not restockAnchor.bagLabel then
		restockAnchor.bagLabel = restockAnchor:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		restockAnchor.bagLabel:SetText("In your bags")
	end
	restockAnchor.bagLabel:ClearAllPoints()
	restockAnchor.bagLabel:SetPoint("TOPLEFT", 8, y)
	y = y - 22
	local bags = {}
	local seen = {}
	for bag = 0, 4 do
		local slots = C_Container.GetContainerNumSlots(bag) or 0
		for slot = 1, slots do
			local info = C_Container.GetContainerItemInfo(bag, slot)
			if info and info.itemID then
				local entry = seen[info.itemID]
				if not entry then
					entry = { itemID = info.itemID, count = 0, texture = info.iconFileID }
					seen[info.itemID] = entry
					bags[#bags + 1] = entry
				end
				entry.count = entry.count + (info.stackCount or 1)
			end
		end
	end
	table.sort(bags, function(a, b)
		return a.itemID < b.itemID
	end)
	local size, gap, perRow = 36, 6, 8
	for i = 1, #bags do
		local entry = bags[i]
		local button = restockAnchor.bagButtons[i]
		if not button then
			button = CreateFrame("Button", nil, restockAnchor)
			button:SetSize(size, size)
			button.icon = button:CreateTexture(nil, "ARTWORK")
			button.icon:SetAllPoints()
			button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
			button.count:SetPoint("BOTTOMRIGHT", -2, 2)
			button:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)
			restockAnchor.bagButtons[i] = button
		end
		local column = (i - 1) % perRow
		local rowIndex = math.floor((i - 1) / perRow)
		button.itemID = entry.itemID
		button.holdCount = entry.count
		button.icon:SetTexture(entry.texture)
		button.count:SetText(entry.count)
		local already = ns:RestockCount(entry.itemID)
		button.icon:SetDesaturated(already and true or false)
		button:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			local _, link = C_Item.GetItemInfo(self.itemID)
			if link then
				GameTooltip:SetHyperlink(link)
			else
				GameTooltip:SetText(ns:ItemLabel(self.itemID))
			end
			GameTooltip:AddLine("Click to restock " .. self.holdCount .. ".", INK_SOFT[1], INK_SOFT[2], INK_SOFT[3])
			GameTooltip:Show()
		end)
		button:SetScript("OnClick", function(self)
			if ns:RestockCount(self.itemID) then
				return
			end
			ns:SetRestock(self.itemID, self.holdCount)
			SettingsUI:Refresh()
		end)
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", 16 + column * (size + gap), y - rowIndex * (size + gap))
		button:Show()
	end
	for i = #bags + 1, #restockAnchor.bagButtons do
		restockAnchor.bagButtons[i]:Hide()
	end
	local bagRows = math.ceil(#bags / perRow)
	if bagRows > 0 then
		y = y - bagRows * (size + gap)
	end
	y = y - 8
	restockAnchor.hint:ClearAllPoints()
	restockAnchor.hint:SetPoint("TOPLEFT", 8, y)
	restockAnchor.hint:SetPoint("RIGHT", -12, 0)
	y = y - 36
	if restockAnchor.addBox then
		restockAnchor.addBox:ClearAllPoints()
		restockAnchor.addBox:SetPoint("TOPLEFT", 16, y)
	end
	y = y - 28
	local index = 0
	for _, entry in ipairs(ns:RestockList()) do
		local itemID, count = entry.id, entry.count
		index = index + 1
		local row = restockAnchor.rows[index]
		if not row then
			row = CreateFrame("Frame", nil, restockAnchor)
			row:SetHeight(22)
			row.label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
			row.label:SetPoint("LEFT", 16, 0)
			row.label:SetJustifyH("LEFT")
			row.edit = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
			row.edit:SetSize(44, 20)
			row.edit:SetPoint("RIGHT", -12, 0)
			row.edit:SetAutoFocus(false)
			row.edit:SetNumeric(true)
			row.edit:SetMaxLetters(4)
			row:EnableMouse(true)
			row:SetScript("OnMouseUp", function(_, button)
				if button == "RightButton" and row.itemID then
					local id = row.itemID
					ConfirmRemove(ns:ItemLabel(id), "Restock", function()
						ns:SetRestock(id, nil)
						SettingsUI:Refresh()
					end)
				end
			end)
			restockAnchor.rows[index] = row
		end
		row.itemID = tonumber(itemID) or itemID
		row.label:SetText(ns:ItemLabel(row.itemID))
		row.edit:SetText(tostring(count))
		local function SaveCount(self)
			local id = row.itemID
			if not id then
				return
			end
			local number = tonumber(self:GetText()) or 1
			if number < 1 then
				number = 1
			end
			ns:SetRestock(id, number)
			self:SetText(tostring(number))
			self:ClearFocus()
		end
		row.edit:SetScript("OnEnterPressed", SaveCount)
		row.edit:SetScript("OnEditFocusLost", nil)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 0, y)
		row:SetPoint("RIGHT", -8, 0)
		row:Show()
		y = y - 24
	end

	restockAnchor:SetHeight(-y + 8)
	if restockCanvas and restockCanvas.inner then
		restockCanvas.inner:SetHeight(restockAnchor:GetHeight() + 12)
	end
end

local function LayoutProfiles()
	if not profilesCanvas or not profilesCanvas.anchor or not ns.db then
		return
	end
	local anchor = profilesCanvas.anchor
	anchor.current:SetText("This character uses " .. ns:CurrentProfile() .. ".")
	local names = ns:ProfileNames()
	local y = -230
	for i = 1, #names do
		local row = anchor.rows[i]
		if not row then
			row = CreateFrame("Button", nil, anchor)
			row:SetHeight(22)
			row.label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
			row.label:SetPoint("LEFT", 16, 0)
			row.label:SetJustifyH("LEFT")
			row:SetScript("OnClick", function(self)
				anchor.box:SetText(self.profileName or "")
				anchor.box:ClearFocus()
			end)
			anchor.rows[i] = row
		end
		row.profileName = names[i]
		row.label:SetText(names[i])
		if names[i] == ns:CurrentProfile() then
			Ink(row.label, { 0.9, 0.8, 0.5 })
		else
			Ink(row.label, INK)
		end
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 0, y)
		row:SetPoint("RIGHT", -8, 0)
		row:Show()
		y = y - 24
	end
	for i = #names + 1, #anchor.rows do
		anchor.rows[i]:Hide()
	end
	anchor:SetHeight(-y + 8)
	if profilesCanvas.inner then
		profilesCanvas.inner:SetHeight(anchor:GetHeight() + 12)
	end
end

function SettingsUI:Refresh()
	if not ns.db or not panel then
		return
	end
	RefreshChecks()
	LayoutLists()
	LayoutRestock()
	LayoutProfiles()
	if panel.repairRow and panel.repairRow.edit and not panel.repairRow.edit:HasFocus() then
		panel.repairRow.edit:SetText(tostring(ns.db.vendor.repairBelow or 100))
	end
end

function SettingsUI:Start()
	if panel or not ns.db then
		return
	end

	panel = CreateFrame("Frame")
	panel.name = "General"
	panel:Hide()
	PaintPaper(panel)

	local scroll = CreateFrame("ScrollFrame", "ZephyrSettingsScroll", panel, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 16, -12)
	scroll:SetPoint("BOTTOMRIGHT", -34, 18)

	child = CreateFrame("Frame", nil, scroll)
	child:SetSize(560, 1)
	scroll:SetScrollChild(child)

	contentY = -2
	local optionPages = {}
	local markSpec
	local repairFrame
	listsAnchor = CreateFrame("Frame", nil, child)
	listsAnchor:SetPoint("TOPLEFT", 0, -2)
	listsAnchor:SetPoint("RIGHT", -8, 0)
	listsAnchor:SetHeight(40)
	listsAnchor.headers = {}
	listsAnchor.bagButtons = {}
	local banner = CreateFrame("Frame", nil, listsAnchor)
	banner:SetPoint("TOPLEFT", 8, -4)
	banner:SetPoint("RIGHT", -8, 0)
	banner:SetHeight(70)
	local wash = banner:CreateTexture(nil, "BACKGROUND")
	wash:SetAllPoints()
	wash:SetColorTexture(0.55, 0.28, 0.08, 0.22)
	local bannerText = banner:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	bannerText:SetPoint("TOPLEFT", 8, -8)
	bannerText:SetWidth(460)
	bannerText:SetJustifyH("LEFT")
	bannerText:SetJustifyV("TOP")
	bannerText:SetWordWrap(true)
	bannerText:SetText(SAVE_NOTE)
	Ink(bannerText, INK)
	listsAnchor.banner = banner
	listsAnchor.hint = listsAnchor:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	listsAnchor.hint:SetJustifyH("LEFT")
	listsAnchor.hint:SetWordWrap(true)
	listsAnchor.hint:SetText("Left-click a bag icon to keep it. Right-click a bag icon to sell it. Right-click a link to remove it.")
	Ink(listsAnchor.hint, INK_SOFT)
	local addBox = CreateFrame("EditBox", nil, listsAnchor, "InputBoxTemplate")
	addBox:SetSize(180, 20)
	addBox:SetAutoFocus(false)
	addBox:SetMaxLetters(80)
	local keepButton = CreateFrame("Button", nil, listsAnchor, "UIPanelButtonTemplate")
	keepButton:SetSize(48, 20)
	keepButton:SetPoint("LEFT", addBox, "RIGHT", 8, 0)
	keepButton:SetText("Keep")
	local sellButton = CreateFrame("Button", nil, listsAnchor, "UIPanelButtonTemplate")
	sellButton:SetSize(48, 20)
	sellButton:SetPoint("LEFT", keepButton, "RIGHT", 8, 0)
	sellButton:SetText("Sell")
	local function AddTyped(list)
		local itemID = ns:ItemIDFromArg(addBox:GetText() or "")
		if not itemID or list[itemID] then
			return
		end
		list[itemID] = true
		addBox:SetText("")
		addBox:ClearFocus()
		if ns.Marks then
			ns.Marks:Update()
		end
		SettingsUI:Refresh()
	end
	keepButton:SetScript("OnClick", function()
		AddTyped(ns.db.vendor.neverSell)
	end)
	sellButton:SetScript("OnClick", function()
		AddTyped(ns.db.vendor.alwaysSell)
	end)
	listsAnchor.addBox = addBox

	listsAnchor:EnableMouse(true)
	local repairRow = CreateFrame("Frame", nil, child)
	repairRow:SetPoint("TOPLEFT", 8, contentY)
	repairRow:SetPoint("RIGHT", -12, 0)
	repairRow:SetHeight(28)
	panel.repairRow = repairRow
	local repairLabel = repairRow:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	repairLabel:SetPoint("TOPLEFT", 0, 0)
	repairLabel:SetWidth(100)
	repairLabel:SetJustifyH("LEFT")
	repairLabel:SetText("Repair below")
	Ink(repairLabel, INK)
	local repairEdit = CreateFrame("EditBox", nil, repairRow, "InputBoxTemplate")
	repairEdit:SetSize(44, 20)
	repairEdit:SetPoint("TOPLEFT", 104, 2)
	repairEdit:SetAutoFocus(false)
	repairEdit:SetNumeric(true)
	repairEdit:SetMaxLetters(3)
	local function SaveRepair(self)
		local number = tonumber(self:GetText()) or 100
		if number < 1 then
			number = 1
		end
		if number > 100 then
			number = 100
		end
		ns.db.vendor.repairBelow = number
		self:SetText(tostring(number))
		self:ClearFocus()
	end
	repairEdit:SetScript("OnEnterPressed", SaveRepair)
	repairEdit:SetScript("OnEditFocusLost", SaveRepair)
	repairRow.edit = repairEdit
	local repairSuffix = repairRow:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	repairSuffix:SetPoint("TOPLEFT", 156, 0)
	repairSuffix:SetJustifyH("LEFT")
	repairSuffix:SetText("%, on all gear average.")
	Ink(repairSuffix, INK_SOFT)
	local repairNote = repairRow:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	repairNote:SetPoint("TOPLEFT", 0, -28)
	repairNote:SetWidth(460)
	repairNote:SetJustifyH("LEFT")
	repairNote:SetJustifyV("TOP")
	repairNote:SetWordWrap(true)
	repairNote:SetText("A broken piece will be repaired on its own regardless, if you can pay for it.")
	Ink(repairNote, INK_SOFT)
	repairRow:SetHeight(64)

	restockAnchor = CreateFrame("Frame", nil, child)
	restockAnchor:SetPoint("TOPLEFT", 0, -2)
	restockAnchor:SetPoint("RIGHT", -8, 0)
	restockAnchor:SetHeight(80)
	restockAnchor:Hide()
	local banner = CreateFrame("Frame", nil, restockAnchor)
	banner:SetPoint("TOPLEFT", 8, -4)
	banner:SetPoint("RIGHT", -8, 0)
	banner:SetHeight(70)
	local wash = banner:CreateTexture(nil, "BACKGROUND")
	wash:SetAllPoints()
	wash:SetColorTexture(0.55, 0.28, 0.08, 0.22)
	local bannerText = banner:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	bannerText:SetPoint("TOPLEFT", 8, -8)
	bannerText:SetWidth(460)
	bannerText:SetJustifyH("LEFT")
	bannerText:SetJustifyV("TOP")
	bannerText:SetWordWrap(true)
	bannerText:SetText(SAVE_NOTE)
	Ink(bannerText, INK)
	restockAnchor.hint = restockAnchor:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	restockAnchor.hint:SetPoint("TOPLEFT", 8, -62)
	restockAnchor.hint:SetPoint("RIGHT", -12, 0)
	restockAnchor.hint:SetJustifyH("LEFT")
	restockAnchor.hint:SetText("Click an item from your bags. The number is how many you want to hold. Right-click a line to remove it.")
	Ink(restockAnchor.hint, INK_SOFT)
	restockAnchor.rows = {}
	restockAnchor.bagButtons = {}
	local addBox = CreateFrame("EditBox", nil, restockAnchor, "InputBoxTemplate")
	addBox:SetSize(180, 20)
	addBox:SetPoint("TOPLEFT", 16, -86)
	addBox:SetAutoFocus(false)
	addBox:SetMaxLetters(80)
	local addCount = CreateFrame("EditBox", nil, restockAnchor, "InputBoxTemplate")
	addCount:SetSize(44, 20)
	addCount:SetPoint("LEFT", addBox, "RIGHT", 8, 0)
	addCount:SetAutoFocus(false)
	addCount:SetNumeric(true)
	addCount:SetMaxLetters(4)
	addCount:SetText("1")
	local addButton = CreateFrame("Button", nil, restockAnchor, "UIPanelButtonTemplate")
	addButton:SetSize(48, 20)
	addButton:SetPoint("LEFT", addCount, "RIGHT", 8, 0)
	addButton:SetText("Add")
	local function AddFromBox()
		local itemID = ns:ItemIDFromArg(addBox:GetText() or "")
		if not itemID then
			return
		end
		local number = tonumber(addCount:GetText()) or 1
		if number < 1 then
			number = 1
		end
		ns:SetRestock(itemID, number)
		addBox:SetText("")
		addBox:ClearFocus()
		SettingsUI:Refresh()
	end
	addButton:SetScript("OnClick", AddFromBox)
	addBox:SetScript("OnEnterPressed", AddFromBox)
	restockAnchor.addBox = addBox
	restockAnchor.addBox = addBox

	restockAnchor:EnableMouse(true)
	restockAnchor:SetScript("OnMouseUp", function()
		local infoType, itemID, link = GetCursorInfo()
		if infoType ~= "item" then
			return
		end
		itemID = ns:ItemIDFromArg(link) or itemID
		if not itemID then
			return
		end
		if not ns:RestockCount(itemID) then
			ns:SetRestock(itemID, 1)
		end
		ClearCursor()
		SettingsUI:Refresh()
	end)

	listsAnchor:SetScript("OnMouseUp", function()
		local infoType = GetCursorInfo()
		if infoType ~= "item" then
			return
		end
		local _, cursorY = GetCursorPosition()
		local scale = listsAnchor:GetEffectiveScale()
		local sell = listsAnchor.headers.Sell
		local boundary = sell and sell:GetTop() and (sell:GetTop() * scale) or 0
		if cursorY >= boundary then
			TakeCursor(ns.db.vendor.neverSell)
		else
			TakeCursor(ns.db.vendor.alwaysSell)
		end
	end)

	local function FitChild()
		local width = panel:GetWidth()
		if width and width > 80 then
			child:SetWidth(width - 56)
		end
	end

	panel:SetScript("OnShow", function()
		FitChild()
		SettingsUI:Refresh()
	end)
	panel:SetScript("OnSizeChanged", FitChild)
	panel:RegisterEvent("GET_ITEM_INFO_RECEIVED")
	panel:SetScript("OnEvent", function()
		if panel:IsShown() then
			LayoutLists()
		end
	end)

	local function MakeCanvas(withIcon)
		local frame = CreateFrame("Frame")
		PaintPaper(frame, withIcon)
		local canvasScroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
		canvasScroll:SetPoint("TOPLEFT", 12, withIcon and -78 or -12)
		canvasScroll:SetPoint("BOTTOMRIGHT", -28, 12)
		local inner = CreateFrame("Frame", nil, canvasScroll)
		inner:SetSize(560, 1)
		canvasScroll:SetScrollChild(inner)
		frame.inner = inner
		return frame
	end

	local function MovePage(anchor, canvas)
		anchor:SetParent(canvas.inner)
		anchor:ClearAllPoints()
		anchor:SetPoint("TOPLEFT", 0, -2)
		anchor:SetPoint("RIGHT", -8, 0)
		anchor:Show()
	end

	restockCanvas = MakeCanvas()
	listsCanvas = MakeCanvas()
	profilesCanvas = MakeCanvas()
	MovePage(restockAnchor, restockCanvas)
	MovePage(listsAnchor, listsCanvas)

	local profilesAnchor = CreateFrame("Frame", nil, profilesCanvas.inner)
	profilesAnchor:SetPoint("TOPLEFT", 0, -2)
	profilesAnchor:SetPoint("RIGHT", -8, 0)
	profilesAnchor:SetHeight(160)
	profilesAnchor.rows = {}
	profilesCanvas.anchor = profilesAnchor
	local profileBanner = CreateFrame("Frame", nil, profilesAnchor)
	profileBanner:SetPoint("TOPLEFT", 8, -4)
	profileBanner:SetPoint("RIGHT", -8, 0)
	profileBanner:SetHeight(70)
	local profileWash = profileBanner:CreateTexture(nil, "BACKGROUND")
	profileWash:SetAllPoints()
	profileWash:SetColorTexture(0.55, 0.28, 0.08, 0.22)
	local profileBannerText = profileBanner:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	profileBannerText:SetPoint("TOPLEFT", 8, -8)
	profileBannerText:SetWidth(460)
	profileBannerText:SetJustifyH("LEFT")
	profileBannerText:SetJustifyV("TOP")
	profileBannerText:SetWordWrap(true)
	profileBannerText:SetText(SAVE_NOTE)
	Ink(profileBannerText, INK)
	local currentLine = profilesAnchor:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	currentLine:SetPoint("TOPLEFT", 8, -80)
	currentLine:SetPoint("RIGHT", -12, 0)
	currentLine:SetJustifyH("LEFT")
	Ink(currentLine, INK)
	profilesAnchor.current = currentLine
	local profileBox = CreateFrame("EditBox", nil, profilesAnchor, "InputBoxTemplate")
	profileBox:SetSize(180, 20)
	profileBox:SetPoint("TOPLEFT", 16, -102)
	profileBox:SetAutoFocus(false)
	profileBox:SetMaxLetters(50)
	profilesAnchor.box = profileBox
	local function TypedName()
		return profileBox:GetText() or ""
	end
	local function ProfileButton(text, x, click)
		local button = CreateFrame("Button", nil, profilesAnchor, "UIPanelButtonTemplate")
		button:SetSize(64, 22)
		button:SetPoint("TOPLEFT", 16 + x, -128)
		button:SetText(text)
		button:SetScript("OnClick", click)
		return button
	end
	ProfileButton("New", 0, function()
		if ns:NewProfile(TypedName()) then
			profileBox:SetText("")
			profileBox:ClearFocus()
		end
	end)
	ProfileButton("Use", 72, function()
		if ns:UseProfile(TypedName()) then
			profileBox:SetText("")
			profileBox:ClearFocus()
		end
	end)
	ProfileButton("Copy", 144, function()
		if ns:CopyProfile(TypedName()) then
			profileBox:SetText("")
			profileBox:ClearFocus()
		end
	end)
	ProfileButton("Delete", 216, function()
		local name = TypedName()
		if name == "" or name == ns:CurrentProfile() then
			return
		end
		ConfirmAsk("Delete the " .. name .. " profile?", function()
			if ns:DeleteProfile(name) then
				profileBox:SetText("")
				SettingsUI:Refresh()
			end
		end)
	end)
	ProfileButton("Reset", 288, function()
		ConfirmAsk("Reset " .. ns:CurrentProfile() .. " to the defaults?", function()
			ns:ResetProfile()
		end)
	end)
	local profileHint = profilesAnchor:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	profileHint:SetPoint("TOPLEFT", 8, -158)
	profileHint:SetPoint("RIGHT", -12, 0)
	profileHint:SetJustifyH("LEFT")
	profileHint:SetWordWrap(true)
	profileHint:SetText("Click a name to fill the box. New starts from the defaults. Use switches to one that exists. Copy replaces this one. Delete removes a profile this character is not using. Reset restores the defaults here.")
	Ink(profileHint, INK_SOFT)

	local pageName = {
		["Faster autoloot"] = "Loot",
		["Sell junk"] = "Sell",
		["Repair"] = "Repair",
		["Open mail"] = "Mail",
		["Quests"] = "Quests",
		["Single gossip"] = "Gossip",
		["Skip cinematics"] = "Cinematics",
		["Dismount and stand"] = "Stand",
		["Confirm grey deletes"] = "Delete",
		["Debug"] = "Debug",
	}
	for s = 1, #SECTIONS do
		for i = 1, #SECTIONS[s].items do
			local spec = SECTIONS[s].items[i]
			if spec.name == "Mark always-sell" then
				markSpec = spec
			else
				local frame = MakeCanvas(false)
				local rowY = -12
				if spec.name == "Repair" then
					local repairBanner = CreateFrame("Frame", nil, frame.inner)
					repairBanner:SetPoint("TOPLEFT", 8, -4)
					repairBanner:SetPoint("RIGHT", -8, 0)
					repairBanner:SetHeight(70)
					local repairWash = repairBanner:CreateTexture(nil, "BACKGROUND")
					repairWash:SetAllPoints()
					repairWash:SetColorTexture(0.55, 0.28, 0.08, 0.22)
					local repairBannerText = repairBanner:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
					repairBannerText:SetPoint("TOPLEFT", 8, -8)
					repairBannerText:SetWidth(460)
					repairBannerText:SetJustifyH("LEFT")
					repairBannerText:SetJustifyV("TOP")
					repairBannerText:SetWordWrap(true)
					repairBannerText:SetText(SAVE_NOTE)
					Ink(repairBannerText, INK)
					rowY = -82
				end
				local nextY = rowY - AddRow(frame.inner, spec, rowY)
				if spec.name == "Repair" and repairRow then
					repairRow:SetParent(frame.inner)
					repairRow:ClearAllPoints()
					repairRow:SetPoint("TOPLEFT", 8, nextY - 8)
					repairRow:SetPoint("RIGHT", -12, 0)
					nextY = nextY - 72
					repairFrame = frame
				end
				frame.inner:SetHeight(-nextY + 24)
				optionPages[#optionPages + 1] = { name = pageName[spec.name] or spec.name, frame = frame }
			end
		end
	end
	if listsAnchor.banner then
		listsAnchor.banner:SetParent(listsCanvas.inner)
		listsAnchor.banner:ClearAllPoints()
		listsAnchor.banner:SetPoint("TOPLEFT", 8, -4)
		listsAnchor.banner:SetPoint("RIGHT", listsCanvas.inner, "RIGHT", -8, 0)
	end
	if markSpec then
		local markY = -82
		local nextY = markY - AddRow(listsCanvas.inner, markSpec, markY)
		listsAnchor:ClearAllPoints()
		listsAnchor:SetPoint("TOPLEFT", 0, nextY - 8)
		listsAnchor:SetPoint("RIGHT", -8, 0)
		listsAnchor.canvasOffset = -(nextY - 8)
	end

	local aboutCanvas = MakeCanvas(false)
	local aboutTitle = aboutCanvas.inner:CreateFontString(nil, "ARTWORK", "QuestFont_Huge")
	aboutTitle:SetPoint("TOPLEFT", 16, -16)
	aboutTitle:SetText("Zephyr")
	Ink(aboutTitle, { 0.9, 0.8, 0.5 })
	local aboutNotes = aboutCanvas.inner:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	aboutNotes:SetPoint("TOPLEFT", aboutTitle, "BOTTOMLEFT", 0, -8)
	aboutNotes:SetPoint("RIGHT", -16, 0)
	aboutNotes:SetJustifyH("LEFT")
	aboutNotes:SetWordWrap(true)
	aboutNotes:SetText("Fast loot, vendors, mail, quests, and other obvious clicks.")
	Ink(aboutNotes, INK)
	local aboutY = -70
	local function AboutLine(label, value)
		local name = aboutCanvas.inner:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		name:SetPoint("TOPLEFT", 16, aboutY)
		name:SetWidth(110)
		name:SetJustifyH("LEFT")
		name:SetText(label)
		local text = aboutCanvas.inner:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		text:SetPoint("LEFT", name, "RIGHT", 8, 0)
		text:SetPoint("RIGHT", -16, 0)
		text:SetJustifyH("LEFT")
		text:SetText(value)
		Ink(text, INK)
		aboutY = aboutY - 18
	end
	AboutLine("Version", ns.VERSION)
	AboutLine("Author", "Ofer Aharonson")
	AboutLine("Category", "Inventory")
	AboutLine("Website", "curseforge.com/wow/addons/zephyr")
	local changesHeader = aboutCanvas.inner:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	changesHeader:SetPoint("TOPLEFT", 16, aboutY - 16)
	changesHeader:SetText("1.1.1")
	local changes = aboutCanvas.inner:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	changes:SetPoint("TOPLEFT", changesHeader, "BOTTOMLEFT", 0, -8)
	changes:SetPoint("RIGHT", -16, 0)
	changes:SetJustifyH("LEFT")
	changes:SetJustifyV("TOP")
	changes:SetWordWrap(true)
	changes:SetText(table.concat({
		"Please read the known issue at the bottom. It is important.",
		"",
		"Quests",
		"Finished quests turn in, including a single reward. That was the main idea that drove this addon to exist.",
		"New quests stay up and party-shared quests stay up. Otherwise it will break the group play immersion.",
		"A turn-in that costs gold stays up. Otherwise, it will eat your last copper.",
		"Zephyr opens no further quest on that person after a gold turn-in. To protect you.",
		"",
		"Gossip",
		"A lone vendor, binder, flight master, trainer, bank, or inn is opened. Zoom Zoom.",
		"A story line stays up. Do you want me to destroy your Forever immersion?",
		"A flight master opens the map and does not pick a destination. I can't read your mind dude.",
		"",
		"Loot",
		"Coin, quest items, and free loot that fits are taken. Loot that Gnoll faster!",
		"A locked roll stays up. I just can't steal that Robe of Arugal, nor would the game allow me.",
		"In a group, unlocked loot that fits is taken.",
		"Master loot and round robin stay on screen. Again, the game won't allow it.",
		"A full bag still takes coin and quest items, then stops. I still want that silver.",
		"",
		"Vendors",
		"Poor junk is sold. That poor junk.",
		"A poor item you marked to keep is not sold with it. Kinda the point.",
		"Repair uses your own coin, including at a camp merchant. But it does it quicker!",
		"Repair runs when the average of your worn gear is below the percent you set. Average across your gear, not per item!",
		"A broken piece is mended if you can pay the bill. This way, your boots can still protect your feet, when you forget it is red.",
		"Restock buys, in one purchase, the amount you are still short. Better keep a nice stack of Simple Wood for camps.",
		"",
		"Mail",
		"Gold and attachments are taken. Now you can go back to the Auction House faster!",
		"COD mail is left alone. Again, do you love your last copper? I do.",
		"An attachment that does not fit is not tried again. Prevents loops in the system.",
		"",
		"Camp, stand, and dismount",
		"Welcoming Campfire keeps you seated if you try to attack. This annoyed me a lot in Redridge, so I decided to put that in!",
		"Loot, a flight, or an interact that the game refused still stands you. I can't stop the game from actually playing.",
		"",
		"Other",
		"Zephyr does not release a corpse. Maybe you want a ress?",
		"Zephyr does not accept a resurrection, summon, duel, trade, or party invite. I want to limit how much you actually want the game to be automatic, and this is not it.",
		"Train all sits beside Train. Top to bottom, trains your skills instead of clicking train 30 times.",
		"Train all buys what you can afford when you press it. It will spend your money, be ready.",
		"A gold confirm stays up. I gotta keep some safeguard.",
		"Skip cinematics starts off for a new character. Because I heard the phrase, \"The last day dawns on the Kingdom of Ascalon\" enough times.",
		"",
		"Settings",
		"The plus icon opens one page per feature: Loot, Sell, Repair, Mail, Quests, Gossip, Cinematics, Stand, Delete, Debug, Restock, Lists, and Profiles. This looks messy, but it gives me a way to implement more features in the future.",
		"",
		"Known issue",
		"WoW Forever beta does not load saved settings after a reload. Repair, Restock, Lists, and Profiles say so on the page. They work for the current session only.",
	}, "\n"))
	Ink(changes, INK)
	changes:SetHeight(1100)
	aboutCanvas.inner:SetHeight(1280)

	listsAnchor:Show()
	restockAnchor:Show()
	SettingsUI:Refresh()

	if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterCanvasLayoutSubcategory and Settings.RegisterAddOnCategory then
		local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, aboutCanvas, "Zephyr")
		if ok and category then
			SettingsUI.category = category
			pcall(Settings.RegisterAddOnCategory, category)
			local function AddSub(frame, name)
				local added, sub = pcall(Settings.RegisterCanvasLayoutSubcategory, category, frame, name)
				if added and sub then
					pcall(Settings.RegisterAddOnCategory, sub)
				end
			end
			for i = 1, #optionPages do
				AddSub(optionPages[i].frame, optionPages[i].name)
			end
			AddSub(restockCanvas, "Restock")
			AddSub(listsCanvas, "Lists")
			AddSub(profilesCanvas, "Profiles")
		end
	elseif InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(panel)
	end
end

function SettingsUI:Open()
	self:Start()
	if not panel then
		return
	end
	if Settings and Settings.OpenToCategory then
		if SettingsUI.category then
			pcall(Settings.OpenToCategory, SettingsUI.category)
			return
		end
		pcall(Settings.OpenToCategory, "Zephyr")
		return
	end
	if InterfaceOptionsFrame_OpenToCategory then
		InterfaceOptionsFrame_OpenToCategory(panel)
		InterfaceOptionsFrame_OpenToCategory(panel)
	end
end
