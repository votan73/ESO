local addon = SET_MANAGER
addon.Selector = {
	allowedInteractions =
	{
		[CRAFTING_TYPE_BLACKSMITHING] = true,
		[CRAFTING_TYPE_CLOTHIER] = true,
		[CRAFTING_TYPE_WOODWORKING] = true,
	},
}
local selector = SET_MANAGER.Selector

local wm = GetWindowManager()
local em = GetEventManager()

function selector:UpdateSetTemplates()
	local templates = addon.account.templates
	self.setTemplates:Clear()
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
				listControl:SetSelectedIndex(index, true, true)
				return true
			end
			return false
		end
		local function OnSelectedSlotChanged(control)
			self.selectedSlot = control.selectedSlot
			local GetItemLinkName, GetSmithingPatternResultLink = GetItemLinkName, GetSmithingPatternResultLink
			local itemLink = control.data[control.selectedSlot]
			local armorType = GetItemLinkArmorType(itemLink)
			local weaponType = GetItemLinkWeaponType(itemLink)
			local itemStyle = GetItemLinkItemStyle(itemLink)
			local itemTrait = GetItemLinkTraitInfo(itemLink)
			local requiredRank, requiredLevel, requiredCP = GetItemLinkSmithingRequiredRankAndLevels(itemLink)
			local itemName = GetItemLinkName(itemLink)


			local craftingType = armorType > 0 and armorType or weaponType

			SMITHING.modeBar.m_object:SelectDescriptor(2)
			local creation = SMITHING.creationPanel
			creation.tabs.m_object:SelectDescriptor(armorType > 0 and 4 or 3)
			SetIndex(creation.patternList, function(_, newData) return itemName == GetItemLinkName(GetSmithingPatternResultLink(newData.patternIndex, 1, 7, 1, 1)) end)
			SetIndex(creation.materialList, function(_, newData) return newData.rankRequirement == requiredRank end)
			SetIndex(creation.styleList, function(_, newData) return newData.itemStyle == itemStyle end)
			SetIndex(creation.traitList, function(_, newData) return newData.traitType == itemTrait end)

			local patternIndex = creation.patternList:GetSelectedData().patternIndex
			local materialIndex = creation.materialList:GetSelectedData().materialIndex

			local GetItemLinkRequiredLevel, GetItemLinkRequiredChampionPoints = GetItemLinkRequiredLevel, GetItemLinkRequiredChampionPoints
			local GetSmithingPatternNextMaterialQuantity = GetSmithingPatternNextMaterialQuantity

			local quantity = 1
			local itemLink
			repeat
				quantity = GetSmithingPatternNextMaterialQuantity(patternIndex, materialIndex, quantity, 1, 1)
				itemLink = GetSmithingPatternResultLink(patternIndex, materialIndex, quantity, 1, 1)
			until requiredLevel == GetItemLinkRequiredLevel(itemLink) and requiredCP == GetItemLinkRequiredChampionPoints(itemLink)
			creation.materialQuantitySpinner:ModifyValue(quantity)

			PlaySound(SOUNDS.DEFAULT_CLICK)
		end
		local function OnTemplateChanged(self)
			local rowData = self.data
			rowData.name = self.templateName
		end

		local function onMouseEnter(rowControl)
			if rowControl.itemLink then
				InitializeTooltip(ItemTooltip, rowControl, TOPRIGHT, 0, -104, TOPLEFT)
				addon:FakeEquippedItemTooltip(rowControl.itemLink)
				self.setTemplates.hoveredSlot = rowControl.slotId
				-- KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptorMouseOver)
			end
		end
		local function onMouseExit(rowControl)
			ClearTooltip(ItemTooltip, rowControl)
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
			edit:SetColor(0.5, 0.5, 0.5)

			local weaponsAllowed = CanSmithingWeaponPatternsBeCraftedHere()
			local apparelAllowed = CanSmithingApparelPatternsBeCraftedHere()

			-- 		local setsAllowed = CanSmithingSetPatternsBeCraftedHere()

			for slotId, slotControl in pairs(control.slots) do
				slotControl.itemLink = data[slotId]
				slotControl:Update()
				slotControl:SetHandler("OnMouseEnter", onMouseEnter)
				slotControl:SetHandler("OnMouseExit", onMouseExit)
				local enabled = slotControl.itemLink ~= nil
				if enabled then
					if GetItemLinkArmorType(slotControl.itemLink) == 0 then
						enabled = weaponsAllowed
					else
						enabled = apparelAllowed
					end
				end
				if enabled then
					enabled = CanSetBeCraftedHere(slotControl.itemLink)
				end
				if not enabled and slotControl.itemLink then
					slotControl:GetNamedChild("Icon"):SetColor(1, 0, 0)
				else
					slotControl:GetNamedChild("Icon"):SetColor(1, 1, 1)
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
	if self.setNameToData then return end

	local setNameToData = { }
	self.setNameToData = setNameToData
	local createLink = string.format
	local GetItemLinkSetInfo = GetItemLinkSetInfo

	local sets = addon.allSets
	for itemId, setInfo in pairs(sets) do
		local itemLink = createLink("|H1:item:%i:304:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", itemId)
		local _, name = GetItemLinkSetInfo(itemLink, false)
		setNameToData[name] = setInfo
	end
end

function selector:Init()
	self.window = SetManagerTopLevelSelector
	SETMANAGER_SELECTOR_FRAGMENT = ZO_HUDFadeSceneFragment:New(self.window)
	SMITHING_SCENE:AddFragment(SETMANAGER_SELECTOR_FRAGMENT)

	SETMANAGER_SELECTOR_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
		if newState == SCENE_FRAGMENT_SHOWING then
			self.interactionType = GetCraftingInteractionType()
			local allowed = self.allowedInteractions[self.interactionType]
			self.window:SetMouseEnabled(allowed)

			if allowed and CanSmithingSetPatternsBeCraftedHere() then
				self:CreateSetNameToData()
				local name
				allowed, name = GetItemLinkSetInfo(GetSmithingPatternResultLink(GetNumSmithingPatterns() / 2 + 1, 1, 7, 1, 1))
				if allowed then
					self.currentSetName = name
					self:UpdateSetTemplates()
				else
					self.currentSetName = nil
				end
			end
		elseif newState == SCENE_FRAGMENT_SHOWN then
		elseif newState == SCENE_FRAGMENT_HIDING then
		elseif newState == SCENE_FRAGMENT_HIDDEN then
			collectgarbage()
		end
	end )

	self:InitSetTemplates()
end