local addon = {
	name = "SetManager",
	playerDefaults =
	{
		sets = { },
		worn = { },
		mode = "INVENTORY",
		quality = ITEM_QUALITY_MAGIC,
	},
	accountDefaults =
	{
		sets = { },
		templates = { },
	},
	setCategory =
	{
		NonCraftable = "NON_CRAFTABLE",
		Craftable = "CRAFTABLE",
	}
}

-- local am = GetAnimationManager()
local wm = GetWindowManager()
local em = GetEventManager()
local ROW_TYPE_ID = 1

local function OnSlotClicked(control)
	local parent = control:GetParent()
	for equipSlot, other in pairs(parent.slots) do
		local selected = other == control
		other:SetState(selected and BSTATE_PRESSED or BSTATE_NORMAL)
		if selected then parent.selectedSlot = equipSlot end
	end
	if parent.OnSelectedChanged then parent.OnSelectedChanged(parent) end
end

local function UpdateSlot(self)
	local iconControl = self:GetNamedChild("Icon")
	if self.itemLink then
		local icon = GetItemLinkInfo(self.itemLink)
		iconControl:SetTexture(icon)
	else
		iconControl:SetTexture(ZO_Character_GetEmptyEquipSlotTexture(self.slotId))
	end
end

function addon:InitializeSlots(parent)
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
		slotControl.slotId = slotId
		slotControl.Update = UpdateSlot
		slotControl:SetHandler("OnClicked", OnSlotClicked)
	end
end

local function OnSlotEditableClicked(control, button)
	if button == MOUSE_BUTTON_INDEX_LEFT then
		OnSlotClicked(control)
	elseif button == MOUSE_BUTTON_INDEX_RIGHT then
		local parent = control:GetParent()
	end
end

function addon:InitializeEditableSlots(parent)
	self:InitializeSlots(parent)
	local edit = parent:GetNamedChild("Name")
	local function TextChanged(self)
		parent.templateName = self:GetText()
		local instructions = self:GetNamedChild("Instructions")
		instructions:SetHidden(parent.templateName ~= "")
	end
	local function TextPressEnter(self)
		self:LoseFocus()
		if parent.OnTemplateChanged then parent:OnTemplateChanged() end
	end
	edit:SetHandler("OnEnter", TextPressEnter)
	edit:SetHandler("OnTextChanged", TextChanged)
	for slotId, slotControl in pairs(parent.slots) do
		slotControl:SetHandler("OnClicked", OnSlotEditableClicked)
	end
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

local function AddLine(tooltip, text, color, alignment)
	local r, g, b = color:UnpackRGB()
	tooltip:AddLine(text, "", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, alignment, alignment ~= TEXT_ALIGN_LEFT)
end

local function AddLineCenter(tooltip, text, color)
	if not color then color = ZO_TOOLTIP_DEFAULT_COLOR end
	AddLine(tooltip, text, color, TEXT_ALIGN_CENTER)
end

local function AddLineTitle(tooltip, text, color)
	if not color then color = ZO_SELECTED_TEXT end
	local r, g, b = color:UnpackRGB()
	tooltip:AddLine(text, "ZoFontHeader3", r, g, b, CENTER, MODIFY_TEXT_TYPE_UPPERCASE, TEXT_ALIGN_CENTER, true)
end

