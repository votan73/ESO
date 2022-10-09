local EnchantedQuality = {
	Name = "EnchantedQuality",
	Author = "Rhyono & votan",
	Version = "1.34",
	SettingsVersion = "1.13"
}

local LAM = LibAddonMenu2

local orgEnchantString = GetString(SI_ITEM_FORMAT_STR_ENCHANT_HEADER_NAMED)
local orgEnchantStringMulti = GetString(SI_ITEM_FORMAT_STR_ENCHANT_HEADER_MULTI_EFFECT)
local orgItemNameString = GetString(SI_TOOLTIP_ITEM_NAME)
local includeQuality = { }
local includeQualityMulti = { }
local subIdToQuality = { }
local lang = GetCVar("language.2")

EnchantedQuality.Default = { ['item_text'] = false, ['enchant_text'] = false, ['enchant_color'] = true }

local function GetEnchantQuality(itemLink)
	local itemId, itemIdSub, enchantSub = itemLink:match("|H[^:]+:item:([^:]+):([^:]+):[^:]+:[^:]+:([^:]+):")
	if not itemId then return 0 end
	enchantSub = tonumber(enchantSub)
	if enchantSub == 0 and not IsItemLinkCrafted(itemLink) then
		local hasSet = GetItemLinkSetInfo(itemLink, false)
		-- For non-crafted sets, the "built-in" enchantment has the same quality as the item itself
		if hasSet then enchantSub = tonumber(itemIdSub) end
	end
	if enchantSub > 0 then
		local quality = subIdToQuality[enchantSub]
		if not quality then
			-- Create a fake itemLink to get the quality from built-in function
			local itemLink = string.format("|H1:item:%i:%i:50:0:0:0:0:0:0:0:0:0:0:0:0:1:1:0:0:10000:0|h|h", itemId, enchantSub)
			quality = GetItemLinkQuality(itemLink)
			subIdToQuality[enchantSub] = quality
		end
		return quality
	end
	return 0
end

local function TooltipHook(tooltipControl, method, linkFunc)
	local origMethod = tooltipControl[method]

	tooltipControl[method] = function(self, ...)
		local modified = false
		local itemLink = linkFunc(...)
		if EnchantedQuality.SavedVars.item_text then
			local itemType = GetItemLinkItemType(itemLink)
			if itemType == ITEMTYPE_ARMOR or itemType == ITEMTYPE_WEAPON then
				local item_quality = GetItemLinkQuality(itemLink)
				local item_color = GetString("SI_ITEMQUALITY", item_quality)
				if #item_color ~= 0 then
					local format = string.format(GetString(SI_ENCHANT_QUALITY_TOOLTIP_ITEM_NAME), item_color, item_color, item_color, item_color)
					SafeAddString(SI_TOOLTIP_ITEM_NAME, format, 2)
					modified = true
				end
			end
		end
		if EnchantedQuality.SavedVars.enchant_color or EnchantedQuality.SavedVars.enchant_text then
			local itemType = GetItemLinkItemType(itemLink)
			if itemType == ITEMTYPE_ARMOR or itemType == ITEMTYPE_WEAPON then
				local quality = GetEnchantQuality(itemLink)
				if quality > 0 then
					SafeAddString(SI_ITEM_FORMAT_STR_ENCHANT_HEADER_NAMED, includeQuality[quality], 2)
					SafeAddString(SI_ITEM_FORMAT_STR_ENCHANT_HEADER_MULTI_EFFECT, includeQualityMulti[quality], 2)
					modified = true
				end
			end
		end
		if modified then
			local result = origMethod(self, ...)
			if EnchantedQuality.SavedVars.item_text then
				SafeAddString(SI_TOOLTIP_ITEM_NAME, orgItemNameString, 2)
			end
			if EnchantedQuality.SavedVars.enchant_color or EnchantedQuality.SavedVars.enchant_text then
				SafeAddString(SI_ITEM_FORMAT_STR_ENCHANT_HEADER_NAMED, orgEnchantString, 2)
				SafeAddString(SI_ITEM_FORMAT_STR_ENCHANT_HEADER_MULTI_EFFECT, orgEnchantStringMulti, 2)
			end
			return result
		else
			return origMethod(self, ...)
		end
	end
