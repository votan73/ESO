local addon = SET_MANAGER
addon.Selector = {
	allowedInteractions = {
		[CRAFTING_TYPE_BLACKSMITHING] = true,
		[CRAFTING_TYPE_CLOTHIER] = true,
		[CRAFTING_TYPE_WOODWORKING] = true,
		[CRAFTING_TYPE_JEWELRYCRAFTING] = true
	},
	allowedArmorType = {
		[CRAFTING_TYPE_BLACKSMITHING] = {[ARMORTYPE_HEAVY] = true},
		[CRAFTING_TYPE_CLOTHIER] = {[ARMORTYPE_LIGHT] = true, [ARMORTYPE_MEDIUM] = true},
		[CRAFTING_TYPE_WOODWORKING] = {}
	},
	allowedWeaponType = {
		[CRAFTING_TYPE_BLACKSMITHING] = {
			[WEAPONTYPE_AXE] = true,
			[WEAPONTYPE_DAGGER] = true,
			[WEAPONTYPE_HAMMER] = true,
			[WEAPONTYPE_SWORD] = true,
			[WEAPONTYPE_TWO_HANDED_AXE] = true,
			[WEAPONTYPE_TWO_HANDED_HAMMER] = true,
			[WEAPONTYPE_TWO_HANDED_SWORD] = true
		},
		[CRAFTING_TYPE_CLOTHIER] = {},
		[CRAFTING_TYPE_WOODWORKING] = {[WEAPONTYPE_BOW] = true, [WEAPONTYPE_FIRE_STAFF] = true, [WEAPONTYPE_FROST_STAFF] = true, [WEAPONTYPE_HEALING_STAFF] = true, [WEAPONTYPE_LIGHTNING_STAFF] = true, [WEAPONTYPE_SHIELD] = true}
	}
}
local selector = SET_MANAGER.Selector

local wm = GetWindowManager()
local em = GetEventManager()

local function CanBeCraftedHere(weaponType, armorType)
	if weaponType > 0 then
		return CanSmithingWeaponPatternsBeCraftedHere()
	elseif armorType > 0 then
		return CanSmithingApparelPatternsBeCraftedHere()
	else
		return CanSmithingJewelryPatternsBeCraftedHere()
	end
end
function selector:UpdateSetTemplates()
	local templates = self.templates
	self.setTemplates:Clear()
	if CanSmithingSetPatternsBeCraftedHere() then
		local equipType, weaponType, armorType, set
		local backpackSlots = SHARED_INVENTORY:GetOrCreateBagCache(BAG_BACKPACK)
		for _, data in pairs(backpackSlots) do
			if data.itemType == ITEMTYPE_MASTER_WRIT then
				local itemLink = GetItemLink(data.bagId, data.slotIndex)
				itemLink, equipType, weaponType, armorType, set = addon:GetWritInfo(itemLink)
				if itemLink and CanBeCraftedHere(weaponType, armorType) then
					self.setTemplates:AddEntry({[ZO_Character_GetEquipSlotForEquipType(equipType) or EQUIP_SLOT_OFF_HAND] = itemLink, ["name"] = ZO_CachedStrFormat(SI_ANTIQUITY_SET_NAME_FORMATTER, set.name)})
				end
			end
		end
	end
	for _, template in ipairs(templates) do
		self.setTemplates:AddEntry(template)
	end
	self.setTemplates:Commit()
	self.setTemplates.dirty = false
end

local function GetItemLinkSmithingRequiredRankAndLevels(itemLink)
	local requiredLevel, requiredCP = GetItemLinkRequiredLevel(itemLink), GetItemLinkRequiredChampionPoints(itemLink)
	local requiredRank
	if requiredLevel <= 14 then
		requiredRank = 1
	elseif requiredLevel <= 24 then
		requiredRank = 2
	elseif requiredLevel <= 34 then
		requiredRank = 3
	elseif requiredLevel <= 44 then
		requiredRank = 4
	elseif requiredLevel <= 50 and requiredCP < 10 then
		requiredRank = 5
	elseif requiredCP <= 30 then
		requiredRank = 6
	elseif requiredCP <= 60 then
		requiredRank = 7
	elseif requiredCP <= 80 then
		requiredRank = 8
	elseif requiredCP <= 140 then
		requiredRank = 9
	else
		requiredRank = 10
	end
	return requiredRank, requiredLevel, requiredCP
end

