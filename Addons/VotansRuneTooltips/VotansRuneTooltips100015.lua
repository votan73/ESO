local addon = {
	name = "VotansRuneTooltips",
	runes =
	{
		-- Jora --
		[45855] = { bonus = 1, },
		-- Porade --
		[45856] = { bonus = 1, },
		-- Jera --
		[45857] = { bonus = 2, },
		-- Jejora --
		[45806] = { bonus = 2, },
		-- Odra --
		[45807] = { bonus = 3, },
		-- Pojora --
		[45808] = { bonus = 3, },
		-- Edora --
		[45809] = { bonus = 4, },
		-- Jaera --
		[45810] = { bonus = 4, },
		-- Pora --
		[45811] = { bonus = 5, },
		-- Denara --
		[45812] = { bonus = 5, },
		-- Rera --
		[45813] = { bonus = 6, },
		-- Derado --
		[45814] = { bonus = 7, },
		-- Rekura --
		[45815] = { bonus = 8, },
		-- Kura --
		[45816] = { bonus = 9, },
		-- Jode --
		[45817] = { bonus = 1, },
		-- Notade --
		[45818] = { bonus = 1, },
		-- Ode --
		[45819] = { bonus = 2, },
		-- Tade --
		[45820] = { bonus = 2, },
		-- Jayde --
		[45821] = { bonus = 3, },
		-- Edode --
		[45822] = { bonus = 3, },
		-- Pojode --
		[45823] = { bonus = 4, },
		-- Rekude --
		[45824] = { bonus = 4, },
		-- Hade --
		[45825] = { bonus = 5, },
		-- Idode --
		[45826] = { bonus = 5, },
		-- Pode --
		[45827] = { bonus = 6, },
		-- Kedeko --
		[45828] = { bonus = 7, },
		-- Rede --
		[45829] = { bonus = 8, },
		-- Kude --
		[45830] = { bonus = 9, },
		-- Jehade --
		[64508] = { bonus = 10, },
		-- Rejera --
		[64509] = { bonus = 10, },
		-- Itade --
		[68340] = { bonus = 10, },
		-- Repora --
		[68341] = { bonus = 10, },

		-- Oko --
		[45831] = { glyphTypePositive = ITEMTYPE_GLYPH_ARMOR, glyphTypeNegative = ITEMTYPE_GLYPH_WEAPON },
		-- Makko --
		[45832] = { glyphTypePositive = ITEMTYPE_GLYPH_ARMOR, glyphTypeNegative = ITEMTYPE_GLYPH_WEAPON },
		-- Deni --
		[45833] = { glyphTypePositive = ITEMTYPE_GLYPH_ARMOR, glyphTypeNegative = ITEMTYPE_GLYPH_WEAPON },
		-- Okoma --
		[45834] = { glyphTypePositive = ITEMTYPE_GLYPH_JEWELRY, glyphTypeNegative = ITEMTYPE_GLYPH_WEAPON },
		-- Makkoma --
		[45835] = { glyphTypePositive = ITEMTYPE_GLYPH_JEWELRY, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY },
		-- Denima --
		[45836] = { glyphTypePositive = ITEMTYPE_GLYPH_JEWELRY, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY },
		-- Kuoko --
		[45837] = { glyphTypePositive = ITEMTYPE_GLYPH_WEAPON, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY },
		-- Rakeipa --
		[45838] = { glyphTypePositive = ITEMTYPE_GLYPH_WEAPON, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY },
		-- Dakeipa --
		[45839] = { glyphTypePositive = ITEMTYPE_GLYPH_WEAPON, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY },
		-- Meip --
		[45840] = { glyphTypePositive = ITEMTYPE_GLYPH_WEAPON, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY },
		-- Haoko --
		[45841] = { glyphTypePositive = ITEMTYPE_GLYPH_WEAPON, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY },
		-- Deteri --
		[45842] = { glyphTypePositive = ITEMTYPE_GLYPH_WEAPON, glyphTypeNegative = ITEMTYPE_GLYPH_WEAPON },
		-- Okori --
		[45843] = { glyphTypePositive = ITEMTYPE_GLYPH_WEAPON, glyphTypeNegative = ITEMTYPE_GLYPH_WEAPON },
		-- Jaedi --
		[45844] = { glyphTypePositive = ITEMTYPE_GLYPH_WEAPON, glyphTypeNegative = ITEMTYPE_GLYPH_WEAPON },
		-- Lire --
		[45845] = { glyphTypePositive = ITEMTYPE_GLYPH_WEAPON, glyphTypeNegative = ITEMTYPE_GLYPH_WEAPON },
		-- Oru --
		[45846] = { glyphTypePositive = ITEMTYPE_GLYPH_JEWELRY, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY },
		-- Taderi --
		[45847] = { glyphTypePositive = ITEMTYPE_GLYPH_JEWELRY, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY },
		-- Makderi --
		[45848] = { glyphTypePositive = ITEMTYPE_GLYPH_JEWELRY, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY },
		-- Kaderi --
		[45849] = { glyphTypePositive = ITEMTYPE_GLYPH_JEWELRY, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY },
		-- Hakeijo --
		[68342] = { glyphTypePositive = ITEMTYPE_GLYPH_ARMOR, glyphTypeNegative = ITEMTYPE_GLYPH_WEAPON },
		-- Indeko --
		[166045] = {glyphTypePositive = ITEMTYPE_GLYPH_JEWELRY, glyphTypeNegative = ITEMTYPE_GLYPH_JEWELRY},

		-- Ta --
		[45850] = { bonus = 1, },
		-- Jejota --
		[45851] = { bonus = 1, },
		-- Denata --
		[45852] = { bonus = 2, },
		-- Rekuta --
		[45853] = { bonus = 3, },
		-- Kuta --
		[45854] = { bonus = 4, },
	},
	showPotencyInfo = function() return true end,
	showEssenceInfo = function() return true end,
}

