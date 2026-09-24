local _, ns = ...

local Trainer = {}
ns.Trainer = Trainer

local function ServiceCost(index)
	if GetTrainerServiceCost then
		return GetTrainerServiceCost(index) or 0
	end
	return 0
end

local function CanBuy(index, moneyLeft)
	if not GetTrainerServiceInfo then
		return false, 0
	end
	local _, category = GetTrainerServiceInfo(index)
	if category ~= "available" then
		return false, 0
	end
	local cost = ServiceCost(index)
	if cost > moneyLeft then
		return false, cost
	end
	return true, cost
end

local function AffordableCount()
	if not GetNumTrainerServices then
		return 0
	end
	local moneyLeft = GetMoney and GetMoney() or 0
	local count = 0
	for index = 1, GetNumTrainerServices() do
		local canBuy, cost = CanBuy(index, moneyLeft)
		if canBuy then
			count = count + 1
			moneyLeft = moneyLeft - cost
		elseif cost > moneyLeft and select(2, GetTrainerServiceInfo(index)) == "available" then
			break
		end
	end
	return count
end

local function TrainAll()
	if not GetNumTrainerServices or not BuyTrainerService then
		return
	end
	local moneyLeft = GetMoney and GetMoney() or 0
	for index = 1, GetNumTrainerServices() do
		local category = select(2, GetTrainerServiceInfo(index))
		if category == "available" then
			local cost = ServiceCost(index)
			if cost > moneyLeft then
				return
			end
			BuyTrainerService(index)
			moneyLeft = moneyLeft - cost
		end
	end
end

local function HookTrainer()
	if not ClassTrainerFrame or not ClassTrainerTrainButton then
		return
	end
	if ClassTrainerFrame.ZephyrTrainAll then
		return
	end
	local button = CreateFrame("Button", nil, ClassTrainerFrame, "UIPanelButtonTemplate")
	button:SetSize(96, 22)
	button:SetPoint("RIGHT", ClassTrainerTrainButton, "LEFT", -4, 0)
	button:SetText("Train all")
	button:SetScript("OnClick", TrainAll)
	ClassTrainerFrame.ZephyrTrainAll = button

	local function Refresh()
		if not ClassTrainerFrame.ZephyrTrainAll then
			return
		end
		local count = AffordableCount()
		button:SetEnabled(count > 0)
	end

	if ClassTrainerFrame_Update then
		hooksecurefunc("ClassTrainerFrame_Update", Refresh)
	end
	ClassTrainerFrame:HookScript("OnShow", Refresh)
	Refresh()
end

function Trainer:Start()
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("ADDON_LOADED")
	frame:SetScript("OnEvent", function(_, _, name)
		if name == "Blizzard_TrainerUI" then
			HookTrainer()
		end
	end)
	HookTrainer()
end
