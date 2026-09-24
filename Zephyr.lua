local addonName, ns = ...

ns.VERSION = "1.1.1"
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

local characterKey

local function CharacterKey()
	if characterKey then
		return characterKey
	end
	local who = UnitName("player")
	if not who or who == "" or who == UNKNOWNOBJECT then
		return nil
	end
	local realm = GetRealmName() or ""
	local _, _, _, version = GetBuildInfo()
	version = tonumber(version) or 0
	if version > 16000 and version < 20000 and C_GameRules and C_GameRules.IsGameRuleActive and Enum and Enum.GameRule then
		if Enum.GameRule.HardcoreRuleset and C_GameRules.IsGameRuleActive(Enum.GameRule.HardcoreRuleset) then
			realm = "Hardcore"
		elseif Enum.GameRule.RPRuleset and C_GameRules.IsGameRuleActive(Enum.GameRule.RPRuleset) then
			realm = "RP"
		elseif Enum.GameRule.PvPRuleset and C_GameRules.IsGameRuleActive(Enum.GameRule.PvPRuleset) then
			realm = "PvP"
		else
			realm = "PvE"
		end
	end
	characterKey = who .. " - " .. realm
	return characterKey
end

local function ProfileStore()
	if type(ZephyrProfilesDB) ~= "table" then
		ZephyrProfilesDB = {}
	end
	if type(ZephyrProfilesDB.profiles) ~= "table" then
		ZephyrProfilesDB.profiles = {}
	end
	if type(ZephyrProfilesDB.profileKeys) ~= "table" then
		ZephyrProfilesDB.profileKeys = {}
	end
	if type(ZephyrProfilesDB.global) ~= "table" then
		ZephyrProfilesDB.global = {}
	end
	return ZephyrProfilesDB
end

local function ValidProfileName(name)
	if type(name) ~= "string" then
		return nil
	end
	name = strtrim(name)
	if name == "" then
		return nil
	end
	local length = strlenutf8 and strlenutf8(name) or #name
	if length > 50 then
		return nil
	end
	return name
end

local function DeepCopy(src)
	if type(src) ~= "table" then
		return src
	end
	local dst = {}
	for key, value in pairs(src) do
		dst[key] = DeepCopy(value)
	end
	return dst
end

local function BindProfile()
	local store = ProfileStore()
	local key = CharacterKey()
	if not key then
		return
	end
	local name = store.profileKeys[key]
	if not ValidProfileName(name) then
		name = "Default"
		store.profileKeys[key] = name
	end
	if type(store.profiles[name]) ~= "table" then
		store.profiles[name] = {}
	end
	ns.db = store.profiles[name]
	if not tonumber(ns.db.dbVersion) then
		CopyDefaults(defaults, ns.db)
	end
	MigrateDB(ns.db)
	CopyDefaults(defaults, ns.db)
	if type(ns.db.vendor.neverSell) ~= "table" then
		ns.db.vendor.neverSell = {}
	end
	if type(ns.db.vendor.alwaysSell) ~= "table" then
		ns.db.vendor.alwaysSell = {}
	end
	if type(ns.db.vendor.restock) ~= "table" then
		ns.db.vendor.restock = { enabled = true, list = {} }
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
end

function ns:CurrentProfile()
	local key = CharacterKey()
	if not key then
		return "Default"
	end
	return ProfileStore().profileKeys[key] or "Default"
end

function ns:ProfileNames()
	local names = {}
	for name in pairs(ProfileStore().profiles) do
		names[#names + 1] = name
	end
	table.sort(names)
	return names
end

local function ApplyProfile()
	BindProfile()
	ns:OnOptionsChanged()
end

function ns:NewProfile(name)
	name = ValidProfileName(name)
	if not name or not CharacterKey() then
		return false
	end
	local store = ProfileStore()
	if type(store.profiles[name]) == "table" then
		return false
	end
	store.profiles[name] = {}
	store.profileKeys[CharacterKey()] = name
	ApplyProfile()
	return true
end

function ns:UseProfile(name)
	name = ValidProfileName(name)
	if not name or not CharacterKey() then
		return false
	end
	local store = ProfileStore()
	if type(store.profiles[name]) ~= "table" then
		return false
	end
	store.profileKeys[CharacterKey()] = name
	ApplyProfile()
	return true
end

function ns:CopyProfile(name)
	name = ValidProfileName(name)
	local key = CharacterKey()
	if not name or not key then
		return false
	end
	local store = ProfileStore()
	if name == store.profileKeys[key] or type(store.profiles[name]) ~= "table" then
		return false
	end
	local current = store.profileKeys[key]
	store.profiles[current] = DeepCopy(store.profiles[name])
	ns.db = store.profiles[current]
	ApplyProfile()
	return true
end

function ns:DeleteProfile(name)
	name = ValidProfileName(name)
	local key = CharacterKey()
	if not name or not key then
		return false
	end
	local store = ProfileStore()
	if name == store.profileKeys[key] or type(store.profiles[name]) ~= "table" then
		return false
	end
	store.profiles[name] = nil
	for charKey, used in pairs(store.profileKeys) do
		if used == name then
			store.profileKeys[charKey] = "Default"
		end
	end
	if type(store.profiles.Default) ~= "table" then
		store.profiles.Default = {}
	end
	return true
end

function ns:ResetProfile()
	local key = CharacterKey()
	if not key then
		return false
	end
	local store = ProfileStore()
	local name = store.profileKeys[key] or "Default"
	local fresh = CopyDefaults(defaults, {})
	fresh.dbVersion = ns.DB_VERSION
	store.profiles[name] = fresh
	store.profileKeys[key] = name
	ns.db = fresh
	BindProfile()
	ns:OnOptionsChanged()
	ns:Print(name .. " is back to the defaults.")
	return true
end

function ns:InitDB()
	if not CharacterKey() then
		return
	end
	if ns.db then
		BindProfile()
		return
	end
	local store = ProfileStore()
	local old
	if type(ZephyrDB) == "table" and ZephyrDB.vendor and not ZephyrDB.profiles then
		old = ZephyrDB
	end
	BindProfile()
	if old and not store.global.importedLegacy then
		for key, value in pairs(old) do
			ns.db[key] = value
		end
		store.global.importedLegacy = true
		BindProfile()
	end
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
loader:SetScript("OnEvent", function(_, event, name)
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
