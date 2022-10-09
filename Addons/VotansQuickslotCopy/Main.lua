local addon = {
	name = "VotansQuickslotCopy"
}
local em = GetEventManager()

------------------ Drag'n'Drop for actions in collectible book -----------------------

local orgGetHotbarForCollectibleCategoryId = GetHotbarForCollectibleCategoryId

local pickupEmoteById = IsProtectedFunction("PickupEmoteById") and function(...)
		return CallSecureProtected("PickupEmoteById", ...)
	end or function(...)
		PickupEmoteById(...)
		return true
	end

function GetHotbarForCollectibleCategoryId(...)
	local categoryId = ...
	if categoryId == 28 then
		return HOTBAR_CATEGORY_EMOTE_WHEEL
	end
	return orgGetHotbarForCollectibleCategoryId(...)
end

local orgOnDragStart = ZO_CollectibleTile_Keyboard.OnDragStart
function ZO_CollectibleTile_Keyboard.OnDragStart(...)
	local self, button = ...
	if button == MOUSE_BUTTON_INDEX_LEFT and self.collectibleData and self.collectibleData:IsUnlocked() and self.collectibleData:GetCategoryData():GetId() == 28 then
		local emoteId = GetCollectibleReferenceId(self.collectibleData:GetId())
		pickupEmoteById(emoteId)
	else
		return orgOnDragStart(...)
	end
end

--------------------------------------------------------------------------------------

local selectSlotSimpleAction = IsProtectedFunction("SelectSlotSimpleAction") and function(...)
		return CallSecureProtected("SelectSlotSimpleAction", ...)
	end or function(...)
		SelectSlotSimpleAction(...)
		return true
	end
local selectSlotItem = IsProtectedFunction("SelectSlotItem") and function(...)
		return CallSecureProtected("SelectSlotItem", ...)
	end or function(...)
		SelectSlotItem(...)
		return true
	end
local clearSlot = IsProtectedFunction("ClearSlot") and function(...)
		return CallSecureProtected("ClearSlot", ...)
	end or function(...)
		ClearSlot(...)
		return true
	end

function addon:SaveTemplate()
	if self.hotbarCategory and self.wheel then
		self.defaultSlots[self.hotbarCategory] = ZO_GetUtilityWheelSlottedEntries(self.wheel:GetHotbarCategory())
		for _, slot in pairs(self.defaultSlots[self.hotbarCategory]) do
			slot.icon = nil
			if slot.type == ACTION_TYPE_ITEM then
				slot.id = GetItemLinkItemId(GetSlotItemLink(slot.slotIndex, self.wheel:GetHotbarCategory()))
			end
		end
		KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
	end
end

function addon:LoadTemplate()
	if not self.wheel or not self.defaultSlots[self.hotbarCategory] then
		return
	end
	local backpackSlots = nil
	for _, slot in pairs(self.defaultSlots[self.hotbarCategory]) do
		if slot.type ~= ACTION_TYPE_ITEM then
			selectSlotSimpleAction(slot.type, slot.id, slot.slotIndex, self.wheel:GetHotbarCategory())
		else
			if not backpackSlots then
				backpackSlots = {}
				for _, item in pairs(SHARED_INVENTORY:GetOrCreateBagCache(BAG_BACKPACK)) do
					backpackSlots[GetItemId(item.bagId, item.slotIndex)] = item
				end
			end
			local item = backpackSlots[slot.id]
			if item and IsValidItemForSlotByItemId(slot.id, slot.slotIndex, self.wheel:GetHotbarCategory()) then
				selectSlotItem(item.bagId, item.slotIndex, slot.slotIndex, self.wheel:GetHotbarCategory())
			end
		end
	end
end

