local addonName, ns = ...

ns.VERSION = "1.1.0"
ns.DB_VERSION = 4

local defaults = {
	dbVersion = 4,
	debug = false,
	loot = { enabled = true },
	vendor = {
		sellJunk = true,
		repair = true,
		repairBelow = 100,
		bagMarks = true,
		neverSell = {},
		alwaysSell = {},
		restock = { enabled = true, items = {} },
	},
	mail = { enabled = true },
	quest = { enabled = true, accept = false },
	gossip = { enabled = true },
	life = {
		releasePvP = true,
		acceptRes = true,
		skipCombatRes = true,
	},
	cinematic = { enabled = false },
	stand = { enabled = true },
	delete = { enabled = true },
}

ns.enabled = { loot = false, sell = false, repair = false }

local function CopyDefaults(src, dst)
	if type(dst) ~= "table" then
		dst = {}
	end
	for key, value in pairs(src) do
		if type(value) == "table" then
			dst[key] = CopyDefaults(value, dst[key])
		elseif dst[key] == nil then
			dst[key] = value
		end
	end
	return dst
end

function ns:Print(message)
	DEFAULT_CHAT_FRAME:AddMessage("|cff7ec8e3Zephyr:|r " .. tostring(message))
end

function ns:Debug(message)
	if ns.db and ns.db.debug then
		DEFAULT_CHAT_FRAME:AddMessage("|cff888888Zephyr:|r " .. tostring(message))
	end
end

function ns:HoldSkip()
	return IsShiftKeyDown()
end

function ns:Waits()
	return ns:HoldSkip()
end

function ns:ItemIDFromArg(arg)
	if not arg or arg == "" then
		return nil
	end
	return tonumber(arg:match("item:(%d+)")) or tonumber(arg:match("(%d+)"))
end

function ns:RestockList()
	local restock = self.db.vendor.restock
	if type(restock.list) ~= "table" then
		restock.list = {}
	end
	return restock.list
end

function ns:RestockCount(itemID)
	itemID = tonumber(itemID)
	if not itemID then
		return nil
	end
	for _, entry in ipairs(self:RestockList()) do
		if entry.id == itemID then
			return entry.count
		end
	end
end

