local addon = {
	name = "VotansFishFillet",
	title = "Fish Fillet",
	defaults = {
		stats = {fishes = 0, perfectRoe = 0},
		showAllStacks = true,
		filletAllStacks = false
	},
	roeItemLink = "|H1:item:64222:29:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
}

local stats

------------ Filleting a fish ----------------
local useItem = IsProtectedFunction("UseItem") and function(...)
		return CallSecureProtected("UseItem", ...)
	end or function(...)
		UseItem(...)
		return true
	end

local function IsItemFish(bagId, slotIndex)
	if bagId ~= BAG_BACKPACK then
		return false
	end

	local itemType = GetItemType(bagId, slotIndex)
	if ITEMTYPE_FISH == itemType then
		local usable, onlyFromActionSlot = IsItemUsable(bagId, slotIndex)
		local canInteractWithItem = CanInteractWithItem(bagId, slotIndex)
		return usable and not onlyFromActionSlot and canInteractWithItem
	end
	return false
end

local FiletFish
local count = 0
local roeCount = 0
local itemLink
local slotIndex
local updateExpected = false
local filletAllStacks = false
local usedFragment

local function CountBag(bagId)
	local slotIndex = ZO_GetNextBagSlotIndex(bagId, nil)
	local stack, _, count
	local sum = 0
	while slotIndex do
		local itemId = GetItemId(bagId, slotIndex)
		if itemId == 64222 then
			_, count = GetItemInfo(bagId, slotIndex)
			sum = sum + count
		end
		slotIndex = ZO_GetNextBagSlotIndex(bagId, slotIndex)
	end
	return sum
end

local function CountPerfectRoe()
	local sum = CountBag(BAG_BACKPACK)
	--if HasCraftBagAccess() then
	local _, count = GetItemInfo(BAG_VIRTUAL, 64222)
	sum = sum + count
	--end
	return sum
end

local function GetCurrentFragment()
	return IsInGamepadPreferredMode() and GAMEPAD_INVENTORY_FRAGMENT or BACKPACK_MENU_BAR_LAYOUT_FRAGMENT
end

local function AbortAction(...)
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_INVENTORY_FULL_UPDATE)
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
	EVENT_MANAGER:UnregisterForUpdate(addon.name)

	-- Count "Perfect Roe" afterwards and add diff to stats
	local newCount = CountPerfectRoe()
	stats.perfectRoe = stats.perfectRoe + (newCount - roeCount)
	roeCount = newCount
	addon.running = false
	updateExpected = false
	KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.allStacksKeybindButtonGroup)
	ShowMouse()
end

local function InventoryStateChange(oldState, newState)
	if newState == SCENE_HIDING then
		count = 0
		AbortAction()
		usedFragment:UnregisterCallback("StateChange", InventoryStateChange)
	end
end

local function EndAction(...)
	AbortAction()
	usedFragment:UnregisterCallback("StateChange", InventoryStateChange)
end

local function HasFishSlots()
	if not (CheckInventorySpaceSilently(2) and GetCurrentFragment():GetState() == SCENE_SHOWN) then
		return false
	end

	local bagId = BAG_BACKPACK
	local bagSlots = GetBagSize(bagId) - 1
	local count = 0
	for index = 0, bagSlots do
		if IsItemFish(bagId, index) then
			count = count + 1
			if count > 1 then
				return true
			end
		end
	end

	return false
end

-- Scan backpack for next fish and use it if found.
local function UseNextFishSlot()
	if not (filletAllStacks and CheckInventorySpaceSilently(2) and GetCurrentFragment():GetState() == SCENE_SHOWN) then
		return false
	end

	local bagId = BAG_BACKPACK
	local bagSlots = GetBagSize(bagId) - 1
	for index = 0, bagSlots do
		if IsItemFish(bagId, index) then
			slotIndex = index
			itemLink = GetItemLink(bagId, slotIndex)
			local _, stack = GetItemInfo(bagId, slotIndex)
			count = stack
			return true
		end
	end

	return false
