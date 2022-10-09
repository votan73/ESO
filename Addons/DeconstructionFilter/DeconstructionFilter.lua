local buttons = {
	["All"] = {
		["texture"] = {
			["up"] = "/esoui/art/inventory/inventory_tabicon_all_up.dds",
			["down"] = "/esoui/art/inventory/inventory_tabicon_all_down.dds",
			["over"] = "/esoui/art/inventory/inventory_tabicon_all_over.dds"
		},
		size = 40,
		offset = 0,
		tooltip = GetString(SI_TRADING_HOUSE_BROWSE_ALL_ITEMS)
	},
	["Stolen"] = {
		["texture"] = {
			["up"] = "/esoui/art/vendor/vendor_tabIcon_fence_up.dds",
			["down"] = "/esoui/art/vendor/vendor_tabIcon_fence_down.dds",
			["over"] = "/esoui/art/vendor/vendor_tabIcon_fence_over.dds"
		},
		size = 40,
		offset = 0,
		tooltip = GetString(SI_DECONFILTER_STOLEN)
	},
	["Intricate"] = {
		["texture"] = {
			["up"] = "/esoui/art/crafting/smithing_tabicon_research_up.dds",
			["down"] = "/esoui/art/crafting/smithing_tabicon_research_down.dds",
			["over"] = "/esoui/art/crafting/smithing_tabicon_research_over.dds"
		},
		size = 40,
		offset = 0,
		tooltip = GetString(SI_DECONFILTER_INTRICATE)
	},
	["Trash"] = {
		["texture"] = {
			["up"] = "/esoui/art/inventory/inventory_tabicon_junk_up.dds",
			["down"] = "/esoui/art/inventory/inventory_tabicon_junk_down.dds",
			["over"] = "/esoui/art/inventory/inventory_tabicon_junk_over.dds"
		},
		size = 40,
		offset = 0,
		tooltip = GetString(SI_DECONFILTER_TRASH)
	},
	["Bag"] = {
		["texture"] = {
			["up"] = "/esoui/art/mainmenu/menubar_inventory_up.dds",
			["down"] = "/esoui/art/mainmenu/menubar_inventory_down.dds",
			["over"] = "/esoui/art/mainmenu/menubar_inventory_over.dds"
		},
		size = 36,
		offset = 0,
		tooltip = GetString(SI_DECONFILTER_BACKSPACE)
	},
	["Worn"] = {
		["texture"] = {
			["up"] = "/esoui/art/treeicons/collection_indexicon_weapons+armor_up.dds",
			["down"] = "/esoui/art/treeicons/collection_indexicon_weapons+armor_down.dds",
			["over"] = "/esoui/art/treeicons/collection_indexicon_weapons+armor_over.dds"
		},
		size = 36,
		offset = 0,
		tooltip = GetString(SI_DECONFILTER_EQUIPPED)
	},
	["Bank"] = {
		["texture"] = {
			["up"] = "/esoui/art/icons/guildranks/guild_indexicon_misc09_up.dds",
			["down"] = "/esoui/art/icons/guildranks/guild_indexicon_misc09_down.dds",
			["over"] = "/esoui/art/icons/guildranks/guild_indexicon_misc09_over.dds"
		},
		size = 48,
		offset = -8,
		tooltip = GetString(SI_DECONFILTER_BANK)
	},
	["Crafted"] = {
		["texture"] = {
			["up"] = "/esoui/art/crafting/smithing_tabicon_creation_up.dds",
			["down"] = "/esoui/art/crafting/smithing_tabicon_creation_down.dds",
			["over"] = "/esoui/art/crafting/smithing_tabicon_creation_over.dds"
		},
		size = 40,
		offset = 0,
		tooltip = GetString(SI_DECONFILTER_CRAFTED)
	},
	["Set"] = {
		["texture"] = {
			["up"] = "esoui/art/crafting/smithing_tabicon_armorset_up.dds",
			["down"] = "esoui/art/crafting/smithing_tabicon_armorset_down.dds",
			["over"] = "esoui/art/crafting/smithing_tabicon_armorset_over.dds"
		},
		size = 40,
		offset = 0,
		tooltip = GetString(SI_DECONFILTER_SETITEMS)
	},
	["KnownSet"] = {
		["texture"] = {
			["up"] = "EsoUI/Art/Collections/collections_tabIcon_itemSets_up.dds",
			["down"] = "EsoUI/Art/Collections/collections_tabIcon_itemSets_down.dds",
			["over"] = "EsoUI/Art/Collections/collections_tabIcon_itemSets_over.dds"
		},
		size = 40,
		offset = 0,
		tooltip = GetString(SI_DECONFILTER_KNOWN_SETITEMS)
	}
}

