local smithingQuickAccess = CreateControlFromVirtual("VotansSmithingQuickAccess", PopupTooltipTopLevel, "ZO_ItemIconTooltip")
--smithingQuickAccess:SetResizeToFitDescendents(false)
smithingQuickAccess:SetDimensionConstraints(439, 24, 439, 571)
--smithingQuickAccess:SetDimensions(439, 571)

local onGlobalMouseDown

local function HideTooltip()
	ClearTooltip(smithingQuickAccess)
	smithingQuickAccess:UnregisterForEvent(EVENT_GLOBAL_MOUSE_DOWN, onGlobalMouseDown)
end

function onGlobalMouseDown()
	if smithingQuickAccess:IsHidden() then
		return
	end
	if smithingQuickAccess.list.inScrollArea or MouseIsOver(smithingQuickAccess) then
		return
	end
	HideTooltip()
end

SMITHING_FRAGMENT:RegisterCallback(
	"StateChange",
	function(oldState, newState)
		if newState == SCENE_HIDING then
			HideTooltip()
		end
	end
)

do
	local orgSetMode = ZO_Smithing.SetMode
	function ZO_Smithing.SetMode(...)
		local self, mode = ...
		if mode ~= SMITHING_MODE_CREATION then
			HideTooltip()
		end
		return orgSetMode(...)
	end
end

local list = CreateControlFromVirtual("$(parent)List", smithingQuickAccess, "ZO_ScrollList")
list:SetParent(smithingQuickAccess)
list:SetAnchor(TOPLEFT, nil, TOPLEFT, 12, 12)
list:SetAnchor(BOTTOMRIGHT, nil, BOTTOMRIGHT, -12, -12)
smithingQuickAccess.list = list

local function onMouseEnter(row)
	ZO_ScrollList_MouseEnter(list, row)
end

local function onMouseExit(row)
	ZO_ScrollList_MouseExit(list, row)
end

local function onClick(row)
	ZO_ScrollList_MouseClick(list, row)
end

local ROW_TYPE_ID = 1
local COLOR_LOW = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, 5))
local COLOR_ORANGE = ZO_ERROR_COLOR -- ZO_ColorDef:New("FFFF6A00")

local function setupDataRow(rowControl, rowData, scrollList)
	local icon = rowControl:GetNamedChild("Icon")
	local nameLabel = rowControl:GetNamedChild("Name")
	local quantityLabel = rowControl:GetNamedChild("Quantity")

	icon:SetTexture(list.getIcon(rowData))
	nameLabel:SetText(list.getName(rowData))

	local quantity = list.getQuantity and list.getQuantity(rowData)
	quantityLabel:SetHidden(quantity == nil)
	if quantity then
		quantityLabel:SetText(quantity >= 10000 and "10k+" or quantity)
		if quantity <= 0 then
			quantityLabel:SetColor(COLOR_ORANGE:UnpackRGB())
		elseif quantity <= 200 then
			quantityLabel:SetColor(COLOR_LOW:UnpackRGB())
		else
			quantityLabel:SetColor(ZO_WHITE:UnpackRGB())
		end
	end

	rowControl:SetHandler("OnMouseEnter", onMouseEnter)
	rowControl:SetHandler("OnMouseExit", onMouseExit)
	rowControl:SetHandler("OnClicked", onClick)
end

ZO_ScrollList_AddDataType(list, ROW_TYPE_ID, "VotansSmithingQuickAccessSlot", 36, setupDataRow)
ZO_ScrollList_EnableHighlight(list, "ZO_ThinListHighlight")
ZO_ScrollList_EnableSelection(
	list,
	nil,
	function()
		local rowData = ZO_ScrollList_GetSelectedData(list)
		if rowData and list.setIndex then
			list.setIndex(rowData)
			HideTooltip()
		end
	end
)

