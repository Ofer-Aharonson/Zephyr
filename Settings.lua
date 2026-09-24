local _, ns = ...

local SettingsUI = {}
ns.Settings = SettingsUI

local NAME_WIDTH = 168
local ROW_HEIGHT = 30
local INK = { 0.22, 0.12, 0.05 }
local INK_SOFT = { 0.40, 0.26, 0.13 }

local panel
local child
local listsAnchor
local restockAnchor
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
				tip = "Takes coin, quest items, and free loot that fits. Shift and a locked roll leave the window up.",
				get = function()
					return ns.db.loot.enabled
				end,
				set = function(value)
					ns.db.loot.enabled = value
				end,
			},
			{
				name = "Sell junk",
				tip = "Sells every coin-marked junk item at a merchant.",
				get = function()
					return ns.db.vendor.sellJunk
				end,
				set = function(value)
					ns.db.vendor.sellJunk = value
				end,
			},
			{
				name = "Repair",
				tip = "Repairs your gear with your own gold.",
				get = function()
					return ns.db.vendor.repair
				end,
				set = function(value)
					ns.db.vendor.repair = value
				end,
			},
			{
				name = "Mark always-sell",
				tip = "Puts a coin on items you added to the always-sell list.",
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
				tip = "Takes gold and attachments. Leaves COD mail alone.",
				get = function()
					return ns.db.mail.enabled
				end,
				set = function(value)
					ns.db.mail.enabled = value
				end,
			},
			{
				name = "Quests",
				tip = "Hands in a finished quest, including one reward. A new quest stays on screen.",
				get = function()
					return ns.db.quest.enabled
				end,
				set = function(value)
					ns.db.quest.enabled = value
				end,
			},
			{
				name = "Single gossip",
				tip = "Clicks a lone vendor, binder, flight master, trainer, bank, or inn. A story line stays up.",
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
				tip = "Stops in-game movies and talking-head popups. Shift leaves a talking head up.",
				get = function()
					return ns.db.cinematic.enabled
				end,
				set = function(value)
					ns.db.cinematic.enabled = value
				end,
			},
			{
				name = "Dismount and stand",
				tip = "Dismounts, and stands when loot, a flight, or an interact was refused. Camp rest keeps you seated.",
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
				tip = "Clicks OK when you destroy a poor-quality item. Hardcore leaves the confirm up.",
				get = function()
					return ns.db.delete.enabled
				end,
				set = function(value)
					ns.db.delete.enabled = value
				end,
			},
			{
				name = "Debug",
				tip = "Prints what Zephyr is doing to chat.",
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

	local tip = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	tip:SetPoint("LEFT", name, "RIGHT", 14, 0)
	tip:SetPoint("RIGHT", row, "RIGHT", -8, 0)
	tip:SetJustifyH("LEFT")
	tip:SetWordWrap(true)
	tip:SetText(spec.tip)
	Ink(tip, INK_SOFT)

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
	end)
	row:SetScript("OnLeave", function()
		hover:Hide()
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

local function ShowItemLink(row, itemID, list)
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
		list[itemID] = nil
		if ns.Marks then
			ns.Marks:Update()
		end
		SettingsUI:Refresh()
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
		ShowItemLink(row, ids[i], list)
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
	local index = 1
	y, index = FillList("Keep", ns.db.vendor.neverSell, y, index)
	y = y - 10
	y = FillList("Sell", ns.db.vendor.alwaysSell, y, index)
	y = y - 8
	listsAnchor.hint:ClearAllPoints()
	listsAnchor.hint:SetPoint("TOPLEFT", 8, y)
	listsAnchor.hint:SetPoint("RIGHT", listsAnchor, "RIGHT", -12, 0)
	y = y - 32
	listsAnchor:SetHeight(-y)
	child:SetHeight(-contentY + listsAnchor:GetHeight() + 12)
end

local function PaintPaper(parent)
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

	local portrait = parent:CreateTexture(nil, "ARTWORK")
	portrait:SetPoint("TOPLEFT", 22, -18)
	portrait:SetSize(46, 46)
	portrait:SetTexture("Interface\\AddOns\\Zephyr\\Media\\icon")
	if portrait.AddMaskTexture and parent.CreateMaskTexture then
		local mask = parent:CreateMaskTexture()
		mask:SetAllPoints(portrait)
		mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		portrait:AddMaskTexture(mask)
	end

	local ring = parent:CreateTexture(nil, "OVERLAY")
	ring:SetPoint("CENTER", portrait, "CENTER", 0, 0)
	ring:SetSize(78, 78)
	ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
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
	local y = -28
	local index = 0
	for itemID, count in pairs(ns.db.vendor.restock.items) do
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
					ns.db.vendor.restock.items[row.itemID] = nil
					SettingsUI:Refresh()
				end
			end)
			restockAnchor.rows[index] = row
		end
		row.itemID = itemID
		row.label:SetText(ns:ItemLabel(itemID))
		row.edit:SetText(tostring(count))
		row.edit:SetScript("OnEnterPressed", function(self)
			local number = tonumber(self:GetText()) or 1
			if number < 1 then
				number = 1
			end
			ns.db.vendor.restock.items[itemID] = number
			self:SetText(tostring(number))
			self:ClearFocus()
		end)
		row.edit:SetScript("OnEditFocusLost", row.edit:GetScript("OnEnterPressed"))
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 0, y)
		row:SetPoint("RIGHT", -8, 0)
		row:Show()
		y = y - 24
	end
	restockAnchor:SetHeight(-y + 8)
