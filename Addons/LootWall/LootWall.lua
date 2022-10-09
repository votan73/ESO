-------------------------------------------------------------------------------
--[[License:
LootWall by Vicodine ("add-on")

"Add-on" is provided to anyone, free of charge
Anyone obtaining a digital copy of "Contents" of the add-on is hereby granted permission of use and/or modification of any of the "Contents"
"Contents" of the "Add-On" package are source code, and documentation of the "Add-On", excluding libraries included in the package's sub-directories with their own respective licenses, which may vary
--]]
--[[CHANGELOG:
v0.7
      + added circonian's LibNeed4Research
      + added presets for Researchable Cloth, WW and BS
      + added defaults for Researchable
      + added trait text to prompt window
v0.6.1 Hotfix Release
      - Removed message ignoreSource meant as debug
      + added Vendor Trash and Fishing Bait presets
v0.6  + Locale/Default.lua
      + Preparation for translations
      + On/Off for "Keep x" replaced with choices of Prompt/Destroy/Junk/Keep
      + Versioning of savedVariablesVersion
      + Update to SavedVars version 2 to migrate checkboxes to dropdowns
      + LootWall:PresetToAction(preset) returns action
      + LootWall:IsInRange(value,range) for checking whether parameter value is contained in range, useful for options
      + better starting window position (200,200 instead of 0,0)
      * rewritten LootWall:DefaultActionForLink(itemLink) to accomodate for dropdowns instead of true/false
      * moved config initialization a bit up in execution
      bug: cursor dissapears by moving window after being toggled on by the add-on
      bug: if you junk a stolen item, it will always try to sell and fail at vendor until you get rid of the stolen item at fence/by hand
v0.5 - proof-read, ready for public release, can't hide the cursor, it just breaks everything, but still can show it
v0.4 - Defaults, DeleteRules,ShowCursor option, keep x_proffesion mats option, keep nirn,ornate,intricate, keep racial
v0.3 - Settings complete and working, AutoSell junk, quality thresholds, update only each 250ms for slower machines
v0.2 - added LibAddonMenu-2 and LibStub, ItemType, ItemSubtype, SellValue in tooltip, buffer for displaying items, display when out of combat
v0.1 - first try, the initial layout
--]]
-------------------------------------------------------------------------------
-- The DroppedItem
-- @itemLink
-- @bagId
-- @slotId
local LWDroppedItem = { }
-------------------------------------------------------------------------------
-- the constructor
-- inItemLink - the looted item item link, duh
-- inBagId - the looted item bagId, should be player`s inventory
-- inSlotId - the slot in given bagId where the item has gone
function LWDroppedItem:new(inItemLink, inBagId, inSlotId)
	local self = setmetatable( { }, LWDroppedItem)
	self.itemLink = inItemLink
	self.bagId = inBagId
	self.slotId = inSlotId
	return self
end
-------------------------------------------------------------------------------
-- unused - nevermind :)
function LWDroppedItem:setItemLink(inItemLink)
	self.itemLink = inItemLink
end
-------------------------------------------------------------------------------
-- unused - nevermind :)
function LWDroppedItem:setBagId(inBagId)
	self.bagId = inBagId
end
-------------------------------------------------------------------------------
-- unused - nevermind :)
function LWDroppedItem:setSlotId(inSlotId)
	self.slotId = inSlotId
end
-------------------------------------------------------------------------------
-- unused - nevermind :)
function LWDroppedItem:getItemName()
	return GetItemLinkName(self.itemLink)
end
-------------------------------------------------------------------------------
-- unused - nevermind :)
function LWDroppedItem:getItemNameF(format)
	if format == "" then
		format = "<<t:1>>"
	end

	return zo_strformat(format, self:getItemName())
end
-------------------------------------------------------------------------------
-- the main class container (table)
-------------------------------------------------------------------------------
-- variables
LootWall = { }
local LootWall = LootWall

-- LootWall.currentWidnowID = 0 --nope
LootWall.name = "LootWall"
LootWall.version = "0.7.15"
LootWall.savedVarsVersion = 5
LootWall.Window = { }
LootWall.Buffer = { }
LootWall.LAM = LibAddonMenu2
-- LootWall.NfR = LibStub("LibNeed4Research")
LootWall.gameCameraInactive = false
LootWall.ignoreLoot = false
-------------------------------------------------------------------------------
-- "constants"
local LW_CONF_IGNORE_BANK = "ignoreBank"
local LW_CONF_IGNORE_GUILDBANK = "ignoreGuildBank"
local LW_CONF_IGNORE_FENCE = "ignoreFence"
local LW_CONF_IGNORE_SHOP = "ignoreMerchants"
local LW_CONF_IGNORE_CRAFT = "ignoreCrafting"
local LW_CONF_IGNORE_MAIL = "ignoreMail"

local LW_UPDATE_INTERVAL
-- button actions
LW_ACTION_UNDEFINED = 0
LW_ACTION_KEEP_ALWAYS = 10
LW_ACTION_KEEP_NOW = 11
LW_ACTION_TRASH_ALWAYS = 20
LW_ACTION_TRASH_NOW = 21
LW_ACTION_TRASH_SECOND = 22
LW_ACTION_DESTROY_ALWAYS = 30
LW_ACTION_DESTROY_NOW = 31
LW_ACTION_DESTROY_SECOND = 32

local LW_CONF_QUALITY_THRESHOLD = "qualityThreshold"
local LW_CONF_KEEPORNATE = "keepOrnate"
local LW_CONF_KEEPNIRN = "keepNirnhoned"
local LW_CONF_KEEPINSP = "keepInspired"
local LW_CONF_SELLJUNK = "sellJunk"
local LW_CONF_KEEPCLOTHMAT = "keepClothingMaterials"
local LW_CONF_KEEPBSMAT = "keepBlacksmithMaterials"
local LW_CONF_KEEPALCHMAT = "keepAlchemyMaterials"
local LW_CONF_KEEPENCHMAT = "keepEnchantingMaterials"
local LW_CONF_KEEPPROVMAT = "keepPrivisioningMaterials"
local LW_CONF_KEEPWWMAT = "keepWoodworkingMaterials"
local LW_CONF_KEEPSTYLEMATS = "keepStyleMaterials"
local LW_CONF_SHOWCURSOR = "showIngameCursor"
-- +0.6.1
local LW_CONF_KEEPTRASH = "keepTrash"
local LW_CONF_KEEPBAIT = "keepBait"
-- *0.6.1
-- +0.7
local LW_CONF_KEEPRES_CLOTH = "keepClothierResearch"
local LW_CONF_KEEPRES_WW = "keepWoodworkResearch"
local LW_CONF_KEEPRES_BS = "keepBlacksmithResearch"
-- *0.7
-- +0.7.1
local LW_CONF_KEEPLOCKPICK = "keepLockpick"
local LW_CONF_SHOWHINT = "showDialogHint"
-- *0.7.1

local LW_PRESET_ACTION_PROMPT = 0
local LW_PRESET_ACTION_DESTROY = 1
local LW_PRESET_ACTION_JUNK = 2
local LW_PRESET_ACTION_KEEP = 3

local LW_PRESET_ACTION_STRING = {
	[0] = GetString(LWS_PRESET_CHOICE_PROMPT),
	[1] = GetString(LWS_PRESET_CHOICE_DESTROY),
	[2] = GetString(LWS_PRESET_CHOICE_JUNK),
	[3] = GetString(LWS_PRESET_CHOICE_KEEP)
}


local LW_CONF_TRANSLATE_QUALITY = {
	[ITEM_QUALITY_ARCANE] = GetItemQualityColor(ITEM_QUALITY_ARCANE):Colorize("Arcane"),
	[ITEM_QUALITY_ARTIFACT] = GetItemQualityColor(ITEM_QUALITY_ARTIFACT):Colorize("Artifact"),
	[ITEM_QUALITY_MAGIC] = GetItemQualityColor(ITEM_QUALITY_MAGIC):Colorize("Magic"),
	[ITEM_QUALITY_LEGENDARY] = GetItemQualityColor(ITEM_QUALITY_LEGENDARY):Colorize("Legendary"),
	[ITEM_QUALITY_NORMAL] = GetItemQualityColor(ITEM_QUALITY_NORMAL):Colorize("Normal"),
	[ITEM_QUALITY_TRASH] = GetItemQualityColor(ITEM_QUALITY_TRASH):Colorize("Trash")
}

local LW_CONF_DEFAULTS = {
	[LW_CONF_QUALITY_THRESHOLD] = ITEM_QUALITY_ARCANE,
	[LW_CONF_KEEPORNATE] = LW_PRESET_ACTION_PROMPT,
	[LW_CONF_KEEPNIRN] = LW_PRESET_ACTION_KEEP,
	[LW_CONF_KEEPINSP] = LW_PRESET_ACTION_PROMPT,
	[LW_CONF_SELLJUNK] = LW_PRESET_ACTION_PROMPT,
	[LW_CONF_KEEPCLOTHMAT] = LW_PRESET_ACTION_PROMPT,
	[LW_CONF_KEEPBSMAT] = LW_PRESET_ACTION_PROMPT,
	[LW_CONF_KEEPALCHMAT] = LW_PRESET_ACTION_PROMPT,
	[LW_CONF_KEEPENCHMAT] = LW_PRESET_ACTION_PROMPT,
	[LW_CONF_KEEPPROVMAT] = LW_PRESET_ACTION_PROMPT,
	[LW_CONF_KEEPWWMAT] = LW_PRESET_ACTION_PROMPT,
	[LW_CONF_KEEPSTYLEMATS] = LW_PRESET_ACTION_PROMPT,
	[LW_CONF_SHOWCURSOR] = true,
	[LW_CONF_IGNORE_BANK] = true,
	[LW_CONF_IGNORE_GUILDBANK] = true,
	[LW_CONF_IGNORE_CRAFT] = true,
	[LW_CONF_IGNORE_FENCE] = true,
	[LW_CONF_IGNORE_MAIL] = true,
	[LW_CONF_IGNORE_SHOP] = true,
	[LW_CONF_KEEPBAIT] = LW_PRESET_ACTION_PROMPT,
	[LW_CONF_KEEPTRASH] = LW_PRESET_ACTION_PROMPT,
	[LW_CONF_KEEPRES_CLOTH] = LW_PRESET_ACTION_PROMPT,
	[LW_CONF_KEEPRES_WW] = LW_PRESET_ACTION_PROMPT,
	[LW_CONF_KEEPRES_BS] = LW_PRESET_ACTION_PROMPT,
	[LW_CONF_KEEPLOCKPICK] = LW_PRESET_ACTION_PROMPT,
	[LW_CONF_SHOWHINT] = true,
}

local LW_ITEMTYPE_ACTION = {
	[LW_CONF_KEEPSTYLEMATS] = { ITEMTYPE_STYLE_MATERIAL },
	[LW_CONF_KEEPALCHMAT] = { ITEMTYPE_REAGENT, ITEMTYPE_ALCHEMY_BASE },
	[LW_CONF_KEEPBSMAT] = { ITEMTYPE_WEAPON_TRAIT, ITEMTYPE_ARMOR_TRAIT, ITEMTYPE_BLACKSMITHING_MATERIAL, ITEMTYPE_BLACKSMITHING_RAW_MATERIAL, ITEMTYPE_BLACKSMITHING_BOOSTER },
	[LW_CONF_KEEPCLOTHMAT] = { ITEMTYPE_CLOTHIER_MATERIAL, ITEMTYPE_ARMOR_TRAIT, ITEMTYPE_CLOTHIER_RAW_MATERIAL, ITEMTYPE_CLOTHIER_BOOSTER },
	[LW_CONF_KEEPENCHMAT] = { ITEMTYPE_ENCHANTING_RUNE_ASPECT, ITEMTYPE_ENCHANTING_RUNE_ESSENCE, ITEMTYPE_ENCHANTING_RUNE_POTENCY },
	[LW_CONF_KEEPWWMAT] = { ITEMTYPE_WEAPON_TRAIT, ITEMTYPE_WOODWORKING_MATERIAL, ITEMTYPE_WOODWORKING_RAW_MATERIAL, ITEMTYPE_WOODWORKING_BOOSTER },
	[LW_CONF_KEEPPROVMAT] = { ITEMTYPE_INGREDIENT },
}
-------------------------------------------------------------------------------
function LootWall:InitializeHandlers()
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, function(...) return self:OnInventoryUpdate(...) end)
	EVENT_MANAGER:AddFilterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_BACKPACK, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT, REGISTER_FILTER_IS_NEW_ITEM, true)
	--
	EVENT_MANAGER:RegisterForUpdate(self.name, 250, function() self:OnUpdate() end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_OPEN_STORE, function(_, ...) self:StoreOpened(...) self:StartLootIgnore(LW_CONF_IGNORE_SHOP) end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_OPEN_BANK, function(_, ...) self:StartLootIgnore(LW_CONF_IGNORE_BANK) end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CLOSE_BANK, function(_, ...) self:EndLootIgnore(LW_CONF_IGNORE_BANK) end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_OPEN_FENCE, function(_, ...) self:StartLootIgnore(LW_CONF_IGNORE_FENCE) end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CLOSE_FENCE, function(_, ...) self:EndLootIgnore(LW_CONF_IGNORE_FENCE) end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_OPEN_GUILD_BANK, function(_, ...) self:StartLootIgnore(LW_CONF_IGNORE_GUILDBANK) end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CLOSE_GUILD_BANK, function(_, ...) self:EndLootIgnore(LW_CONF_IGNORE_GUILDBANK) end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_MAIL_OPEN_MAILBOX, function(_, ...) self:StartLootIgnore(LW_CONF_IGNORE_MAIL) end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_MAIL_CLOSE_MAILBOX, function(_, ...) self:EndLootIgnore(LW_CONF_IGNORE_MAIL) end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CLOSE_STORE, function(_, ...) self:EndLootIgnore(LW_CONF_IGNORE_SHOP) end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CRAFTING_STATION_INTERACT, function(_, _, _, ...) self:StartLootIgnore(LW_CONF_IGNORE_CRAFT) end)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_END_CRAFTING_STATION_INTERACT, function(_, ...) self:EndLootIgnore(LW_CONF_IGNORE_CRAFT) end)
	--[[
      EVENT_CLOSE_BANK (integer eventCode)
      EVENT_OPEN_BANK (integer eventCode)
      EVENT_CLOSE_FENCE (integer eventCode)
      EVENT_OPEN_FENCE (integer eventCode)
      EVENT_OPEN_GUILD_BANK (integer eventCode)
      EVENT_CLOSE_GUILD_BANK (integer eventCode)
      EVENT_MAIL_OPEN_MAILBOX (integer eventCode)
      EVENT_MAIL_CLOSE_MAILBOX (integer eventCode)
      EVENT_CLOSE_STORE (integer eventCode)
      EVENT_OPEN_STORE (integer eventCode)
      EVENT_CRAFTING_STATION_INTERACT (integer eventCode, integer craftSkill, bool sameStation)
      EVENT_END_CRAFTING_STATION_INTERACT (integer eventCode)
   ]]
	--

end
-------------------------------------------------------------------------------
function LootWall:Initialize()
	self.savedVariables = ZO_SavedVars:New("LWSavedVars", 2, nil, { })

	if self.savedVariables.conf == nil then
		self.savedVariables.conf = { }
		self:DefaultConfig()
		self.savedVariables.conf.version = self.savedVarsVersion
		self.savedVariables.wLeft = 200
		self.savedVariables.wTop = 200
	end

	local svVersion
	if self.savedVariables.conf.version == nil then
		svVersion = 0
	else
		svVersion = self.savedVariables.conf.version
	end

	if svVersion < self.savedVarsVersion then
		-- update to version 2
		if svVersion < 2 then
			self.savedVariables.conf[LW_CONF_KEEPORNATE] = self:ConvertToV2(self.savedVariables.conf[LW_CONF_KEEPORNATE])
			self.savedVariables.conf[LW_CONF_KEEPNIRN] = self:ConvertToV2(self.savedVariables.conf[LW_CONF_KEEPNIRN])
			self.savedVariables.conf[LW_CONF_KEEPINSP] = self:ConvertToV2(self.savedVariables.conf[LW_CONF_KEEPINSP])
			self.savedVariables.conf[LW_CONF_SELLJUNK] = self:ConvertToV2(self.savedVariables.conf[LW_CONF_SELLJUNK])
			self.savedVariables.conf[LW_CONF_KEEPCLOTHMAT] = self:ConvertToV2(self.savedVariables.conf[LW_CONF_KEEPCLOTHMAT])
			self.savedVariables.conf[LW_CONF_KEEPBSMAT] = self:ConvertToV2(self.savedVariables.conf[LW_CONF_KEEPBSMAT])
			self.savedVariables.conf[LW_CONF_KEEPALCHMAT] = self:ConvertToV2(self.savedVariables.conf[LW_CONF_KEEPALCHMAT])
			self.savedVariables.conf[LW_CONF_KEEPENCHMAT] = self:ConvertToV2(self.savedVariables.conf[LW_CONF_KEEPENCHMAT])
			self.savedVariables.conf[LW_CONF_KEEPPROVMAT] = self:ConvertToV2(self.savedVariables.conf[LW_CONF_KEEPPROVMAT])
			self.savedVariables.conf[LW_CONF_KEEPWWMAT] = self:ConvertToV2(self.savedVariables.conf[LW_CONF_KEEPWWMAT])
			self.savedVariables.conf[LW_CONF_KEEPSTYLEMATS] = self:ConvertToV2(self.savedVariables.conf[LW_CONF_KEEPSTYLEMATS])
			self.savedVariables.conf[LW_CONF_SHOWCURSOR] = true
			self.savedVariables.conf[LW_CONF_IGNORE_BANK] = true
			self.savedVariables.conf[LW_CONF_IGNORE_GUILDBANK] = true
			self.savedVariables.conf[LW_CONF_IGNORE_CRAFT] = true
			self.savedVariables.conf[LW_CONF_IGNORE_FENCE] = true
			self.savedVariables.conf[LW_CONF_IGNORE_MAIL] = true
			self.savedVariables.conf[LW_CONF_IGNORE_SHOP] = true
			-- d(GetString(LWS_TEXT_SETTINGSCHANGED))
		end

		if svVersion < 3 then
			self.savedVariables.conf[LW_CONF_KEEPBAIT] = LW_CONF_DEFAULTS[LW_CONF_KEEPBAIT]
			self.savedVariables.conf[LW_CONF_KEEPTRASH] = LW_CONF_DEFAULTS[LW_CONF_KEEPTRASH]
		end

		if svVersion < 4 then
			self.savedVariables.conf[LW_CONF_KEEPRES_BS] = LW_CONF_DEFAULTS[LW_CONF_KEEPRES_BS]
			self.savedVariables.conf[LW_CONF_KEEPRES_CLOTH] = LW_CONF_DEFAULTS[LW_CONF_KEEPRES_CLOTH]
			self.savedVariables.conf[LW_CONF_KEEPRES_WW] = LW_CONF_DEFAULTS[LW_CONF_KEEPRES_WW]
		end

		if svVersion < 5 then
			self.savedVariables.conf[LW_CONF_KEEPLOCKPICK] = LW_CONF_DEFAULTS[LW_CONF_KEEPLOCKPICK]
			self.savedVariables.conf[LW_CONF_SHOWHINT] = LW_CONF_DEFAULTS[LW_CONF_SHOWHINT]
		end

		self.savedVariables.conf.version = self.savedVarsVersion
	end
	-- LAM
	local panelData = {
		type = "panel",
		name = "LootWall",
		author = "Vicodine & votan",
		slashCommand = "/lootwall",
		version = self.version,
		registerForDefaults = true,
		resetFunc = function() self:DefaultConfig() end
	}
	self.LAM:RegisterAddonPanel("LootWallOptions", panelData)

	local optionsControls = {
		{
			type = "description",
			title = GetString(LWS_DESCRIPTION_TITLE),
			text = GetString(LWS_DESCRIPTION)
		},
		{
			type = "header",
			name = GetString(LWS_GENERAL_SETTINGS),
		},
		{
			type = "dropdown",
			name = GetString(LWS_QUALITY_THRESHOLD),
			tooltip = GetString(LWS_QUALITY_THRESHOLD_TOOLTIP),
			choices = { LW_CONF_TRANSLATE_QUALITY[ITEM_QUALITY_TRASH], LW_CONF_TRANSLATE_QUALITY[ITEM_QUALITY_NORMAL], LW_CONF_TRANSLATE_QUALITY[ITEM_QUALITY_MAGIC], LW_CONF_TRANSLATE_QUALITY[ITEM_QUALITY_ARCANE], LW_CONF_TRANSLATE_QUALITY[ITEM_QUALITY_ARTIFACT], LW_CONF_TRANSLATE_QUALITY[ITEM_QUALITY_LEGENDARY] },
			getFunc = function() return self:GetConfValueForKey(LW_CONF_QUALITY_THRESHOLD) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_QUALITY_THRESHOLD, value) end
		},
		{
			type = "dropdown",
			name = GetString(LWS_PRESET_ORNATE),
			tooltip = GetString(LWS_PRESET_ORNATE_TOOLTIP),
			choices = { LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_PROMPT], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_DESTROY], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_JUNK], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_KEEP] },
			getFunc = function() return self:GetConfValueForKey(LW_CONF_KEEPORNATE) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_KEEPORNATE, value) end
		},
		{
			type = "dropdown",
			name = GetString(LWS_PRESET_INTRICATE),
			tooltip = GetString(LWS_PRESET_INTRICATE_TOOLTIP),
			choices = { LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_PROMPT], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_DESTROY], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_JUNK], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_KEEP] },
			getFunc = function() return self:GetConfValueForKey(LW_CONF_KEEPINSP) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_KEEPINSP, value) end
		},
		{
			type = "dropdown",
			name = GetString(LWS_PRESET_NIRNHONED),
			tooltip = GetString(LWS_PRESET_NIRNHONED_TOOLTIP),
			choices = { LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_PROMPT], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_DESTROY], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_JUNK], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_KEEP] },
			getFunc = function() return self:GetConfValueForKey(LW_CONF_KEEPNIRN) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_KEEPNIRN, value) end
		},
		{
			type = "dropdown",
			name = GetString(LWS_PRESET_TRASH),
			tooltip = GetString(LWS_PRESET_TRASH_TOOLTIP),
			choices = { LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_PROMPT], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_DESTROY], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_JUNK], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_KEEP] },
			getFunc = function() return self:GetConfValueForKey(LW_CONF_KEEPTRASH) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_KEEPTRASH, value) end
		},
		{
			type = "dropdown",
			name = GetString(LWS_PRESET_BAIT),
			tooltip = GetString(LWS_PRESET_BAIT_TOOLTIP),
			choices = { LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_PROMPT], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_DESTROY], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_JUNK], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_KEEP] },
			getFunc = function() return self:GetConfValueForKey(LW_CONF_KEEPBAIT) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_KEEPBAIT, value) end
		},
		{
			type = "dropdown",
			name = GetString(LWS_PRESET_LOCKPICK),
			tooltip = GetString(LWS_PRESET_LOCKPICK_TOOLTIP),
			choices = { LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_PROMPT], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_DESTROY], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_JUNK], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_KEEP] },
			getFunc = function() return self:GetConfValueForKey(LW_CONF_KEEPLOCKPICK) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_KEEPLOCKPICK, value) end
		},
		{
			type = "checkbox",
			name = GetString(LWS_PRESET_SELLJUNK),
			tooltip = GetString(LWS_PRESET_SELLJUNK_TOOLTIP),
			getFunc = function() return self:GetConfValueForKey(LW_CONF_SELLJUNK) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_SELLJUNK, value) end
		},
		{
			type = "checkbox",
			name = GetString(LWS_PRESET_SHOWCURSOR),
			tooltip = GetString(LWS_PRESET_SHOWCURSOR_TOOLTIP),
			getFunc = function() return self:GetConfValueForKey(LW_CONF_SHOWCURSOR) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_SHOWCURSOR, value) end
		},
		{
			type = "checkbox",
			name = GetString(LWS_CONF_SHOWHINT),
			tooltip = GetString(LWS_CONF_SHOWHINT_TOOLTIP),
			getFunc = function() return self:GetConfValueForKey(LW_CONF_SHOWHINT) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_SHOWHINT, value) end
		},
		{
			type = "header",
			name = GetString(LWS_CRAFTING_RESOURCES),
		},
		{
			type = "dropdown",
			name = GetString(LWS_PRESET_STYLEMATS),
			tooltip = GetString(LWS_PRESET_STYLEMATS_TOOLTIP),
			choices = { LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_PROMPT], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_DESTROY], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_JUNK], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_KEEP] },
			getFunc = function() return self:GetConfValueForKey(LW_CONF_KEEPSTYLEMATS) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_KEEPSTYLEMATS, value) end
		},
		{
			type = "dropdown",
			name = GetString(LWS_PRESET_ALCHEMYMATS),
			tooltip = GetString(LWS_PRESET_ALCHEMYMATS_TOOLTIP),
			choices = { LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_PROMPT], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_DESTROY], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_JUNK], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_KEEP] },
			getFunc = function() return self:GetConfValueForKey(LW_CONF_KEEPALCHMAT) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_KEEPALCHMAT, value) end
		},
		{
			type = "dropdown",
			name = GetString(LWS_PRESET_ENCHANTINGMATS),
			tooltip = GetString(LWS_PRESET_ENCHANTINGMATS_TOOLTIP),
			choices = { LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_PROMPT], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_DESTROY], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_JUNK], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_KEEP] },
			getFunc = function() return self:GetConfValueForKey(LW_CONF_KEEPENCHMAT) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_KEEPENCHMAT, value) end
		},
		{
			type = "dropdown",
			name = GetString(LWS_PRESET_PROVISIONMATS),
			tooltip = GetString(LWS_PRESET_PROVISIONMATS_TOOLTIP),
			choices = { LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_PROMPT], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_DESTROY], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_JUNK], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_KEEP] },
			getFunc = function() return self:GetConfValueForKey(LW_CONF_KEEPPROVMAT) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_KEEPPROVMAT, value) end
		},
		{
			type = "dropdown",
			name = GetString(LWS_PRESET_CLOTHINGMATS),
			tooltip = GetString(LWS_PRESET_CLOTHINGMATS_TOOLTIP),
			choices = { LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_PROMPT], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_DESTROY], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_JUNK], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_KEEP] },
			getFunc = function() return self:GetConfValueForKey(LW_CONF_KEEPCLOTHMAT) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_KEEPCLOTHMAT, value) end
		},
		{
			type = "dropdown",
			name = GetString(LWS_PRESET_BLACKSMITHMATS),
			tooltip = GetString(LWS_PRESET_BLACKSMITHMATS_TOOLTIP),
			choices = { LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_PROMPT], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_DESTROY], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_JUNK], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_KEEP] },
			getFunc = function() return self:GetConfValueForKey(LW_CONF_KEEPBSMAT) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_KEEPBSMAT, value) end
		},
		{
			type = "dropdown",
			name = GetString(LWS_PRESET_WOODWORKMATS),
			tooltip = GetString(LWS_PRESET_WOODWORKMATS_TOOLTIP),
			choices = { LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_PROMPT], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_DESTROY], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_JUNK], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_KEEP] },
			getFunc = function() return self:GetConfValueForKey(LW_CONF_KEEPWWMAT) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_KEEPWWMAT, value) end
		},
		{
			type = "header",
			name = GetString(LWS_HDR_RESEARCH),
		},
		{
			type = "dropdown",
			name = GetString(LWS_PRESET_RESEARCH_BS),
			tooltip = GetString(LWS_PRESET_RESEARCH_BS_TOOLTIP),
			choices = { LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_PROMPT], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_DESTROY], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_JUNK], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_KEEP] },
			getFunc = function() return self:GetConfValueForKey(LW_CONF_KEEPRES_BS) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_KEEPRES_BS, value) end
		},
		{
			type = "dropdown",
			name = GetString(LWS_PRESET_RESEARCH_CLOTH),
			tooltip = GetString(LWS_PRESET_RESEARCH_CLOTH_TOOLTIP),
			choices = { LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_PROMPT], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_DESTROY], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_JUNK], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_KEEP] },
			getFunc = function() return self:GetConfValueForKey(LW_CONF_KEEPRES_CLOTH) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_KEEPRES_CLOTH, value) end
		},
		{
			type = "dropdown",
			name = GetString(LWS_PRESET_RESEARCH_WWORK),
			tooltip = GetString(LWS_PRESET_RESEARCH_WWORK_TOOLTIP),
			choices = { LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_PROMPT], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_DESTROY], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_JUNK], LW_PRESET_ACTION_STRING[LW_PRESET_ACTION_KEEP] },
			getFunc = function() return self:GetConfValueForKey(LW_CONF_KEEPRES_WW) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_KEEPRES_WW, value) end
		},
		{
			type = "header",
			name = GetString(LWS_HEADER_IGNORES),
		},
		{
			type = "checkbox",
			name = GetString(LWS_PRESET_IGNOREBANK),
			tooltip = GetString(LWS_PRESET_IGNOREBANK_TOOLTIP),
			disabled = true,
			getFunc = function() return self:GetConfValueForKey(LW_CONF_IGNORE_BANK) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_IGNORE_BANK, value) end
		},
		{
			type = "checkbox",
			name = GetString(LWS_PRESET_IGNOREGUILDBANK),
			tooltip = GetString(LWS_PRESET_IGNOREGUILDBANK_TOOLTIP),
			disabled = true,
			getFunc = function() return self:GetConfValueForKey(LW_CONF_IGNORE_GUILDBANK) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_IGNORE_GUILDBANK, value) end
		},
		{
			type = "checkbox",
			name = GetString(LWS_PRESET_IGNORESTORE),
			tooltip = GetString(LWS_PRESET_IGNORESTORE_TOOLTIP),
			getFunc = function() return self:GetConfValueForKey(LW_CONF_IGNORE_SHOP) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_IGNORE_SHOP, value) end
		},
		{
			type = "checkbox",
			name = GetString(LWS_PRESET_IGNOREMAIL),
			tooltip = GetString(LWS_PRESET_IGNOREMAIL_TOOLTIP),
			getFunc = function() return self:GetConfValueForKey(LW_CONF_IGNORE_MAIL) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_IGNORE_MAIL, value) end
		},
		{
			type = "checkbox",
			name = GetString(LWS_PRESET_IGNORECRAFT),
			tooltip = GetString(LWS_PRESET_IGNORECRAFT_TOOLTIP),
			getFunc = function() return self:GetConfValueForKey(LW_CONF_IGNORE_CRAFT) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_IGNORE_CRAFT, value) end
		},
		{
			type = "checkbox",
			name = GetString(LWS_PRESET_IGNOREFENCE),
			tooltip = GetString(LWS_PRESET_IGNOREFENCE_TOOLTIP),
			getFunc = function() return self:GetConfValueForKey(LW_CONF_IGNORE_FENCE) end,
			setFunc = function(value) self:SetConfValueForKey(LW_CONF_IGNORE_FENCE, value) end
		},
		{
			type = "header",
			name = GetString(LWS_STORED_RULES),
		},
		{
			type = "description",
			title = GetString(LWS_STORED_RULES_TITLE),
			text = GetString(LWS_STORED_RULES_DESCRIPTION)
		},
		{
			type = "button",
			name = GetString(LWS_BUTTON_DELETEALL),
			tooltip = GetString(LWS_BUTTON_DELETEALL_TOOLTIP),
			func = function() self:RemoveAllRules() end
		},
	}

	self.LAM:RegisterOptionControls("LootWallOptions", optionsControls)

	-- end of LAM
	self.Window.control = CreateControlFromVirtual("LootWallLootable", LootWallControl, "LootWallLootable", 1)
	--  self.Window.label = self.Window.control:GetNamedChild('_Name')
	--  self.Window.icon = self.Window.control:GetNamedChild('_Icon')
	--  self.Window.itemType = self.Window.control:GetNamedChild('_Type')
	--  self.Window.itemSubType = self.Window.control:GetNamedChild('_SubType')
	--  self.Window.itemValue = self.Window.control:GetNamedChild('_Value')
	self.Window.shown = false
	--  self.Window.research = self.Window.control:GetNamedChild('_Research')
	self.Window.control:SetHidden(true)

	SCENE_MANAGER:RegisterTopLevel(self.Window.control)

	self:InitializeHandlers()

	if (self.savedVariables.itemList == nil) then
		self.savedVariables.itemList = { }
	end

	if (self.savedVariables.wLeft ~= nil) and(self.savedVariables.wTop ~= nil) then
		self:RestorePosition()
	end
	-- SCENE_MANAGER:HideTopLevel(self.Window.control)
end
-------------------------------------------------------------------------------
function LootWall:ConvertToV2(value)
	if (value == true) then
		return LW_PRESET_ACTION_KEEP
	else
		return LW_PRESET_ACTION_PROMPT
	end
end

-------------------------------------------------------------------------------
-- Each update has its own definition of the lower bits
-- Classic: Lower bits code quality and have "reducer" bits
function LootWall:CreateSubItemId(level, champ, quality, hasValue)
	quality = quality or 1
	quality = math.max(0, quality - 1)
	level = math.max(1, math.min(50, level))
	local subId
	if level < 50 or champ == nil then
		if level < 4 then
			subId = 30
		elseif level < 6 then
			subId = 25
		else
			subId = 20
		end
		subId = subId + quality
	else
		if champ < 110 then
			champ = math.max(10, champ)
			-- introduce of vet silver and gold
			subId = 124 + math.floor(champ / 10) + quality * 10
		elseif champ < 130 then
			-- Craglorn
			subId = 236 + math.floor((champ - 110) / 10) * 18 + quality
		elseif champ < 150 then
			-- Upper Craglorn
			subId = 272 + math.floor((champ - 130) / 10) * 18 + quality
			if not hasValue then subId = subId + 47 end
		else
			champ = math.min(GetChampionPointsPlayerProgressionCap(), champ)
			subId = 308 + math.floor((champ - 150) / 10) * 58 + quality
		end
	end
	return subId
end

-------------------------------------------------------------------------------
function LootWall:CreateItemLinkFromStringId(id)
	local itemLevel, itemQuality, itemType, itemTypeSub, equipType, itemTrait, itemStyle, itemId, extra, itemValue, itemStolen = id:match("(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)")
	local level, champ
	itemLevel = tonumber(itemLevel)
	if itemLevel > 50 then
		level, champ = 50, itemLevel - 50
	else
		level, champ = itemLevel, nil
	end
	local subId = self:CreateSubItemId(level, champ, itemQuality, itemValue ~= "0")

	return string.format("|H1:item:%s:%i:%i:0:0:0:0:0:0:0:0:0:0:0:0:%s:0:0:%s:10000:%s|h|h", itemId, subId, level, itemStyle, itemStolen, extra)
end

-------------------------------------------------------------------------------
function LootWall:MakeItemStringId(itemLink)
	local itemId, extra = itemLink:match("|H[^:]+:item:([^:]+):[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:([^|]+)")
	-- 									  |H1    :item:45174  :307  :50   :0    :0    :0    :0    :0    :0    :0    :0    :0    :0    :0    :0    :6    :0    :0    :0    :10000:0|h|h

	assert(itemId and extra, "Invalid itemId and extra")

	local itemType, itemTypeSub = GetItemLinkItemType(itemLink)
	local itemQuality, itemTrait, itemStyle, itemLevel, equipType, itemValue, itemStolen

	if itemType ~= ITEMTYPE_TRASH then
		itemQuality = GetItemLinkQuality(itemLink)
		itemLevel = GetItemLinkRequiredLevel(itemLink) + GetItemLinkRequiredChampionPoints(itemLink)
	else
		itemQuality = 0
		itemLevel = 1
	end

	itemTrait = GetItemLinkTraitInfo(itemLink)
	itemStolen = IsItemLinkStolen(itemLink) and 1 or 0
	itemValue = GetItemLinkValue(itemLink) > 0 and 1 or 0
	if itemType == ITEMTYPE_ARMOR or itemType == ITEMTYPE_WEAPON then
		itemStyle = GetItemLinkItemStyle(itemLink)
		equipType = GetItemLinkEquipType(itemLink)
	else
		itemStyle = 0
		equipType = 0
	end

	return string.format("%d:%d:%d:%d:%d:%d:%d:%s:%s:%d:%d", itemLevel, itemQuality, itemType, itemTypeSub, equipType, itemTrait, itemStyle, itemId, extra, itemValue, itemStolen)

end
-------------------------------------------------------------------------------
function LootWall:PresetToAction(preset)
	if preset == LW_PRESET_ACTION_DESTROY then
		return LW_ACTION_DESTROY_NOW
	elseif preset == LW_PRESET_ACTION_JUNK then
		return LW_ACTION_TRASH_NOW
	elseif preset == LW_PRESET_ACTION_KEEP then
		return LW_ACTION_KEEP_NOW
	end
end
-------------------------------------------------------------------------------
function LootWall:DefaultActionForLink(itemLink)
	local itemQuality = GetItemLinkQuality(itemLink)
	if tonumber(itemQuality) >= tonumber(self.savedVariables.conf[LW_CONF_QUALITY_THRESHOLD]) then
		return LW_ACTION_KEEP_ALWAYS
	end

	local itemType = GetItemLinkItemType(itemLink)
	local itemTrait = GetItemLinkTraitInfo(itemLink)

	if (itemType == ITEMTYPE_LURE) and(self.savedVariables.conf[LW_CONF_KEEPBAIT] > LW_PRESET_ACTION_PROMPT) then
		return self:PresetToAction(self.savedVariables.conf[LW_CONF_KEEPBAIT])
	end

	if (itemType == ITEMTYPE_LOCKPICK or itemType == ITEMTYPE_TOOL) and(self.savedVariables.conf[LW_CONF_KEEPLOCKPICK] > LW_PRESET_ACTION_PROMPT) then
		return self:PresetToAction(self.savedVariables.conf[LW_CONF_KEEPLOCKPICK])
	end

	if (self.savedVariables.conf[LW_CONF_KEEPINSP] > LW_PRESET_ACTION_PROMPT) then
		if (itemTrait == ITEM_TRAIT_TYPE_ARMOR_INTRICATE) or(itemTrait == ITEM_TRAIT_TYPE_WEAPON_INTRICATE) then
			return self:PresetToAction(self.savedVariables.conf[LW_CONF_KEEPINSP])
		end
	end

	if (self.savedVariables.conf[LW_CONF_KEEPNIRN] > LW_PRESET_ACTION_PROMPT) then
		if (itemTrait == ITEM_TRAIT_TYPE_ARMOR_NIRNHONED) or(itemTrait == ITEM_TRAIT_TYPE_WEAPON_NIRNHONED) or(itemTrait == ITEM_TRAIT_TYPE_JEWELRY_ORNATE) then
			return self:PresetToAction(self.savedVariables.conf[LW_CONF_KEEPNIRN])
		end
	end

	-- local researchNeeded, craftskillType = self.NfR:DoesPlayerNeedTrait(GetUnitName("player"), itemLink, nil)
	-- if researchNeeded == true then
	-- 	if (craftskillType == CRAFTING_TYPE_BLACKSMITHING) and(self.savedVariables.conf[LW_CONF_KEEPRES_BS] > LW_PRESET_ACTION_PROMPT) then
	-- 		return self:PresetToAction(self.savedVariables.conf[LW_CONF_KEEPRES_BS])
	-- 	end

	-- 	if (craftskillType == CRAFTING_TYPE_CLOTHIER) and(self.savedVariables.conf[LW_CONF_KEEPRES_CLOTH] > LW_PRESET_ACTION_PROMPT) then
	-- 		return self:PresetToAction(self.savedVariables.conf[LW_CONF_KEEPRES_CLOTH])
	-- 	end

	-- 	if (craftskillType == CRAFTING_TYPE_WOODWORKING) and(self.savedVariables.conf[LW_CONF_KEEPRES_WW] > LW_PRESET_ACTION_PROMPT) then
	-- 		return self:PresetToAction(self.savedVariables.conf[LW_CONF_KEEPRES_WW])
	-- 	end
	-- end

	local configs = self.savedVariables.conf
	for conf, types in pairs(LW_ITEMTYPE_ACTION) do
		if (configs[conf] > LW_PRESET_ACTION_PROMPT) then
			if self:IsItemOfType(itemLink, types) then return self:PresetToAction(configs[conf]) end
		end
	end

	if (self.savedVariables.conf[LW_CONF_KEEPORNATE] > LW_PRESET_ACTION_PROMPT) then
		if GetItemLinkValue(itemLink) > 0 and(itemTrait == ITEM_TRAIT_TYPE_ARMOR_ORNATE or itemTrait == ITEM_TRAIT_TYPE_WEAPON_ORNATE or itemTrait == ITEM_TRAIT_TYPE_JEWELRY_ORNATE) then
			return self:PresetToAction(self.savedVariables.conf[LW_CONF_KEEPORNATE])
		end
	end

	-- if (self.savedVariables.conf[LW_CONF_KEEPORNATE] > LW_PRESET_ACTION_PROMPT) then
	-- 	if (itemTrait == ITEM_TRAIT_TYPE_NONE) and GetItemLinkValue(itemLink) <= 0 then
	-- 		return self:PresetToAction(self.savedVariables.conf[LW_CONF_KEEPORNATE])
	-- 	end
	-- end

	if (itemQuality == ITEM_QUALITY_TRASH) and(self.savedVariables.conf[LW_CONF_KEEPTRASH] > LW_PRESET_ACTION_PROMPT) then
		return self:PresetToAction(self.savedVariables.conf[LW_CONF_KEEPTRASH])
	end

	return LW_ACTION_UNDEFINED
end
-------------------------------------------------------------------------------
function LootWall:IsItemOfType(itemLink, itemTypeTable)
	local itemType = GetItemLinkItemType(itemLink)
	for i = 1, #itemTypeTable do
		if (itemType == itemTypeTable[i]) then
			return true
		end
	end
	return false
end
-------------------------------------------------------------------------------
function LootWall:IsInRange(value, range)
	for k, v in pairs(range) do
		if (value == v) then
			return true
		end
	end
	return false
end
-------------------------------------------------------------------------------
function LootWall:RemoveAllRules()
	self.savedVariables.itemList = { }
end
-------------------------------------------------------------------------------
function LootWall:DefaultConfig()
	self.savedVariables.conf = LW_CONF_DEFAULTS
end
-------------------------------------------------------------------------------
function LootWall:GetConfValueForKey(key)
	-- handle dropboxes
	if key == LW_CONF_QUALITY_THRESHOLD then
		local qualityValue = self.savedVariables.conf[key]
		return LW_CONF_TRANSLATE_QUALITY[tonumber(qualityValue)]
	end

	if self:IsInRange(key, { LW_CONF_KEEPALCHMAT, LW_CONF_KEEPBSMAT, LW_CONF_KEEPCLOTHMAT, LW_CONF_KEEPENCHMAT, LW_CONF_KEEPINSP, LW_CONF_KEEPNIRN, LW_CONF_KEEPORNATE, LW_CONF_KEEPSTYLEMATS, LW_CONF_KEEPWWMAT, LW_CONF_KEEPPROVMAT, LW_CONF_KEEPBAIT, LW_CONF_KEEPTRASH, LW_CONF_KEEPRES_BS, LW_CONF_KEEPRES_CLOTH, LW_CONF_KEEPRES_WW, LW_CONF_KEEPLOCKPICK }) then
		return LW_PRESET_ACTION_STRING[self.savedVariables.conf[key]]
	end

	return self.savedVariables.conf[key]
end
-------------------------------------------------------------------------------
function LootWall:SetConfValueForKey(key, value)
	-- handle dropboxes
	if key == LW_CONF_QUALITY_THRESHOLD then
		self.savedVariables.conf[key] = self:KeyForValue(LW_CONF_TRANSLATE_QUALITY, value)
	elseif self:IsInRange(key, { LW_CONF_KEEPALCHMAT, LW_CONF_KEEPBSMAT, LW_CONF_KEEPCLOTHMAT, LW_CONF_KEEPENCHMAT, LW_CONF_KEEPINSP, LW_CONF_KEEPNIRN, LW_CONF_KEEPORNATE, LW_CONF_KEEPSTYLEMATS, LW_CONF_KEEPWWMAT, LW_CONF_KEEPPROVMAT, LW_CONF_KEEPBAIT, LW_CONF_KEEPTRASH, LW_CONF_KEEPRES_BS, LW_CONF_KEEPRES_CLOTH, LW_CONF_KEEPRES_WW, LW_CONF_KEEPLOCKPICK }) then
		self.savedVariables.conf[key] = self:KeyForValue(LW_PRESET_ACTION_STRING, value)
	else
		self.savedVariables.conf[key] = value
	end
end
-------------------------------------------------------------------------------
function LootWall:KeyForValue(t, value)
	for k, v in pairs(t) do
		if v == value then
			return tonumber(k)
		end
	end
	return nil
end
-------------------------------------------------------------------------------
-- just a function to restore window to player moved pos
function LootWall:RestorePosition()
	local wLeft = self.savedVariables.wLeft
	local wTop = self.savedVariables.wTop

	self.Window.control:ClearAnchors()
	self.Window.control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, wLeft, wTop)

end
-------------------------------------------------------------------------------
-- check whether the given itemLink has a rule saved, or if it was just one time rule
function LootWall:ItemHasRule(itemLink, itemIdentifier)
	-- local itemName = GetItemLinkName(itemLink)
	if itemIdentifier == nil then itemIdentifier = self:MakeItemStringId(itemLink) end
	local itemRule = self.savedVariables.itemList[itemIdentifier]

	if (itemRule == nil) or(itemRule == LW_ACTION_UNDEFINED) or(itemRule == LW_ACTION_DESTROY_NOW) or(itemRule == LW_ACTION_KEEP_NOW) or(itemRule == LW_ACTION_TRASH_NOW) then
		return false
	else
		return true
	end

end
-------------------------------------------------------------------------------
function LootWall:ConstructAndShowWindow(itemToDisplay)
	self.Window.shown = true
	self.Window.displayItem = itemToDisplay

	local itemLink = itemToDisplay.itemLink
	-- Show next without hiding needs this
	ClearTooltipImmediately(self.Window.control)
	-- Copy function may hooked by tooltip addon, eg. Harven's Trait and Style
	self.Window.control.SetLink = PopupTooltip.SetLink
	self.Window.control:SetLink(itemLink)

	if self:GetConfValueForKey(LW_CONF_SHOWHINT) then
		self.Window.control:AddVerticalPadding(10)
		self.Window.control:AddLine("This item does not match any of your loot rules and/or you have looted it for the first time. Please select how to treat this item below.", "ZoFontGameSmall", .65, .65, .65, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
		self.Window.control:AddVerticalPadding(39)
	else
		self.Window.control:AddVerticalPadding(45)
	end

	-- Reserve space for the buttons, which overlap that
	self.Window.control:AddLine("")

	self.Window.control:SetDrawTier(DT_HIGH)
	self.Window.control:SetDrawLevel(DL_OVERLAY)

	local showDestroy = itemToDisplay.mode == nil or itemToDisplay.mode == LW_PRESET_ACTION_DESTROY or itemToDisplay.mode == LW_PRESET_ACTION_PROMPT
	local showJunk = itemToDisplay.mode == nil or itemToDisplay.mode == LW_PRESET_ACTION_JUNK or itemToDisplay.mode == LW_PRESET_ACTION_PROMPT
	local showKeep = itemToDisplay.mode == nil

	self.Window.control:GetNamedChild("_BKeepAlways"):SetEnabled(showKeep or showJunk)
	self.Window.control:GetNamedChild("_BKeepNow"):SetEnabled(showKeep or showDestroy)
	self.Window.control:GetNamedChild("_BTrashAlways"):SetEnabled(showJunk)
	self.Window.control:GetNamedChild("_BTrashNow"):SetEnabled(showJunk)
	self.Window.control:GetNamedChild("_BTrashSecondSlot"):SetEnabled(showJunk)
	self.Window.control:GetNamedChild("_BDestroyAlways"):SetEnabled(showDestroy)
	self.Window.control:GetNamedChild("_BDestroyNow"):SetEnabled(showDestroy)
	self.Window.control:GetNamedChild("_BDestroySecondSlot"):SetEnabled(showDestroy)

	if (self.savedVariables.conf[LW_CONF_SHOWCURSOR] == true) then
		SCENE_MANAGER:ShowTopLevel(self.Window.control)
	end
	self.Window.control:SetHidden(false)
end
-------------------------------------------------------------------------------
-- hide and cleanup the window
function LootWall:HideWindow()
	if (self.savedVariables.conf[LW_CONF_SHOWCURSOR] == true) then
		SCENE_MANAGER:HideTopLevel(self.Window.control)
	else
		self.Window.control:SetHidden(true)
	end
	self.Window.shown = false
	self.Window.displayItem = nil
end
-------------------------------------------------------------------------------
-- find slots with same item
do
	local result = { }
	local function Scan(bagId, itemLink)
		local GetItemLink, GetItemLink, GetSlotStackSize = GetItemLink, GetItemLink, GetSlotStackSize
		for slotIndex = 0, GetBagSize(bagId) -1 do
			local otherItemLink = GetItemLink(bagId, slotIndex)
			if otherItemLink == itemLink then
				local size, max = GetSlotStackSize(bagId, slotIndex)
				result[#result + 1] = { bagId = bagId, slotIndex = slotIndex, size = size, max = max }
			end
		end
	end
	function LootWall:GetSameSlots(itemLink)
		ZO_ClearNumericallyIndexedTable(result)

		Scan(BAG_BANK, itemLink)
		Scan(BAG_BACKPACK, itemLink)
		table.sort(result, function(a, b) return a.size > b.size end)
		return result
	end
end
-------------------------------------------------------------------------------
local function PreHookSetItemIsJunk()
	local SetItemIsJunk, DestroyItem = SetItemIsJunk, DestroyItem
	-- apply a rule to the looted item
	-- rule = int, constant, ACTION_x_x
	-- itemBagId = int, the bagId
	-- itemSlotId = int, the slotId of bag with bagId
	function LootWall:ApplyRuleToItem(rule, itemBagId, itemSlotId, itemLink)
		if (rule == LW_ACTION_TRASH_ALWAYS) or(rule == LW_ACTION_TRASH_NOW) then
			SetItemIsJunk(itemBagId, itemSlotId, true)
		elseif (rule == LW_ACTION_DESTROY_ALWAYS) or(rule == LW_ACTION_DESTROY_NOW) then
			if GetItemLink(itemBagId, itemSlotId) == itemLink then
				df("|cFF0000[LootWall]|r Destroy item %s", itemLink)
				DestroyItem(itemBagId, itemSlotId)
			end
		elseif (rule == LW_ACTION_TRASH_SECOND) then
			local result = self:GetSameSlots(itemLink)
			if #result <= 1 then return end
			if result[1].size < result[1].max then return end
			local BAG_BACKPACK, SetItemIsJunk = BAG_BACKPACK, SetItemIsJunk
			for i = #result, 2, -1 do
				local item = result[i]
				if item.bagId == BAG_BACKPACK then
					SetItemIsJunk(item.bagId, item.slotIndex, true)
				end
			end
		elseif (rule == LW_ACTION_DESTROY_SECOND) then
			local result = self:GetSameSlots(itemLink)
			if #result <= 1 then return end
			if result[1].size < result[1].max then return end
			local BAG_BACKPACK, DestroyItem = BAG_BACKPACK, DestroyItem
			for i = #result, 2, -1 do
				local item = result[i]
				if item.bagId == BAG_BACKPACK then
					DestroyItem(item.bagId, item.slotIndex)
					df("|cFF0000[LootWall]|r Destroy item seconds %s", itemLink)
				end
			end
		end
	end
end
-------------------------------------------------------------------------------
-- Button OnClick Action Functions
-------------------------------------------------------------------------------
do
	local function SaveAndApplyRule(self, rule)
		local displayedItem = self.Window.displayItem

		-- local itemName = GetItemLinkName(displayedItem.itemLink)

		local id = self:MakeItemStringId(displayedItem.itemLink)
		if rule ~= LW_ACTION_KEEP_NOW and rule ~= LW_ACTION_TRASH_NOW and rule ~= LW_ACTION_DESTROY_NOW then
			self.savedVariables.itemList[id] = rule
		end
		self:ApplyRuleToItem(rule, displayedItem.bagId, displayedItem.slotId, displayedItem.itemLink)
		self:HideWindow()
	end

	-- Destroy (2. Slot) button action
	-- $(parent)_BDestroySecondSlot
	function LootWall:DestroySecondSlotAction()
		SaveAndApplyRule(self, LW_ACTION_DESTROY_SECOND)
	end
	-- Destroy (now) button action
	-- $(parent)_BDestroyNow
	function LootWall:DestroyNowAction()
		SaveAndApplyRule(self, LW_ACTION_DESTROY_NOW)
	end
	-------------------------------------------------------------------------------
	-- Destroy (Always) button action
	-- $(parent)_BDestroyAlways
	function LootWall:DestroyAlwaysAction()
		SaveAndApplyRule(self, LW_ACTION_DESTROY_ALWAYS)
	end
	-------------------------------------------------------------------------------
	-- Junk (2. Slot) button action
	-- $(parent)_BTrashSecondSlot
	function LootWall:TrashSecondSlotAction()
		SaveAndApplyRule(self, LW_ACTION_TRASH_SECOND)
	end
	-------------------------------------------------------------------------------
	-- Junk (now) button action
	-- $(parent)_BTrashNow
	function LootWall:TrashNowAction()
		SaveAndApplyRule(self, LW_ACTION_TRASH_NOW)
	end
	-------------------------------------------------------------------------------
	-- Junk (Always) button action
	-- $(parent)_BTrashAlways
	function LootWall:TrashAlwaysAction()
		SaveAndApplyRule(self, LW_ACTION_TRASH_ALWAYS)
	end
	-------------------------------------------------------------------------------
	-- Keep (now) button action
	-- $(parent)_BKeepNow
	function LootWall:KeepNowAction()
		SaveAndApplyRule(self, LW_ACTION_KEEP_NOW)
	end
	-------------------------------------------------------------------------------
	-- Keep (Always) button action
	-- $(parent)_BKeepAlways
	function LootWall:KeepAlwaysAction()
		SaveAndApplyRule(self, LW_ACTION_KEEP_ALWAYS)
	end
end
-- end of Button Actions

-------------------------------------------------------------------------------
do
	ZO_CreateStringId("SI_BINDING_NAME_LOOTWALL_APPLY_RULE", "Loot Wall")

	local function ShowLootWallMenu(inventorySlot, slotActions)
		local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
		local itemLink = bagId and GetItemLink(bagId, slotIndex) or ""

		return itemLink ~= ""
	end

	local function AddMenuItem(inventorySlot, slotActions)
		slotActions:AddCustomSlotAction(SI_BINDING_NAME_LOOTWALL_APPLY_RULE, function()
			local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
			local itemLink = GetItemLink(bagId, slotIndex)

			local itemToDisplay = LWDroppedItem:new(itemLink, bagId, slotIndex)
			LootWall:ConstructAndShowWindow(itemToDisplay)
		end , "")
	end

	local function AddItem(...)
		if ShowLootWallMenu(...) then
			AddMenuItem(...)
		end
	end
	local menu = LibCustomMenu
	menu:RegisterContextMenu(AddItem)
end

-------------------------------------------------------------------------------
-- Track manual junking items
local function HookSetItemIsJunk()
	PreHookSetItemIsJunk()
	local orgSetItemIsJunk = SetItemIsJunk
	function SetItemIsJunk(...)
		-- if IsUnitInCombat("player") then return end
		local bagId, slotId, isJunk = ...
		local itemLink = GetItemLink(bagId, slotId)
		local identifier = LootWall:MakeItemStringId(itemLink)
		if isJunk then
			local itemQuality = GetItemLinkQuality(itemLink)
			if itemQuality >= tonumber(LootWall.savedVariables.conf[LW_CONF_QUALITY_THRESHOLD]) then
				local droppedItem = LWDroppedItem:new(itemLink, bagId, slotId)
				droppedItem.mode = LW_PRESET_ACTION_JUNK
				table.insert(LootWall.Buffer, 1, droppedItem)
				return
			else
				LootWall:ApplyRuleToItem(LW_ACTION_TRASH_ALWAYS, bagId, slotId, itemLink)
			end
		else
			local droppedItem = LWDroppedItem:new(itemLink, bagId, slotId)
			table.insert(LootWall.Buffer, 1, droppedItem)
			droppedItem.mode = LW_PRESET_ACTION_PROMPT
		end
		return orgSetItemIsJunk(...)
	end
	local orgZO_InventorySlot_InitiateDestroyItem = ZO_InventorySlot_InitiateDestroyItem
	function ZO_InventorySlot_InitiateDestroyItem(...)
		local bagId, slotId = ZO_Inventory_GetBagAndIndex(...)
		local itemLink = GetItemLink(bagId, slotId)
		local itemQuality = GetItemLinkQuality(itemLink)
		if itemQuality >= tonumber(LootWall.savedVariables.conf[LW_CONF_QUALITY_THRESHOLD]) then
			local droppedItem = LWDroppedItem:new(itemLink, bagId, slotId)
			droppedItem.mode = LW_PRESET_ACTION_DESTROY
			table.insert(LootWall.Buffer, 1, droppedItem)
			return
		end
		return orgZO_InventorySlot_InitiateDestroyItem(...)
	end
end

-------------------------------------------------------------------------------
-- This is not used, but it was a start
function LootWall:OnItemLooted(eventCode, lootedBy, itemLink, quantity, itemSound, lootType, isSelf, isPickPocketLoot)
	if ((not isSelf) or(isPickPocketLoot)) then
		return
	end


	local icon, sellPrice, meetsUsageRequirement, equipType, itemStyle = GetItemLinkInfo(itemLink)
	local trueName = GetItemLinkName(itemLink)
	d(itemLink)
	d(icon)
	self.Window.label:SetText(trueName)
	self.Window.icon:SetTexture(icon)
end
-------------------------------------------------------------------------------
-- called when an item is added to the inventory
function LootWall:OnInventoryUpdate(eventCode, bagId, slotId, isNewItem, itemSoundCategory, updateReason)
	if (not isNewItem) or(updateReason ~= INVENTORY_UPDATE_REASON_DEFAULT) then
		return
	end

	if bagId ~= BAG_BACKPACK then
		return
	end

	if self.ignoreLoot == true then
		return
	end

	if (GetItemFilterTypeInfo(bagId, slotId) == ITEMFILTERTYPE_QUEST) then
		return
	end

	local itemLink = GetItemLink(bagId, slotId)
	if itemLink == "" then return end

	-- local itemName = GetItemLinkName(itemLink)

	local itemIdentifier = self:MakeItemStringId(itemLink)
	-- local defaultAction = self:DefaultActionForLink(itemLink)
	local defaultAction = self.savedVariables.itemList[itemIdentifier] or self:DefaultActionForLink(itemLink)
	-- if action and action > LW_ACTION_KEEP_NOW and action < defaultAction then defaultAction = action end
	if defaultAction ~= LW_ACTION_UNDEFINED then
		self:ApplyRuleToItem(defaultAction, bagId, slotId, itemLink)
	else
		-- 	if self:ItemHasRule(itemLink, itemIdentifier) then
		-- 		self:ApplyRuleToItem(self.savedVariables.itemList[itemIdentifier], bagId, slotId, itemLink)
		-- 	else
		local droppedItem = LWDroppedItem:new(itemLink, bagId, slotId)
		table.insert(self.Buffer, 1, droppedItem)
		-- 	end
	end
end
-------------------------------------------------------------------------------
-- the OnLoad event handler
local function OnAddOnLoaded(event, addonName)

	if addonName == LootWall.name then
		EVENT_MANAGER:UnregisterForEvent(LootWall.name, EVENT_ADD_ON_LOADED)
		LootWall:Initialize()
		HookSetItemIsJunk()
	end
end
-------------------------------------------------------------------------------
-- the window was moved, let`s save the values of where it went, so I don`t loose it
function LootWall:OnWindowMoveStop()
	self.savedVariables.wLeft = self.Window.control:GetLeft()
	self.savedVariables.wTop = self.Window.control:GetTop()
end
-------------------------------------------------------------------------------
-- called every 250ms, if not in combat and have an looted item in buffer, display id
-- v 0.2: check if rule was not set after adding item to buffer
function LootWall:OnUpdate()
	local hiddenForReason = IsUnitInCombat("player") or IsPlayerMoving()
	if (self.Window.shown == false) and(hiddenForReason == false) then
		local itemToShow = table.remove(LootWall.Buffer)
		if itemToShow ~= nil then
			-- +v 0.2 check if rule wasn't created in the mean time
			if (itemToShow.mode or not self:ItemHasRule(itemToShow.itemLink)) then
				self:ConstructAndShowWindow(itemToShow)
			end
		end
	elseif (self.Window.shown == true) and(hiddenForReason) then
		if (self.Window.displayItem ~= nil) then
			table.insert(LootWall.Buffer, self.Window.displayItem)
		end
		self:HideWindow()
	end
end
-------------------------------------------------------------------------------
function LootWall:GameCameraDeactivated()
	if self.gameCameraInactive == false then
		self.gameCameraInactive = true
		SetGameCameraUIMode(true)
	end
end
-------------------------------------------------------------------------------
-- EVENT_GAME_CAMERA_ACTIVATED
function LootWall:GameCameraActivated()
	if self.gameCameraInactive == true then
		self.gameCameraInactive = false
		SetGameCameraUIMode(false)
	end
end
-------------------------------------------------------------------------------
function LootWall:StartLootIgnore(ignoreSource)
	if (self.savedVariables.conf[ignoreSource] == true) then
		self.ignoreLoot = true
	end
end
-------------------------------------------------------------------------------
function LootWall:EndLootIgnore(ignoreSource)
	self.ignoreLoot = false
end
-------------------------------------------------------------------------------
function LootWall:StoreOpened()
	local sellJunk = self.savedVariables.conf[LW_CONF_SELLJUNK] or false
	if (sellJunk) and(HasAnyJunk(BAG_BACKPACK)) then
		SellAllJunk()
		d("|cFF0000[LootWall]|cFFFFFFSold all junk.|r")
	end
end
-------------------------------------------------------------------------------
-- Register for load event
EVENT_MANAGER:RegisterForEvent(LootWall.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
