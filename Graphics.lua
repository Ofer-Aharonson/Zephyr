local _, ns = ...

local Graphics = {}
ns.Graphics = Graphics

local hub
local kids = {}
local open = false

local function Coin(amount)
	amount = math.floor(tonumber(amount) or 0)
	if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then
		local text = C_CurrencyInfo.GetCoinTextureString(amount)
		if text and text ~= "" then
			return text
		end
	end
	return tostring(amount)
end

local function Actions()
	return {
		{
			text = "Fix stutter",
			icon = "Interface\\Icons\\INV_Misc_Gear_01",
			tip = "Restarts the graphics.",
			show = function()
				return ns.db and ns.db.graphics and ns.db.graphics.button
			end,
			run = function()
				if ConsoleExec then
					ConsoleExec("gxRestart")
				end
				ns:Print("Restarting graphics.")
			end,
		},
		{
			text = "Reset",
			icon = "Interface\\Icons\\Spell_Nature_TimeStop",
			tip = "Resets your instances.",
			show = function()
				return ns.db and ns.db.instances and ns.db.instances.button ~= false
			end,
			run = function()
				if ResetInstances then
					ResetInstances()
				end
				ns:Print("Instances reset.")
			end,
		},
	}
end

local function RoundButton(texture)
	local button = CreateFrame("Button", nil, Minimap)
	button:SetSize(31, 31)
	button:SetFrameStrata("MEDIUM")
	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetSize(17, 17)
	icon:SetPoint("TOPLEFT", 7, -6)
	icon:SetTexture(texture)
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetSize(53, 53)
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	border:SetPoint("TOPLEFT")
	return button
end

local function PlaceKids()
	local shown = 0
	for i = 1, #kids do
		local kid = kids[i]
		if kid.action.show() and open then
			shown = shown + 1
			kid:ClearAllPoints()
			kid:SetPoint("RIGHT", hub, "LEFT", -4 - (shown - 1) * 32, 0)
			kid:Show()
		else
			kid:Hide()
		end
	end
end

local function PlaceHub()
	if not hub or not Minimap then
		return
	end
	local angle = 225
	if ns.db and ns.db.graphics and ns.db.graphics.angle then
		angle = ns.db.graphics.angle
	end
	local rad = math.rad(angle)
	local radius = (Minimap:GetWidth() / 2) + 5
	hub:ClearAllPoints()
	hub:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad) * radius, math.sin(rad) * radius)
end

local function DragHub()
	if not Minimap or not ns.db then
		return
	end
	ns.db.graphics = ns.db.graphics or {}
	local mx, my = Minimap:GetCenter()
	local px, py = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()
	px, py = px / scale, py / scale
	ns.db.graphics.angle = math.deg(math.atan2(py - my, px - mx)) % 360
	PlaceHub()
end

function Graphics:Update()
	if not hub then
		return
	end
	local any = false
	for i = 1, #kids do
		if kids[i].action.show() then
			any = true
			break
		end
	end
	if any and Minimap then
		PlaceHub()
		hub:Show()
	else
		hub:Hide()
		open = false
	end
	PlaceKids()
end

local PAPER_SLOTS = {
	{ 1, "CharacterHeadSlot" },
	{ 2, "CharacterNeckSlot" },
	{ 3, "CharacterShoulderSlot" },
	{ 5, "CharacterChestSlot" },
	{ 6, "CharacterWaistSlot" },
	{ 7, "CharacterLegsSlot" },
	{ 8, "CharacterFeetSlot" },
	{ 9, "CharacterWristSlot" },
	{ 10, "CharacterHandsSlot" },
	{ 11, "CharacterFinger0Slot" },
	{ 12, "CharacterFinger1Slot" },
	{ 13, "CharacterTrinket0Slot" },
	{ 14, "CharacterTrinket1Slot" },
	{ 15, "CharacterBackSlot" },
	{ 16, "CharacterMainHandSlot" },
	{ 17, "CharacterSecondaryHandSlot" },
	{ 18, "CharacterRangedSlot" },
}

local function RefreshCharacter()
	local parent = PaperDollFrame or CharacterFrame
	if not parent then
		return
	end
	if not parent.ZephyrRepair then
		local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		label:SetPoint("BOTTOM", parent, "BOTTOM", 0, 32)
		parent.ZephyrRepair = label
		parent:HookScript("OnShow", RefreshCharacter)
	end
	local cost = GetRepairAllCost and (GetRepairAllCost() or 0) or 0
	if cost > 0 then
		parent.ZephyrRepair:SetText("Repair " .. Coin(cost))
		parent.ZephyrRepair:Show()
	else
		parent.ZephyrRepair:Hide()
	end
	for i = 1, #PAPER_SLOTS do
		local slotId, frameName = PAPER_SLOTS[i][1], PAPER_SLOTS[i][2]
		local button = _G[frameName]
		if button then
			local text = button.ZephyrDur
			if not text then
				text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
				local font, size = text:GetFont()
				text:SetFont(font, size or 10, "OUTLINE")
				text:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
				button.ZephyrDur = text
			end
			local current, max = nil, nil
			if GetInventoryItemDurability then
				current, max = GetInventoryItemDurability(slotId)
			end
			if current and max and max > 0 then
				text:SetText(current .. "/" .. max)
				text:Show()
			else
				text:Hide()
			end
		end
	end
end

function Graphics:Start()
	if hub then
		self:Update()
		RefreshCharacter()
		return
	end
	hub = RoundButton("Interface\\AddOns\\Zephyr\\Media\\icon")
	hub:RegisterForDrag("LeftButton")
	hub:SetScript("OnDragStart", function(self)
		self.dragging = true
		self:SetScript("OnUpdate", DragHub)
		GameTooltip:Hide()
	end)
	hub:SetScript("OnDragStop", function(self)
		self:SetScript("OnUpdate", nil)
		self.dragging = false
	end)
	hub:SetScript("OnClick", function(self)
		if self.dragging then
			return
		end
		open = not open
		PlaceKids()
	end)
	hub:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText("Zephyr")
		GameTooltip:AddLine("Opens Fix stutter and Reset.", 1, 1, 1, true)
		GameTooltip:Show()
	end)
	hub:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	local list = Actions()
	for i = 1, #list do
		local kid = RoundButton(list[i].icon)
		kid.action = list[i]
		kid:SetScript("OnClick", function(self)
			self.action.run()
		end)
		kid:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(self.action.text)
			GameTooltip:AddLine(self.action.tip, 1, 1, 1, true)
			GameTooltip:Show()
		end)
		kid:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		kid:Hide()
		kids[i] = kid
	end
	self:Update()
	RefreshCharacter()
	local watcher = CreateFrame("Frame")
	watcher:RegisterEvent("ADDON_LOADED")
	watcher:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
	watcher:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	watcher:RegisterEvent("UNIT_INVENTORY_CHANGED")
	watcher:SetScript("OnEvent", function(_, event, unit)
		if event == "UNIT_INVENTORY_CHANGED" and unit ~= "player" then
			return
		end
		RefreshCharacter()
	end)
end
