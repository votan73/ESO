local addon = SET_MANAGER

local rs, gs, bs = ZO_SELECTED_TEXT:UnpackRGB()
local rn, gn, bn = ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB()
local rd, gd, bd = ZO_DISABLED_TEXT:UnpackRGB()

SetItemTooltip = WINDOW_MANAGER:CreateControlFromVirtual("SetItemTooltip", ItemTooltipTopLevel, "ZO_ItemIconTooltip")
local SetItemTooltip = SetItemTooltip

local statValuePairPool = ZO_ControlPool:New("ZO_TooltipStatValuePair", SetItemTooltip, "SetManagerStatValuePair")
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

do
	local orgClearLines = SetItemTooltip.ClearLines
	function SetItemTooltip:ClearLines()
		statValuePairPool:ReleaseAllObjects()
		return orgClearLines(self)
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

local function AddSection(tooltip, title, description)
	tooltip:AddLine(title, "ZoFontWinT2", rs, gs, bs, CENTER, MODIFY_TEXT_TYPE_UPPERCASE, TEXT_ALIGN_CENTER, true)
	tooltip:AddVerticalPadding(-5)
	tooltip:AddLine(description, "ZoFontGame", rn, gn, bn, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
	tooltip:AddVerticalPadding(5)
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

local function AddLevelSections(self, requiredLevel, requiredChampionPoints, hasValue)
	if requiredLevel > 0 or requiredChampionPoints > 0 then
		if requiredLevel > 0 then
			if hasValue then
				self:AddVerticalPadding(-51)
				SetStatValue(self, GetString(SI_ITEM_FORMAT_STR_LEVEL), requiredLevel):SetAnchor(CENTER)
			else
				SetStatValue(self, GetString(SI_ITEM_FORMAT_STR_LEVEL), requiredLevel):SetAnchor(LEFT, nil, CENTER, -100, 0)
			end
		end
		if requiredChampionPoints > 0 then
			if requiredLevel > 0 then self:AddVerticalPadding(-51) end
			if hasValue then
				SetStatValue(self, zo_iconTextFormatNoSpace(GetGamepadChampionPointsIcon(), 32, 32, GetString(SI_ITEM_FORMAT_STR_CHAMPION)), requiredChampionPoints):SetAnchor(LEFT, nil, CENTER, 170, 0)
			else
				SetStatValue(self, zo_iconTextFormatNoSpace(GetGamepadChampionPointsIcon(), 32, 32, GetString(SI_ITEM_FORMAT_STR_CHAMPION)), requiredChampionPoints):SetAnchor(LEFT, nil, CENTER, 120, 0)
			end
		end
	end
end

local lines = { }
function SetItemTooltip:SetTemplateItemLink(itemLink, setTemplate, equipped)
	-- SetLink uses original functions only. They protected it.
	-- Rewrite Tooltip

	local function AddItemTitle(itemLink)
		local name = GetItemLinkName(itemLink)
		local quality = GetItemLinkQuality(itemLink)
		local qualityColor = GetItemQualityColor(quality)
		AddLineTitle(self, zo_strformat(SI_TOOLTIP_ITEM_NAME, name), qualityColor)
		self:AddVerticalPadding(-12)
		ZO_Tooltip_AddDivider(self)
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
		self:AddHeaderLine(table.concat(lines, " "), "ZoFontWinT2", 1, TOOLTIP_HEADER_SIDE_LEFT, rn, gn, bn)

		ZO_ClearNumericallyIndexedTable(lines)

		self:AddHeaderLine(zo_strformat("<<1>>", GetString("SI_ITEMSTYLE", GetItemLinkItemStyle(itemLink))), "ZoFontWinT2", 2, TOOLTIP_HEADER_SIDE_LEFT, rn, gn, bn)

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

		self:AddHeaderLine(table.concat(lines, " "), "ZoFontWinT2", 1, TOOLTIP_HEADER_SIDE_RIGHT)
		ZO_ClearNumericallyIndexedTable(lines)
	end
	local function AddBaseStats(itemLink)
		self:AddVerticalPadding(-5)

		local weaponPower = GetItemLinkWeaponPower(itemLink)
		local hasValue = false
		if weaponPower > 0 then
			SetStatValue(self, GetString(SI_ITEM_FORMAT_STR_DAMAGE), weaponPower):SetAnchor(LEFT, nil, CENTER, -150, 0)
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

				SetStatValue(self, GetString(SI_ITEM_FORMAT_STR_ARMOR), valueText):SetAnchor(LEFT, nil, CENTER, -150, 0)
				hasValue = true
			end
		end

		-- Required Level/Champ Rank
		local requiredLevel, requiredChampionPoints = GetItemLinkRequiredLevel(itemLink), GetItemLinkRequiredChampionPoints(itemLink)
		AddLevelSections(self, requiredLevel, requiredChampionPoints, hasValue)
	end
	local function AddEnchant(itemLink)
		local hasEnchant, enchantHeader, enchantDescription = GetItemLinkEnchantInfo(itemLink)
		if hasEnchant then
			AddSection(self, enchantHeader, enchantDescription)
		end
	end
	local function AddTrait(itemLink)
		local traitType, traitDescription, traitSubtype, traitSubtypeName, traitSubtypeDescription = GetItemLinkTraitInfo(itemLink)
		if (traitType ~= ITEM_TRAIT_TYPE_NONE and traitType ~= ITEM_TRAIT_TYPE_SPECIAL_STAT and traitDescription ~= "") then
			local traitName = GetString("SI_ITEMTRAITTYPE", traitType)
			if traitName ~= "" then
				AddSection(self, zo_strformat(SI_ITEM_FORMAT_STR_ITEM_TRAIT_HEADER, traitName), zo_strformat(SI_ITEM_FORMAT_STR_ITEM_TRAIT_DESCRIPTION, traitDescription))
			end
		end
		if traitSubtype ~= 0 and traitSubtypeName ~= "" then
			AddSection(self, zo_strformat(SI_ITEM_FORMAT_STR_ITEM_TRAIT_HEADER, traitSubtypeName), zo_strformat(SI_ITEM_FORMAT_STR_ITEM_TRAIT_DESCRIPTION, traitSubtypeDescription))
		end
	end
	local function GetNumEquipped(setName)
		local GetItemLinkSetInfo = GetItemLinkSetInfo
		local numEquipped = 0
		local weaponMainCounted, weaponOffHandCounted = false, false

		for slotId = EQUIP_SLOT_HEAD, EQUIP_SLOT_MAX_VALUE do
			local otherLink = setTemplate[slotId]
			if otherLink then
				local _, otherSetName = GetItemLinkSetInfo(otherLink)
				if otherSetName == setName then
					if slotId == EQUIP_SLOT_MAIN_HAND or slotId == EQUIP_SLOT_BACKUP_MAIN then
						if weaponMainCounted then
							-- compensate
							numEquipped = numEquipped - 1
						else
							weaponMainCounted = true
						end
					elseif slotId == EQUIP_SLOT_OFF_HAND or slotId == EQUIP_SLOT_BACKUP_OFF then
						if weaponOffHandCounted then
							-- compensate
							numEquipped = numEquipped - 1
						else
							weaponOffHandCounted = true
						end
					end
					numEquipped = numEquipped + 1
				end
			end
		end
		return numEquipped
	end

	local function AddSet(itemLink)
		local hasSet, setName, numBonuses, _, maxEquipped = GetItemLinkSetInfo(itemLink)
		local numEquipped = hasSet and GetNumEquipped(setName) or 0

		if hasSet then
			self:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_SET_NAME, setName, numEquipped, maxEquipped), "ZoFontWinT2", rs, gs, bs, CENTER, MODIFY_TEXT_TYPE_UPPERCASE, TEXT_ALIGN_CENTER, true)
			for i = 1, numBonuses do
				local numRequired, bonusDescription = GetItemLinkSetBonusInfo(itemLink, equipped, i)
				if numEquipped >= numRequired then
					self:AddLine(bonusDescription, "ZoFontGame", rn, gn, bn, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
				else
					self:AddLine(bonusDescription, "ZoFontGame", rd, gd, bd, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
				end
			end
		end
	end

	self:ClearLines()
	self:SetHeaderRowSpacing(0)
	self:SetHeaderVerticalOffset(10)
	local iconTexture = GetItemLinkInfo(itemLink)
	ZO_ItemIconTooltip_OnAddGameData(self, TOOLTIP_GAME_DATA_ITEM_ICON, iconTexture)

	AddTopSection(itemLink)
	AddItemTitle(itemLink)
	AddBaseStats(itemLink)
	AddEnchant(itemLink)
	AddTrait(itemLink)
	AddSet(itemLink)
end

function SetItemTooltip:SetSetLink(itemLink)
	self:ClearLines()

	local iconTexture = GetItemLinkInfo(itemLink)
	ZO_ItemIconTooltip_OnAddGameData(self, TOOLTIP_GAME_DATA_ITEM_ICON, iconTexture)
	self:AddVerticalPadding(24)

	local hasSet, setName, numBonuses, _, maxEquipped = GetItemLinkSetInfo(itemLink)
	if hasSet then
		local requiredLevel, requiredChampionPoints = GetItemLinkRequiredLevel(itemLink), GetItemLinkRequiredChampionPoints(itemLink)
		local quality = GetItemLinkQuality(itemLink)

		local GetItemLinkSetBonusInfo = GetItemLinkSetBonusInfo
		AddLineTitle(self, zo_strformat(SI_TOOLTIP_ITEM_NAME, setName), GetItemQualityColor(quality))
		self:AddVerticalPadding(-9)
		ZO_Tooltip_AddDivider(self)

		AddLevelSections(self, requiredLevel, requiredChampionPoints, false)

		for i = 1, numBonuses do
			local _, bonusDescription = GetItemLinkSetBonusInfo(itemLink, false, i)
			AddLineCenter(self, bonusDescription)
		end
	end
end
