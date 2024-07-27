local LIB_NAME = "LibVotansAddonList"
local addon = {}

local em = GetEventManager()
local AddOnManager = GetAddOnManager()

local function areAddonsCurrentlyEnabled()
	local areAllAddonsCurrentlyEnabled = true
	if AddOnManager.AreAddOnsEnabled then
		areAllAddonsCurrentlyEnabled = AddOnManager:AreAddOnsEnabled()
	end
	return areAllAddonsCurrentlyEnabled
end

function addon:Initialize()
	local list = ADD_ON_MANAGER.list
	if list.dataTypes[1] then
		list.dataTypes[1].setupCallback = ADD_ON_MANAGER:GetRowSetupFunction()
	else
		ZO_ScrollList_AddDataType(list, 1, "ZO_AddOnRow", ZO_ADDON_ROW_HEIGHT or 30, ADD_ON_MANAGER:GetRowSetupFunction())
	end
end

addon.libKeepEnabledList = {
	["LibVotansAddonList"] = true,
	["AddonSelector"] = true,
	["LibDialog"] = true
}

function addon:RefreshMultiButton()
	ADD_ON_MANAGER.isDirty = true
	ADD_ON_MANAGER:RefreshKeybinds()
end

function addon:DisableAllAddons()
	if not areAddonsCurrentlyEnabled() then
		return
	end

	local masterList, libKeepEnabledList = self.masterList, self.libKeepEnabledList
	local data
	for i = 1, #masterList do
		data = masterList[i]
		if data.isLibrary then
			local numUsed = data.usedBy and #data.usedBy or 0
			AddOnManager:SetAddOnEnabled(data.index, data.addOnEnabled and (numUsed == 0 or libKeepEnabledList[data.addOnFileName] == true))
		else
			AddOnManager:SetAddOnEnabled(data.index, data.addOnEnabled and libKeepEnabledList[data.addOnFileName] == true)
		end
	end
	self:RefreshMultiButton()
end

function addon:DisableAllLibraries()
	if not areAddonsCurrentlyEnabled() then
		return
	end

	local masterList, libKeepEnabledList = self.masterList, addon.libKeepEnabledList
	local data
	for i = 1, #masterList do
		data = masterList[i]
		if data.isLibrary then
			AddOnManager:SetAddOnEnabled(data.index, libKeepEnabledList[data.addOnFileName] == true)
		end
	end
	self:RefreshMultiButton()
end

local function createToolbar(self)
	self.toolBar = CreateControlFromVirtual("$(parent)ToolBar", self, "ZO_MenuBarTemplate")
	self.toolBar:ClearAnchors()
	self.toolBar:SetAnchor(BOTTOMRIGHT, self, BOTTOMRIGHT, -5, 0)

	ZO_MenuBar_OnInitialized(self.toolBar)
	local barData = {
		buttonPadding = -4,
		normalSize = 28,
		downSize = 28,
		animationDuration = DEFAULT_SCENE_TRANSITION_TIME,
		buttonTemplate = "ZO_MenuBarTooltipButton"
	}
	ZO_MenuBar_SetData(self.toolBar, barData)
	ZO_MenuBar_SetClickSound(self.toolBar, "DEFAULT_CLICK")

	local function CreateButtonData(name, mode, normal, highlight, disabled)
		return {
			activeTabText = name,
			categoryName = name,
			CustomTooltipFunction = function(tooltip)
				SetTooltipText(tooltip, GetString(self.toolBar.IsLibrary and SI_VOTANS_ADDONLIST_DISABLE_ALL_LIBS or SI_VOTANS_ADDONLIST_DISABLE_ALL_ADDONS))
			end,
			tooltip = SI_VOTANS_ADDONLIST_DISABLE_ALL_LIBS,
			alwaysShowTooltip = true,
			descriptor = mode,
			normal = normal,
			pressed = normal,
			highlight = highlight,
			disabled = disabled,
			callback = function(tabData)
				if self.toolBar.IsLibrary then
					addon:DisableAllLibraries()
				else
					addon:DisableAllAddons()
				end
				ADD_ON_MANAGER:RefreshData()
				ZO_MenuBar_ClearSelection(self.toolBar)
				PlaySound(SOUNDS.DEFAULT_CLICK)
			end
		}
	end

	local mainAddonsTab = CreateButtonData(SI_VOTANS_ADDONLIST_DISABLE_ALL_LIBS, 1, "esoui/art/buttons/edit_cancel_up.dds", "esoui/art/buttons/edit_cancel_over.dds", "esoui/art/buttons/edit_cancel_disabled.dds")
	ZO_MenuBar_AddButton(self.toolBar, mainAddonsTab)

	ZO_MenuBar_ClearSelection(self.toolBar)