local function GetLevelOrChampionString(min, cpMin)
	if min and min < 50 then
		return min
	else
		return "|t28:28:esoui/art/champion/champion_icon.dds|t" .. cpMin
	end
end

local function GetRuneInfoText(itemLink)
	local success, runeType, known, itemId = pcall( function()
		local isRune = IsItemLinkEnchantingRune(itemLink)
		if not isRune then return ENCHANTING_RUNE_NONE, nil, nil end
		local runeType = GetItemLinkEnchantingRuneClassification(itemLink)
		local id = itemLink:match("|H[^:]+:item:([^:]+):")
		local known = GetItemLinkEnchantingRuneName(itemLink)

		return runeType, known, tonumber(id)
	end )
	if not success then
		d("VotansRuneTooltips failure: valid itemLink", itemLink)
		return nil
	end
	if runeType == ENCHANTING_RUNE_POTENCY and(known or addon.settings.showUnknownPotency) and addon.showPotencyInfo() then
		local lvlMin, cpMin = GetItemLinkGlyphMinLevels(itemLink)
		if not cpMin then
			return zo_strformat(GetString(SI_ENCHANTING_GLYPH_REQUIRED_SINGLE_LEVEL), lvlMin)
		else
			return zo_strformat(GetString(SI_ENCHANTING_GLYPH_REQUIRED_SINGLE_CHAMPION_POINTS), cpMin)
		end
	elseif runeType == ENCHANTING_RUNE_ESSENCE and(known or addon.settings.showUnknownEssence) and addon.showEssenceInfo() then
		local info = addon.runes[itemId]
		if info then
			return zo_strformat(GetString("SI_RUNETOOLTIP_ESSENCE_RUNE_GLYPH", itemId), GetString("SI_ITEMTYPE", info.glyphTypePositive, 1), GetString("SI_ITEMTYPE", info.glyphTypeNegative, 1))
		end
		-- elseif runeType == ENCHANTING_RUNE_ASPECT then
	end
	return nil
end

