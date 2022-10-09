local CDGBS = ZO_Object:Subclass()

CDGBS.Name = "CDGBankStack"
CDGBS.NameSpaced = "CDG Bank Stacker"
CDGBS.Author = "|cFFA500CrazyDutchGuy|r & Garkin"
CDGBS.Version = "1.91.1"
CDGBS.defaults = {
	logToDefaultChat = true,
	logToCDGShowLoot = true,
	ignoreSavedItems = true
}

CDGBS.SV = {}

function CDGBS:LogActionToChat(quantity, bagStack, bagItemLink)
	if CDGBS.SV.logToDefaultChat then
		CHAT_ROUTER:FormatAndAddChatMessage(EVENT_BROADCAST, zo_strformat("Banked [<<1>>/<<2>>] <<t:3>>", quantity, bagStack, bagItemLink))
	end
	if CDGBS.SV.logToCDGShowLoot then
		local itemName = GetItemLinkName(bagItemLink)
		local icon = GetItemLinkInfo(bagItemLink)
		local quality = GetItemLinkQuality(bagItemLink)
		local color = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality))

		local lootData = {
			text = zo_strformat(SI_TOOLTIP_ITEM_NAME, itemName),
			icon = icon,
			stackCount = quantity,
			color = color,
			backgroundColor = color,
			itemId = bagItemLink,
			quality = quality
		}

		local lootEntry = self.lootHistory:CreateLootEntry(lootData)
		self.lootHistory:InsertOrQueue(lootEntry)
	end
end

function CDGBS:IsItemProtected(bagId, slotId)
	if IsItemBound(bagId, slotId) and GetItemBindType(bagId, slotId) == BIND_TYPE_ON_PICKUP_BACKPACK then
		return true
	end

	-- Item Saver support
	if ItemSaver_IsItemSaved and ItemSaver_IsItemSaved(bagId, slotId) then
		return true
	end

	-- FCO ItemSaver support
	if FCOIsMarked and FCOIsMarked(GetItemInstanceId(bagId, slotId), -1) then
		return true
	end

	-- FilterIt support
	if FilterIt and FilterIt.AccountSavedVariables and FilterIt.AccountSavedVariables.FilteredItems then
		local sUniqueId = Id64ToString(GetItemUniqueId(bagId, slotId))
		if FilterIt.AccountSavedVariables.FilteredItems[sUniqueId] then
			return true
		end
	end

	return false
end

local blackListItemType = {
	[ITEMTYPE_FOOD] = true,
	[ITEMTYPE_DRINK] = true,
	[ITEMTYPE_POTION] = true,
	[ITEMTYPE_POISON] = true,
	[ITEMTYPE_SOUL_GEM] = true,
	[ITEMTYPE_TOOL] = true
}

function CDGBS:EVENT_OPEN_BANK(...)
	local bankCache = IsESOPlusSubscriber() and SHARED_INVENTORY:GenerateFullSlotData(nil, BAG_BANK, BAG_SUBSCRIBER_BANK) or SHARED_INVENTORY:GenerateFullSlotData(nil, BAG_BANK)
	local bagCache = SHARED_INVENTORY:GenerateFullSlotData(nil, BAG_BACKPACK)

	local GetSlotStackSize = GetSlotStackSize
	local GetItemLink = GetItemLink
	for _, bankSlotData in pairs(bankCache) do
		if blackListItemType[bankSlotData.itemType] ~= true then
			local bagId, bankSlot = bankSlotData.bagId, bankSlotData.slotIndex
			local bankStack, bankMaxStack = GetSlotStackSize(bagId, bankSlot)
			if bankStack > 0 and bankStack < bankMaxStack then
				for _, bagSlotData in pairs(bagCache) do
					local bagSlot = bagSlotData.slotIndex
					if not bagSlotData.stolen and bankSlotData.rawName == bagSlotData.rawName and (not self.SV.ignoreSavedItems or (self.SV.ignoreSavedItems and not self:IsItemProtected(BAG_BACKPACK, bagSlot))) then
						local bagStack, bagMaxStack = GetSlotStackSize(BAG_BACKPACK, bagSlot)
						local bagItemLink = GetItemLink(BAG_BACKPACK, bagSlot, LINK_STYLE_DEFAULT)
						local quantity = zo_min(bagStack, bankMaxStack - bankStack)

						if IsProtectedFunction("RequestMoveItem") then
							CallSecureProtected("RequestMoveItem", BAG_BACKPACK, bagSlot, bagId, bankSlot, quantity)
						else
							RequestMoveItem(BAG_BACKPACK, bagSlot, bagId, bankSlot, quantity)
						end

						self:LogActionToChat(quantity, bagStack, bagItemLink)

						bankStack = bankStack + quantity

						if bankStack == bankMaxStack then
							break
						end
					end
				end
			end
		end
	end
end

function CDGBS:CreateLAM2Panel()
	local panelData = {
		type = "panel",
		name = self.NameSpaced,
		displayName = ZO_HIGHLIGHT_TEXT:Colorize(self.NameSpaced),
		author = self.Author,
		version = self.Version
	}

	local optionsData = {
		{
			type = "checkbox",
			name = "Log to default chat",
			tooltip = "Log to default chat.",
			getFunc = function()
				return self.SV.logToDefaultChat
			end,
			setFunc = function(value)
				self.SV.logToDefaultChat = value
			end
		},
		{
			type = "checkbox",
			name = "Log to CDG Show Loot",
			tooltip = "Log to CDG Show Loot.",
			getFunc = function()
				return self.SV.logToCDGShowLoot
			end,
			setFunc = function(value)
				self.SV.logToCDGShowLoot = value
			end
		},
		{
			type = "checkbox",
			name = 'Don\'t move "saved" items',
			tooltip = "Don't touch items marked by ItemSaver, FCO ItemSaver or Circonians FilterIt.",
			getFunc = function()
				return self.SV.ignoreSavedItems
			end,
			setFunc = function(value)
				self.SV.ignoreSavedItems = value
			end
		},
		{
			type = "description",
			text = "|cEFEBBECrazyDutchGuy's Bank Stacker|r is an addon that automatically moves items from your backpack onto unfilled stacks in your bank."
		}
	}

	local LAM2 = LibAddonMenu2
	LAM2:RegisterAddonPanel(self.Name .. "LAM2Options", panelData)
	LAM2:RegisterOptionControls(self.Name .. "LAM2Options", optionsData)
end

function CDGBS:EVENT_ADD_ON_LOADED(eventCode, addOnName, ...)
	if (addOnName == self.Name) then
		EVENT_MANAGER:UnregisterForEvent(self.Name, EVENT_ADD_ON_LOADED)

		self.SV = ZO_SavedVars:New(self.Name .. "_SV", 1, nil, self.defaults)

		self:CreateLAM2Panel()

		self.lootHistory = IsInGamepadPreferredMode() and LOOT_HISTORY_KEYBOARD or LOOT_HISTORY_GAMEPAD
		-- SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME)

		EVENT_MANAGER:RegisterForEvent(
			self.Name,
			EVENT_OPEN_BANK,
			function(...)
				CDGBS:EVENT_OPEN_BANK(...)
			end
		)
	end
end

EVENT_MANAGER:RegisterForEvent(
	CDGBS.Name,
	EVENT_ADD_ON_LOADED,
	function(...)
		CDGBS:EVENT_ADD_ON_LOADED(...)
	end
)