local tooltipOwner
local function ShowTooltip(button)
	if button.tooltip then
		InitializeTooltip(InformationTooltip, button, BOTTOMRIGHT, 10, 10, TOPLEFT)
		SetTooltipText(InformationTooltip, button.tooltip)
		tooltipOwner = button
	end
end
local function HideTooltip()
	if tooltipOwner then
		ClearTooltip(InformationTooltip, tooltipOwner)
		tooltipOwner = nil
	end
end
SCENE_MANAGER:GetScene("smithing"):RegisterCallback(
	"StateChange",
	function(oldState, newState)
		if newState == SCENE_FRAGMENT_HIDING then
			HideTooltip()
		end
	end
)

local IsKnown = IsItemSetCollectionPieceUnlocked and function(...)
		return IsItemSetCollectionPieceUnlocked(GetItemId(...))
	end or function(...)
		return IsItemBound(...)
	end

local function doFilter(self, bagId, slotIndex, mode)
	if mode == "Stolen" then
		return not IsItemStolen(bagId, slotIndex)
	end

	if mode == "Intricate" then
		local trait = GetItemTrait(bagId, slotIndex)
		if trait == ITEM_TRAIT_TYPE_ARMOR_INTRICATE or trait == ITEM_TRAIT_TYPE_WEAPON_INTRICATE then
			return false
		end

		-- 		if FCOIsMarked then
		-- 			if FCOIsMarked and FCOIsMarked(GetItemInstanceId(bagId, slotIndex), 12) then return false end
		-- 			if FCOIsMarked(GetItemInstanceId(bagId, slotIndex), { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 }) then return true end
		-- 		end
		-- 		if ItemSaver_IsItemSaved and ItemSaver_IsItemSaved(bagId, slotIndex) then return true end
		-- 		if IsItemStoredForCraftStore and IsItemStoredForCraftStore(Id64ToString(GetItemUniqueId(bagId, slotIndex))) then return true end

		-- 		if GetItemTrait(bagId, slotIndex) == ITEM_TRAIT_TYPE_ARMOR_NIRNHONED or GetItemTrait(bagId, slotIndex) == ITEM_TRAIT_TYPE_WEAPON_NIRNHONED then
		-- 			return true
		-- 		end

		-- 		if IsItemLinkCrafted(GetItemLink(bagId, slotIndex)) then
		-- 			local hasSet = GetItemLinkSetInfo(GetItemLink(bagId, slotIndex), false)
		-- 			return hasSet
		-- 		end

		return true
	end

	if mode == "Trash" then
		if FCOIsMarked then
			if FCOIsMarked and FCOIsMarked(GetItemInstanceId(bagId, slotIndex), 9) then
				return false
			end
			if FCOIsMarked(GetItemInstanceId(bagId, slotIndex), {1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12}) then
				return true
			end
		end
		if ItemSaver_IsItemSaved and ItemSaver_IsItemSaved(bagId, slotIndex) then
			return true
		end
		if IsItemStoredForCraftStore and IsItemStoredForCraftStore(Id64ToString(GetItemUniqueId(bagId, slotIndex))) then
			return true
		end

		if IsItemJunk(bagId, slotIndex) then
			return false
		end

		if IsItemLinkCrafted(GetItemLink(bagId, slotIndex)) then
			return true
		end

		local hasSet = GetItemLinkSetInfo(GetItemLink(bagId, slotIndex), false)
		return hasSet
	end
	if mode == "Bag" then
		return bagId ~= BAG_BACKPACK
	end
	if mode == "Worn" then
		return bagId ~= BAG_WORN
	end
	if mode == "Bank" then
		return (bagId ~= BAG_BANK) and (bagId ~= BAG_SUBSCRIBER_BANK)
	end
	if mode == "Crafted" then
		return not IsItemLinkCrafted(GetItemLink(bagId, slotIndex))
	end
	if mode == "Set" then
		local hasSet = GetItemLinkSetInfo(GetItemLink(bagId, slotIndex), false)
		return not hasSet
	end
	if mode == "KnownSet" then
		local hasSet = GetItemLinkSetInfo(GetItemLink(bagId, slotIndex), false)
		return hasSet and not IsKnown(bagId, slotIndex)
	end

	return false
