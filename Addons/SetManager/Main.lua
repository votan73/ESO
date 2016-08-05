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

do
	local function OnSlotClicked(parent, control)
		for equipSlot, other in pairs(parent.slots) do
			local selected = other == control
			if other:GetState() ~= BSTATE_DISABLED then
				other:SetState(selected and BSTATE_PRESSED or BSTATE_NORMAL)
			end
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

		parent.OnSlotClicked = OnSlotClicked
		local ZO_Character_GetEmptyEquipSlotTexture = ZO_Character_GetEmptyEquipSlotTexture
		for slotId, slotControl in pairs(slots) do
			slotControl.slotId = slotId
			slotControl.Update = UpdateSlot
			slotControl:SetHandler("OnClicked", function(control, ...) control:GetParent():OnSlotClicked(control, ...) end)
		end
	end
end

do
	local rs, gs, bs = ZO_SELECTED_TEXT:UnpackRGB()
	local rn, gn, bn = ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB()
	local rd, gd, bd = ZO_DISABLED_TEXT:UnpackRGB()

	local statValuePairPool = ZO_ControlPool:New("ZO_TooltipStatValuePair", GuiRoot, "SetManagerStatValuePair")
	statValuePairPool:SetCustomFactoryBehavior( function(self)
		self.statLabel = self:GetNamedChild("Stat")
		self.valueLabel = self:GetNamedChild("Value")
		self.statLabel:SetFont("ZoFontWinT2")
		self.valueLabel:SetFont("ZoFontHeader3")
		self.statLabel:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)

		self.statLabel:SetColor(rn, gn, bn)
		self.valueLabel:SetColor(rs, gs, bs)
		self.valueLabel:SetAnchor(BOTTOMLEFT, self.statLabel, BOTTOMRIGHT, 4, 2)
	end )

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

	local function AddSection(tooltip, title, description)
		tooltip:AddLine(title, "ZoFontWinT2", rs, gs, bs, CENTER, MODIFY_TEXT_TYPE_UPPERCASE, TEXT_ALIGN_CENTER, true)
		tooltip:AddVerticalPadding(-5)
		tooltip:AddLine(description, "ZoFontGame", rn, gn, bn, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
		tooltip:AddVerticalPadding(5)
	end

	local lines = { }
	function addon:FakeEquippedItemTooltip(itemLink, setTemplate, equipped)
		-- SetLink uses original functions only. They protected it.
		-- Rewrite Tooltip???
		-- ItemTooltip:SetLink(itemLink, true)
		local tooltip = ItemTooltip

		local function AddItemTitle(itemLink)
			local name = GetItemLinkName(itemLink)
			local quality = GetItemLinkQuality(itemLink)
			local qualityColor = GetItemQualityColor(quality)
			AddLineTitle(tooltip, zo_strformat(SI_TOOLTIP_ITEM_NAME, name), qualityColor)
			tooltip:AddVerticalPadding(-12)
			ZO_Tooltip_AddDivider(tooltip)
		end

		local function SetStatValue(tooltip, text, value)
			local statValuePair = statValuePairPool:AcquireObject()
			statValuePair.statLabel:SetWidth(0)
			statValuePair.statLabel:SetText(text)
			statValuePair.statLabel:SetDimensions(statValuePair.statLabel:GetTextDimensions(text))
			statValuePair.valueLabel:SetWidth(0)
			statValuePair.valueLabel:SetText(value)
			statValuePair.valueLabel:SetDimensions(statValuePair.valueLabel:GetTextDimensions(text))
			statValuePair:SetParent(tooltip)
			local width = statValuePair.statLabel:GetWidth() + statValuePair.valueLabel:GetWidth()
			statValuePair:SetDimensions(width, statValuePair.valueLabel:GetHeight())
			statValuePair:ClearAnchors()
			tooltip:AddControl(statValuePair)
			return statValuePair
		end

		local function AddTopSection(itemLink)
			ZO_ClearNumericallyIndexedTable(lines)
			local itemType = GetItemLinkItemType(itemLink)
			local equipType = GetItemLinkEquipType(itemLink)
			if itemType ~= ITEMTYPE_NONE and equipType ~= EQUIP_TYPE_INVALID then
				local weaponType = GetItemLinkWeaponType(itemLink)
				if itemType == ITEMTYPE_ARMOR and weaponType == WEAPONTYPE_NONE then
					local armorType = GetItemLinkArmorType(itemLink)
					if armorType ~= ARMORTYPE_NONE then
						lines[#lines + 1] = zo_strformat(SI_ITEM_FORMAT_STR_TEXT1_ARMOR2, GetString("SI_EQUIPTYPE", equipType), GetString("SI_ARMORTYPE", armorType))
					else
						lines[#lines + 1] = zo_strformat(SI_ITEM_FORMAT_STR_BROAD_TYPE, GetString("SI_EQUIPTYPE", equipType))
					end
				elseif weaponType ~= WEAPONTYPE_NONE then
					lines[#lines + 1] = zo_strformat(SI_ITEM_FORMAT_STR_TEXT1_TEXT2, GetString("SI_WEAPONTYPE", weaponType), GetString("SI_EQUIPTYPE", equipType))
				end
			end
			tooltip:AddHeaderLine(table.concat(lines, " "), "ZoFontWinT2", 1, TOOLTIP_HEADER_SIDE_LEFT, rn, gn, bn)

			ZO_ClearNumericallyIndexedTable(lines)

			tooltip:AddHeaderLine(zo_strformat("<<1>>", GetString("SI_ITEMSTYLE", GetItemLinkItemStyle(itemLink))), "ZoFontWinT2", 2, TOOLTIP_HEADER_SIDE_LEFT, rn, gn, bn)

			-- Item counts
			local bagCount, bankCount, craftBagCount = GetItemLinkStacks(itemLink)

			if bagCount > 0 then
				lines[#lines + 1] = bagCount
				lines[#lines + 1] = zo_iconFormat("EsoUI/Art/Tooltips/icon_bag.dds", 20, 20)
			end

			if bankCount > 0 then
				lines[#lines + 1] = bankCount
				lines[#lines + 1] = zo_iconFormat("EsoUI/Art/Tooltips/icon_bank.dds", 20, 20)
			end

			-- 		if craftBagCount > 0 then
			-- 			lines[#lines + 1] = zo_iconTextFormat("EsoUI/Art/Tooltips/icon_craft_bag.dds", 24, 24, craftBagCount)
			-- 		end

			tooltip:AddHeaderLine(table.concat(lines, " "), "ZoFontWinT2", 1, TOOLTIP_HEADER_SIDE_RIGHT)
			ZO_ClearNumericallyIndexedTable(lines)
		end
		local function AddBaseStats(itemLink)
			tooltip:AddVerticalPadding(-5)

			local weaponPower = GetItemLinkWeaponPower(itemLink)
			local hasValue = false
			if weaponPower > 0 then
				SetStatValue(tooltip, GetString(SI_ITEM_FORMAT_STR_DAMAGE), weaponPower):SetAnchor(LEFT, nil, CENTER, -150, 0)
				hasValue = true
			else
				local CONSIDER_CONDITION = true
				local armorRating = GetItemLinkArmorRating(itemLink, not CONSIDER_CONDITION)
				if armorRating > 0 then
					local effectiveArmorRating = GetItemLinkArmorRating(itemLink, CONSIDER_CONDITION)
					local valueText
					if effectiveArmorRating == armorRating then
						valueText = effectiveArmorRating
					else
						valueText = zo_strformat(SI_ITEM_FORMAT_STR_EFFECTIVE_VALUE_OF_MAX, effectiveArmorRating, armorRating)
					end

					SetStatValue(tooltip, GetString(SI_ITEM_FORMAT_STR_ARMOR), valueText):SetAnchor(LEFT, nil, CENTER, -150, 0)
					hasValue = true
				end
			end

			-- Required Level/Champ Rank
			local requiredLevel = GetItemLinkRequiredLevel(itemLink)
			local requiredChampionPoints = GetItemLinkRequiredChampionPoints(itemLink)
			if requiredLevel > 0 or requiredChampionPoints > 0 then
				if requiredLevel > 0 then
					if hasValue then
						tooltip:AddVerticalPadding(-51)
						SetStatValue(tooltip, GetString(SI_ITEM_FORMAT_STR_LEVEL), requiredLevel):SetAnchor(CENTER)
					else
						SetStatValue(tooltip, GetString(SI_ITEM_FORMAT_STR_LEVEL), requiredLevel):SetAnchor(LEFT, nil, CENTER, -100, 0)
					end
				end
				if requiredChampionPoints > 0 then
					if requiredLevel > 0 then tooltip:AddVerticalPadding(-51) end
					if hasValue then
						SetStatValue(tooltip, zo_iconTextFormatNoSpace(GetGamepadChampionPointsIcon(), 32, 32, GetString(SI_ITEM_FORMAT_STR_CHAMPION)), requiredChampionPoints):SetAnchor(LEFT, nil, CENTER, 170, 0)
					else
						SetStatValue(tooltip, zo_iconTextFormatNoSpace(GetGamepadChampionPointsIcon(), 32, 32, GetString(SI_ITEM_FORMAT_STR_CHAMPION)), requiredChampionPoints):SetAnchor(LEFT, nil, CENTER, 120, 0)
					end
				end
			end
		end
		local function AddEnchant(itemLink)
			local hasEnchant, enchantHeader, enchantDescription = GetItemLinkEnchantInfo(itemLink)
			if hasEnchant then
				AddSection(tooltip, enchantHeader, enchantDescription)
			end
		end
		local function AddTrait(itemLink)
			local traitType, traitDescription, traitSubtype, traitSubtypeName, traitSubtypeDescription = GetItemLinkTraitInfo(itemLink)
			if (traitType ~= ITEM_TRAIT_TYPE_NONE and traitType ~= ITEM_TRAIT_TYPE_SPECIAL_STAT and traitDescription ~= "") then
				local traitName = GetString("SI_ITEMTRAITTYPE", traitType)
				if traitName ~= "" then
					AddSection(tooltip, zo_strformat(SI_ITEM_FORMAT_STR_ITEM_TRAIT_HEADER, traitName), zo_strformat(SI_ITEM_FORMAT_STR_ITEM_TRAIT_DESCRIPTION, traitDescription))
				end
			end
			if traitSubtype ~= 0 and traitSubtypeName ~= "" then
				AddSection(tooltip, zo_strformat(SI_ITEM_FORMAT_STR_ITEM_TRAIT_HEADER, traitSubtypeName), zo_strformat(SI_ITEM_FORMAT_STR_ITEM_TRAIT_DESCRIPTION, traitSubtypeDescription))
			end
		end
		local function AddSet(itemLink)
			local GetItemLinkSetInfo = GetItemLinkSetInfo
			local hasSet, setName, numBonuses, _, maxEquipped = GetItemLinkSetInfo(itemLink)
			local numEquipped = 0
			for slotId = EQUIP_SLOT_HEAD, EQUIP_SLOT_MAX_VALUE do
				local otherLink = setTemplate[slotId]
				if otherLink then
					local _, otherSetName = GetItemLinkSetInfo(otherLink)
					if otherSetName == setName then numEquipped = numEquipped + 1 end
				end
			end

			if hasSet then
				tooltip:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_SET_NAME, setName, numEquipped, maxEquipped), "ZoFontWinT2", rs, gs, bs, CENTER, MODIFY_TEXT_TYPE_UPPERCASE, TEXT_ALIGN_CENTER, true)
				for i = 1, numBonuses do
					local numRequired, bonusDescription = GetItemLinkSetBonusInfo(itemLink, equipped, i)
					if numEquipped >= numRequired then
						tooltip:AddLine(bonusDescription, "ZoFontGame", rn, gn, bn, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
					else
						tooltip:AddLine(bonusDescription, "ZoFontGame", rd, gd, bd, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
					end
				end
			end
		end

		tooltip:ClearLines()
		statValuePairPool:ReleaseAllObjects()
		tooltip:SetHeaderRowSpacing(0)
		tooltip:SetHeaderVerticalOffset(10)
		local iconTexture = GetItemLinkInfo(itemLink)
		ZO_ItemIconTooltip_OnAddGameData(tooltip, TOOLTIP_GAME_DATA_ITEM_ICON, iconTexture)
		-- tooltip:AddVerticalPadding(24)

		AddTopSection(itemLink)
		AddItemTitle(itemLink)
		AddBaseStats(itemLink)
		-- if (DoesItemLinkHaveEnchantCharges(itemLink)) then
		-- 	self:AddEnchantChargeBar(itemLink, forceFullDurability, previewValueToAdd)
		-- end

		AddEnchant(itemLink)
		AddTrait(itemLink)
		AddSet(itemLink)

		ZO_ItemTooltip_SetStolen(tooltip, false)
	end
	function addon:ClearFakeEquippedItemTooltip()
		ClearTooltip(ItemTooltip)
		statValuePairPool:ReleaseAllObjects()
	end
end

function addon:Init()
	SLASH_COMMANDS["/setm"] = function(...) addon:cmdSetManager(...) end

	local LMM2 = LibStub("LibMainMenu-2.0")
	LMM2:Init()
	self.LMM2 = LMM2

	self.Designer:Init()
	self.Selector:Init()

	self:InitInventoryScan()
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
	addon.account.all = nil

	local templates = addon.account.templates
	if #templates == 0 then
		templates[#templates + 1] = { }
	end

	addon:Init()

	em:RegisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED, PlayerActivated)
end

function addon:ToggleEditorScene()
	self.LMM2:SelectMenuItem(self.name)
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

SET_MANAGER = addon