function addon:InitItemList()
	local function onMouseEnter(rowControl)
		HideRowHighlight(rowControl, false)
		InitializeTooltip(ItemTooltip, rowControl, TOPRIGHT, 0, -104, TOPLEFT)
		local rowData = ZO_ScrollList_GetData(rowControl)
		ItemTooltip:SetLink(rowData.itemLink)
		self.ItemList.hovered = ZO_ScrollList_GetData(rowControl)
		KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptorMouseOver)
	end
	local function onMouseExit(rowControl)
		HideRowHighlight(rowControl, true)
		self.ItemList.hovered = nil
		KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptorMouseOver)
	end
	local function onMouseDoubleClick(rowControl)
	end

	local function setupDataRow(rowControl, rowData, scrollList)
		local icon = rowControl:GetNamedChild("Texture")
		local nameLabel = rowControl:GetNamedChild("Name")

		local itemName = GetItemLinkName(rowData.itemLink)
		local iconTexture = GetItemLinkInfo(rowData.itemLink)
		local quality = GetItemLinkQuality(rowData.itemLink)

		icon:SetTexture(iconTexture)
		nameLabel:SetText(zo_strformat("<<C:1>>", itemName))
		nameLabel:SetColor(GetItemQualityColor(quality):UnpackRGB())

		rowControl:SetHandler("OnMouseEnter", onMouseEnter)
		rowControl:SetHandler("OnMouseExit", onMouseExit)
		rowControl:SetHandler("OnMouseDoubleClick", onMouseDoubleClick)
	end
	self.ItemList = SetManagerTopLevelItemList

	ZO_ScrollList_AddDataType(self.ItemList, ROW_TYPE_ID, "SetManagerItemListRow", 48, setupDataRow)
end

function addon:InitSetsList()
	local function onMouseEnter(rowControl)
		HideRowHighlight(rowControl, false)
		InitializeTooltip(ItemTooltip, rowControl, TOPRIGHT, 0, -104, TOPLEFT)
		local rowData = ZO_ScrollList_GetData(rowControl)
		ItemTooltip:ClearLines()

		local itemLink = rowData.itemLink

		local iconTexture = GetItemLinkInfo(itemLink)
		ZO_ItemIconTooltip_OnAddGameData(ItemTooltip, TOOLTIP_GAME_DATA_ITEM_ICON, iconTexture)
		ItemTooltip:AddVerticalPadding(24)

		local hasSet, setName, numBonuses, _, maxEquipped = GetItemLinkSetInfo(itemLink)
		if hasSet then
			AddLineTitle(ItemTooltip, zo_strformat(SI_TOOLTIP_ITEM_NAME, setName))
			ItemTooltip:AddVerticalPadding(-9)
			ZO_Tooltip_AddDivider(ItemTooltip)
			for i = 1, numBonuses do
				local _, bonusDescription = GetItemLinkSetBonusInfo(itemLink, false, i)
				AddLineCenter(ItemTooltip, bonusDescription)
			end
		end
	end
	local function onMouseExit(rowControl)
		local rowData = ZO_ScrollList_GetData(rowControl)
		HideRowHighlight(rowControl, self.SetsList.selected ~= rowData.id)
	end
	local selectedRow
	local function onMouseDoubleClick(rowControl)
		local rowData = ZO_ScrollList_GetData(rowControl)
		self.SetsList.selected = rowData.id
		if selectedRow then ZO_ScrollList_RefreshVisible(self.SetsList, selectedRow) end
		selectedRow = rowData
		self:UpdateItemList()
		PlaySound(SOUNDS.DEFAULT_CLICK)
	end

	local function setupDataRow(rowControl, rowData, scrollList)
		local icon = rowControl:GetNamedChild("Texture")
		local nameLabel = rowControl:GetNamedChild("Name")

		local setInfo = rowData.setInfo
		local iconiconTexture
		if setInfo.isCraftable then
			iconTexture = "/esoui/art/icons/poi/poi_crafting_complete.dds"
		elseif setInfo.isMonster then
			iconTexture = "/esoui/art/icons/servicemappins/servicepin_undaunted.dds"
		elseif setInfo.isJevelry then
			iconTexture = "/esoui/art/icons/servicemappins/servicepin_armory.dds"
		else
			iconTexture = "/esoui/art/icons/mapkey/mapkey_bank.dds"
		end
		icon:SetTexture(iconTexture)
		nameLabel:SetText(zo_strformat("<<C:1>>", rowData.name))

		rowControl:SetHandler("OnMouseEnter", onMouseEnter)
		rowControl:SetHandler("OnMouseExit", onMouseExit)
		-- rowControl:EnableMouseButton(1, true)
		rowControl:SetHandler("OnClicked", onMouseDoubleClick)
		onMouseExit(rowControl)
	end
	self.SetsList = SetManagerTopLevelSetsList
	ZO_ScrollList_Initialize(self.SetsList)
	self.SetsList.dirty = true

	ZO_ScrollList_AddDataType(self.SetsList, ROW_TYPE_ID, "SetManagerSetsListRow", 48, setupDataRow, setupDataRow)
