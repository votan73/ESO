local addon = {
	name = "VotansTakeOne",
	title = "Votan's Take One",
	defaults =
	{
	},
}

local requestMoveItem
if IsProtectedFunction("RequestMoveItem") then
	requestMoveItem = function(...) return CallSecureProtected("RequestMoveItem", ...) end
else
	requestMoveItem = RequestMoveItem
end

local function IsItemStacked(bagId, slotIndex)
	if bagId ~= BAG_BANK and bagId ~= BAG_SUBSCRIBER_BANK then return false end

	local slotSize, maxSize = GetSlotStackSize(bagId, slotIndex)
	return maxSize > 1 and slotSize > 0
end

function addon:FindSlotForItem(bagId, itemLink, num)
	local GetItemLink, GetSlotStackSize, ZO_GetNextBagSlotIndex = GetItemLink, GetSlotStackSize, ZO_GetNextBagSlotIndex
	local emptySlot = -1

	local slotLink
	local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagId)
	local slotIndex = ZO_GetNextBagSlotIndex(bagId)
	while slotIndex do
		local slot = bagCache[slotIndex]
		if slot then
			slotLink = GetItemLink(slot.bagId, slot.slotIndex)
			if slotLink == itemLink then
				local slotSize, maxSize = GetSlotStackSize(slot.bagId, slot.slotIndex)
				if (maxSize - slotSize) >= num then return slot.bagId, slot.slotIndex end
			end
		elseif GetSlotStackSize(bagId, slotIndex) == 0 and emptySlot < 0 then
			emptySlot = slotIndex
		end
		slotIndex = ZO_GetNextBagSlotIndex(bagId, slotIndex)
	end

	if emptySlot >= 0 then
		return bagId, emptySlot
	end
end

local bagId, slotIndex

local function DoInventorySlot(num)
	local targetBag, targetSlot = addon:FindSlotForItem(BAG_BACKPACK, GetItemLink(bagId, slotIndex), num)
	if targetSlot then
		return requestMoveItem(bagId, slotIndex, targetBag, targetSlot, num)
	end
	d("no slot")
	return false
end

local function RemoveMouseOverKeybinds()
	bagId, slotIndex = 0, 0
	KEYBIND_STRIP:RemoveKeybindButtonGroup(addon.takeKeybindButtonGroup)
end

local function AddTakeItem(inventorySlot, slotActions)
	RemoveMouseOverKeybinds()
	if not(PLAYER_INVENTORY:IsBanking() or PLAYER_INVENTORY:IsGuildBanking()) then return end

	bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
	if IsItemStacked(bagId, slotIndex) then
		KEYBIND_STRIP:AddKeybindButtonGroup(addon.takeKeybindButtonGroup)
	end
end

function addon:AddKeyBind()
	self.takeKeybindButtonGroup = {
		alignment = KEYBIND_STRIP_ALIGN_RIGHT,
		{
			name = GetString(SI_BINDING_NAME_VOTANS_MULTITAKE_ONE),
			keybind = "UI_SHORTCUT_NEGATIVE",
			enabled = function() return DoesBagHaveSpaceFor(BAG_BACKPACK, bagId, slotIndex) end,
			visible = function(keybind) return bagId > 0 end,
			order = 100,
			callback = function(keybind) return DoInventorySlot(1) end,
		},
		-- 	{
		-- 		name = GetString(SI_BINDING_NAME_VOTANS_MULTITAKE_THREE),
		-- 		keybind = "UI_SHORTCUT_SHOW_QUEST_ON_MAP",
		-- 		enabled = function() return DoesBagHaveSpaceFor(BAG_BACKPACK, bagId, slotIndex) end,
		-- 		visible = function(keybind) return true end,
		-- 		order = 101,
		-- 		callback = function(keybind) return DoInventorySlot(3) end,
		-- 	},
	}

	local menu = LibCustomMenu
	menu:RegisterKeyStripEnter(AddTakeItem)
	menu:RegisterKeyStripExit(RemoveMouseOverKeybinds)
end

----------------- Settings -----------------------
function addon:SetupSettings()
end

--------------- End Settings ---------------------

function addon:SlashCommand()
end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then return end
	EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	-- addon.settings = ZO_SavedVars:NewAccountWide("VotansTakeOne_Data", 1, nil, addon.defaults)

	-- addon:SlashCommand()
	addon:AddKeyBind()
	-- addon:SetupSettings()
end

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

VOTANS_TAKE_ONE = addon