function selector:InitSetTemplates()
	local function InitSetTemplates(scrollListControl, listContainer, listSlotTemplate)
		local function SetIndex(listControl, matchFunc)
			local index = listControl:FindIndexFromData(0, matchFunc)
			if index then
				listControl:SetSelectedIndex(index, true, true, false, true)
				return true
			end
			return false
		end
		local function SetMaterialQuantity(creation, requiredLevel, requiredCP)
			local data = creation.materialList:GetSelectedData()
			local value = data.isChampionPoint and requiredCP or requiredLevel
			for index, item in ipairs(data.combinations) do
				if item.createsItemOfLevel >= value then
					creation.materialQuantitySpinner:ModifyValue(index)
					return true
				end
			end
			return false
		end
		local function OnSelectedSlotChanged(control)
			self.selectedSlot = control.selectedSlot
			local GetItemLinkName, GetSmithingPatternResultLink = GetItemLinkName, GetSmithingPatternResultLink
			local itemLink = control.data[control.selectedSlot]
			local armorType = GetItemLinkArmorType(itemLink)
			local weaponType = GetItemLinkWeaponType(itemLink)
			local itemStyleId = GetItemLinkItemStyle(itemLink)
			local itemTrait = GetItemLinkTraitInfo(itemLink)
			local requiredRank, requiredLevel, requiredCP = GetItemLinkSmithingRequiredRankAndLevels(itemLink)
			local itemName = GetItemLinkName(itemLink)
			local creation = SMITHING.creationPanel
			local success

			ZO_MenuBar_SelectDescriptor(SMITHING.modeBar, SMITHING_MODE_CREATION, true)

			local descriptor
			if armorType > 0 or weaponType == WEAPONTYPE_SHIELD then
				descriptor = SMITHING_FILTER_TYPE_SET_ARMOR
			elseif armorType > 0 then
				descriptor = SMITHING_FILTER_TYPE_SET_WEAPONS
			else
				descriptor = SMITHING_FILTER_TYPE_SET_JEWELRY
			end
			ZO_MenuBar_SelectDescriptor(creation.tabs, descriptor, true)
			success =
				SetIndex(
				creation.patternList,
				function(_, newData)
					return itemName == GetItemLinkName(GetSmithingPatternResultLink(newData.patternIndex, 1, 7, 1, 1))
				end
			)
			if not success then
				local equipType = GetItemLinkEquipType(itemLink)
				if armorType > 0 then
					success =
						SetIndex(
						creation.patternList,
						function(_, newData)
							local otherLink = GetSmithingPatternResultLink(newData.patternIndex, 1, 7, 1, 1)
							return armorType == GetItemLinkArmorType(otherLink) and equipType == GetItemLinkEquipType(otherLink)
						end
					)
				elseif weaponType > 0 then
					success =
						SetIndex(
						creation.patternList,
						function(_, newData)
							local otherLink = GetSmithingPatternResultLink(newData.patternIndex, 1, 7, 1, 1)
							return weaponType == GetItemLinkWeaponType(otherLink) and equipType == GetItemLinkEquipType(otherLink)
						end
					)
				else
					requiredRank = 5
					success =
						SetIndex(
						creation.patternList,
						function(_, newData)
							local rankData = newData.materialData[1]
							local otherLink = GetSmithingPatternResultLink(newData.patternIndex, rankData.materialIndex, rankData.min, 1, 1)
							return equipType == GetItemLinkEquipType(otherLink)
						end
					)
				end
			end
			if
				SetIndex(
					creation.materialList,
					function(_, newData)
						return newData.rankRequirement == requiredRank
					end
				)
			 then
				success = true
			else
				success = false
			end
			if armorType > 0 or weaponType > 0 then
				success =
					SetIndex(
					creation.styleList,
					function(_, newData)
						return newData.itemStyleId == itemStyleId
					end
				) and success
			end
			success =
				SetIndex(
				creation.traitList,
				function(_, newData)
					return newData.traitType == itemTrait
				end
			) and success

			PlaySound(success and SOUNDS.DEFAULT_CLICK or SOUNDS.NEGATIVE_CLICK)
		end
		local function OnTemplateChanged(self)
			local rowData = self.data
			rowData.name = self.templateName
		end

		local function onMouseEnter(rowControl)
			if rowControl.itemLink then
				InitializeTooltip(SetItemTooltip, rowControl, TOPRIGHT, 0, -104, TOPLEFT)
				SetItemTooltip:SetTemplateItemLink(rowControl.itemLink, self.setTemplates:GetSelectedData(), false)
				self.setTemplates.hoveredSlot = rowControl.slotId
			-- KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptorMouseOver)
			end
		end
		local function onMouseExit(rowControl)
			ClearTooltip(SetItemTooltip)
			self.setTemplates.hoveredSlot = nil
			-- KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptorMouseOver)
		end
		local function CanSetBeCraftedHere(itemLink)
			local hasSet, name = GetItemLinkSetInfo(itemLink, false)
			return hasSet and name == self.currentSetName
		end
		local function SetupFunction(control, data, selected, selectedDuringRebuild, enabled)
			control.data = data
			control.OnSelectedChanged = OnSelectedSlotChanged
			control.OnTemplateChanged = OnTemplateChanged

			local edit = control:GetNamedChild("Name")
			edit:SetText(data.name)

			edit = control:GetNamedChild("AccessoriesSectionText")
			edit:SetColor(ZO_DEFAULT_DISABLED_COLOR:UnpackRGB())

			local weaponsAllowed = CanSmithingWeaponPatternsBeCraftedHere()
			local apparelAllowed = CanSmithingApparelPatternsBeCraftedHere()
			local jewelryAllowed = CanSmithingJewelryPatternsBeCraftedHere()

			-- 		local setsAllowed = CanSmithingSetPatternsBeCraftedHere()

			for slotId, slotControl in pairs(control.slots) do
				slotControl.itemLink = data[slotId]
				slotControl:Update()
				slotControl:SetHandler("OnMouseEnter", onMouseEnter)
				slotControl:SetHandler("OnMouseExit", onMouseExit)
				local enabled = slotControl.itemLink ~= nil
				if enabled then
					local itemType = GetItemLinkArmorType(slotControl.itemLink)
					if itemType == 0 then
						itemType = GetItemLinkWeaponType(slotControl.itemLink)
						if itemType == 0 then
							enabled = jewelryAllowed
						else
							enabled = weaponsAllowed and self.allowedWeaponType[self.interactionType][itemType]
						end
					else
						enabled = apparelAllowed and self.allowedArmorType[self.interactionType][itemType]
					end
				end
				if not enabled then
					slotControl:GetNamedChild("Icon"):SetColor(1, 0.1, 0.1)
				else
					if slotControl.itemLink == nil or CanSetBeCraftedHere(slotControl.itemLink) then
						slotControl:GetNamedChild("Icon"):SetColor(1, 1, 1)
					else
						slotControl:GetNamedChild("Icon"):SetColor(0.9, 0.9, 0.2)
						enabled = true
					end
				end
				slotControl:SetEnabled(enabled)
			end
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
	self.setTemplates = InitSetTemplates(ZO_HorizontalScrollList, SetManagerTopLevelSelectorSetTemplateList, "SetManager_Character_Template_Selector")
	self.setTemplates:SetScaleExtents(0.6, 1)
	self.setTemplates.dirty = true