function ns:SetRestock(itemID, count)
	itemID = tonumber(itemID)
	count = tonumber(count)
	if not itemID then
		return
	end
	local list = self:RestockList()
	for index, entry in ipairs(list) do
		if entry.id == itemID then
			if not count or count < 1 then
				table.remove(list, index)
			else
				entry.count = count
			end
			return
		end
	end
	if count and count > 0 then
		list[#list + 1] = { id = itemID, count = count }
	end
end

function ns:ItemLabel(itemID)
	local name, link = C_Item.GetItemInfo(itemID)
	return link or name or ("item:" .. tostring(itemID))
end

function ns:RefreshEnabled()
	if not ns.db then
		return
	end
	ns.enabled.loot = ns.db.loot.enabled and true or false
	ns.enabled.sell = ns.db.vendor.sellJunk and true or false
	ns.enabled.repair = ns.db.vendor.repair and true or false
end

function ns:OnOptionsChanged()
	ns:RefreshEnabled()
	if ns.Marks then
		ns.Marks:Update()
	end
	if ns.Settings and ns.Settings.Refresh then
		ns.Settings:Refresh()
	end
end

local function MigrateDB(db)
	local version = tonumber(db.dbVersion) or 1
	if version < 2 then
		if db.debug == nil then
			db.debug = false
		end
		db.vendor = db.vendor or {}
		if db.vendor.bagMarks == nil then
			db.vendor.bagMarks = true
		end
	end
	if version < 3 then
		db.mail = db.mail or { enabled = true }
		db.quest = db.quest or { enabled = true }
		db.gossip = db.gossip or { enabled = true }
		db.life = db.life or { releasePvP = true, acceptRes = true, skipCombatRes = true }
		db.cinematic = db.cinematic or { enabled = true }
		db.stand = db.stand or { enabled = true }
		db.delete = db.delete or { enabled = true }
	end
	if version < 4 then
		db.quest = db.quest or {}
		db.quest.accept = false
	end
	db.dbVersion = ns.DB_VERSION
end

function ns:IsHardcore()
	if not C_GameRules then
		return false
	end
	if C_GameRules.IsHardcoreActive and C_GameRules.IsHardcoreActive() then
		return true
	end
	if C_GameRules.IsGameRuleActive and Enum and Enum.GameRule and Enum.GameRule.HardcoreRuleset then
		return C_GameRules.IsGameRuleActive(Enum.GameRule.HardcoreRuleset) and true or false
	end
	return false
end

function ns:InitDB()
	ZephyrDB = CopyDefaults(defaults, ZephyrDB)
	MigrateDB(ZephyrDB)
	ns.db = ZephyrDB
	if type(ns.db.vendor.neverSell) ~= "table" then
		ns.db.vendor.neverSell = {}
	end
	if type(ns.db.vendor.alwaysSell) ~= "table" then
		ns.db.vendor.alwaysSell = {}
	end
	if type(ns.db.vendor.restock) ~= "table" then
		ns.db.vendor.restock = { enabled = true, items = {} }
	end
	if type(ns.db.vendor.restock.list) ~= "table" then
		ns.db.vendor.restock.list = {}
	end
	if type(ns.db.vendor.restock.items) == "table" then
		for key, count in pairs(ns.db.vendor.restock.items) do
			ns:SetRestock(key, count)
		end
		ns.db.vendor.restock.items = nil
	end
	if type(ns.db.vendor.repairBelow) ~= "number" then
		ns.db.vendor.repairBelow = 100
	end
	if type(ns.db.profile) ~= "string" or ns.db.profile == "" then
		ns.db.profile = "Default"
	end
	ns:EnsureProfiles()
end

local function DeepCopy(src)
	if type(src) ~= "table" then
		return src
	end
	local out = {}
	for key, value in pairs(src) do
		out[key] = DeepCopy(value)
	end
	return out
end

function ns:ProfileStore()
	if type(ZephyrProfiles) ~= "table" then
		ZephyrProfiles = { profiles = {} }
	end
	if type(ZephyrProfiles.profiles) ~= "table" then
		ZephyrProfiles.profiles = {}
	end
	return ZephyrProfiles
end

function ns:EnsureProfiles()
	local store = ns:ProfileStore()
	local name = ns.db.profile or "Default"
	if type(store.profiles[name]) ~= "table" then
		store.profiles[name] = DeepCopy(ns.db)
	end
end

function ns:SaveCurrentProfile(name)
	name = name and name:gsub("^%s+", ""):gsub("%s+$", "") or ""
	if name == "" then
		return
	end
	ns:ProfileStore().profiles[name] = DeepCopy(ns.db)
	ns.db.profile = name
	ns:ProfileStore().profiles[name].profile = name
end

function ns:UseProfile(name)
	if name ~= ns.db.profile then
		ns:SaveCurrentProfile(ns.db.profile)
	end
	local stored = ns:ProfileStore().profiles[name]
	if type(stored) ~= "table" then
		return
	end
	local copy = DeepCopy(stored)
	copy.profile = name
	for key in pairs(ns.db) do
		ns.db[key] = nil
	end
	for key, value in pairs(copy) do
		ns.db[key] = value
	end
	ns:InitDB()
	ns:OnOptionsChanged()
end

function ns:DeleteProfile(name)
	if name == ns.db.profile then
		return
	end
	ns:ProfileStore().profiles[name] = nil
end

function ns:ResetCurrentProfile()
	local name = ns.db.profile or "Default"
	local fresh = DeepCopy(defaults)
	fresh.profile = name
	for key in pairs(ns.db) do
		ns.db[key] = nil
	end
	for key, value in pairs(fresh) do
		ns.db[key] = value
	end
	ns:InitDB()
	ns:SaveCurrentProfile(name)
	ns:OnOptionsChanged()
end

local function ModuleStatus(module)
	local savedOn
	if module == "loot" then
		savedOn = ns.db.loot.enabled
	elseif module == "sell" then
		savedOn = ns.db.vendor.sellJunk
	else
		savedOn = ns.db.vendor.repair
	end
	if savedOn then
		return "on"
	end
	return "off"
end

local function CountKeys(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

local function PrintHelp()
	ns:Print("v" .. ns.VERSION .. "  db v" .. tostring(ns.db.dbVersion))
	ns:Print("loot: " .. ModuleStatus("loot"))
	ns:Print("sell: " .. ModuleStatus("sell"))
	ns:Print("repair: " .. ModuleStatus("repair"))
	ns:Print("debug: " .. (ns.db.debug and "on" or "off") .. "  marks: " .. (ns.db.vendor.bagMarks and "on" or "off"))
	ns:Print("mail " .. (ns.db.mail.enabled and "on" or "off")
		.. "  quest " .. (ns.db.quest.enabled and "on" or "off")
		.. "  gossip " .. (ns.db.gossip.enabled and "on" or "off"))
	ns:Print("cinematic " .. (ns.db.cinematic.enabled and "on" or "off"))
	ns:Print("stand " .. (ns.db.stand.enabled and "on" or "off")
		.. "  delete " .. (ns.db.delete.enabled and "on" or "off"))
	ns:Print("keep " .. CountKeys(ns.db.vendor.neverSell) .. "  sellitem " .. CountKeys(ns.db.vendor.alwaysSell))
	ns:Print("/zephyr loot|sell|repair|mail|quest|gossip|cinematic|stand|delete")
	ns:Print("/zephyr debug|marks|lists|settings")
	ns:Print("/zephyr keep|unkeep|sellitem|unsell [link|id]")
end

local function PrintList(title, tbl)
	ns:Print(title)
	local any = false
	for itemID in pairs(tbl) do
		any = true
		ns:Print("  " .. tostring(itemID) .. "  " .. ns:ItemLabel(itemID))
	end
	if not any then
		ns:Print("  (empty)")
	end
end

local function ToggleSaved(module)
	if module == "loot" then
		ns.db.loot.enabled = not ns.db.loot.enabled
	elseif module == "sell" then
		ns.db.vendor.sellJunk = not ns.db.vendor.sellJunk
	else
		ns.db.vendor.repair = not ns.db.vendor.repair
	end
	ns:OnOptionsChanged()
	ns:Print(module .. " " .. ModuleStatus(module))
end

local function SetListItem(list, itemID, enabled)
	if enabled then
		list[itemID] = true
	else
		list[itemID] = nil
	end
	if ns.Marks then
		ns.Marks:Update()
	end
end

SLASH_ZEPHYR1 = "/zephyr"
SlashCmdList.ZEPHYR = function(msg)
	if not ns.db then
		return
	end
	msg = msg and msg:gsub("^%s+", ""):gsub("%s+$", "") or ""
	local cmd, rest = msg:match("^(%S+)%s*(.*)$")
	cmd = cmd and cmd:lower() or ""

	if cmd == "" or cmd == "help" then
		PrintHelp()
		return
	end

	if cmd == "loot" or cmd == "sell" or cmd == "repair" then
		ToggleSaved(cmd)
		return
	end

	local simple = {
		mail = function()
			ns.db.mail.enabled = not ns.db.mail.enabled
			return "mail", ns.db.mail.enabled
		end,
		quest = function()
			ns.db.quest.enabled = not ns.db.quest.enabled
			return "quest", ns.db.quest.enabled
		end,
		gossip = function()
			ns.db.gossip.enabled = not ns.db.gossip.enabled
			return "gossip", ns.db.gossip.enabled
		end,
		cinematic = function()
			ns.db.cinematic.enabled = not ns.db.cinematic.enabled
			return "cinematic", ns.db.cinematic.enabled
		end,
		stand = function()
			ns.db.stand.enabled = not ns.db.stand.enabled
			return "stand", ns.db.stand.enabled
		end,
		delete = function()
			ns.db.delete.enabled = not ns.db.delete.enabled
			return "delete", ns.db.delete.enabled
		end,
	}
	if cmd == "release" or cmd == "rez" then
		ns:Print("Zephyr leaves that for you.")
		return
	end

	if simple[cmd] then
		local name, on = simple[cmd]()
		ns:Print(name .. " " .. (on and "on" or "off"))
		return
	end

	if cmd == "debug" then
		ns.db.debug = not ns.db.debug
		ns:Print("debug " .. (ns.db.debug and "on" or "off"))
		return
	end

	if cmd == "marks" then
		ns.db.vendor.bagMarks = not ns.db.vendor.bagMarks
		ns:OnOptionsChanged()
		ns:Print("marks " .. (ns.db.vendor.bagMarks and "on" or "off"))
		return
	end

	if cmd == "settings" then
		if ns.Settings and ns.Settings.Open then
			ns.Settings:Open()
		else
			ns:Print("settings panel is not available on this client")
		end
		return
	end

	if cmd == "lists" then
		PrintList("never-sell", ns.db.vendor.neverSell)
		PrintList("always-sell", ns.db.vendor.alwaysSell)
		return
	end

	if cmd == "keep" or cmd == "unkeep" or cmd == "sellitem" or cmd == "unsell" then
		local itemID = ns:ItemIDFromArg(rest)
		if not itemID then
			ns:Print("usage: /zephyr " .. cmd .. " [link|id]")
			return
		end
		if cmd == "keep" then
			SetListItem(ns.db.vendor.neverSell, itemID, true)
			ns:Print("will not sell " .. ns:ItemLabel(itemID))
		elseif cmd == "unkeep" then
			SetListItem(ns.db.vendor.neverSell, itemID, false)
			ns:Print("removed from never-sell: " .. ns:ItemLabel(itemID))
		elseif cmd == "sellitem" then
			SetListItem(ns.db.vendor.alwaysSell, itemID, true)
			ns:Print("will sell " .. ns:ItemLabel(itemID))
		else
			SetListItem(ns.db.vendor.alwaysSell, itemID, false)
			ns:Print("removed from always-sell: " .. ns:ItemLabel(itemID))
		end
		return
	end

	PrintHelp()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("PLAYER_LOGOUT")
loader:SetScript("OnEvent", function(_, event, name)
	if event == "PLAYER_LOGOUT" then
		if ns.db then
			ns:SaveCurrentProfile(ns.db.profile)
		end
		return
	end
	if event == "ADDON_LOADED" then
		if name == addonName then
			ns:InitDB()
		end
		return
	end

	if event == "PLAYER_LOGIN" then
		if not ns.db then
			ns:InitDB()
		end
		ns:RefreshEnabled()
		if ns.Loot then
			ns.Loot:Start()
		end
		if ns.Vendor then
			ns.Vendor:Start()
		end
		if ns.Marks then
			ns.Marks:Start()
		end
		if ns.Settings then
			ns.Settings:Start()
		end
		if ns.Mail then
			ns.Mail:Start()
		end
		if ns.Quest then
			ns.Quest:Start()
		end
		if ns.Life then
			ns.Life:Start()
		end
		if ns.Cinematic then
			ns.Cinematic:Start()
		end
		if ns.Stand then
			ns.Stand:Start()
		end
		if ns.Delete then
			ns.Delete:Start()
		end
		if ns.Trainer then
			ns.Trainer:Start()
		end
	end
end)
