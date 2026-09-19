local _, ns = ...

local Marks = {}
ns.Marks = Marks

local function EnsureMark(button)
	local mark = button.ZephyrSellMark
	if mark then
		return mark
	end
	mark = button:CreateTexture(nil, "OVERLAY")
	mark:SetTexture("Interface\\Buttons\\UI-GroupLoot-Coin-Up")
	mark:SetSize(16, 16)
	mark:SetPoint("TOPLEFT", 2, -2)
	button.ZephyrSellMark = mark
	return mark
end

local function Apply(button, bag, slot)
	if not button then
		return
	end
	local show = false
	if ns.db and ns.db.vendor.bagMarks and ns.enabled.sell and bag and slot then
		local info = C_Container.GetContainerItemInfo(bag, slot)
		local itemID = info and info.itemID
		show = itemID and ns.db.vendor.alwaysSell[itemID] and not ns.db.vendor.neverSell[itemID]
	end
	if show then
		EnsureMark(button):Show()
	elseif button.ZephyrSellMark then
		button.ZephyrSellMark:Hide()
	end
end

local function BagAndSlot(button, parent)
	if button.GetBagID and button.GetID then
		local ok, bag = pcall(button.GetBagID, button)
		if ok and type(bag) == "number" then
			return bag, button:GetID()
		end
	end
	if button.GetBag and button.GetID then
		local ok, bag = pcall(button.GetBag, button)
		if ok and type(bag) == "number" then
			return bag, button:GetID()
		end
	end
	if parent and parent.GetID and button.GetID then
		return parent:GetID(), button:GetID()
	end
	return nil, nil
end

local function WalkClassicFrame(frame)
	if not frame or not frame:IsShown() then
		return
	end
	local name = frame.GetName and frame:GetName()
	local size = frame.size or 36
	if name then
		for i = 1, size do
			local button = _G[name .. "Item" .. i]
			if button and button:IsShown() then
				Apply(button, BagAndSlot(button, frame))
			end
		end
	end
	if frame.Items then
		for _, button in pairs(frame.Items) do
			if button and button.IsShown and button:IsShown() then
				Apply(button, BagAndSlot(button, frame))
			end
		end
	end
end

function Marks:Update()
	if ContainerFrameCombinedBags then
		WalkClassicFrame(ContainerFrameCombinedBags)
	end
	for i = 1, NUM_CONTAINER_FRAMES or 13 do
		WalkClassicFrame(_G["ContainerFrame" .. i])
	end
end

function Marks:Start()
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("BAG_UPDATE_DELAYED")
	frame:RegisterEvent("BAG_UPDATE")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:SetScript("OnEvent", function()
		self:Update()
	end)

	if ContainerFrame_Update then
		hooksecurefunc("ContainerFrame_Update", function()
			self:Update()
		end)
	end
	if ContainerFrame_UpdateAll then
		hooksecurefunc("ContainerFrame_UpdateAll", function()
			self:Update()
		end)
	end

	local mixin = _G.ContainerFrameItemButtonMixin
	if mixin and mixin.Update then
		hooksecurefunc(mixin, "Update", function(button)
			if button then
				Apply(button, BagAndSlot(button))
			end
		end)
	end
end