end

local function SlotUpdate(eventCode, bagId, slotId, isNew, itemSoundCategory, updateReason)
	if updateReason ~= INVENTORY_UPDATE_REASON_DEFAULT or (bagId ~= BAG_BACKPACK and bagId ~= BAG_VIRTUAL) then
		return
	end

	if isNew and updateExpected then
		local itemId = GetItemId(bagId, slotId)
		if itemId ~= 33753 then
			return
		end
		count = count - 1
		stats.fishes = stats.fishes + 1
		updateExpected = false
		if count > 0 then
			-- Not zo_callLater: if there is a delay already, it will not registered twice
			EVENT_MANAGER:RegisterForUpdate(addon.name, 500, FiletFish)
		elseif UseNextFishSlot() then
			EVENT_MANAGER:RegisterForUpdate(addon.name, 500, FiletFish)
		else
			EndAction()
		end
	end
end

-- After reorg of the inventory, e.g. after new entry "fish", find the stack again
local function SlotFullUpdate(eventCode, bagId, ...)
	if bagId ~= BAG_BACKPACK and bagId ~= BAG_VIRTUAL then
		return
	end

	if IsItemFish(bagId, slotIndex) then
		SlotUpdate(eventCode, bagId, slotIndex, true, nil, INVENTORY_UPDATE_REASON_DEFAULT)
		return
	end

	local bagSlots = GetBagSize(bagId) - 1
	local found = false
	local git = GetItemLink
	local gii = GetItemInfo
	for index = 0, bagSlots do
		if itemLink == git(bagId, index) then
			found = true
			slotIndex = index
			local _, stack = gii(bagId, slotIndex)
			if stack == (count - 1) then
				break
			end
		end
	end
	if found then
		SlotUpdate(eventCode, bagId, slotIndex, true, nil, INVENTORY_UPDATE_REASON_DEFAULT)
	else
		EndAction()
	end
end

FiletFish = function()
	addon.running = true
	EVENT_MANAGER:UnregisterForUpdate(addon.name)
	if not CheckInventorySpaceSilently(2) then
		EndAction()
		ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, SI_INVENTORY_ERROR_INVENTORY_FULL)
		return false
	end
	local remaining = GetItemCooldownInfo(BAG_BACKPACK, slotIndex)
	if remaining > 0 then
		EVENT_MANAGER:RegisterForUpdate(addon.name, remaining + 17, FiletFish)
		return
	end

	if IsItemFish(BAG_BACKPACK, slotIndex) then
		-- inventorySlot is unvalid afterwards, because the position could have changed due to the new entry "fish"
		EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_INVENTORY_FULL_UPDATE, SlotFullUpdate)
		EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, SlotUpdate)

		if not useItem(BAG_BACKPACK, slotIndex) then
			EndAction()
			PlaySound(SOUNDS.NEGATIVE_CLICK)
			return false
		end
		updateExpected = true
	else
		EndAction()
	end
	return false
end

local function UseInventorySlot(inventorySlot, slotActions)
	local bagId, _
	bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)

	filletAllStacks = addon.settings.filletAllStacks
	if IsItemFish(bagId, slotIndex) then
		_, count = GetItemInfo(bagId, slotIndex)
		-- Count "Perfect Roe" before
		roeCount = CountPerfectRoe()
		if count > 0 then
			addon.running = true
			itemLink = GetItemLink(bagId, slotIndex)
			usedFragment = GetCurrentFragment()
			usedFragment:RegisterCallback("StateChange", InventoryStateChange)
			EVENT_MANAGER:RegisterForUpdate(addon.name, 40, FiletFish)
			slotActions:Clear()
			ClearCursor()
			ClearMenu()
			HideMouse()
			KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.allStacksKeybindButtonGroup)
			return true
		else
			itemLink = ""
			EndAction()
		end
	end
	return false
end