local function AddRuneInfo(tooltip, rune)
	if rune then
		tooltip:AddVerticalPadding(8)
		tooltip:AddLine(rune, "", 1, 1, 1, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
	end
end

local mystyle = { fontSize = 34, fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1, }
local function AddRuneInfo_Gamepad(tooltip, rune)
	if rune then
		tooltip:AddLine(rune, mystyle, tooltip:GetStyle("bodySection"))
	end
end

local function TooltipHook(tooltipControl, method, linkFunc)
	local origMethod = tooltipControl[method]

	tooltipControl[method] = function(self, ...)
		origMethod(self, ...)
		AddRuneInfo(self, GetRuneInfoText(linkFunc(...)))
	end
end

local function TooltipHook_Gamepad(tooltipControl, method, linkFunc)
	local origMethod = tooltipControl[method]

	tooltipControl[method] = function(self, ...)
		local result = origMethod(self, ...)
		AddRuneInfo_Gamepad(self, GetRuneInfoText(linkFunc(...)))
		return result
	end
end

local function ReturnItemLink(itemLink)
	return itemLink
end

local function HookBagTips()
	TooltipHook(ItemTooltip, "SetBagItem", GetItemLink)
	TooltipHook(ItemTooltip, "SetTradeItem", GetTradeItemLink)
	TooltipHook(ItemTooltip, "SetBuybackItem", GetBuybackItemLink)
	TooltipHook(ItemTooltip, "SetStoreItem", GetStoreItemLink)
	TooltipHook(ItemTooltip, "SetAttachedMailItem", GetAttachedItemLink)
	TooltipHook(ItemTooltip, "SetLootItem", GetLootItemLink)
	TooltipHook(ItemTooltip, "SetTradingHouseItem", GetTradingHouseSearchResultItemLink)
	TooltipHook(ItemTooltip, "SetTradingHouseListing", GetTradingHouseListingItemLink)
	TooltipHook(ItemTooltip, "SetLink", ReturnItemLink)

	TooltipHook(PopupTooltip, "SetLink", ReturnItemLink)

	TooltipHook_Gamepad(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_LEFT_TOOLTIP), "LayoutItem", ReturnItemLink)
	TooltipHook_Gamepad(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_RIGHT_TOOLTIP), "LayoutItem", ReturnItemLink)
	TooltipHook_Gamepad(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_MOVABLE_TOOLTIP), "LayoutItem", ReturnItemLink)
end

local function InitSettings()
	local LibHarvensAddonSettings = LibHarvensAddonSettings or LibStub("LibHarvensAddonSettings-1.0")
	if not LibHarvensAddonSettings then return end

	local settings = LibHarvensAddonSettings:AddAddon("Votan's Rune Tooltips")
	if not settings then return end
	addon.settingsControls = settings
	settings.version = "1.4.7"
	settings.website = "http://www.esoui.com/downloads/info915-VotansRuneTooltips.html"

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_LABEL,
		label = GetString(SI_RUNETOOLTIP_RUNE_SHOW_UNKNOWN),
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = " |u12:0::|u" .. GetString(SI_RUNETOOLTIP_POTENCY_RUNE_SHOW_UNKNOWN),
		tooltip = nil,
		getFunction = function() if addon.showPotencyInfo() then return addon.settings.showUnknownPotency else return false end end,
		setFunction = function(value) addon.settings.showUnknownPotency = value end,
		disable = function() return not addon.showPotencyInfo() end,
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = " |u12:0::|u" .. GetString(SI_RUNETOOLTIP_ESSENCE_RUNE_SHOW_UNKNOWN),
		tooltip = nil,
		getFunction = function() return addon.settings.showUnknownEssence end,
		setFunction = function(value) addon.settings.showUnknownEssence = value end,
	}

end

do
	local savedVars
	local function ShowPotencyInfoQuickEnchanter()
		addon.showPotencyInfo = function()
			if not savedVars then
				savedVars = ZO_SavedVars:NewAccountWide("QuickEnchanter_SavedVariables", 1, nil, nil, nil)
			end
			return not(savedVars.show_potency_level_tooltip or false)
		end
	end

	local function OnAddOnLoaded(event, addonName)
		if addonName == addon.name then
			addon.settings = ZO_SavedVars:NewAccountWide("VotansRuneTooltips_Storage", 1, nil, { showUnknownPotency = true, showUnknownEssence = true }, nil)

			InitSettings()
			HookBagTips()
		elseif addonName == "QuickEnchanter" then
			ShowPotencyInfoQuickEnchanter()
		end
	end

	EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
end
