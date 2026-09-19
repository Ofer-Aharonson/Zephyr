local _, ns = ...

local Mail = {}
ns.Mail = Mail

local busy = false
local open = false

local function ProcessInbox()
	if not open or not ns.db.mail.enabled or ns:HoldSkip() then
		return
	end

	local num = GetInboxNumItems()
	if not num or num == 0 then
		ns:Debug("mail inbox empty")
		return
	end

	for index = num, 1, -1 do
		local _, _, _, _, money, cod, _, hasItem, _, _, _, _, isGM = GetInboxHeaderInfo(index)
		if not isGM and (not cod or cod == 0) then
			if money and money > 0 then
				ns:Debug("mail take gold #" .. index)
				TakeInboxMoney(index)
				return
			end
			if hasItem then
				for attach = ATTACHMENTS_MAX_RECEIVE or 16, 1, -1 do
					if GetInboxItem(index, attach) then
						ns:Debug("mail take item #" .. index .. ":" .. attach)
						TakeInboxItem(index, attach)
						return
					end
				end
			end
		elseif (cod or 0) > 0 then
			ns:Debug("mail skip COD #" .. index)
		end
	end
end

local function Kick()
	if busy or not open then
		return
	end
	busy = true
	C_Timer.After(0.15, function()
		busy = false
		ProcessInbox()
	end)
end

function Mail:Start()
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("MAIL_SHOW")
	frame:RegisterEvent("MAIL_CLOSED")
	frame:RegisterEvent("MAIL_INBOX_UPDATE")
	if Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.MailInfo then
		frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
	end
	frame:SetScript("OnEvent", function(_, event, arg1)
		if event == "MAIL_SHOW" or (event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" and arg1 == Enum.PlayerInteractionType.MailInfo) then
			open = true
			if CheckInbox then
				CheckInbox()
			end
			ns:Debug("mailbox opened")
			Kick()
		elseif event == "MAIL_CLOSED" then
			open = false
		elseif event == "MAIL_INBOX_UPDATE" and open then
			Kick()
		end
	end)
end
