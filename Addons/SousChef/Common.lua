local SousChef = SousChef
local u = SousChef.Utility
local m = SousChef.Media
local str = SousChef.Strings[SousChef.lang]

local COOKING_RANK_1 = [[SousChef/media/One.dds]]
local COOKING_RANK_2 = [[SousChef/media/Two.dds]]
local COOKING_RANK_3 = [[SousChef/media/Three.dds]]
local COOKING_RANK_4 = [[SousChef/media/Four.dds]]
local COOKING_RANK_5 = [[SousChef/media/Five.dds]]
local COOKING_RANK_6 = [[SousChef/media/Six.dds]]
local COOKING_FLAVOUR = [[SousChef/media/Flavour.dds]]
local COOKING_SPICE = [[SousChef/media/Spice.dds]]
local COOKING_RANK_1B = [[SousChef/media/One_flat.dds]]
local COOKING_RANK_2B = [[SousChef/media/Two_flat.dds]]
local COOKING_RANK_3B = [[SousChef/media/Three_flat.dds]]
local COOKING_RANK_4B = [[SousChef/media/Four_flat.dds]]
local COOKING_RANK_5B = [[SousChef/media/Five_flat.dds]]
local COOKING_RANK_6B = [[SousChef/media/Six_flat.dds]]
local COOKING_FLAVOURB = [[SousChef/media/flavour_flat.dds]]
local COOKING_SPICEB = [[SousChef/media/Spice_Flat.dds]]