end

local function FakeEquippedItemTooltip(itemLink)
	-- SetLink uses original functions only. They protected it.
	-- Rewrite Tooltip???
	ItemTooltip:SetLink(itemLink, true)
end

function addon:InitSetTemplateList()
	local function InitSetTemplateList(scrollListControl, listContainer, listSlotTemplate)
		local function OnSelectedSlotChanged(control)
			self.selectedSlot = control.selectedSlot
			self:UpdateItemList()
			PlaySound(SOUNDS.DEFAULT_CLICK)
		end
		local function OnTemplateChanged(self)
			local rowData = self.data
			rowData.name = self.templateName
		end

		local function onMouseEnter(rowControl)
			if rowControl.itemLink then
				InitializeTooltip(ItemTooltip, rowControl, TOPRIGHT, 0, -104, TOPLEFT)
				FakeEquippedItemTooltip(rowControl.itemLink)
				self.scrollListSet.hoveredSlot = rowControl.slotId
				KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptorMouseOver)
			end
		end
		local function onMouseExit(rowControl)
			ClearTooltip(ItemTooltip, rowControl)
			self.scrollListSet.hoveredSlot = nil
			KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptorMouseOver)
		end
		local function SetupFunction(control, data, selected, selectedDuringRebuild, enabled)
			control.data = data
			control.OnSelectedChanged = OnSelectedSlotChanged
			control.OnTemplateChanged = OnTemplateChanged

			local edit = control:GetNamedChild("Name")
			edit:SetText(data.name)

			for slotId, slotControl in pairs(control.slots) do
				slotControl.itemLink = data[slotId]
				slotControl:Update()
				slotControl:SetHandler("OnMouseEnter", onMouseEnter)
				slotControl:SetHandler("OnMouseExit", onMouseExit)
			end

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
	self.scrollListSet = InitSetTemplateList(ZO_HorizontalScrollList, SetManagerTopLevelSetTemplateList, "SetManager_Character_Template_Editable")
	self.scrollListSet:SetScaleExtents(0.6, 1)
	self.scrollListSet.dirty = true
end

