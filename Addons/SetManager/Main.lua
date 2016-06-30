local addon = {
	name = "SetManager",
	playerDefaults =
	{
		crafting = { },
		sets = { }
	},
	accountDefaults =
	{
		sets = { }
	},
}

-- local am = GetAnimationManager()
local wm = GetWindowManager()
local em = GetEventManager()
local LMM2
local ROW_TYPE_ID = 1

local function InitializeSlots(parent)
	if parent.slots then return end

	local slots =
	{
		[EQUIP_SLOT_HEAD] = parent:GetNamedChild("EquipmentSlotsHead"),
		[EQUIP_SLOT_NECK] = parent:GetNamedChild("EquipmentSlotsNeck"),
		[EQUIP_SLOT_CHEST] = parent:GetNamedChild("EquipmentSlotsChest"),
		[EQUIP_SLOT_SHOULDERS] = parent:GetNamedChild("EquipmentSlotsShoulder"),
		[EQUIP_SLOT_MAIN_HAND] = parent:GetNamedChild("EquipmentSlotsMainHand"),
		[EQUIP_SLOT_OFF_HAND] = parent:GetNamedChild("EquipmentSlotsOffHand"),
		[EQUIP_SLOT_POISON] = parent:GetNamedChild("EquipmentSlotsPoison"),
		[EQUIP_SLOT_WAIST] = parent:GetNamedChild("EquipmentSlotsBelt"),
		[EQUIP_SLOT_LEGS] = parent:GetNamedChild("EquipmentSlotsLeg"),
		[EQUIP_SLOT_FEET] = parent:GetNamedChild("EquipmentSlotsFoot"),
		[EQUIP_SLOT_COSTUME] = parent:GetNamedChild("EquipmentSlotsCostume"),
		[EQUIP_SLOT_RING1] = parent:GetNamedChild("EquipmentSlotsRing1"),
		[EQUIP_SLOT_RING2] = parent:GetNamedChild("EquipmentSlotsRing2"),
		[EQUIP_SLOT_HAND] = parent:GetNamedChild("EquipmentSlotsGlove"),
		[EQUIP_SLOT_BACKUP_MAIN] = parent:GetNamedChild("EquipmentSlotsBackupMain"),
		[EQUIP_SLOT_BACKUP_OFF] = parent:GetNamedChild("EquipmentSlotsBackupOff"),
		[EQUIP_SLOT_BACKUP_POISON] = parent:GetNamedChild("EquipmentSlotsBackupPoison"),
	}

	parent.slots = slots

	parent:GetNamedChild("PaperDoll"):SetTexture(GetUnitSilhouetteTexture("player"))

	local ZO_Character_GetEmptyEquipSlotTexture = ZO_Character_GetEmptyEquipSlotTexture
	for slotId, slotControl in pairs(slots) do
		local iconControl = slotControl:GetNamedChild("Icon")
		iconControl:SetTexture(ZO_Character_GetEmptyEquipSlotTexture(slotId))
	end
end

local function PlayerActivated()
	em:UnregisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED)
	-- RefreshWornInventory()
	-- RefreshBackUpWeaponSlotStates()
end

local function HideRowHighlight(rowControl, hidden)
	if not rowControl then return end
	if not ZO_ScrollList_GetData(rowControl) then return end

	local highlight = rowControl:GetNamedChild("Highlight")

	if highlight then
		if not highlight.animation then
			highlight.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ShowOnMouseOverLabelAnimation", highlight)
		end

		if highlight.animation:IsPlaying() then
			highlight.animation:Stop()
		end
		if hidden then
			highlight.animation:PlayBackward()
			ClearTooltip(ItemTooltip, rowControl)
		else
			highlight.animation:PlayForward()
		end
	end
end