local function IsPlayerAlive()
	return not IsUnitDead("player")
end

local function DoAllStacks()
	filletAllStacks = true
	if UseNextFishSlot() then
		local bagId = BAG_BACKPACK
		local _
		_, count = GetItemInfo(bagId, slotIndex)
		-- Count "Perfect Roe" before
		roeCount = CountPerfectRoe()
		if count > 0 then
			addon.running = true
			itemLink = GetItemLink(bagId, slotIndex)
			usedFragment = GetCurrentFragment()
			usedFragment:RegisterCallback("StateChange", InventoryStateChange)
			EVENT_MANAGER:RegisterForUpdate(addon.name, 40, FiletFish)
			HideMouse()
			KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.allStacksKeybindButtonGroup)
			return true
		else
			itemLink = ""
			EndAction()
		end
	end
	return false
end

local function AddFiletAll(inventorySlot, slotActions)
	local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
	if IsItemFish(bagId, slotIndex) and CheckInventorySpaceSilently(2) and GetCurrentFragment():GetState() == SCENE_SHOWN then
		slotActions:AddCustomSlotAction(
			addon.settings.filletAllStacks and SI_BINDING_NAME_VOTANS_FISH_FILLET_ALL_STACKS or SI_VOTANS_FILET_FISH_ALL,
			function(...)
				return UseInventorySlot(inventorySlot, slotActions)
			end,
			"primary"
		)
		if IsInGamepadPreferredMode() and not addon.settings.filletAllStacks and addon.settings.showAllStacks then
			slotActions:AddCustomSlotAction(SI_BINDING_NAME_VOTANS_FISH_FILLET_ALL_STACKS, DoAllStacks)
		end
	end
	return false
end

function addon:AddKeyBind()
	local menu = LibCustomMenu
	menu:RegisterContextMenu(AddFiletAll, menu.CATEGORY_EARLY)
	menu:RegisterKeyStripEnter(AddFiletAll, menu.CATEGORY_EARLY)

	self.allStacksKeybindButtonGroup = {
		alignment = KEYBIND_STRIP_ALIGN_LEFT,
		{
			name = GetString(SI_BINDING_NAME_VOTANS_FISH_FILLET_ALL_STACKS),
			keybind = "VOTANS_FISH_FILLET_ALL_STACKS",
			enabled = function()
				return addon.running ~= true
			end,
			visible = HasFishSlots,
			order = 100,
			callback = DoAllStacks
		}
	}

	BACKPACK_MENU_BAR_LAYOUT_FRAGMENT:RegisterCallback(
		"StateChange",
		function(oldState, newState)
			if newState == SCENE_SHOWN and self.settings.showAllStacks then
				KEYBIND_STRIP:AddKeybindButtonGroup(addon.allStacksKeybindButtonGroup)
			elseif newState == SCENE_HIDING then
				KEYBIND_STRIP:RemoveKeybindButtonGroup(addon.allStacksKeybindButtonGroup)
			end
		end
	)
end

------------ End Filleting a fish ----------------

---------------- tooltip stats -------------------

function addon:ModifyTooltip(tooltip, itemLink)
	local itemType = GetItemLinkItemType(itemLink)
	if itemType == ITEMTYPE_INGREDIENT then
		if itemLink:find(":item:64222:") == nil then
			return
		end
	elseif itemType ~= ITEMTYPE_FISH then
		return
	end
	tooltip:AddVerticalPadding(10)
	if stats.fishes > 0 then
		tooltip:AddLine(zo_strjoin(nil, addon.perfectRoeName, ": ", stats.perfectRoe, "/", stats.fishes, " (", math.floor(stats.perfectRoe * 10000 / stats.fishes) / 100, "%)"))
	else
		tooltip:AddLine(zo_strjoin(nil, addon.perfectRoeName, ": 0/0 (-)"))
	end
end