function addon:InitializeStyleList()
	local function InitializeStyleList(scrollListControl, styleUnknownFont, notEnoughInInventoryFont, listSlotTemplate)
		local listContainer = SetManagerTopLevelStyleList
		local highlightTexture = listContainer.highlightTexture
		listContainer.titleLabel:SetText(GetString(SI_SMITHING_HEADER_STYLE))

		local function SetupFunction(control, data, selected, selectedDuringRebuild, enabled)

			-- SetupSharedSlot(control, SLOT_TYPE_SMITHING_STYLE, listContainer, self.styleList)
			ZO_ItemSlot_SetAlwaysShowStackCount(control, true)

			control.styleIndex = data.styleIndex
			local usesUniversalStyleItem = false
			local stackCount = GetCurrentSmithingStyleItemCount(data.styleIndex)
			local hasEnoughInInventory = stackCount > 0
			local universalStyleItemCount = GetCurrentSmithingStyleItemCount(ZO_ADJUSTED_UNIVERSAL_STYLE_ITEM_INDEX)
			local isStyleKnown = true
			local usable = true
			ZO_ItemSlot_SetupSlot(control, stackCount, data.icon, usable, not enabled)
			local stackCountLabel = GetControl(control, "StackCount")
			stackCountLabel:SetHidden(usesUniversalStyleItem)

			if selected then
				HideRowHighlight(highlightTexture, usable)

				-- self:SetLabelHidden(listContainer.extraInfoLabel, true)
				if not usable then
					if not isStyleKnown then
						-- self:SetLabelHidden(listContainer.extraInfoLabel, false)
						listContainer.extraInfoLabel:SetText(GetString(SI_SMITHING_UNKNOWN_STYLE))
					end
				end

				local universalStyleItemCount = GetCurrentSmithingStyleItemCount(ZO_ADJUSTED_UNIVERSAL_STYLE_ITEM_INDEX)
				self.isStyleUsable = usable and USABILITY_TYPE_USABLE or USABILITY_TYPE_VALID_BUT_MISSING_REQUIREMENT

				if not data.localizedName then
					if data.itemStyle == ITEMSTYLE_NONE then
						data.localizedName = GetString("SI_ITEMSTYLE", data.itemStyle)
					else
						data.localizedName = zo_strformat(SI_SMITHING_STYLE_DESCRIPTION, data.name, GetString("SI_ITEMSTYLE", data.itemStyle))
					end
				end

				listContainer.selectedLabel:SetText(data.localizedName)

				if not selectedDuringRebuild then
					-- self:RefreshVisiblePatterns()
				end
			end
		end

		local function EqualityFunction(leftData, rightData)
			return leftData.craftingType == rightData.craftingType and leftData.name == rightData.name
		end

		local function OnHorizonalScrollListCleared(...)
			-- self:OnHorizonalScrollListCleared(...)
		end

		self.styleList = scrollListControl:New(listContainer.listControl, listSlotTemplate, BASE_NUM_ITEMS_IN_LIST, SetupFunction, EqualityFunction, OnHorizonalScrollListShown, OnHorizonalScrollListCleared)
		self.styleList:SetNoItemText(GetString(SI_SMITHING_NO_STYLE_FOUND))

		self.styleList:SetSelectionHighlightInfo(highlightTexture, highlightTexture and highlightTexture.pulseAnimation)
		self.styleList:SetScaleExtents(0.6, 1)

		self.styleList:SetOnSelectedDataChangedCallback( function(selectedData, oldData, selectedDuringRebuild)
			self.styleList.selectedStyle = selectedData
			addon:UpdateItemList()
		end )

	end
	local scrollListControl = ZO_HorizontalScrollList
	local traitUnknownFont = "ZoFontWinH4"
	local notEnoughInInventoryFont = "ZoFontHeader4"
	local listSlotTemplate = "ZO_SmithingListSlot"

	InitializeStyleList(scrollListControl, traitUnknownFont, notEnoughInInventoryFont, listSlotTemplate)
end