end

do
	local orgSetupSectionHeaderRow = ZO_AddOnManager.SetupSectionHeaderRow
	local function setupHeaderFunction(manager, control, data)
		if not control.toolBar then
			createToolbar(control)
		end
		control.toolBar.IsLibrary = data.sortIndex ~= 1
		control.toolBar:SetHidden(false)
	end
	function ZO_AddOnManager.SetupSectionHeaderRow(...)
		setupHeaderFunction(...)
		return orgSetupSectionHeaderRow(...)
	end
end

do
	local function isLibrary(addOnFileName)
		return addOnFileName == "LibStub"
	end
	local orgGetAddOnInfo = AddOnManager.GetAddOnInfo
	function AddOnManager:GetAddOnInfo(i)
		local result = {orgGetAddOnInfo(self, i)}
		result[8] = result[8] or isLibrary(result[1])
		return unpack(result)
	end
end

do
	local function sortBySortable(a, b)
		return a.sortableName < b.sortableName
	end
	local IS_LIBRARY = true
	local IS_ADDON = false
	local orgBuildMasterList = ADD_ON_MANAGER.BuildMasterList
	local function StripText(text)
		return text:gsub("|[Rr]", "")
	end
	function ADD_ON_MANAGER:BuildMasterList()
		orgBuildMasterList(self)

		addon.masterList = addon.masterList or {}
		local masterList = addon.masterList
		ZO_ClearNumericallyIndexedTable(masterList)

		local nameToLib = {}
		local function addToLookup(scrollData)
			for i = 1, #scrollData do
				local data = scrollData[i]
				nameToLib[data.addOnFileName] = data
				data.sortableName = data.strippedAddOnName:upper()
				data.expandable = false
				masterList[#masterList + 1] = data
			end
		end
		local function checkDependency(masterList)
			local data
			local name, i, dependency, depCount, isPatchFor, dependsOn, dependencyExists, dependencyActive, dependencyMinVersion, dependencyVersion
			for index = 1, #masterList do
				data = masterList[index]
				i = data.index
				name, depCount = nil, 0
				dependsOn = {}
				data.dependsOn = dependsOn
				data.strippedAddOnName = StripText(data.strippedAddOnName)
				data.unloadable = false
				for j = 1, AddOnManager:GetAddOnNumDependencies(i) do
					dependency, dependencyExists, dependencyActive, dependencyMinVersion, dependencyVersion = AddOnManager:GetAddOnDependencyInfo(i, j)
					dependency = nameToLib[dependency]
					if dependency and not dependency.isLibrary and not dependency.missing then
						if not name then
							name = dependency.sortableName
							isPatchFor = dependency
						end
						depCount = depCount + 1
					end
					if dependency then
						dependsOn[#dependsOn + 1] = dependency
						dependency.hasReference = true
						dependency.usedBy = dependency.usedBy or {}
						dependency.usedBy[#dependency.usedBy + 1] = data
						local dependencyTooLowVersion = dependencyVersion < dependencyMinVersion
						data.unloadable = data.unloadable or dependencyTooLowVersion
					else
						local name = AddOnManager:GetAddOnDependencyInfo(i, j)
						local missing = {
							addOnName = name,
							sortableName = name:upper(),
							addOnEnabled = false,
							missing = true
						}
						nameToLib[name] = missing
						dependsOn[#dependsOn + 1] = missing
						data.unloadable = true
					end
				end

				data.isPatch = name and depCount >= 1
				if data.isPatch then
					data.isLibrary = false
					data.isPatchFor = isPatchFor
					data.sortableName = string.format("%s-%s", name, data.sortableName)
				elseif not data.isLibrary then
					local path = zo_strupper(AddOnManager:GetAddOnRootDirectoryPath(i))
					local expectedPath = zo_strupper(string.format("user:/AddOns/%s/", data.addOnFileName))
					if path ~= expectedPath then
						data.expectedPath = string.format("AddOns/%s", data.addOnFileName)
					end
				end
			end
		end
		-- AddonCategory adds more types => iterate all
		for _, list in pairs(self.addonTypes) do
			addToLookup(list)
		end
		for _, list in pairs(self.addonTypes) do
			checkDependency(list)
		end

		self.sortCallback = sortBySortable
	end
end

do
	local HINT_COLOR = ZO_HINT_TEXT
	local OPTIONAL_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, ITEM_QUALITY_MAGIC))
	local DISABLED_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED))

	local attentionIcon = zo_iconFormatInheritColor(ZO_KEYBOARD_NEW_ICON, 28, 28)

	local function AddLine(tooltip, text, color, alignment)
		local r, g, b = color:UnpackRGB()
		tooltip:AddLine(text, "", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, alignment, alignment ~= TEXT_ALIGN_LEFT)
	end

	local function AddLineCenter(tooltip, text, color)
		if not color then
			color = ZO_TOOLTIP_DEFAULT_COLOR
		end
		AddLine(tooltip, text, color, TEXT_ALIGN_CENTER)
	end

	local function AddLineTitle(tooltip, text, color)
		if not color then
			color = ZO_SELECTED_TEXT
		end
		local r, g, b = color:UnpackRGB()
		tooltip:AddLine(text, "ZoFontHeader3", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
	end

	local function AddLineSubTitle(tooltip, text, color)
		if not color then
			color = ZO_SELECTED_TEXT
		end
		local r, g, b = color:UnpackRGB()
		tooltip:AddLine(text, "ZoFontWinH5", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
	end

	local function AddLinePath(tooltip, text, color)
		if not color then
			color = ZO_HINT_TEXT
		end
		local r, g, b = color:UnpackRGB()
		tooltip:AddLine(text, "ZoFontWinH4", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
	end

	-- zo_strformat converts the dot in version numbers into comma (localization of decimal numbers, but wrong here)
	local formatDep = GetString(SI_ADDON_MANAGER_DEPENDENCIES):gsub("<<1>>", "")
	local formatMissing = GetString(SI_ADDON_MANAGER_DEPENDENCY_MISSING):gsub("<<1>>", "%%s")
	local formatDisabled = GetString(SI_ADDON_MANAGER_DEPENDENCY_DISABLED):gsub("<<1>>", "%%s")
	local formatLowVersion = GetString(SI_ADDON_MANAGER_DEPENDENCY_TOO_LOW_VERSION):gsub("<<1>>", "%%s")
	local formatLocation = "|t32:32:esoui/art/treeicons/gamepad/gp_store_indexicon_dlc.dds:inheritColor|t"
	local function onMouseEnter(control)
		local data = ZO_ScrollList_GetData(control)
		if not data then
			return
		end
		InitializeTooltip(ItemTooltip, control, LEFT, -7, -30, BOTTOMRIGHT)
		ItemTooltip:SetMinHeaderRowHeight(0)
		ItemTooltip:SetMinHeaderRows(1)

		ZO_ItemIconTooltip_OnAddGameData(ItemTooltip, TOOLTIP_GAME_DATA_ITEM_ICON, data.isLibrary and "esoui/art/journal/journal_tabicon_cadwell_up.dds" or "esoui/art/inventory/inventory_tabicon_misc_up.dds")

		if data.isLibrary then
			ItemTooltip:AddHeaderLine(zo_strformat(SI_ITEM_FORMAT_STR_TEXT1, GetString(SI_VOTANS_ADDONLIST_LIB)), "ZoFontWinH5", 1, TOOLTIP_HEADER_SIDE_LEFT, ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
		end
		AddLineTitle(ItemTooltip, data.addOnName)
		ItemTooltip:AddVerticalPadding(-9)

		local version = AddOnManager.GetAddOnVersion and AddOnManager:GetAddOnVersion(data.index) or 0
		if version > 0 then
			ItemTooltip:AddVerticalPadding(-3)
			AddLineSubTitle(ItemTooltip, string.format("Version %i", version), ZO_TOOLTIP_DEFAULT_COLOR)
			ItemTooltip:AddVerticalPadding(-6)
		end

		ZO_Tooltip_AddDivider(ItemTooltip)

		if data.addOnAuthorByLine ~= "" then
			AddLineSubTitle(ItemTooltip, data.addOnAuthorByLine)
		end

		if data.addOnDescription ~= "" then
			AddLineCenter(ItemTooltip, data.addOnDescription)
		end

		local path = AddOnManager:GetAddOnRootDirectoryPath(data.index):gsub("^user:/", formatLocation):gsub("/$", "")
		if data.expectedPath then
			AddLinePath(ItemTooltip, path, HINT_COLOR)
			ItemTooltip:AddVerticalPadding(-6)
			AddLineCenter(ItemTooltip, GetString(SI_VOTANS_ADDONLIST_SUSPICIOUS_PATH):format(data.expectedPath), HINT_COLOR)
		else
			AddLinePath(ItemTooltip, path)
		end

		if data.isLibrary and not data.hasReference then
			AddLineCenter(ItemTooltip, GetString(SI_VOTANS_ADDONLIST_OPTIONAL_LIB), OPTIONAL_COLOR)
		end

		local numDep = data.dependsOn and #data.dependsOn or 0
		if numDep > 0 then
			AddLineSubTitle(ItemTooltip, formatDep)
			ItemTooltip:AddVerticalPadding(-6)
			local dependencyText = {}
			local dependency, dependencyName, dependencyExists, dependencyActive, dependencyMinVersion, dependencyVersion
			for j = 1, #data.dependsOn do
				dependency = data.dependsOn[j]
				dependencyName, dependencyExists, dependencyActive, dependencyMinVersion, dependencyVersion = AddOnManager:GetAddOnDependencyInfo(data.index, j)
				local dependencyTooLowVersion = dependencyVersion < dependencyMinVersion

				if not dependencyActive or not dependencyExists or dependencyTooLowVersion then
					if not dependencyExists then
						dependencyName = ZO_ERROR_COLOR:Colorize(formatMissing:format(dependencyName))
					elseif not dependencyActive then
						dependencyName = DISABLED_COLOR:Colorize(formatDisabled:format(dependencyName))
					elseif dependencyTooLowVersion then
						dependencyName = ZO_ERROR_COLOR:Colorize(formatLowVersion:format(dependencyName))
					end
				end
				dependencyText[#dependencyText + 1] = dependencyName
			end
			table.sort(dependencyText)
			AddLineCenter(ItemTooltip, table.concat(dependencyText, ", "))
		end

		local numDep = data.usedBy and #data.usedBy or 0
		if numDep > 0 then
			AddLineSubTitle(ItemTooltip, GetString(SI_VOTANS_ADDONLIST_USED_BY))
			ItemTooltip:AddVerticalPadding(-6)

			local dependencyText = {}
			local dependency, dependencyName, dependencyActive
			for j = 1, numDep do
				dependency = data.usedBy[j]
				dependencyName, dependencyActive = dependency.strippedAddOnName, dependency.addOnEnabled

				if not dependencyActive then
					dependencyName = DISABLED_COLOR:Colorize(dependencyName)
				end
				dependencyText[#dependencyText + 1] = dependencyName
			end
			table.sort(dependencyText)
			AddLineCenter(ItemTooltip, table.concat(dependencyText, ", "))
		end

		ZO_ItemIconTooltip_OnAddGameData(ItemTooltip, TOOLTIP_GAME_DATA_STOLEN, false)
	end
	local function onMouseChildEnter(control)
		return onMouseEnter(control:GetParent())
	end
	local function onMouseExit(control)
		ClearTooltip(ItemTooltip)
	end

	local function modify(control, data)
		if not data then
			return
		end

		local areAllAddonsCurrentlyEnabled = areAddonsCurrentlyEnabled()

		local indent = data.isPatch and 12 or 0
		local expandButton = control:GetNamedChild("ExpandButton")
		expandButton:SetHidden(true)
		local enableButton = control:GetNamedChild("Enabled")
		enableButton:SetAnchor(TOPLEFT, nil, TOPLEFT, 7 + indent, 7)
		enableButton:SetHidden(false)
		enableButton:SetMouseEnabled(areAllAddonsCurrentlyEnabled)
		if data.hasDependencyError then
			ZO_TriStateCheckButton_SetState(enableButton, TRISTATE_CHECK_BUTTON_UNCHECKED)
		end

		local state = control:GetNamedChild("State")
		state:SetDimensions(28, 28)
		state:ClearAnchors()
		state:SetAnchor(TOPRIGHT, nil, TOPRIGHT, -7, 1)
		state:SetMouseEnabled(false)
		local stateText
		-- out-dated libs coming from out-dated main-addons. If an out-dated lib is used by an up-to-date addon, it is still working.
		-- if it is a patch, but its parent is not enabled, show out-of-date warning only.
		if data.unloadable or data.expectedPath then
			stateText = attentionIcon
			if not data.unloadable and AddOnManager:GetLoadOutOfDateAddOns() or (data.isPatch and not data.isPatchFor.addOnEnabled) then
				stateText = HINT_COLOR:Colorize(stateText)
			elseif data.unloadable then
				stateText = ZO_ERROR_COLOR:Colorize(stateText)
			else
				stateText = DISABLED_COLOR:Colorize(stateText)
			end
		elseif data.isLibrary and not data.hasReference then
			stateText = attentionIcon
			stateText = OPTIONAL_COLOR:Colorize(stateText)
		else
			stateText = ""
		end
		state:SetText(stateText)

		local name = control:GetNamedChild("Name")
		name:SetWidth(385 - indent)
		local author = control:GetNamedChild("Author")
		author:SetWidth(372)

		if (data.isPatch and not data.isPatchFor.addOnEnabled) or (data.hasDependencyError and not data.unloadable) then
			local color = ZO_DEFAULT_DISABLED_COLOR
			name:SetColor(color:UnpackRGBA())
			author:SetColor(color:UnpackRGBA())
		end

		if not control.votanAddonLib then
			control.votanAddonLib = true
			ZO_PreHookHandler(control, "OnMouseEnter", onMouseEnter)
			ZO_PreHookHandler(control, "OnMouseExit", onMouseExit)

			local name = control:GetNamedChild("Name")
			ZO_PreHookHandler(name, "OnMouseEnter", onMouseChildEnter)
			ZO_PreHookHandler(name, "OnMouseExit", onMouseExit)
		end
		control:SetMouseEnabled(areAllAddonsCurrentlyEnabled)
	end
	local orgGetRowSetupFunction = ZO_AddOnManager.GetRowSetupFunction
	function ZO_AddOnManager:GetRowSetupFunction()
		local function setupAddonRow(...)
			local orgSetup = orgGetRowSetupFunction(self)
			orgSetup(...)
			return modify(...)
		end
		return setupAddonRow
	end
end

do
	local function checkDependsOn(data)
		-- assume success to break recursion
		data.addOnEnabled, data.addOnState = true, ADDON_STATE_ENABLED

		local other
		for i = 1, #data.dependsOn do
			other = data.dependsOn[i]
			if other.addOnState ~= ADDON_STATE_ENABLED and not other.missing then
				checkDependsOn(other)
			end
		end
		AddOnManager:SetAddOnEnabled(data.index, true)
		-- Verify success
		data.addOnEnabled, data.addOnState = select(5, AddOnManager:GetAddOnInfo(data.index))
		return data.addOnState == ADDON_STATE_ENABLED
	end
	local function checkDisableUnusedLibs(data)
		local other, enabled, dependency
		for i = 1, #data.dependsOn do
			other = data.dependsOn[i]
			if other.isLibrary and other.addOnState == ADDON_STATE_ENABLED then
				enabled = false
				local numDep = other.usedBy and #other.usedBy or 0
				if numDep > 0 then
					for j = 1, numDep do
						dependency = other.usedBy[j]
						enabled = enabled or (dependency ~= data and not dependency.isLibrary and dependency.addOnState == ADDON_STATE_ENABLED)
					end
					AddOnManager:SetAddOnEnabled(other.index, enabled)
				end
			end
		end

		-- Verify success
		data.addOnEnabled, data.addOnState = select(5, AddOnManager:GetAddOnInfo(data.index))
	end
	local function CheckPreRequirements(self, control, checkState)
		local row = control:GetParent()

		if checkState == TRISTATE_CHECK_BUTTON_CHECKED then
			return checkDependsOn(row.data)
		elseif checkState == TRISTATE_CHECK_BUTTON_INDETERMINATE then
			return true
		else
			checkDisableUnusedLibs(row.data)
			return true
		end
	end
	local function refresh(self)
		return self:RefreshData()
	end
	local orgOnEnabledButtonClicked = ZO_AddOnManager.OnEnabledButtonClicked
	function ZO_AddOnManager.OnEnabledButtonClicked(...)
		if not areAddonsCurrentlyEnabled() then
			return
		end
		if CheckPreRequirements(...) then
			return orgOnEnabledButtonClicked(...)
		else
			refresh(...)
			PlaySound(SOUNDS.GENERAL_ALERT_ERROR)
		end
	end
end

function ZO_AddOnManager:OnExpandButtonClicked(row)
	-- Disabled.
end

function addon:SetSection(mode)
	local function endAnim()
		ZO_MenuBar_ClearSelection(self.sectionBar)
	end
	if mode == 1 then
		local value = ADD_ON_MANAGER.list.scrollbar:GetValue()
		if value > 0 then
			ZO_ScrollList_ScrollRelative(ADD_ON_MANAGER.list, -value, endAnim)
		else
			endAnim()
		end
	elseif mode == 2 then
		local scrollData = ZO_ScrollList_GetDataList(ADD_ON_MANAGER.list)
		local categoryLibs = GetString(SI_ADDON_MANAGER_SECTION_LIBRARIES)
		for i = #scrollData, 1, -1 do
			local entry = scrollData[i]
			if entry.typeId == 2 and ZO_ScrollList_GetDataEntryData(entry).text == categoryLibs then
				ZO_ScrollList_ScrollDataToCenter(ADD_ON_MANAGER.list, i, endAnim)
				break
			end
		end
	end
end

do
	local function InitializeModeBar(self)
		self.sectionBar = CreateControlFromVirtual("$(parent)SectionBar", ZO_AddOns, "ZO_MenuBarTemplate")
		self.sectionBar:ClearAnchors()
		self.sectionBar:SetAnchor(BOTTOMRIGHT, ZO_AddOnsDivider, TOPRIGHT, -6, -5)

		ZO_MenuBar_OnInitialized(self.sectionBar)
		local barData = {
			buttonPadding = 6,
			normalSize = 42,
			downSize = 51,
			animationDuration = DEFAULT_SCENE_TRANSITION_TIME,
			buttonTemplate = "ZO_MenuBarButtonTemplateWithTooltip"
		}
		ZO_MenuBar_SetData(self.sectionBar, barData)
		ZO_MenuBar_SetClickSound(self.sectionBar, "DEFAULT_CLICK")

		local function CreateButtonData(name, mode, normal, highlight, disabled)
			return {
				activeTabText = name,
				categoryName = name,
				tooltip = name,
				descriptor = mode,
				normal = normal,
				pressed = normal,
				highlight = highlight,
				disabled = disabled,
				callback = function(tabData)
					self:SetSection(mode)
				end
			}
		end

		local mainAddonsTab = CreateButtonData(SI_WINDOW_TITLE_ADDON_MANAGER, 1, "esoui/art/inventory/inventory_tabicon_misc_up.dds", "esoui/art/inventory/inventory_tabicon_misc_over.dds", "esoui/art/inventory/inventory_tabicon_misc_disabled.dds")
		ZO_MenuBar_AddButton(self.sectionBar, mainAddonsTab)

		local libAddonsTab = CreateButtonData(SI_VOTANS_ADDONLIST_LIBS, 2, "esoui/art/journal/journal_tabicon_cadwell_up.dds", "esoui/art/journal/journal_tabicon_cadwell_over.dds", "esoui/art/journal/journal_tabicon_cadwell_disabled.dds")
		ZO_MenuBar_AddButton(self.sectionBar, libAddonsTab)
		ZO_MenuBar_SetDescriptorEnabled(self.sectionBar, 2, self.libSectionDataIndex ~= 0)

		ZO_MenuBar_ClearSelection(self.sectionBar)
	end

	local function initTabs(oldState, newState)
		if (newState == SCENE_FRAGMENT_SHOWN) then
			ADDONS_FRAGMENT:UnregisterCallback("StateChange", initTabs)
			if ZO_ScrollList_EnoughEntriesToScroll(ADD_ON_MANAGER.list) then
				InitializeModeBar(addon)
			end
		end
	end
	ADDONS_FRAGMENT:RegisterCallback("StateChange", initTabs)
end

local function OnAddonLoaded(event, name)
	if name ~= LIB_NAME and name ~= "AddonSelector" then
		return
	end
	em:UnregisterForEvent(LIB_NAME, EVENT_ADD_ON_LOADED)
	if name == LIB_NAME then
		addon:Initialize()
	end
end

em:RegisterForEvent(LIB_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)