end

function selector:CreateSetNameToData()
	if self.setNameToData then
		return
	end

	local setNameToData = {}
	self.setNameToData = setNameToData
	local createLink = string.format
	local GetItemLinkSetInfo = GetItemLinkSetInfo

	local sets = addon.allSets
	for itemId, setInfo in pairs(sets) do
		local itemLink = createLink("|H1:item:%i:304:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", itemId)
		local _, name = GetItemLinkSetInfo(itemLink, false)
		setInfo.name = name
		setNameToData[name] = setInfo
	end
end

function selector:Init()
	self.window = SetManagerTopLevelSelector
	SETMANAGER_SELECTOR_FRAGMENT = ZO_HUDFadeSceneFragment:New(self.window)
	SMITHING_SCENE:AddFragment(SETMANAGER_SELECTOR_FRAGMENT)

	SETMANAGER_SELECTOR_FRAGMENT:RegisterCallback(
		"StateChange",
		function(oldState, newState)
			if newState == SCENE_FRAGMENT_SHOWING then
				self.window:SetMouseEnabled(true)

				self.templates = addon.account.templates
				self:CreateSetNameToData()
			elseif newState == SCENE_FRAGMENT_SHOWN then
				-- elseif newState == SCENE_FRAGMENT_HIDING then
				--local allowed, name = GetItemLinkSetInfo(GetSmithingPatternResultLink(GetNumSmithingPatterns() / 2 + 1, 1, 7, 1, 1))
				local allowed, name = GetItemLinkSetInfo(GetSmithingPatternResultLink(SMITHING.creationPanel:GetResultCraftingParameters()))
				if allowed then
					self.currentSetName = name
					self:UpdateSetTemplates()
				else
					self.currentSetName = nil
				end
			elseif newState == SCENE_FRAGMENT_HIDDEN then
				collectgarbage()
			end
		end
	)

	self:InitSetTemplates()

	local orgSetHidden = SMITHING.creationPanel.SetHidden
	function SMITHING.creationPanel:SetHidden(hidden)
		SETMANAGER_SELECTOR_FRAGMENT:SetHiddenForReason("hidden", hidden)
		selector.interactionType = GetCraftingInteractionType()
		local allowed = selector.allowedInteractions[selector.interactionType] and CanSmithingSetPatternsBeCraftedHere() or false
		SETMANAGER_SELECTOR_FRAGMENT:SetHiddenForReason("wrongStation", not allowed)
		SETMANAGER_SELECTOR_FRAGMENT:Refresh()
		return orgSetHidden(self, hidden)
	end
end