local function SetupList(source, getIcon, getName, setIndex, sortFunc, getQuantity)
	list.getIcon, list.getName, list.setIndex, list.getQuantity = getIcon, getName, nil, getQuantity
	local scrollList = smithingQuickAccess.list
	local dataList = ZO_ScrollList_GetDataList(scrollList)

	ZO_ScrollList_Clear(scrollList)
	for _, rowData in ipairs(source) do
		dataList[#dataList + 1] = ZO_ScrollList_CreateDataEntry(ROW_TYPE_ID, rowData, 1)
	end
	smithingQuickAccess:SetHeight(#dataList * 36 + 24)

	if sortFunc then
		table.sort(dataList, sortFunc)
	end

	ZO_ScrollList_Commit(scrollList)
	list.setIndex = setIndex
end

local function getIcon(rowData)
	return rowData.icon
end
local function localize(name)
	return ZO_CachedStrFormat("<<C:1>>", name)
end

local championPointIcon = GetChampionIconMarkupStringInheritColor("100%")
local errorColor = "|c" .. ZO_ERROR_COLOR:ToHex()
local setupFunction = {}

setupFunction[ZO_SmithingTopLevelCreationPanelPatternList] = function(control, list)
	SetupList(
		list,
		function(rowData)
			local self = SMITHING.creationPanel
			local patternIndex = rowData.patternIndex
			local materialOverride = self:GetSelectedMaterialIndex()
			local materialQuantityOverride = select(3, GetSmithingPatternMaterialItemInfo(patternIndex, materialOverride))
			local styleOverride = self:GetSelectedItemStyleId()
			local traitOverride = self.traitList:GetSelectedData() and self.traitList:GetSelectedData().traitType

			return select(3, GetSmithingPatternInfo(patternIndex, materialOverride, materialQuantityOverride, styleOverride, traitOverride))
		end,
		function(rowData)
			if rowData.numTraitsRequired > 0 then
				return SMITHING.creationPanel:GetPlatformFormattedTextString(SI_SMITHING_SELECTED_PATTERN, rowData.patternName, rowData.numTraitsRequired)
			else
				return ZO_CachedStrFormat(SI_SMITHING_SELECTED_PATTERN_NO_TRAITS, rowData.patternName)
			end
		end,
		function(rowData)
			local index =
				control.horizontalScrollList:FindIndexFromData(
				rowData.patternIndex,
				function(oldStyleItemId, newStyleData)
					return oldStyleItemId == newStyleData.patternIndex
				end
			)
			control.horizontalScrollList:SetSelectedIndex(index, true, true)
		end
	)
end
setupFunction[ZO_SmithingTopLevelCreationPanelMaterialList] = function(control, list)
	SetupList(
		list,
		getIcon,
		function(rowData)
			local localizedName
			if rowData.isChampionPoint then
				localizedName = ZO_CachedStrFormat(SI_SMITHING_MATERIAL_CHAMPION_POINT_RANGE, rowData.name, championPointIcon, rowData.minCreatesItemOfLevel, championPointIcon, rowData.maxCreatesItemOfLevel)
			else
				localizedName = ZO_CachedStrFormat(SI_SMITHING_MATERIAL_LEVEL_RANGE, rowData.name, rowData.minCreatesItemOfLevel, rowData.maxCreatesItemOfLevel)
			end
			local useable = select(7, SMITHING.creationPanel:GetMaterialInformation(rowData))
			if useable then
				return localizedName
			else
				rowData.localizedUnknownName = rowData.localizedUnknownName or COLOR_ORANGE:Colorize(localizedName)
				return rowData.localizedUnknownName
			end
		end,
		function(rowData)
			local index =
				control.horizontalScrollList:FindIndexFromData(
				rowData.materialIndex,
				function(oldStyleItemId, newStyleData)
					return oldStyleItemId == newStyleData.materialIndex
				end
			)
			control.horizontalScrollList:SetSelectedIndex(index, true, true)
		end,
		nil,
		function(rowData)
			return GetCurrentSmithingMaterialItemCount(rowData.patternIndex, rowData.materialIndex)
		end
	)
end

setupFunction[ZO_SmithingTopLevelCreationPanelStyleList] = function(control, list)
	SetupList(
		list,
		getIcon,
		function(rowData)
			rowData.localizedName = rowData.localizedName or SMITHING.creationPanel:GetPlatformFormattedTextString(SI_SMITHING_STYLE_DESCRIPTION, localize(rowData.name), localize(GetItemStyleName(rowData.itemStyleId)))
			if IsSmithingStyleKnown(rowData.itemStyleId, SMITHING.creationPanel:GetSelectedPatternIndex()) then
				return rowData.localizedName
			else
				rowData.localizedUnknownName = rowData.localizedUnknownName or rowData.localizedName:gsub("|c%x%x%x%x%x%x", errorColor)
				return rowData.localizedUnknownName
			end
		end,
		function(rowData)
			local index =
				control.horizontalScrollList:FindIndexFromData(
				rowData.itemStyleId,
				function(oldStyleItemId, newStyleData)
					return oldStyleItemId == newStyleData.itemStyleId
				end
			)
			control.horizontalScrollList:SetSelectedIndex(index, true, true)
		end,
		function(a, b)
			return GetItemStyleName(a.data.itemStyleId) < GetItemStyleName(b.data.itemStyleId)
		end,
		function(rowData)
			return GetCurrentSmithingStyleItemCount(rowData.itemStyleId)
		end
	)
end

setupFunction[ZO_SmithingTopLevelCreationPanelTraitList] = function(control, list)
	SetupList(
		list,
		getIcon,
		function(rowData)
			rowData.localizedName = rowData.localizedName or SMITHING.creationPanel:GetPlatformFormattedTextString(SI_SMITHING_TRAIT_DESCRIPTION, rowData.name, GetString("SI_ITEMTRAITTYPE", rowData.traitType))
			local patternIndex = SMITHING.creationPanel:GetSelectedPatternIndex()
			if not patternIndex or IsSmithingTraitKnownForPattern(patternIndex, rowData.traitType) then
				return rowData.localizedName
			else
				rowData.localizedUnknownName = rowData.localizedUnknownName or rowData.localizedName:gsub("|c%x%x%x%x%x%x", errorColor)
				return rowData.localizedUnknownName
			end
		end,
		function(rowData)
			local index =
				control.horizontalScrollList:FindIndexFromData(
				rowData.traitIndex,
				function(oldStyleItemId, newStyleData)
					return oldStyleItemId == newStyleData.traitIndex
				end
			)
			control.horizontalScrollList:SetSelectedIndex(index, true, true)
		end,
		nil,
		function(rowData)
			return rowData.traitIndex > 1 and GetCurrentSmithingTraitItemCount(rowData.traitIndex) or nil
		end
	)
end

-- setupFunction[ZO_SmithingTopLevelResearchPanelResearchLineList] = setupFunction[ZO_SmithingTopLevelCreationPanelPatternList]

local function BuildScrollList(parent)
	local control = parent:GetNamedChild("List")
	setupFunction[parent](control, control.horizontalScrollList.list)
end

local function onMouseUp(control, button, upInside)
	if not upInside then
		return
	end
	control = control:GetParent()
	if smithingQuickAccess:IsHidden() or smithingQuickAccess:GetOwner() ~= control then
		InitializeTooltip(smithingQuickAccess, control, TOPRIGHT, 12, -24, TOPLEFT)
		BuildScrollList(control)
		smithingQuickAccess:RegisterForEvent(EVENT_GLOBAL_MOUSE_DOWN, onGlobalMouseDown)
	else
		HideTooltip()
	end
end

local function setLabelColorText(label, over)
	label:SetColor((over and ZO_HIGHLIGHT_TEXT or ZO_WHITE):UnpackRGBA())
end

local function labelEnter(self)
	setLabelColorText(self, true)
end

local function labelExit(self)
	setLabelColorText(self, false)
end

local function addHandler(list)
	local control = list:GetNamedChild("Title")
	ZO_PreHookHandler(control, "OnMouseUp", onMouseUp)
	control:SetMouseEnabled(true)

	ZO_PreHookHandler(control, "OnMouseEnter", labelEnter)
	ZO_PreHookHandler(control, "OnMouseExit", labelExit)
end

addHandler(ZO_SmithingTopLevelCreationPanelPatternList)
addHandler(ZO_SmithingTopLevelCreationPanelMaterialList)
addHandler(ZO_SmithingTopLevelCreationPanelStyleList)
addHandler(ZO_SmithingTopLevelCreationPanelTraitList)
-- ZO_SmithingTopLevelResearchPanelResearchLineList:SetHandler("OnMouseUp", onMouseUp)
-- ZO_SmithingTopLevelResearchPanelResearchLineList:SetMouseEnabled(true)

-- local orgDoesStylePassFilter = ZO_SharedSmithingCreation.DoesStylePassFilter
-- function ZO_SharedSmithingCreation.DoesStylePassFilter(self, itemStyleId, alwaysHideIfLocked, ...)
-- 	alwaysHideIfLocked = false
-- 	return orgDoesStylePassFilter(self, itemStyleId, alwaysHideIfLocked, ...)
-- end