function addon:InitItemList()
	local function onMouseEnter(rowControl)
		HideRowHighlight(rowControl, false)
	end
	local function onMouseExit(rowControl)
		HideRowHighlight(rowControl, true)
	end
	local function onMouseDoubleClick(rowControl)
	end

	local function setupDataRow(rowControl, rowData, scrollList)
		local icon = rowControl:GetNamedChild("Texture")
		local nameLabel = rowControl:GetNamedChild("Name")

		icon:SetTexture(rowData.icon)
		nameLabel:SetText(zo_strformat(rowData.name))

		rowControl:SetHandler("OnMouseEnter", onMouseEnter)
		rowControl:SetHandler("OnMouseExit", onMouseExit)
		rowControl:SetHandler("OnMouseDoubleClick", onMouseDoubleClick)
	end
	self.ItemList = SetManagerTopLevelItemList
	ZO_ScrollList_AddDataType(self.ItemList, ROW_TYPE_ID, "SetManagerItemListRow", 32, setupDataRow)
end

function addon:InitSetsList()
	local function onMouseEnter(rowControl)
		HideRowHighlight(rowControl, false)
		InitializeTooltip(ItemTooltip, rowControl, TOPRIGHT, 0, -104, TOPLEFT)
		local rowData = ZO_ScrollList_GetData(rowControl)
		--ItemTooltip:ClearLines()
		--ToDo: Nice formatting of SetBonusInfo
		ItemTooltip:SetLink(rowData.itemLink)
	end
	local function onMouseExit(rowControl)
		HideRowHighlight(rowControl, true)
	end
	local function onMouseDoubleClick(rowControl)
	end

	local function setupDataRow(rowControl, rowData, scrollList)
		local icon = rowControl:GetNamedChild("Texture")
		local nameLabel = rowControl:GetNamedChild("Name")

		-- icon:SetTexture(rowData.icon)
		nameLabel:SetText(zo_strformat("<<C:1>>", rowData.name))

		rowControl:SetHandler("OnMouseEnter", onMouseEnter)
		rowControl:SetHandler("OnMouseExit", onMouseExit)
		rowControl:SetHandler("OnMouseDoubleClick", onMouseDoubleClick)
	end
	self.SetsList = SetManagerTopLevelSetsList
	self.SetsList.dirty = true

	ZO_ScrollList_AddDataType(self.SetsList, ROW_TYPE_ID, "SetManagerSetsListRow", 48, setupDataRow)
end