function addon:UpdateSetsList()
	local scrollList = self.SetsList
	local dataList = ZO_ScrollList_GetDataList(scrollList)

	ZO_ScrollList_Clear(scrollList)
	for _, categoryId in pairs(self.setCategory) do
		ZO_ScrollList_AddCategory(scrollList, categoryId)
	end

	local format, createLink = zo_strformat, string.format
	local GetItemLinkSetInfo, ZO_ScrollList_CreateDataEntry = GetItemLinkSetInfo, ZO_ScrollList_CreateDataEntry

	local sets = self.allSets
	for itemId, setInfo in pairs(sets) do
		local itemLink = createLink("|H1:item:%i:304:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", itemId)
		local _, name = GetItemLinkSetInfo(itemLink, false)

		local rowData = { id = itemId, name = name, itemLink = itemLink, setInfo = setInfo }
		local categoryId = setInfo.isCraftable and self.setCategory.Craftable or self.setCategory.NonCraftable
		dataList[#dataList + 1] = ZO_ScrollList_CreateDataEntry(ROW_TYPE_ID, rowData, categoryId)
	end

	table.sort(dataList, function(a, b) return a.data.name < b.data.name end)

	ZO_ScrollList_Commit(scrollList)
	scrollList.dirty = false
end

function addon:UpdateItemList()
	local scrollList = self.ItemList

	ZO_ScrollList_Clear(scrollList)
	local dataList = ZO_ScrollList_GetDataList(scrollList)
	self:ApplyFilter(dataList)
	ZO_ScrollList_Commit(scrollList)
	SetManagerTopLevelCraft:SetHidden((self.player.mode == "INVENTORY") or(#dataList == 0))

	scrollList.dirty = false
end

function addon:UpdateTemplateList()
	local templates = self.account.templates
	self.scrollListSet:Clear()
	for _, template in ipairs(templates) do
		self.scrollListSet:AddEntry(template)
	end
	self.scrollListSet:Commit()
	self.scrollListSet.dirty = false
end

function addon:UpdateStyleList()
	self.styleList:Clear()

	local GetSmithingStyleItemInfo = GetSmithingStyleItemInfo
	for styleIndex = 1, GetNumSmithingStyleItems() do
		local name, icon, sellPrice, meetsUsageRequirement, itemStyle, quality = GetSmithingStyleItemInfo(styleIndex)
		if meetsUsageRequirement then
			self.styleList:AddEntry( { craftingType = 0, styleIndex = styleIndex, name = name, itemStyle = itemStyle, icon = icon, quality = quality })
		end
	end

	self.styleList:Commit()
end

do
	local function FilterByInventory(self, dataList)
		local selectedSlot = self.selectedSlot
		if not selectedSlot then return end
		local GetItemLinkEquipType, ZO_Character_DoesEquipSlotUseEquipType = GetItemLinkEquipType, ZO_Character_DoesEquipSlotUseEquipType
		local function ItemFilter(itemLink)
			local equipType = GetItemLinkEquipType(itemLink)
			if ZO_Character_DoesEquipSlotUseEquipType(selectedSlot, equipType) then
				local rowData = { id = itemId, itemLink = itemLink }
				dataList[#dataList + 1] = ZO_ScrollList_CreateDataEntry(ROW_TYPE_ID, rowData, 1)
			end
		end
		for _, itemLink in ipairs(self.account.sets) do ItemFilter(itemLink) end
		for _, itemLink in ipairs(self.player.sets) do ItemFilter(itemLink) end
		for _, itemLink in ipairs(self.player.worn) do ItemFilter(itemLink) end
	end

	local function FilterByCraftableSet(self, dataList)
		local targetSetId, selectedSlot = self.SetsList.selected, self.selectedSlot
		if not targetSetId or not selectedSlot then return end
		local setInfo = self.allSets[targetSetId]
		if not setInfo then return end

		local format, createLink = zo_strformat, string.format
		local GetItemLinkSetInfo, GetItemLinkEquipType, GetItemLinkEquipType, ZO_Character_DoesEquipSlotUseEquipType = GetItemLinkSetInfo, GetItemLinkEquipType, GetItemLinkEquipType, ZO_Character_DoesEquipSlotUseEquipType

		local level, champ = GetUnitLevel("player"), GetUnitChampionPoints("player")
		local quality = ZO_MenuBar_GetSelectedDescriptor(self.qualityBar)
		local subId = self:CreateSubItemId(level, champ, quality)
		local itemLink = createLink("|H1:item:%i:%i:%i:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", targetSetId, subId, level)
		local _, targetSetName = GetItemLinkSetInfo(itemLink, false)
		local function ItemFilter(itemLink)
			local _, name = GetItemLinkSetInfo(itemLink, false)
			if name == targetSetName then
				local equipType = GetItemLinkEquipType(itemLink)
				if ZO_Character_DoesEquipSlotUseEquipType(selectedSlot, equipType) then
					local rowData = { id = itemId, itemLink = itemLink }
					dataList[#dataList + 1] = ZO_ScrollList_CreateDataEntry(ROW_TYPE_ID, rowData, 1)
				end
			end
		end
		local itemStyle = self.styleList.selectedStyle and self.styleList.selectedStyle.itemStyle or 0
		for _, itemId in ipairs(setInfo.items) do ItemFilter(createLink("|H1:item:%i:%i:%i:0:0:0:0:0:0:0:0:0:0:0:0:%i:0:0:0:10000:0|h|h", itemId, subId, level, itemStyle)) end
	end

	local function FilterBySet(self, dataList)
		local targetSetId, selectedSlot = self.SetsList.selected, self.selectedSlot
		if not targetSetId or not selectedSlot then return end
		local setInfo = self.allSets[targetSetId]
		if not setInfo then return end

		local format, createLink = zo_strformat, string.format
		local GetItemLinkSetInfo, GetItemLinkEquipType, GetItemLinkEquipType, ZO_Character_DoesEquipSlotUseEquipType = GetItemLinkSetInfo, GetItemLinkEquipType, GetItemLinkEquipType, ZO_Character_DoesEquipSlotUseEquipType

		local level, champ = GetUnitLevel("player"), GetUnitChampionPoints("player")
		local quality = ZO_MenuBar_GetSelectedDescriptor(self.qualityBar)
		local subId = self:CreateSubItemId(level, champ, quality)
		local itemLink = createLink("|H1:item:%i:%i:%i:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", targetSetId, subId, level)
		local _, targetSetName = GetItemLinkSetInfo(itemLink, false)
		local function ItemFilter(itemLink)
			local _, name = GetItemLinkSetInfo(itemLink, false)
			if name == targetSetName then
				local equipType = GetItemLinkEquipType(itemLink)
				if ZO_Character_DoesEquipSlotUseEquipType(selectedSlot, equipType) then
					local rowData = { id = itemId, itemLink = itemLink }
					dataList[#dataList + 1] = ZO_ScrollList_CreateDataEntry(ROW_TYPE_ID, rowData, 1)
				end
			end
		end
		local itemStyle = addon.styleList.selectedStyle and addon.styleList.selectedStyle.itemStyle or 0
		for _, itemId in ipairs(setInfo.items) do ItemFilter(createLink("|H1:item:%i:%i:%i:0:0:0:0:0:0:0:0:0:0:0:0:%i:0:0:0:10000:0|h|h", itemId, subId, level, itemStyle)) end
	end

	function addon:InitModeBar()
		self.modeBar = SetManagerTopLevel:GetNamedChild("ModeMenuBar")
		self.modeBarLabel = self.modeBar:GetNamedChild("Label")

		local function CreateButtonData(name, mode, normal, pressed, highlight, disabled, filterFunc)
			return {
				activeTabText = name,
				categoryName = name,

				descriptor = mode,
				normal = normal,
				pressed = pressed,
				highlight = highlight,
				disabled = disabled,
				callback = function(tabData)
					self.modeBarLabel:SetText(GetString(name))
					self.ApplyFilter = filterFunc
					self.mode = mode
					self.player.mode = mode
					if mode == "CRAFTING" then
						ZO_ScrollList_HideCategory(self.SetsList, self.setCategory.NonCraftable)
					else
						ZO_ScrollList_ShowCategory(self.SetsList, self.setCategory.NonCraftable)
					end
					self:UpdateItemList()
				end,
			}
		end

		ZO_MenuBar_AddButton(self.modeBar, CreateButtonData(
		SI_INVENTORY_MENU_INVENTORY,
		"INVENTORY",
		"/esoui/art/inventory/inventory_tabicon_items_up.dds",
		"/esoui/art/inventory/inventory_tabicon_items_down.dds",
		"/esoui/art/inventory/inventory_tabicon_items_over.dds",
		"/esoui/art/inventory/inventory_tabicon_items_disabled.dds",
		FilterByInventory
		))

		ZO_MenuBar_AddButton(self.modeBar, CreateButtonData(
		SI_SMITHING_TAB_CREATION,
		"CRAFTING",
		"/esoui/art/crafting/smithing_tabicon_creation_up.dds",
		"/esoui/art/crafting/smithing_tabicon_creation_down.dds",
		"/esoui/art/crafting/smithing_tabicon_creation_over.dds",
		"/esoui/art/crafting/smithing_tabicon_creation_disabled.dds",
		FilterByCraftableSet
		))

		ZO_MenuBar_AddButton(self.modeBar, CreateButtonData(
		SI_TRADING_HOUSE_BUY_ITEM,
		"BUY",
		"/esoui/art/vendor/vendor_tabicon_buy_up.dds",
		"/esoui/art/vendor/vendor_tabicon_buy_down.dds",
		"/esoui/art/vendor/vendor_tabicon_buy_over.dds",
		"/esoui/art/vendor/vendor_tabicon_buy_disabled.dds",
		FilterBySet
		))
	end
end

do
	local barData =
	{
		initialButtonAnchorPoint = LEFT,
		buttonTemplate = "ZO_MenuBarTooltipButton",
		normalSize = 32,
		downSize = 48,
		buttonPadding = 0,
		animationDuration = DEFAULT_SCENE_TRANSITION_TIME,
	}

	function addon:InitQualityBar()
		self.qualityBar = SetManagerTopLevelQuality
		self.qualityBarLabel = self.qualityBar:GetNamedChild("Label")

		ZO_MenuBar_OnInitialized(self.qualityBar)

		local function CreateButtonData(name, quality)
			return {
				activeTabText = name,
				categoryName = name,

				descriptor = quality,
				normal = "/esoui/art/buttons/gamepad/gp_checkbox_up.dds",
				pressed = "/esoui/art/buttons/gamepad/gp_checkbox_downover.dds",
				highlight = "/esoui/art/buttons/gamepad/gp_checkbox_upover.dds",
				disabled = "/esoui/art/buttons/gamepad/gp_checkbox_disabled.dds",
				callback = function(tabData)
					self.qualityBarLabel:SetText(GetString(name))
					if self.quality then
						self.player.quality = quality
						self:UpdateItemList()
					end
				end,
			}
		end
		local function AddButton(data)
			local button = ZO_MenuBar_AddButton(self.qualityBar, data)
			button:GetNamedChild("Image"):SetColor(GetItemQualityColor(data.descriptor):UnpackRGB())
		end

		ZO_MenuBar_SetData(self.qualityBar, barData)

		AddButton(CreateButtonData(SI_ITEMQUALITY2, ITEM_QUALITY_MAGIC))
		AddButton(CreateButtonData(SI_ITEMQUALITY3, ITEM_QUALITY_ARCANE))
		AddButton(CreateButtonData(SI_ITEMQUALITY4, ITEM_QUALITY_ARTIFACT))
		AddButton(CreateButtonData(SI_ITEMQUALITY5, ITEM_QUALITY_LEGENDARY))
	end
end

do
	local initialized
	function addon:InitWindow()
		if initialized then return end
		initialized = true

		self:InitModeBar()
		self:InitSetTemplateList()
		self:InitItemList()
		self:InitSetsList()
		self:InitializeStyleList()
		self:InitQualityBar()
	end
end

do
	local function InitKeybindStripDescriptor()
		local self = addon

		self.keybindStripDescriptor =
		{
			alignment = KEYBIND_STRIP_ALIGN_CENTER,

			{
				name = GetString(SI_BINDING_NAME_SET_MANAGER_ADD_SET),
				keybind = "UI_SHORTCUT_TERTIARY",

				callback = function()
					local templates = self.account.templates
					local template = { }
					templates[#templates + 1] = template

					self.scrollListSet:AddEntry(template)
					self.scrollListSet:Commit()
					self.scrollListSet:SetSelectedDataIndex(#templates)
					KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
				end,

				visible = function()
					return true
				end
			},
			{
				name = GetString(SI_BINDING_NAME_SET_MANAGER_DElETE_SET),
				keybind = "UI_SHORTCUT_NEGATIVE",

				callback = function()
					-- Don't ask me, this is what you get.
					local index = 1 - self.scrollListSet:GetSelectedIndex()
					if index > 0 then
						local templates = self.account.templates
						table.remove(templates, index)
						table.remove(self.scrollListSet.list, index)
						self.scrollListSet:Commit()
						KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
					end
				end,

				visible = function()
					return true
				end,

				enabled = function()
					return #self.account.templates > 1
				end
			},
		}
		self.keybindStripDescriptorMouseOver =
		{
			alignment = KEYBIND_STRIP_ALIGN_RIGHT,

			{
				name = function() return self.ItemList.hovered and "Apply" or "Remove" end,
				keybind = "UI_SHORTCUT_PRIMARY",

				callback = function()
					local selectedSet = self.scrollListSet:GetSelectedData()
					if not selectedSet then return end
					if self.ItemList.hovered then
						local selectedSlot = self.selectedSlot
						local hoveredItem = self.ItemList.hovered
						if not hoveredItem or not selectedSlot then return end

						selectedSet[selectedSlot] = hoveredItem.itemLink

						local soundCategory = GetItemSoundCategoryFromLink(hoveredItem.itemLink)
						PlayItemSound(soundCategory, ITEM_SOUND_ACTION_EQUIP)
					elseif self.scrollListSet.hoveredSlot then
						local soundCategory = GetItemSoundCategoryFromLink(selectedSet[self.scrollListSet.hoveredSlot])
						selectedSet[self.scrollListSet.hoveredSlot] = nil
						PlayItemSound(soundCategory, ITEM_SOUND_ACTION_UNEQUIP)
					end
					self.scrollListSet:RefreshVisible()
				end,

				visible = function()
					return(self.selectedSlot and self.ItemList.hovered) or(self.scrollListSet.hoveredSlot)
				end,
			},
		}
	end

	function addon:InitSetManager()
		InitKeybindStripDescriptor()

		local control = SetManagerTopLevel
		control:SetHidden(true)
		self.windowSet = control

		SETMANAGER_CHARACTER_FRAGMENT = ZO_FadeSceneFragment:New(self.windowSet, false, 0)

		local descriptor = self.name
		local sceneName = self.name
		SETMANAGER_SCENE = ZO_Scene:New(sceneName, SCENE_MANAGER)

		SETMANAGER_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
		SETMANAGER_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
		SETMANAGER_SCENE:AddFragment(THIN_LEFT_PANEL_BG_FRAGMENT)
		SETMANAGER_SCENE:AddFragment(CHARACTER_WINDOW_FRAGMENT)
		SETMANAGER_SCENE:AddFragment(SETMANAGER_CHARACTER_FRAGMENT)
		SETMANAGER_SCENE:AddFragment(WIDE_RIGHT_BG_FRAGMENT)
		SETMANAGER_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_JOURNAL)
		SETMANAGER_SCENE:AddFragment(CHARACTER_WINDOW_SOUNDS)

		SCENE_MANAGER:AddSceneGroup("SetManagerSceneGroup", ZO_SceneGroup:New(descriptor))

		SLASH_COMMANDS["/setm"] = function(...) addon:cmdSetManager(...) end

		local LMM2 = LibStub("LibMainMenu-2.0")
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

		SETMANAGER_CHARACTER_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
			if newState == SCENE_FRAGMENT_SHOWING then
				addon:InitWindow()
				ZO_Character_SetIsShowingReadOnlyFragment(true)
				if self.SetsList.dirty then
					self:UpdateSetsList()
				end

				if self.scrollListSet.dirty then
					self:UpdateTemplateList()
				end
			elseif newState == SCENE_FRAGMENT_SHOWN then
				PushActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_SET_MANAGER))
				KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
				KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptorMouseOver)

				ZO_MenuBar_SelectDescriptor(self.qualityBar, self.player.quality)
				ZO_MenuBar_SelectDescriptor(self.modeBar, self.player.mode)

				self:UpdateStyleList()
			elseif newState == SCENE_FRAGMENT_HIDING then
				ClearTooltip(ItemTooltip)
				KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptorMouseOver)
				KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
				RemoveActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_SET_MANAGER))
			elseif newState == SCENE_FRAGMENT_HIDDEN then
				collectgarbage()
			end
		end )
	end
end

local function PlayerActivated()
	em:UnregisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED)
	-- reserved
end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then return end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	addon.player = ZO_SavedVars:New("SetManager_Data", 1, nil, addon.playerDefaults, nil)
	addon.account = ZO_SavedVars:NewAccountWide("SetManager_Data", 1, nil, addon.accountDefaults, nil)

	local templates = addon.account.templates
	if #templates == 0 then
		templates[#templates + 1] = { }
	end

	addon:InitSetManager()
	addon:InitInventoryScan()

	em:RegisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED, PlayerActivated)
end

function addon:ToggleEditorScene()
	self.LMM2:SelectMenuItem(self.name)
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

SET_MANAGER = addon