end

local function ReturnItemLink(itemLink)
	return itemLink
end

local function GetWornItemLinkGameData(equipSlot, actorCategory)
	local bagId = actorCategory ~= GAMEPLAY_ACTOR_CATEGORY_COMPANION and BAG_WORN or BAG_COMPANION_WORN
	return GetItemLink(bagId, equipSlot)
end
local function GetWornItemLinkTooltip(equipSlot, bagId)
	return GetItemLink(bagId, equipSlot)
end

local function EnchantOnAddGameData(tooltip, gameDataType, ...)
	if gameDataType == TOOLTIP_GAME_DATA_EQUIPPED_INFO then
		local itemLink = GetWornItemLinkGameData(...)
		if EnchantedQuality.SavedVars.item_text then
			local item_quality = GetItemLinkQuality(itemLink)
			local item_color = GetString("SI_ITEMQUALITY", item_quality)
			if #item_color ~= 0 then
				local format = string.format(GetString(SI_ENCHANT_QUALITY_TOOLTIP_ITEM_NAME), item_color, item_color, item_color, item_color)
				SafeAddString(SI_TOOLTIP_ITEM_NAME, format, 2)
			end
		end
		if EnchantedQuality.SavedVars.enchant_color or EnchantedQuality.SavedVars.enchant_text then
			local quality = GetEnchantQuality(itemLink)
			if quality > 0 then
				-- Set string only. Will be used right after the prehook.
				SafeAddString(SI_ITEM_FORMAT_STR_ENCHANT_HEADER_NAMED, includeQuality[quality], 2)
				SafeAddString(SI_ITEM_FORMAT_STR_ENCHANT_HEADER_MULTI_EFFECT, includeQualityMulti[quality], 2)
			end
		end
	elseif gameDataType == TOOLTIP_GAME_DATA_STOLEN then
		-- This is called afterwards. Reset string:
		SafeAddString(SI_TOOLTIP_ITEM_NAME, orgItemNameString, 2)
		SafeAddString(SI_ITEM_FORMAT_STR_ENCHANT_HEADER_NAMED, orgEnchantString, 2)
		SafeAddString(SI_ITEM_FORMAT_STR_ENCHANT_HEADER_MULTI_EFFECT, orgEnchantStringMulti, 2)
	end
end

local function EQColorize(target,quality,item_color)
	--Text and color on
	if EnchantedQuality.SavedVars.enchant_text and EnchantedQuality.SavedVars.enchant_color then
		return GetItemQualityColor(quality):Colorize(string.format(target, item_color, item_color, item_color, item_color))
	--Only text on
	elseif EnchantedQuality.SavedVars.enchant_text and not EnchantedQuality.SavedVars.enchant_color then
		return string.format(target, item_color, item_color, item_color, item_color)
	--Only color on
	else
		return GetItemQualityColor(quality):Colorize(target)
	end
end

local function QualitySet()
	local single, multiple = orgEnchantString, orgEnchantStringMulti
	--Only add quality name if enabled
	if EnchantedQuality.SavedVars.enchant_text then
		single, multiple = GetString(SI_ENCHANT_QUALITY_ENCHANTED_NAME), GetString(SI_ENCHANT_QUALITY_ENCHANTED_NAME_MULTI_EFFECT)
	end
	for quality = ITEM_FUNCTIONAL_QUALITY_MIN_VALUE, ITEM_FUNCTIONAL_QUALITY_MAX_VALUE do
		local item_color = GetString("SI_ITEMDISPLAYQUALITY", quality)
		includeQuality[quality] = EQColorize(single,quality,item_color)
		includeQualityMulti[quality] = EQColorize(multiple,quality,item_color)
	end
end