function addon:InitWindow()
	local function InitSetScrollList(scrollListControl, listContainer, listSlotTemplate)

		local function SetupFunction(control, data, selected, selectedDuringRebuild, enabled)
			InitializeSlots(control)

			-- 		if self:IsInvalidMode() then return end

			-- 		SetupSharedSlot(control, SLOT_TYPE_SMITHING_TRAIT, listContainer, self.traitList)
			-- 		ZO_ItemSlot_SetAlwaysShowStackCount(control, data.traitType ~= ITEM_TRAIT_TYPE_NONE)

			-- 		control.traitIndex = data.traitIndex
			-- 		control.traitType = data.traitType
			-- 		local stackCount = GetCurrentSmithingTraitItemCount(data.traitIndex)
			-- 		local hasEnoughInInventory = stackCount > 0
			-- 		local isTraitKnown = false
			-- 		if self:IsCraftableWithoutTrait() then
			-- 			local patternIndex, materialIndex, materialQty, styleIndex = self:GetAllNonTraitCraftingParameters()
			-- 			isTraitKnown = IsSmithingTraitKnownForResult(patternIndex, materialIndex, materialQty, styleIndex, data.traitIndex)
			-- 		end
			-- 		local usable = data.traitType == ITEM_TRAIT_TYPE_NONE or(hasEnoughInInventory and isTraitKnown)

			-- 		ZO_ItemSlot_SetupSlot(control, stackCount, data.icon, usable, not enabled)

			-- 		if selected then
			-- 			SetHighlightColor(highlightTexture, usable)

			-- 			self:SetLabelHidden(listContainer.extraInfoLabel, usable or data.traitType == ITEM_TRAIT_TYPE_NONE)
			-- 			if usable then
			-- 				self.isTraitUsable = USABILITY_TYPE_USABLE
			-- 			else
			-- 				self.isTraitUsable = USABILITY_TYPE_VALID_BUT_MISSING_REQUIREMENT
			-- 				if not isTraitKnown then
			-- 					listContainer.extraInfoLabel:SetText(GetString(SI_SMITHING_TRAIT_MUST_BE_RESEARCHED))
			-- 				elseif not hasEnoughInInventory then
			-- 					self:SetLabelHidden(listContainer.extraInfoLabel, true)
			-- 				end
			-- 			end

			-- 			if not data.localizedName then
			-- 				if data.traitType == ITEM_TRAIT_TYPE_NONE then
			-- 					data.localizedName = GetString("SI_ITEMTRAITTYPE", data.traitType)
			-- 				else
			-- 					data.localizedName = self:GetPlatformFormattedTextString(SI_SMITHING_TRAIT_DESCRIPTION, data.name, GetString("SI_ITEMTRAITTYPE", data.traitType))
			-- 				end
			-- 			end

			-- 			listContainer.selectedLabel:SetText(data.localizedName)

			-- 			if not selectedDuringRebuild then
			-- 				self:RefreshVisiblePatterns()
			-- 			end
			-- 		end
		end

		local function EqualityFunction(leftData, rightData)
			return leftData == rightData
		end

		local function OnHorizonalScrollListShown(list)
			--    local listContainer = list:GetControl():GetParent()
			--    listContainer.selectedLabel:SetHidden(false)
		end

		local function OnHorizonalScrollListCleared(list)
		end
		local scroll = listContainer:GetNamedChild("Scroll")
		scroll:SetFadeGradient(1, 1, 0, 64)
		scroll:SetFadeGradient(2, -1, 0, 64)
		return scrollListControl:New(listContainer, listSlotTemplate, 1, SetupFunction, EqualityFunction, OnHorizonalScrollListShown, OnHorizonalScrollListCleared)
	end

	local control

	control = SetManagerTopLevel
	control:SetHidden(true)
	addon.windowSet = control

	self.scrollListSet = InitSetScrollList(ZO_HorizontalScrollList, SetManagerTopLevelSetTemplateList, "SetManager_Character_Template")
	self.scrollListSet:SetScaleExtents(0.6, 1)

	self:InitItemList()
	self:InitSetsList()

	-- Demo fake
	self.scrollListSet:Clear()
	self.scrollListSet:AddEntry( { })
	self.scrollListSet:AddEntry( { })
	self.scrollListSet:AddEntry( { })
	self.scrollListSet:Commit()

	SETMANAGER_CHARACTER_FRAGMENT = ZO_FadeSceneFragment:New(addon.windowSet, false, 0)

	local descriptor = addon.name
	local sceneName = addon.name
	SETMANAGER_SCENE = ZO_Scene:New(sceneName, SCENE_MANAGER)

	SETMANAGER_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
	SETMANAGER_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
	SETMANAGER_SCENE:AddFragment(THIN_LEFT_PANEL_BG_FRAGMENT)
	SETMANAGER_SCENE:AddFragment(CHARACTER_WINDOW_FRAGMENT)
	SETMANAGER_SCENE:AddFragment(SETMANAGER_CHARACTER_FRAGMENT)
	SETMANAGER_SCENE:AddFragment(WIDE_RIGHT_BG_FRAGMENT)
	SETMANAGER_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_JOURNAL)
	SETMANAGER_SCENE:AddFragment(CHARACTER_WINDOW_SOUNDS)
	-- SETMANAGER_SCENE:AddFragment(ZO_WindowSoundFragment:New(SOUNDS.ALCHEMY_OPENED, SOUNDS.ALCHEMY_CLOSED))

	SCENE_MANAGER:AddSceneGroup("SetManagerSceneGroup", ZO_SceneGroup:New(descriptor))

	SLASH_COMMANDS["/setm"] = function(...) addon:cmdSetManager(...) end
	LMM2 = LibStub("LibMainMenu-2.0")
	LMM2:Init()
	self.LMM2 = LMM2

	-- Add to main menu
	local categoryLayoutInfo =
	{
		binding = "SET_MANAGER",
		categoryName = SI_BINDING_NAME_SET_MANAGER,
		callback = function(buttonData)
			if not SCENE_MANAGER:IsShowing(sceneName) then
				SCENE_MANAGER:Show(sceneName)
			else
				SCENE_MANAGER:ShowBaseScene()
			end
		end,
		visible = function(buttonData) return true end,

		normal = "esoui/art/crafting/smithing_tabicon_armorset_up.dds",
		pressed = "esoui/art/crafting/smithing_tabicon_armorset_down.dds",
		highlight = "esoui/art/crafting/smithing_tabicon_armorset_over.dds",
		disabled = "esoui/art/crafting/smithing_tabicon_armorset_disabled.dds",
	}

	LMM2:AddMenuItem(descriptor, sceneName, categoryLayoutInfo, nil)

	em:RegisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED, PlayerActivated)
