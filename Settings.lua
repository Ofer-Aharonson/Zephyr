local _, ns = ...

local SettingsUI = {}
ns.Settings = SettingsUI

local NAME_WIDTH = 168
local ROW_HEIGHT = 32
local panel
local rows = {}

local SECTIONS = {
	{
		title = "Loot and vendors",
		items = {
			{
				name = "Faster autoloot",
				tip = "Takes loot as soon as the corpse or chest opens.",
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
				tip = "Accepts and turns in quests. Leaves multi-item rewards.",
				get = function()
					return ns.db.quest.enabled
				end,
				set = function(value)
					ns.db.quest.enabled = value
				end,
			},
			{
				name = "Single gossip",
				tip = "Clicks the only chat option, such as an inn or binder.",
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
				name = "Release in PvP",
				tip = "Releases your spirit in battlegrounds. Keeps soulstones.",
				get = function()
					return ns.db.life.releasePvP
				end,
				set = function(value)
					ns.db.life.releasePvP = value
				end,
			},
			{
				name = "Accept resurrections",
				tip = "Accepts a res outside battlegrounds.",
				get = function()
					return ns.db.life.acceptRes
				end,
				set = function(value)
					ns.db.life.acceptRes = value
				end,
			},
			{
				name = "Skip combat res",
				tip = "Ignores a res from someone who is in combat.",
				get = function()
					return ns.db.life.skipCombatRes
				end,
				set = function(value)
					ns.db.life.skipCombatRes = value
				end,
			},
			{
				name = "Skip cinematics",
				tip = "Stops in-game movies and talking-head popups.",
				get = function()
					return ns.db.cinematic.enabled
				end,
				set = function(value)
					ns.db.cinematic.enabled = value
				end,
			},
			{
				name = "Dismount and stand",
				tip = "Gets you off a mount or on your feet when the game asks.",
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
				tip = "Clicks OK when you destroy a poor-quality item.",
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

local function AddHeader(parent, text, y)
	local header = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	header:SetPoint("TOPLEFT", 6, y)
	header:SetText(text)

	local line = parent:CreateTexture(nil, "ARTWORK")
	line:SetColorTexture(1, 0.82, 0, 0.22)
	line:SetPoint("LEFT", header, "RIGHT", 12, 0)
	line:SetPoint("RIGHT", parent, "RIGHT", -10, 0)
	line:SetHeight(1)
	return 24
end

local function AddRow(parent, spec, y)
	local row = CreateFrame("Button", nil, parent)
	row:SetPoint("TOPLEFT", 0, y)
	row:SetPoint("RIGHT", -6, 0)
	row:SetHeight(ROW_HEIGHT)

	local hover = row:CreateTexture(nil, "BACKGROUND")
	hover:SetAllPoints()
	hover:SetColorTexture(1, 1, 1, 0.05)
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

	local tip = row:CreateFontString(nil, "ARTWORK", "GameFontDisable")
	tip:SetPoint("LEFT", name, "RIGHT", 14, 0)
	tip:SetPoint("RIGHT", row, "RIGHT", -8, 0)
	tip:SetJustifyH("LEFT")
	tip:SetWordWrap(true)
	tip:SetText(spec.tip)

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
		name:SetTextColor(1, 1, 1)
	end)
	row:SetScript("OnLeave", function()
		hover:Hide()
		name:SetTextColor(0.92, 0.92, 0.92)
	end)
	name:SetTextColor(0.92, 0.92, 0.92)

	row.Sync = Sync
	rows[#rows + 1] = row
	return ROW_HEIGHT
end

local function Refresh()
	if not ns.db then
		return
	end
	for _, row in ipairs(rows) do
		row.Sync()
	end
end

function SettingsUI:Start()
	if panel or not ns.db then
		return
	end

	panel = CreateFrame("Frame")
	panel.name = "Zephyr"
	panel:Hide()

	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("Zephyr")

	local version = panel:CreateFontString(nil, "ARTWORK", "GameFontDisable")
	version:SetPoint("LEFT", title, "RIGHT", 8, 0)
	version:SetText("v" .. ns.VERSION)

	local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
	sub:SetPoint("RIGHT", panel, "RIGHT", -20, 0)
	sub:SetJustifyH("LEFT")
	sub:SetText("Hold Shift to skip the current window.")

	local scroll = CreateFrame("ScrollFrame", "ZephyrSettingsScroll", panel, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 12, -56)
	scroll:SetPoint("BOTTOMRIGHT", -32, 16)

	local child = CreateFrame("Frame", nil, scroll)
	child:SetSize(560, 1)
	scroll:SetScrollChild(child)

	local y = -2
	for _, section in ipairs(SECTIONS) do
		y = y - AddHeader(child, section.title, y)
		for _, spec in ipairs(section.items) do
			y = y - AddRow(child, spec, y)
		end
		y = y - 8
	end

	local note = child:CreateFontString(nil, "ARTWORK", "GameFontDisable")
	note:SetPoint("TOPLEFT", 8, y - 4)
	note:SetPoint("RIGHT", child, "RIGHT", -10, 0)
	note:SetJustifyH("LEFT")
	note:SetText("Keep and always-sell lists: /zephyr keep and /zephyr sellitem.")
	y = y - 22

	child:SetHeight(-y + 8)

	local function FitChild()
		local width = panel:GetWidth()
		if width and width > 80 then
			child:SetWidth(width - 48)
		end
	end

	panel:SetScript("OnShow", function()
		FitChild()
		Refresh()
	end)
	panel:SetScript("OnSizeChanged", FitChild)

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