end

function SettingsUI:Refresh()
	if not ns.db or not panel then
		return
	end
	RefreshChecks()
	LayoutLists()
	LayoutRestock()
	if panel.repairRow and panel.repairRow.edit and not panel.repairRow.edit:HasFocus() then
		panel.repairRow.edit:SetText(tostring(ns.db.vendor.repairBelow or 100))
	end
end

function SettingsUI:Start()
	if panel or not ns.db then
		return
	end

	panel = CreateFrame("Frame")
	panel.name = "Zephyr"
	panel:Hide()
	PaintPaper(panel)

	local title = panel:CreateFontString(nil, "ARTWORK", "QuestFont_Huge")
	title:SetPoint("TOPLEFT", 84, -22)
	title:SetText("Zephyr")
	Ink(title, INK)

	local version = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	version:SetPoint("LEFT", title, "RIGHT", 10, -2)
	version:SetText("v" .. ns.VERSION)
	Ink(version, INK_SOFT)

	local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
	sub:SetPoint("RIGHT", panel, "RIGHT", -28, 0)
	sub:SetJustifyH("LEFT")
	sub:SetText("Hold Shift, and Zephyr waits.")
	Ink(sub, INK)

	local scroll = CreateFrame("ScrollFrame", "ZephyrSettingsScroll", panel, "UIPanelScrollFrameTemplate")
	local pageButtons = {}
	local function ShowPage(name)
		page = name
		local optionsOn = name == "options"
		for i = 1, #sectionBits do
			local bit = sectionBits[i]
			if bit and bit.Show then
				if optionsOn then
					bit:Show()
				else
					bit:Hide()
				end
			end
		end
		if panel.repairRow then
			if optionsOn then
				panel.repairRow:Show()
			else
				panel.repairRow:Hide()
			end
		end
		if listsAnchor then
			if name == "lists" then
				listsAnchor:Show()
			else
				listsAnchor:Hide()
			end
		end
		if restockAnchor then
			if name == "restock" then
				restockAnchor:Show()
			else
				restockAnchor:Hide()
			end
		end
		for key, button in pairs(pageButtons) do
			if key == name then
				button:SetAlpha(1)
			else
				button:SetAlpha(0.55)
			end
		end
	end

	local function PageButton(label, name, x)
		local button = CreateFrame("Button", nil, panel)
		button:SetSize(90, 18)
		if x > 0 and pageButtons.options then
			button:SetPoint("TOPLEFT", pageButtons.options, "TOPRIGHT", 16, 0)
		else
			button:SetPoint("TOPLEFT", 84, -58)
		end
		local text = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		text:SetAllPoints()
		text:SetJustifyH("LEFT")
		text:SetText(label)
		button:SetScript("OnClick", function()
			ShowPage(name)
			SettingsUI:Refresh()
		end)
		pageButtons[name] = button
		return button
	end

	PageButton("Options", "options", 0)
	PageButton("Restock", "restock", 1)
	local listsButton = PageButton("Lists", "lists", 1)
	listsButton:ClearAllPoints()
	listsButton:SetPoint("TOPLEFT", pageButtons.restock, "TOPRIGHT", 16, 0)

	scroll:SetPoint("TOPLEFT", 20, -82)
	scroll:SetPoint("BOTTOMRIGHT", -34, 18)

	child = CreateFrame("Frame", nil, scroll)
	child:SetSize(560, 1)
	scroll:SetScrollChild(child)

	local y = -2
	for s = 1, #SECTIONS do
		local section = SECTIONS[s]
		y = y - AddHeader(child, section.title, y)
		for i = 1, #section.items do
			y = y - AddRow(child, section.items[i], y)
		end
		y = y - 8
	end

	contentY = y
	listsAnchor = CreateFrame("Frame", nil, child)
	listsAnchor:SetPoint("TOPLEFT", 0, y)
	listsAnchor:SetPoint("RIGHT", -8, 0)
	listsAnchor:SetHeight(40)
	listsAnchor.headers = {}
	listsAnchor.hint = listsAnchor:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	listsAnchor.hint:SetJustifyH("LEFT")
	listsAnchor.hint:SetWordWrap(true)
	listsAnchor.hint:SetText("Drop an item on Keep or Sell. Right-click a link to remove it.")
	Ink(listsAnchor.hint, INK_SOFT)

	listsAnchor:EnableMouse(true)
	local repairRow = CreateFrame("Frame", nil, child)
	repairRow:SetPoint("TOPLEFT", 8, contentY)
	repairRow:SetPoint("RIGHT", -12, 0)
	repairRow:SetHeight(28)
	panel.repairRow = repairRow
	local repairLabel = repairRow:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	repairLabel:SetPoint("LEFT", 0, 0)
	repairLabel:SetText("Repair below")
	Ink(repairLabel, INK)
	local repairEdit = CreateFrame("EditBox", nil, repairRow, "InputBoxTemplate")
	repairEdit:SetSize(44, 20)
	repairEdit:SetPoint("LEFT", repairLabel, "RIGHT", 12, 0)
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
	repairSuffix:SetPoint("LEFT", repairEdit, "RIGHT", 8, 0)
	repairSuffix:SetText("percent, on average. A broken piece is mended if you can pay.")
	Ink(repairSuffix, INK_SOFT)

	restockAnchor = CreateFrame("Frame", nil, child)
	restockAnchor:SetPoint("TOPLEFT", 0, -2)
	restockAnchor:SetPoint("RIGHT", -8, 0)
	restockAnchor:SetHeight(80)
	restockAnchor:Hide()
	restockAnchor.hint = restockAnchor:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	restockAnchor.hint:SetPoint("TOPLEFT", 8, -4)
	restockAnchor.hint:SetPoint("RIGHT", -12, 0)
	restockAnchor.hint:SetJustifyH("LEFT")
	restockAnchor.hint:SetText("Drop an item. The number is how many you want to hold. Right-click to remove it.")
	Ink(restockAnchor.hint, INK_SOFT)
	restockAnchor.rows = {}
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
		if not ns.db.vendor.restock.items[itemID] then
			ns.db.vendor.restock.items[itemID] = 1
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

	ShowPage("options")

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

	if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
		local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, panel, "Zephyr")
		if ok and category then
			pcall(Settings.RegisterAddOnCategory, category)
			SettingsUI.category = category
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
