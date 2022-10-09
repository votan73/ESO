local addon = {
	name = "LootWall",
}
local LAM2

----- Loot List -----
local ROW_TYPE_ID = 1

function addon:Update()
	ZO_ScrollList_Clear(addon.rules)

	local GetItemLinkName = GetItemLinkName
	local names = { }
	for key, action in pairs(LootWall.savedVariables.itemList) do
		if action >= LW_ACTION_DESTROY_ALWAYS then
			local itemLink = LootWall:CreateItemLinkFromStringId(key)
			names[#names + 1] = { name = GetItemLinkName(itemLink), itemLink = itemLink, key = key }
		end
	end
	table.sort(names, function(a, b) return a.name < b.name end)

	local ZO_ScrollList_CreateDataEntry = ZO_ScrollList_CreateDataEntry
	local dataList = ZO_ScrollList_GetDataList(addon.rules)
	for i = 1, #names do
		dataList[#dataList + 1] = ZO_ScrollList_CreateDataEntry(ROW_TYPE_ID, names[i], 1)
	end

	ZO_ScrollList_Commit(addon.rules)
	addon.rules.dirty = true
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
			ClearTooltip(ItemTooltip)
		else
			highlight.animation:PlayForward()

			InitializeTooltip(ItemTooltip, rowControl, TOPRIGHT, 24, -104, TOPLEFT)
			local rowData = ZO_ScrollList_GetData(rowControl)
			ItemTooltip:SetLink(rowData.itemLink)
		end
	end
end

local function InitScrollList()
	local function onMouseEnter(rowControl)
		HideRowHighlight(rowControl, false)
	end
	local function onMouseExit(rowControl)
		HideRowHighlight(rowControl, true)
	end
	local function onMouseClick(button)
		local rowData = ZO_ScrollList_GetData(button:GetParent())
		LootWall.savedVariables.itemList[rowData.key] = 0
		ZO_ScrollList_RefreshVisible(addon.rules)
	end

	local function setupDataRow(rowControl, rowData, scrollList)
		rowControl:SetMouseEnabled(true)
		local nameLabel = rowControl:GetNamedChild("Name")
		local ruleLabel = rowControl:GetNamedChild("Rule")
		local button = rowControl:GetNamedChild("Reset")

		local rule = LootWall.savedVariables.itemList[rowData.key]
		button:SetEnabled(rule ~= 0)
		local itemLink = rowData.itemLink
		nameLabel:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, rowData.name))
		nameLabel:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, GetItemLinkQuality(itemLink)))

		local ruleText
		if rule == 0 then
			ruleText = "Prompt"
		elseif rule == 10 then
			ruleText = "Keep Always"
		elseif rule == 11 then
			ruleText = "Keep Now"
		elseif rule == 20 then
			ruleText = "Trash Always"
		elseif rule == 21 then
			ruleText = "Trash Now"
		elseif rule == 22 then
			ruleText = "Trash Second"
		elseif rule == 30 then
			ruleText = "Destroy Always"
		elseif rule == 31 then
			ruleText = "Destroy Now"
		elseif rule == 32 then
			ruleText = "Destroy Second"
		end
		ruleLabel:SetText(ruleText)

		rowControl:SetHandler("OnMouseEnter", onMouseEnter)
		rowControl:SetHandler("OnMouseExit", onMouseExit)
		button:SetHandler("OnClicked", onMouseClick)
	end
	ZO_ScrollList_AddDataType(addon.rules, ROW_TYPE_ID, "LootWallBackyardRow", 30, setupDataRow)
end

----- Create Settings Panel -----

local function CreateOwnControls(panel)
	if panel ~= addon.control then return end
	CALLBACK_MANAGER:UnregisterCallback("LAM-PanelControlsCreated", CreateOwnControls)

	local control
	local wm = WINDOW_MANAGER

	control = wm:CreateControlFromVirtual("$(parent)Tabs", panel.scroll, "ZO_InventoryTabs")
	control:SetWidth(565)
	control:SetAnchor(TOPLEFT, panel.container, TOPLEFT, 0, 0)
	addon.tabs = control

	control = wm:CreateControlFromVirtual("$(parent)RuleList", panel.scroll, "ZO_ScrollList")
	control:SetAnchor(TOPLEFT, addon.tabs, BOTTOMLEFT, 0, 0)
	control:SetAnchor(BOTTOMRIGHT, panel.container, BOTTOMRIGHT, -16, -32)
	control:SetHandler("OnEffectivelyShown", function()
		if addon.rules.dirty then
			addon:Update()
			addon.rules.dirty = false
			ZO_ScrollList_RefreshVisible(addon.rules)
		end
	end )
	addon.rules = control
	InitScrollList()

	ADDONS_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
		if newState == SCENE_SHOWING then addon.rules.dirty = true end
	end )

	CALLBACK_MANAGER:RegisterCallback("LAM-RefreshPanel", function(panel) addon:Update() end)
end

----- Init -----

function addon:Initialize()
	LAM2 = LibAddonMenu2
	self:InitSettings()
end

function addon:InitSettings()
	local addonName = "LootWall Page 2"
	local version = "v0.5"
	local panelData = {
		type = "panel",
		name = addonName,
		displayName = "LootWall Destroy Rules",
		author = "votan",
		version = version,
		registerForRefresh = true,
		registerForDefaults = false,
	}
	addon.control = LAM2:RegisterAddonPanel(addonName, panelData)

	local optionsTable = {
	}
	LAM2:RegisterOptionControls(addonName, optionsTable)

	CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated", CreateOwnControls)
end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then return end
	EVENT_MANAGER:UnregisterForEvent("LootWallBackyard", EVENT_ADD_ON_LOADED)

	addon:Initialize()
end

EVENT_MANAGER:RegisterForEvent("LootWallBackyard", EVENT_ADD_ON_LOADED, OnAddonLoaded)