function addon:InitializeKeybindStripDescriptor()
	if self.keybindStripDescriptor then
		return
	end

	self.keybindStripDescriptor = {
		alignment = KEYBIND_STRIP_ALIGN_LEFT,
		{
			name = GetString(VOTANS_QUICKSLOTCOPY_SAVE_TEMPLATE),
			keybind = "UI_SHORTCUT_SHOW_QUEST_ON_MAP",
			callback = function()
				PlaySound(SOUNDS.DEFAULT_CLICK)
				self:SaveTemplate()
			end,
			visible = function(keybindButtonDescriptor)
				return self.hotbarCategory ~= nil
			end,
			enabled = function()
				return self.wheel:GetHotbarCategory() == self.hotbarCategory
			end
		},
		{
			name = GetString(VOTANS_QUICKSLOTCOPY_LOAD_TEMPLATE),
			keybind = "UI_SHORTCUT_NEGATIVE",
			callback = function()
				PlaySound(SOUNDS.DEFAULT_CLICK)
				self:LoadTemplate()
			end,
			visible = function(keybindButtonDescriptor)
				return self.hotbarCategory ~= nil
			end,
			enabled = function()
				return (self.hotbarCategory and self.defaultSlots[self.hotbarCategory] and next(self.defaultSlots[self.hotbarCategory])) ~= nil
			end
		}
	}
end

function addon:Initialize()
	local function OnStateChanged(oldState, newState)
		if newState == SCENE_SHOWN then
			self.wheel = COLLECTIONS_BOOK.wheel
			self.hotbarCategory = COLLECTIONS_BOOK.hotbarCategory
			if self.hotbarCategory then
				self:InitializeKeybindStripDescriptor()
				KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
			end
		elseif newState == SCENE_HIDING then
			KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
			self.wheel = nil
			self.hotbarCategory = nil
		end
	end
	COLLECTIONS_BOOK.scene:RegisterCallback("StateChange", OnStateChanged)

	local function OnStateChanged(oldState, newState)
		if newState == SCENE_SHOWN then
			self.wheel = KEYBOARD_PLAYER_EMOTE.wheel
			self:InitializeKeybindStripDescriptor()
			self.hotbarCategory = HOTBAR_CATEGORY_EMOTE_WHEEL
			KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
		elseif newState == SCENE_HIDING then
			KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
			self.wheel = nil
			self.hotbarCategory = nil
		end
	end
	HELP_EMOTES_SCENE:RegisterCallback("StateChange", OnStateChanged)

	local function OnStateChanged(oldState, newState)
		if newState == SCENE_FRAGMENT_SHOWN then
			self.wheel = QUICKSLOT_KEYBOARD.wheel
			self:InitializeKeybindStripDescriptor()
			self.hotbarCategory = HOTBAR_CATEGORY_QUICKSLOT_WHEEL
			KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
		elseif newState == SCENE_FRAGMENT_HIDING then
			KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
			self.wheel = nil
			self.hotbarCategory = nil
		end
	end
	KEYBOARD_QUICKSLOT_FRAGMENT:RegisterCallback("StateChange", OnStateChanged)

	assert(ZO_CollectionsBook.UpdateUtilityWheel, "UpdateUtilityWheel")
	SecurePostHook(
		ZO_CollectionsBook,
		"UpdateUtilityWheel",
		function(book)
			self.hotbarCategory = book.hotbarCategory

			self:InitializeKeybindStripDescriptor()
			if KEYBIND_STRIP:HasKeybindButtonGroup(self.keybindStripDescriptor) then
				KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
			else
				KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
			end
		end
	)

	VOTANS_QUICKSLOTCOPY_DATA = VOTANS_QUICKSLOTCOPY_DATA or {}
	VOTANS_QUICKSLOTCOPY_DATA.defaultSlots = VOTANS_QUICKSLOTCOPY_DATA.defaultSlots or {}
	self.defaultSlots = VOTANS_QUICKSLOTCOPY_DATA.defaultSlots
end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then
		return
	end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	addon:Initialize()
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

VOTANS_QUICKSLOTCOPY = addon