end

function addon:FillSetsList()
	local scrollList = self.SetsList
	local dataList = ZO_ScrollList_GetDataList(scrollList)

	ZO_ScrollList_Clear(scrollList)

	local format, createLink = zo_strformat, string.format
	local GetItemLinkSetInfo = GetItemLinkSetInfo

	local sets = self.allSets
	for itemId, items in pairs(sets) do
		local itemLink = createLink("|H1:item:%i:304:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", itemId)
		local _, name = GetItemLinkSetInfo(itemLink, false)

		local rowData = { name = name, itemLink = itemLink, items = items }
		dataList[#dataList + 1] = ZO_ScrollList_CreateDataEntry(ROW_TYPE_ID, rowData, 1)
	end

	table.sort(dataList, function(a, b) return a.data.name < b.data.name end)

	ZO_ScrollList_Commit(scrollList)
	scrollList.dirty = false
end

function addon:InitSetManager()
	SETMANAGER_CHARACTER_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
		if newState == SCENE_FRAGMENT_SHOWING then
			if self.SetsList.dirty then
				self:FillSetsList()
			end
		elseif newState == SCENE_FRAGMENT_SHOWN then
		elseif newState == SCENE_FRAGMENT_HIDING then
		elseif newState == SCENE_FRAGMENT_HIDDEN then
		end
	end )
end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then return end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	addon.player = ZO_SavedVars:New("SetManager_Data", 1, nil, addon.playerDefaults, nil)
	addon.account = ZO_SavedVars:NewAccountWide("SetManager_Data", 1, nil, addon.accountDefaults, nil)

	addon:InitWindow()
	addon:InitInventoryScan()

	-- addon.debugstart = GetGameTimeMilliseconds()
	-- local format, createLink = zo_strformat, string.format
	-- local GetItemLinkSetInfo = GetItemLinkSetInfo
	-- local list = { }
	-- for itemId = 29500, 90000 do
	-- 	local itemLink = createLink("|H1:item:%i:304:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", itemId)
	-- 	local hasSet, setName = GetItemLinkSetInfo(itemLink, false)
	-- 	if hasSet then
	-- 		local parts = list[setName] or { }
	-- 		parts[#parts + 1] = itemId
	-- 		list[setName] = parts
	-- 	end
	-- end
	-- local sets = { }
	-- for name, items in pairs(list) do
	-- 	local firstItem = items[1]
	-- 	sets[firstItem] = items
	-- end
	-- addon.account.all = sets
	-- addon.debugend = GetGameTimeMilliseconds()

	addon:InitSetManager()
end

function addon:ToggleEditorScene()
	self.LMM2:SelectMenuItem(self.name)
end

function addon:cmdSetManager(text)
	d("execute /setm")
	if (text == "dump") then
		self:dumpItems(5, true)
	elseif (text == "reset") then
		d("check")
		addon:DoCompleteProcess()
	elseif (text == "boni") then
		d("boni")
		addon:dumpBoni()
	else
		d("use check|dump")
	end
end

function addon:dumpItems(minNum, unbound)
	if (addon.sets ~= nil) then
		for set, info in pairs(addon.sets) do
			self:dumpSetInfo(set, info)
		end
	else
		d("No sets stored")
	end
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

SET_MANAGER = addon