local GRILLED = [[/esoui/art/treeicons/provisioner_indexicon_meat_down.dds]]
local BREADPIE = [[/esoui/art/treeicons/provisioner_indexicon_baked_down.dds]]
local SOUPSTEW = [[/esoui/art/treeicons/provisioner_indexicon_stew_down.dds]]
local BEER = [[/esoui/art/treeicons/provisioner_indexicon_beer_down.dds]]
local SPIRITS = [[/esoui/art/treeicons/provisioner_indexicon_spirits_down.dds]]
local WINE = [[/esoui/art/treeicons/provisioner_indexicon_wine_down.dds]]
local GENERAL_DRINK = [[/esoui/art/inventory/inventory_quest_tabicon_active.dds]]
local FRUIT = [[//esoui/art/progression/progression_indexicon_race_down.dds]]
local VEGGIES = [[/esoui/art/compass/ava_farm_neutral.dds]]
local TONICS = [[/esoui/art/crafting/alchemy_tabicon_solvent_down.dds]]

-- 		1-food spice, 2-drink flavoring, 3-meat, 4-fruit, 5-veg, 6-booze, 7-teas, 8-tonics, 9-general foods, 10-general drinks
m.COOKING = {COOKING_SPICE, COOKING_FLAVOUR, GRILLED, FRUIT, VEGGIES, SPIRITS, BEER, TONICS, SOUPSTEW, GENERAL_DRINK, "EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_down.dds"}
-- m.COOKINGB = {COOKING_SPICEB, COOKING_FLAVOURB, GRILLED, SOUPSTEW, BREADPIE, BEER, SPIRITS, WINE, COOKING_RANK_1B, COOKING_RANK_2B}

-- m.COOKING = { COOKING_RANK_1, COOKING_RANK_2, COOKING_RANK_3, COOKING_RANK_4, COOKING_RANK_5, COOKING_RANK_6, COOKING_FLAVOUR, COOKING_SPICE, GRILLED, BREADPIE, SOUPSTEW, BEER, SPIRITS, WINE}
-- m.COOKINGB = { COOKING_RANK_1B, COOKING_RANK_2B, COOKING_RANK_3B, COOKING_RANK_4B, COOKING_RANK_5B, COOKING_RANK_6B, COOKING_FLAVOURB, COOKING_SPICEB, GRILLED, BREADPIE, SOUPSTEW, BEER, SPIRITS, WINE}

m.CANLEARN = [[/esoui/art/loot/loot_finesseitem.dds]]

local INVENTORIES = {
	[PLAYER_INVENTORY.inventories[1].listView] = {GetItemLink, "bagId", "slotIndex"},
	-- Backpack
	[PLAYER_INVENTORY.inventories[3].listView] = {GetItemLink, "bagId", "slotIndex"},
	-- Bank
	[PLAYER_INVENTORY.inventories[4].listView] = {GetItemLink, "bagId", "slotIndex"},
	-- GuildBank
	[LOOT_WINDOW.list] = {GetLootItemLink, "lootId", nil},
	-- LootWindow
	[STORE_WINDOW.list] = {GetStoreItemLink, "slotIndex", nil}
	-- Store
}
local rowClicked = {}

local function TooltipHook(tooltipControl, method, linkFunc)
	local origMethod = tooltipControl[method]

	tooltipControl[method] = function(self, ...)
		origMethod(self, ...)
		SousChef.AddDetails(self, linkFunc(...))
	end
end

-- local function TooltipHook_Gamepad(tooltipControl, method, linkFunc)
-- local origMethod = tooltipControl[method]

-- tooltipControl[method] = function(self, ...)
-- 	local result = origMethod(self, ...)
-- 	AddRuneInfo_Gamepad(self, GetRuneInfoText(linkFunc(...)))
-- 	return result
-- end
-- end

local function ReturnItemLink(itemLink)
	return itemLink
end

function SousChef.HookInventory()
	for list, funcs in pairs(INVENTORIES) do
		if list and list.dataTypes and list.dataTypes[1] then
			local listName = list:GetName()
			SousChef.hookedFunctions[listName] = list.dataTypes[1].setupCallback
			if SousChef.hookedFunctions[listName] then
				list.dataTypes[1].setupCallback = function(rowControl, slot)
					SousChef.hookedFunctions[listName](rowControl, slot)
					SousChef.AddRankToSlot(rowControl, funcs)
				end
			else
				d("SousChef could not hook into the Inventory")
			end
		end
	end

	for inventoryType in pairs(PLAYER_INVENTORY.inventories) do
		PLAYER_INVENTORY.isListDirty[inventoryType] = true
	end

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
end

function SousChef.getIcon(row)
	local rankIcon = SousChef.slotLines[row:GetName()]
	if (not rankIcon) then
		rankIcon = WINDOW_MANAGER:CreateControl(row:GetName() .. "SousChef", row, CT_TEXTURE)
		SousChef.slotLines[row:GetName()] = rankIcon
	-- if SousChef.settings.showOnClick then
	--	ZO_PreHookHandler(row, "OnMouseDown", SousChef.AddDetails)
	--	ZO_PreHookHandler(row, "OnMouseExit", function(self) rowClicked = nil return false end)
	-- end
	end
	return rankIcon
end

local function CalculateHowManyCouldBeCreated(recipeListIndex, recipeIndex, numIngredients)
	local minCount

	for ingredientIndex = 1, numIngredients do
		local _, _, requiredQuantity = GetRecipeIngredientItemInfo(recipeListIndex, recipeIndex, ingredientIndex)
		local ingredientCount = GetCurrentRecipeIngredientCount(recipeListIndex, recipeIndex, ingredientIndex)

		minCount = zo_min(zo_floor(ingredientCount / requiredQuantity), minCount or math.huge)
		if minCount == 0 then
			return 0
		end
	end

	return minCount or 0
end

do
	local lines = {}
	local fav = {}
	local ZO_ERROR_COLOR = ZO_ERROR_COLOR
	local MAGIC_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, ITEM_QUALITY_MAGIC))
	local charId = GetCurrentCharacterId()

	function SousChef.AddDetails(ItemTooltip, itemLink)
		if itemLink == "" or not SousChef.scanned then
			return false
		end

		-- item is a recipe
		if GetItemLinkItemType(itemLink) == ITEMTYPE_RECIPE then
			-- ZO_Tooltip_AddDivider(ItemTooltip)
			-- ItemTooltip:AddLine(zo_strformat(str.TOOLTIP_CREATES, GetItemLinkRequiredLevel(GetItemLinkRecipeResultItemLink(itemLink)), GetItemLinkName(GetItemLinkRecipeResultItemLink(itemLink))), "ZoFontWinH5", 1, 1, 1, BOTTOM)
			if SousChef.settings.showAltKnowledge then
				ItemTooltip:AddVerticalPadding(8)
				local itemId = u.GetItemID(GetItemLinkRecipeResultItemLink(itemLink))
				local knownBy = SousChef.common.Cookbook[itemId]
				ItemTooltip:AddLine(str.TOOLTIP_KNOWN_BY, "ZoFontWinH5", 1, 1, 1, BOTTOM, MODIFY_TEXT_TYPE_UPPERCASE)
				ZO_ClearNumericallyIndexedTable(lines)
				if knownBy then
					local known = GetRecipeInfo(select(2, GetRecipeInfoFromItemId(itemId)))
					if known then
						knownBy[charId] = 1
					end
					for i = 1, GetNumCharacters() do
						local _, _, _, _, _, _, id = GetCharacterInfo(i)
						if knownBy[id] then
							lines[#lines + 1] = SousChef.charToName[id]
						end
					end
					local r, g, b = MAGIC_COLOR:UnpackRGB()
					ItemTooltip:AddLine(table.concat(lines, ", "), "ZoFontGame", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)

					ZO_ClearNumericallyIndexedTable(lines)
					for i = 1, GetNumCharacters() do
						local _, _, _, _, _, _, id = GetCharacterInfo(i)
						if knownBy[id] == nil then
							lines[#lines + 1] = SousChef.charToName[id]
						end
					end
					r, g, b = ZO_ERROR_COLOR:UnpackRGB()
					ItemTooltip:AddLine(table.concat(lines, ", "), "ZoFontGame", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
				else
					local r, g, b = ZO_ERROR_COLOR:UnpackRGB()
					for i = 1, GetNumCharacters() do
						local _, _, _, _, _, _, id = GetCharacterInfo(i)
						lines[#lines + 1] = SousChef.charToName[id]
					end
					ItemTooltip:AddLine(table.concat(lines, ", "), "ZoFontGame", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
				end
			end
			return false
		end

		-- if we're only showing items on the shopping list, and we've already hidden this item, then don't touch it!
		-- if SousChef.settings.onlyShowShopping and SousChef.slotLines[row:GetName()] and SousChef.slotLines[row:GetName()]:IsHidden() then return end

		-- item is an ingredient
		local itemId = u.GetItemID(itemLink)
		-- Get itemId of inventory or loot or store slot
		local usableIngredient
		if SousChef.settings.showAltIngredientKnowledge then
			usableIngredient = SousChef.common.ReverseCookbook[itemId]
		else
			usableIngredient = SousChef.ReverseCookbook[itemId]
		end
		if usableIngredient then
			-- ZO_Tooltip_AddDivider(ItemTooltip)
			local star = "|t20:20:esoui/art/ava/ava_rankicon_general.dds|t"
			ItemTooltip:AddLine(str.TOOLTIP_USED_IN, "ZoFontWinH5", 1, 1, 1, BOTTOM, MODIFY_TEXT_TYPE_UPPERCASE)

			ZO_ClearNumericallyIndexedTable(lines)
			ZO_ClearNumericallyIndexedTable(fav)
			local zo_strformat = zo_strformat
			local shoppingList = SousChef.settings.shoppingList
			for i, resultLink in ipairs(usableIngredient) do
				local count = 0
				local itemId = u.GetItemID(resultLink)
				if SousChef.settings.showCounts then
					local bookmark = SousChef.CookbookIndex[itemId]
					if bookmark then
						count = CalculateHowManyCouldBeCreated(bookmark.listIndex, bookmark.recipeIndex, bookmark.numIngredients)
					end
				end
				local line = zo_strformat(count > 0 and "<<C:1>> <<C:2[//×$d]>>" or "<<C:1>>", u.GetColoredLinkName(resultLink), count)
				local favorite = false
				if type(shoppingList[itemId]) == "table" and next(shoppingList[itemId]) then
					line = zo_strjoin(nil, star, line)
					-- u.TableKeyConcat(shoppingList[itemId]),
					favorite = true
				end
				if favorite then
					fav[#fav + 1] = line
				else
					if (#fav + #lines) < 15 then
						lines[#lines + 1] = line
					end
				end
			end
			if #fav > 0 then
				table.sort(fav)
				ItemTooltip:AddLine(table.concat(fav, "\n"), "ZoFontWinH4", 1, 1, 1, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
			end
			if #lines > 0 then
				table.sort(lines)
				if (#fav + #lines) >= 15 then
					lines[#lines + 1] = "..."
				end
				ItemTooltip:AddLine(table.concat(lines, "\n"), "ZoFontWinH4", 1, 1, 1, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
			end
		end
		return false
	end
end

function SousChef.AddRecipeToIgnoreList(link)
	if GetItemLinkInfo(link) ~= "" then
		link = string.match(link, "([%w\128-\244 ]+)%]")
	end
	SousChef.settings.ignoredRecipes[link] = true
	d(str.SC_ADDING1 .. link .. str.SC_ADDING2)
end

function SousChef.RemoveRecipeFromIgnoreList(link)
	if GetItemLinkInfo(link) ~= "" then
		link = string.match(link, "([%w\128-\244 ]+)%]")
	end
	if not SousChef.settings.ignoredRecipes[link] then
		d(link .. str.SC_NOT_FOUND)
		return
	end
	SousChef.settings.ignoredRecipes[link] = nil
	d(str.SC_REMOVING1 .. link .. str.SC_REMOVING2)
end

function SousChef.ListIgnoredRecipes()
	d(str.SC_IGNORED)
	for recipe in pairs(SousChef.settings.ignoredRecipes) do
		d(recipe)
	end
end