local mystyle = {fontSize = 34, fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1}
function addon:ModifyTooltip_Gamepad(tooltip, itemLink)
	local itemType = GetItemLinkItemType(itemLink)
	if itemType == ITEMTYPE_INGREDIENT then
		if itemLink:find(":item:64222:") == nil then
			return
		end
	elseif itemType ~= ITEMTYPE_FISH then
		return
	end
	if stats.fishes > 0 then
		tooltip:AddLine(zo_strjoin(nil, addon.perfectRoeName, ": ", stats.perfectRoe, "/", stats.fishes, " (", math.floor(stats.perfectRoe * 10000 / stats.fishes) / 100, "%)"), mystyle, tooltip:GetStyle("bodySection"))
	else
		tooltip:AddLine(zo_strjoin(nil, addon.perfectRoeName, ": 0/0 (-)"), mystyle, tooltip:GetStyle("bodySection"))
	end
end

local function TooltipHook(tooltipControl, method, linkFunc)
	local origMethod = tooltipControl[method]

	tooltipControl[method] = function(self, ...)
		origMethod(self, ...)
		addon:ModifyTooltip(self, linkFunc(...))
	end
end

local function TooltipHook_Gamepad(tooltipControl, method, linkFunc)
	local origMethod = tooltipControl[method]

	tooltipControl[method] = function(self, ...)
		local result = origMethod(self, ...)
		addon:ModifyTooltip_Gamepad(self, linkFunc(...))
		return result
	end
end

local function ReturnItemLink(itemLink)
	return itemLink
end

------------- end tooltip stats ------------------

----------------- Settings -----------------------
function addon:SetupSettings()
	local LAM2 = LibAddonMenu2 or LibStub("LibAddonMenu-2.0")
	if not LAM2 then
		return
	end

	local panelData = {
		type = "panel",
		name = addon.title,
		displayName = addon.title,
		author = "votan",
		version = "1.6.4",
		-- slashCommand = "",
		-- registerForRefresh = true,
		registerForDefaults = true,
		website = "http://www.esoui.com/downloads/info958-VotansFishFillet.html"
	}
	LAM2:RegisterAddonPanel(addon.name, panelData)

	local optionsTable = {
		{
			type = "checkbox",
			name = GetString(SI_VOTANS_FILET_OPT_ALLSTACKS),
			tooltip = GetString(SI_VOTANS_FILET_OPT_ALLSTACKS_TOOLTIP),
			getFunc = function()
				return addon.settings.showAllStacks
			end,
			setFunc = function(value)
				addon.settings.showAllStacks = value
			end,
			default = self.defaults.showAllStacks
		},
		{
			type = "checkbox",
			name = GetString(SI_VOTANS_FILET_OPT_ALLSTACKS_ALWAYS),
			tooltip = GetString(SI_VOTANS_FILET_OPT_ALLSTACKS_ALWAYS_TOOLTIP),
			getFunc = function()
				return addon.settings.filletAllStacks
			end,
			setFunc = function(value)
				addon.settings.filletAllStacks = value
			end,
			default = self.defaults.filletAllStacks
		}
	}
	LAM2:RegisterOptionControls(addon.name, optionsTable)
end

--------------- End Settings ---------------------

-- Add stats for perfect roe
-- [64221] = "Psijik-Ambrosia^ns",
-- [64222] = "perfekter Rogen^ms",
-- [64223] = "Rezept: Psijik-Ambrosia^n:ns",

function addon:SlashCommand()
	SLASH_COMMANDS["/roestats"] = function()
		ZO_PopupTooltip_SetLink(addon.roeItemLink)
	end
end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then
		return
	end
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	addon.settings = ZO_SavedVars:NewAccountWide("VotanFishFillet_Data", 1, nil, addon.defaults)
	stats = addon.settings.stats

	addon.perfectRoeName = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(addon.roeItemLink))

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

	addon:SlashCommand()
	addon:AddKeyBind()
	addon:SetupSettings()
end

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

VOTANS_FISH_FILLET = addon