end

local function CreateButtons(control, inventory, ...)
	local mode = "All"
	local function filterFunction(self, bagId, slotIndex)
		return doFilter(self, bagId, slotIndex, mode)
	end

	local nameToButton = {}
	local function callback(self)
		mode = self.name
		for name, button in pairs(nameToButton) do
			button:SetState(mode == name and BSTATE_PRESSED or BSTATE_NORMAL)
		end
		return inventory:HandleDirtyEvent()
	end

	local function createButton(name, position)
		if nameToButton[name] then
			return false
		end

		local buttonName = "$(parent)Filter" .. name

		local button = WINDOW_MANAGER:CreateControl(buttonName, control, CT_BUTTON)
		nameToButton[name] = button

		local buttonData = buttons[name]
		button.name = name
		button:SetNormalTexture(buttonData.texture.up)
		button:SetPressedTexture(buttonData.texture.down)
		button:SetMouseOverTexture(buttonData.texture.over)
		button:SetState(mode == name and BSTATE_PRESSED or BSTATE_NORMAL)
		button:SetClickSound(SOUNDS.MENU_BAR_CLICK)
		button:SetDimensions(buttonData.size * 0.9, buttonData.size * 0.9)
		button:SetDrawTier(DT_MEDIUM)
		button:SetDrawLayer(DL_CONTROLS)
		button:SetDrawLevel(2)
		button:SetAnchor(LEFT, CRAFTSTATION_SMITHING_DECONSTRUCTION_TABS, TOPLEFT, 24 + 34 * position + buttonData.offset, 30)
		button:SetHandler("OnClicked", callback)
		button.tooltip = buttonData.tooltip
		button:SetMouseEnabled(true)
		button:SetHandler("OnMouseEnter", ShowTooltip)
		button:SetHandler("OnMouseExit", HideTooltip)
	end

	local modes = {...}
	for pos = 1, #modes do
		createButton(modes[pos], pos - 1)
	end

	ZO_PreHook(inventory, "AddItemData", filterFunction)
end

CreateButtons(ZO_SmithingTopLevelDeconstructionPanelInventory, SMITHING.deconstructionPanel.inventory, "All", "Stolen", "Trash", "Bag", "Bank", "Intricate", "Set", "KnownSet")
ZO_SmithingTopLevelDeconstructionPanelInventoryIncludeBanked:SetHidden(true)
ZO_SmithingTopLevelDeconstructionPanelInventoryButtonDivider:SetHidden(true)
ZO_SmithingTopLevelDeconstructionPanelInventoryButtonDivider:ClearAnchors()
ZO_SmithingTopLevelDeconstructionPanelInventoryButtonDivider:SetAnchor(TOPLEFT, ZO_SmithingTopLevelDeconstructionPanelInventoryFilterDivider, TOPLEFT, 0, 0)

CreateButtons(ZO_SmithingTopLevelImprovementPanelInventory, SMITHING.improvementPanel.inventory, "All", "Bag", "Bank", "Worn", "Crafted", "Set")
CreateButtons(ZO_RetraitStation_KeyboardTopLevelRetraitPanelInventory, ZO_RETRAIT_KEYBOARD.inventory, "All", "Bag", "Bank", "Worn", "Set")