local function HookTooltips()
	TooltipHook(ItemTooltip, "SetBagItem", GetItemLink)
	TooltipHook(ItemTooltip, "SetWornItem", GetWornItemLinkTooltip)
	TooltipHook(ItemTooltip, "SetTradeItem", GetTradeItemLink)
	TooltipHook(ItemTooltip, "SetBuybackItem", GetBuybackItemLink)
	TooltipHook(ItemTooltip, "SetStoreItem", GetStoreItemLink)
	TooltipHook(ItemTooltip, "SetAttachedMailItem", GetAttachedItemLink)
	TooltipHook(ItemTooltip, "SetLootItem", GetLootItemLink)
	TooltipHook(ItemTooltip, "SetTradingHouseItem", GetTradingHouseSearchResultItemLink)
	TooltipHook(ItemTooltip, "SetTradingHouseListing", GetTradingHouseListingItemLink)
	TooltipHook(ItemTooltip, "SetLink", ReturnItemLink)

	TooltipHook(PopupTooltip, "SetLink", ReturnItemLink)

	TooltipHook(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_LEFT_TOOLTIP), "LayoutItem", ReturnItemLink)
	TooltipHook(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_RIGHT_TOOLTIP), "LayoutItem", ReturnItemLink)
	TooltipHook(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_MOVABLE_TOOLTIP), "LayoutItem", ReturnItemLink)

	-- TooltipHook(ZO_SmithingTopLevelCreationPanelResultTooltip, "SetPendingSmithingItem", GetSmithingPatternResultLink)
	-- TooltipHook(ZO_SmithingTopLevelImprovementPanelResultTooltip, "SetSmithingImprovementResult", GetSmithingImprovedItemLink)

	ZO_PreHookHandler(ComparativeTooltip1, "OnAddGameData", EnchantOnAddGameData)
	ZO_PreHookHandler(ComparativeTooltip2, "OnAddGameData", EnchantOnAddGameData)
end

local function SettingsUpdate(setname, setval)
	EnchantedQuality.SavedVars[setname] = setval
	QualitySet()
end

-- Menu
local panelData = {
	type = "panel",
	name = "Enchanted Quality",
	displayName = "Enchanted Quality",
	author = EnchantedQuality.Author,
	version = EnchantedQuality.Version,
	slashCommand = "/eqoptions",
	registerForRefresh = true,
	registerForDefaults = true,
}

local optionsTable = {
	{
		type = "checkbox",
		name = GetString(SI_ENCHANT_QUALITY_MENU_ITEM_QUALITY_TEXT),
		tooltip = GetString(SI_ENCHANT_QUALITY_MENU_ITEM_QUALITY_TOOLTIP),
		getFunc = function() return EnchantedQuality.SavedVars.item_text end,
		setFunc = function(value) SettingsUpdate('item_text', value) end,
		default = EnchantedQuality.Default.item_text,
	},
	{
		type = "checkbox",
		name = GetString(SI_ENCHANT_QUALITY_MENU_ENCHANT_QUALITY_TEXT),
		tooltip = GetString(SI_ENCHANT_QUALITY_MENU_ENCHANT_QUALITY_TOOLTIP),
		getFunc = function() return EnchantedQuality.SavedVars.enchant_text end,
		setFunc = function(value) SettingsUpdate('enchant_text', value) end,
		default = EnchantedQuality.Default.enchant_text,
	},
	{
		type = "checkbox",
		name = GetString(SI_ENCHANT_QUALITY_MENU_ENCHANT_COLOR_TEXT),
		tooltip = GetString(SI_ENCHANT_QUALITY_MENU_ENCHANT_COLOR_TOOLTIP),
		getFunc = function() return EnchantedQuality.SavedVars.enchant_color end,
		setFunc = function(value) SettingsUpdate('enchant_color', value) end,
		default = EnchantedQuality.Default.enchant_color,
	},
}

local function OnAddOnLoaded(event, addonName)
	if addonName == EnchantedQuality.Name then
		EnchantedQuality.SavedVars = ZO_SavedVars:NewAccountWide("EnchantedQualityVars", EnchantedQuality.SettingsVersion, nil, EnchantedQuality.Default)
		QualitySet()
		HookTooltips()

		LAM:RegisterAddonPanel(EnchantedQuality.Name, panelData)
		LAM:RegisterOptionControls(EnchantedQuality.Name, optionsTable)

		EVENT_MANAGER:UnregisterForEvent(EnchantedQuality.Name, EVENT_ADD_ON_LOADED)
	end
end

EVENT_MANAGER:RegisterForEvent(EnchantedQuality.Name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
