if not IsConsoleUI() then
	return
end

local LibHarvensAddonSettings = LibHarvensAddonSettings

local Templates = {
	[LibHarvensAddonSettings.ST_CHECKBOX] = "ZO_GamepadOptionsCheckboxRow",
	[LibHarvensAddonSettings.ST_SLIDER] = "LibHarvensAddonSettingsGamepadSlider",
	[LibHarvensAddonSettings.ST_EDIT] = "LibHarvensAddonSettingsGamepadEdit",
	[LibHarvensAddonSettings.ST_DROPDOWN] = "ZO_GamepadHorizontalListRow",
	[LibHarvensAddonSettings.ST_COLOR] = "ZO_GamepadOptionsColorRow",
	[LibHarvensAddonSettings.ST_BUTTON] = "ZO_GamepadOptionsLabelRow",
	[LibHarvensAddonSettings.ST_LABEL] = "ZO_GamepadOptionsLabelRow",
	[LibHarvensAddonSettings.ST_SECTION] = "ZO_Options_SectionTitle_WithDivider"
}

local currentSettings
local needUpdate = true

-----
-- Control specific functions tables
-----
local function SetNameControlState(control, enabled)
	local nameControl = control:GetNamedChild("Name")

	if nameControl then
		local selected = LibHarvensAddonSettings.list:GetSelectedControl() == control
		local color = ZO_GamepadMenuEntryTemplate_GetLabelColor(selected, not enabled)
		nameControl:SetColor(color:UnpackRGB())
	end
end

local changeControlStateFunctions = {
	[LibHarvensAddonSettings.ST_CHECKBOX] = function(control, state)
		SetNameControlState(control, state)
		control:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(state))
	end,
	[LibHarvensAddonSettings.ST_DROPDOWN] = function(control, state)
		SetNameControlState(control, state)
		control:GetDropDown():SetSelectedFromParent(state)
	end,
	[LibHarvensAddonSettings.ST_SLIDER] = function(control, state)
		SetNameControlState(control, state)
		local slider = control and control.slider
		slider:SetEnabled(state)
		local selected = LibHarvensAddonSettings.list:GetSelectedControl() == control
		local alpha = ZO_GamepadMenuEntryTemplate_GetAlpha(state and selected)
		slider:SetAlpha(alpha)
		slider:GetNamedChild("Left"):SetAlpha(alpha)
		slider:GetNamedChild("Right"):SetAlpha(alpha)
		slider:GetNamedChild("Center"):SetAlpha(alpha)
		slider.label:SetAlpha(alpha)
	end,
	[LibHarvensAddonSettings.ST_BUTTON] = function(control, state)
		SetNameControlState(control, state)
	end,
	[LibHarvensAddonSettings.ST_EDIT] = function(control, state)
		SetNameControlState(control, state)
		local editBackdrop = control:GetNamedChild("ValueTextField")
		editBackdrop:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(state))
		editBackdrop:GetNamedChild("Edit"):SetEditEnabled(state)
	end,
	[LibHarvensAddonSettings.ST_COLOR] = function(control, state)
		SetNameControlState(control, state)
		local color = control.texture
		color:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(state))
	end
}

local updateControlFunctions = {
	[LibHarvensAddonSettings.ST_CHECKBOX] = function(self, control)
		control:GetNamedChild("Name"):SetText(self:GetValueOrCallback(self.labelText))

		local function toggle(control, state)
			if state then
				control:GetNamedChild("On"):SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGB())
				control:GetNamedChild("Off"):SetColor(ZO_DEFAULT_DISABLED_COLOR:UnpackRGB())
				ZO_CheckButton_SetChecked(control.checkbox)
			else
				control:GetNamedChild("On"):SetColor(ZO_DEFAULT_DISABLED_COLOR:UnpackRGB())
				control:GetNamedChild("Off"):SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGB())
				ZO_CheckButton_SetUnchecked(control.checkbox)
			end
		end

		local checkbox = control.checkbox
		ZO_CheckButton_SetToggleFunction(checkbox, nil)
		toggle(self.control, self.getFunction())
		ZO_CheckButton_SetToggleFunction(
			checkbox,
			function(control, state)
				toggle(control:GetParent(), state)
				self:ValueChanged(state)
			end
		)
	end,
	[LibHarvensAddonSettings.ST_SLIDER] = function(self, control)
		control:GetNamedChild("Name"):SetText(self:GetValueOrCallback(self.labelText))
		local slider = control.slider
		slider:SetHandler("OnValueChanged", nil)
		slider:SetMinMax(self.min, self.max)
		slider:SetValue(self.getFunction())
		local label = slider.label
		local value = self.getFunction() or "0"
		if self.unit and #self.unit > 0 then
			label:SetText(value .. self:GetValueOrCallback(self.unit))
		else
			label:SetText(value)
		end
		slider:SetValueStep(self.step)
		slider:SetHandler(
			"OnValueChanged",
			function(control, value)
				local formattedValue = tonumber(string.format(self.format, value))
				if self.unit and #self.unit > 0 then
					control.label:SetText(formattedValue .. self:GetValueOrCallback(self.unit))
				else
					control.label:SetText(formattedValue)
				end
				self:ValueChanged(formattedValue)
			end
		)
	end,
	[LibHarvensAddonSettings.ST_BUTTON] = function(self, control)
		control:SetHidden(false)
		control:GetNamedChild("Name"):SetText(self:GetValueOrCallback(self.labelText))
		--click handled in keystrip
	end,
	[LibHarvensAddonSettings.ST_EDIT] = function(self, control)
		control:SetHidden(false)
		control:GetNamedChild("Name"):SetText(self:GetValueOrCallback(self.labelText))
		local editControl = control.editBox
		editControl:SetTextType(self.textType or TEXT_TYPE_ALL)
		editControl:SetMaxInputChars(self.maxInputChars or MAX_HELP_DESCRIPTION_BODY)
		editControl:SetText(self.getFunction() or "")
		editControl:SetColor(ZO_NORMAL_TEXT:UnpackRGB())
	end,
	[LibHarvensAddonSettings.ST_DROPDOWN] = function(self, control)
		control:GetNamedChild("Name"):SetText(self:GetValueOrCallback(self.labelText))
		local combobox = control:GetDropDown()
		combobox:SetOnSelectedDataChangedCallback(nil)
		combobox:Clear()
		local itemEntry
		local callback = function(data)
			self:ValueChanged(control, data.name, data)
		end
		local items = self:GetValueOrCallback(self.items)
		for i = 1, #items do
			combobox:AddEntry(items[i])
		end
		combobox:Commit()
		combobox:SetSelectedIndex(combobox:FindIndexFromData(self.getFunction(), combobox.equalityFunction) or self.default or 0, false, true)
		combobox:SetOnSelectedDataChangedCallback(callback)
	end,
	[LibHarvensAddonSettings.ST_LABEL] = function(self, control)
		local label = control:GetNamedChild("Name")
		label:SetText(self:GetValueOrCallback(self.labelText))
		control:SetHeight(label:GetTextHeight())
	end,
	[LibHarvensAddonSettings.ST_SECTION] = function(self, control)
		local label = control.label
		label:SetText(self:GetValueOrCallback(self.labelText))
		control:SetHeight(label:GetTextHeight() + 4)
	end,
	[LibHarvensAddonSettings.ST_COLOR] = function(self, control)
		local label = control:GetNamedChild("Name")
		label:SetText(self:GetValueOrCallback(self.labelText))
		self.control:GetNamedChild("Color"):SetColor(self.getFunction())
		local function OnColorSet(r, g, b, a)
			self:ValueChanged(r, g, b, a)
			self.control.texture:SetColor(self.getFunction())
		end
		--Click is handled in keystrip
	end
}

local createControlFunctions = {
	[LibHarvensAddonSettings.ST_CHECKBOX] = function(self, lastControl)
		LibHarvensAddonSettings.list:AddEntry(Templates[self.type], self)
	end,
	[LibHarvensAddonSettings.ST_SLIDER] = function(self, lastControl)
		LibHarvensAddonSettings.list:AddEntry(Templates[self.type], self)
	end,
	[LibHarvensAddonSettings.ST_BUTTON] = function(self, lastControl)
		LibHarvensAddonSettings.list:AddEntry(Templates[self.type], self)
	end,
	[LibHarvensAddonSettings.ST_EDIT] = function(self, lastControl)
		LibHarvensAddonSettings.list:AddEntry(Templates[self.type], self)
	end,
	[LibHarvensAddonSettings.ST_DROPDOWN] = function(self, lastControl)
		table.sort(
			self.items,
			function(leftData, rightData)
				return leftData.name < rightData.name
			end
		)
		LibHarvensAddonSettings.list:AddEntry(Templates[self.type], self)
	end,
	[LibHarvensAddonSettings.ST_LABEL] = function(self, lastControl)
		LibHarvensAddonSettings.list:AddEntry(Templates[self.type], self)
		self.canSelect = false
	end,
	[LibHarvensAddonSettings.ST_SECTION] = function(self, lastControl)
		LibHarvensAddonSettings.list:AddEntry(Templates[self.type], self)
		self.canSelect = false
	end,
	[LibHarvensAddonSettings.ST_COLOR] = function(self, lastControl)
		LibHarvensAddonSettings.list:AddEntry(Templates[self.type], self)
	end
}

local cleanControlFunctions = {
	[LibHarvensAddonSettings.ST_CHECKBOX] = function(self)
		ZO_CheckButton_SetToggleFunction(self.control:GetNamedChild("Checkbox"), nil)
	end,
	[LibHarvensAddonSettings.ST_SLIDER] = function(self, control)
		control.slider:SetHandler("OnValueChanged", nil)
		control.slider:Deactivate()
	end,
	[LibHarvensAddonSettings.ST_BUTTON] = function(self)
	end,
	[LibHarvensAddonSettings.ST_EDIT] = function(self)
		self.control:SetHidden(true)
	end,
	[LibHarvensAddonSettings.ST_DROPDOWN] = function(self)
		local combobox = self.control:GetDropDown()
		combobox:SetOnSelectedDataChangedCallback(nil)
	end,
	[LibHarvensAddonSettings.ST_LABEL] = function(self)
		self.control:GetNamedChild("Name"):SetText(nil)
	end,
	[LibHarvensAddonSettings.ST_SECTION] = function(self)
		self.control:GetNamedChild("Label"):SetText(nil)
	end,
	[LibHarvensAddonSettings.ST_COLOR] = function(self)
		self.control:GetNamedChild("Name"):SetText(nil)
	end
}

local setupControlFunctions = {
	[LibHarvensAddonSettings.ST_CHECKBOX] = function(self, params)
		self.labelText = params.label
		self.tooltipText = params.tooltip
		self.setFunction = params.setFunction
		self.getFunction = params.getFunction
		self.default = params.default
		self.disable = params.disable
	end,
	[LibHarvensAddonSettings.ST_SLIDER] = function(self, params)
		self.min = params.min
		self.max = params.max
		self.unit = params.unit
		self.step = params.step
		self.format = params.format or "%f"
		self.labelText = params.label
		self.tooltipText = params.tooltip
		self.setFunction = params.setFunction
		self.getFunction = params.getFunction
		self.default = params.default
		self.disable = params.disable
	end,
	[LibHarvensAddonSettings.ST_BUTTON] = function(self, params)
		self.clickHandler = params.clickHandler
		self.labelText = params.label
		self.tooltipText = params.tooltip
		self.default = params.default
		self.disable = params.disable
		self.buttonText = params.buttonText
	end,
	[LibHarvensAddonSettings.ST_EDIT] = function(self, params)
		self.textType = params.textType
		self.maxInputChars = params.maxChars
		self.labelText = params.label
		self.tooltipText = params.tooltip
		self.setFunction = params.setFunction
		self.getFunction = params.getFunction
		self.default = params.default
		self.disable = params.disable
	end,
	[LibHarvensAddonSettings.ST_DROPDOWN] = function(self, params)
		self.items = params.items
		self.labelText = params.label
		self.tooltipText = params.tooltip
		self.setFunction = params.setFunction
		self.getFunction = params.getFunction
		self.default = params.default
		self.disable = params.disable
	end,
	[LibHarvensAddonSettings.ST_LABEL] = function(self, params)
		self.labelText = params.label
		self.tooltipText = params.tooltip
	end,
	[LibHarvensAddonSettings.ST_SECTION] = function(self, params)
		self.labelText = params.label
		self.tooltipText = params.tooltip
	end,
	[LibHarvensAddonSettings.ST_COLOR] = function(self, params)
		self.labelText = params.label
		self.tooltipText = params.tooltip
		self.setFunction = params.setFunction
		self.getFunction = params.getFunction
		self.default = params.default
		self.disable = params.disable
	end
}

-----

-----
-- AddonSettingsControl class - represents single option control
-----
function LibHarvensAddonSettings.AddonSettingsControl:SetupControl(params)
	if setupControlFunctions[self.type] then
		setupControlFunctions[self.type](self, params)
	end
end

function LibHarvensAddonSettings.AddonSettingsControl:CreateControl(lastControl)
	if createControlFunctions[self.type] then
		createControlFunctions[self.type](self, lastControl)
	end
end

function LibHarvensAddonSettings.AddonSettingsControl:SetEnabled(state)
	if self.control and changeControlStateFunctions[self.type] then
		changeControlStateFunctions[self.type](self.control, state)
	end
end

function LibHarvensAddonSettings.AddonSettingsControl:UpdateControl()
	local updateFunc = updateControlFunctions[self.type]
	if self.control and updateFunc then
		updateFunc(self, self.control)
	end

	self:SetEnabled(not self:IsDisabled())
end

function LibHarvensAddonSettings.AddonSettingsControl:CleanUp()
	self:SetEnabled(true)
end

-----
-- AddonSettings class - represents addon settings panel
-----
function LibHarvensAddonSettings.AddonSettings:InitHandlers()
	CALLBACK_MANAGER:RegisterCallback(
		"LibHarvensAddonSettings_AddonSelected",
		function()
			if self.selected then
				self:CleanUp()
				self.selected = false
				self:UpdateHighlight()
			end
		end
	)
end

function LibHarvensAddonSettings.AddonSettings:CreateControls()
	local list = LibHarvensAddonSettings.list
	list:Clear()
	local hasDefaults = false
	for i = 1, #self.settings do
		self.settings[i]:CreateControl()
		hasDefaults = hasDefaults or self.settings[i].default ~= nil
	end
	self.hasDefaults = hasDefaults
	list:Commit()
	needUpdate = false
end

function LibHarvensAddonSettings.AddonSettings:UpdateControls()
	for i = 1, #self.settings do
		self.settings[i]:UpdateControl()
	end
	LibHarvensAddonSettings.list:RefreshVisible()
	needUpdate = false
end

----- end -----

function LibHarvensAddonSettings:RefreshAddonSettings()
	-- Called from out-side, therefore need to check this (again)
	if needUpdate and currentSettings ~= nil then
		currentSettings:UpdateControls()
	end
end

function LibHarvensAddonSettings:SelectFirstAddon()
	currentSettings = LibHarvensAddonSettings.addons[1]
	if not currentSettings.selected then
		currentSettings:Select()
	end
end

-----
-- Settings_ParametricList class
-----

local Settings_ParametricList = ZO_Gamepad_ParametricList_Screen:Subclass()

function Settings_ParametricList:New(control)
	return ZO_Gamepad_ParametricList_Screen.New(self, control)
end

function Settings_ParametricList:Initialize(control)
	ZO_Gamepad_ParametricList_Screen.Initialize(self, control, false, true, LibHarvensAddonSettings.scene)
end

function Settings_ParametricList:PerformUpdate()
end

function Settings_ParametricList:InitializeKeybindStripDescriptors()
	local CONTROL_TYPES_WITH_PRIMARY_ACTION = {
		[LibHarvensAddonSettings.ST_CHECKBOX] = true,
		[LibHarvensAddonSettings.ST_BUTTON] = true,
		[LibHarvensAddonSettings.ST_COLOR] = true,
		[LibHarvensAddonSettings.ST_EDIT] = true
	}
	local CONTROL_TYPES_WITH_INPUT = {
		[LibHarvensAddonSettings.ST_SLIDER] = true,
		[LibHarvensAddonSettings.ST_DROPDOWN] = true
	}
	local lastActiveInput
	self.keybindStripDescriptor = {
		{
			alignment = KEYBIND_STRIP_ALIGN_LEFT,
			name = function()
				local data = LibHarvensAddonSettings.list:GetSelectedData()
				if data and data.type == LibHarvensAddonSettings.ST_CHECKBOX then
					return GetString(SI_GAMEPAD_TOGGLE_OPTION)
				elseif data and data.type == LibHarvensAddonSettings.ST_BUTTON then
					return data:GetValueOrCallback(data.buttonText) or GetString(SI_GAMEPAD_SELECT_OPTION)
				else
					return GetString(SI_GAMEPAD_SELECT_OPTION)
				end
			end,
			keybind = "UI_SHORTCUT_PRIMARY",
			order = -500,
			callback = function()
				local control = LibHarvensAddonSettings.list:GetSelectedControl()
				local data = LibHarvensAddonSettings.list:GetSelectedData()
				if not data then
					return
				end
				local controlType = data.type
				if data:IsDisabled() then
					return
				end
				if controlType == LibHarvensAddonSettings.ST_CHECKBOX then
					ZO_CheckButton_OnClicked(control:GetNamedChild("Checkbox"))
				elseif controlType == LibHarvensAddonSettings.ST_BUTTON then
					PlaySound(SOUNDS.DEFAULT_CLICK)
					LibHarvensAddonSettings.list:GetSelectedData():ValueChanged(control)
				elseif controlType == LibHarvensAddonSettings.ST_COLOR then
					control:ShowDialog()
				elseif controlType == LibHarvensAddonSettings.ST_EDIT then
					control:Activate()
				end
			end,
			enabled = function()
				local data = LibHarvensAddonSettings.list:GetSelectedData()
				return data and not data:IsDisabled()
			end,
			visible = function()
				local data = LibHarvensAddonSettings.list:GetSelectedData()
				local control = LibHarvensAddonSettings.list:GetSelectedControl()
				if lastActiveInput then
					if control == nil or lastActiveInput ~= control then
						lastActiveInput:Deactivate()
						lastActiveInput = nil
					end
				end
				local showingInfoPanel = false
				if data then
					if type(data.tooltipText) == "function" then
						showingInfoPanel = false -- Not supported
					elseif data.tooltipText and #data.tooltipText > 0 then
						showingInfoPanel = true
					end
					if CONTROL_TYPES_WITH_INPUT[data.type] and not data:IsDisabled() then
						lastActiveInput = control
						lastActiveInput:Activate()
					end
				end
				if showingInfoPanel then
					--warningText
					GAMEPAD_TOOLTIPS:LayoutSettingTooltip(GAMEPAD_LEFT_TOOLTIP, data.tooltipText, "")
				else
					GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
				end

				return data and CONTROL_TYPES_WITH_PRIMARY_ACTION[data.type]
			end
		},
		{
			alignment = KEYBIND_STRIP_ALIGN_LEFT,
			name = GetString(SI_OPTIONS_DEFAULTS),
			keybind = "UI_SHORTCUT_SECONDARY",
			visible = function()
				return currentSettings and currentSettings.hasDefaults
			end,
			callback = function()
				ZO_Dialogs_ShowGamepadDialog("LibHarvensAddonSettings_Defaults")
			end
		}
	}
	ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
	LibHarvensAddonSettings.scene:RegisterCallback(
		"StateChange",
		function(newState)
			if newState == SCENE_HIDING and lastActiveInput then
				lastActiveInput:Deactivate()
				lastActiveInput = nil
			end
		end
	)
	ZO_Dialogs_RegisterCustomDialog(
		"LibHarvensAddonSettings_Defaults",
		{
			mustChoose = true,
			gamepadInfo = {
				dialogType = GAMEPAD_DIALOGS.BASIC
			},
			title = {
				text = SI_OPTIONS_RESET_TITLE
			},
			mainText = {
				text = function()
					return SI_OPTIONS_RESET_PROMPT
				end
			},
			buttons = {
				[1] = {
					text = SI_OPTIONS_RESET,
					callback = function(dialog)
						if currentSettings then
							currentSettings:ResetToDefaults()
						end
					end
				},
				[2] = {
					text = SI_DIALOG_CANCEL
				}
			}
		}
	)
end

function Settings_ParametricList:SetupList(list)
end

-----

local function OptionsWindowFragmentStateChangeRefresh(oldState, newState)
	if newState == SCENE_FRAGMENT_HIDING then
		needUpdate = true
		if currentSettings then
			currentSettings.lastSelectedRow = LibHarvensAddonSettings.list:GetSelectedData()
		end
	elseif newState == SCENE_FRAGMENT_SHOWING then
		if needUpdate and currentSettings ~= nil then
			LibHarvensAddonSettings:RefreshAddonSettings()
		elseif #LibHarvensAddonSettings.addons == 1 then
			LibHarvensAddonSettings:SelectFirstAddon()
		end
		if currentSettings then
			local list = LibHarvensAddonSettings.list
			if #currentSettings.settings > 0 then
				list:SetSelectedIndexWithoutAnimation(
					list:FindFirstIndexByEval(
						function(data)
							return data == currentSettings.lastSelectedRow
						end
					) or list:CalculateFirstSelectableIndex(),
					true,
					false
				)
			end
		end
	end
end

function LibHarvensAddonSettings:CreateAddonSettingsPanel()
	local headerData = {}

	local insertPosition = 0
	for i = 1, #ZO_MENU_ENTRIES do
		if ZO_MENU_ENTRIES[i].id == ZO_MENU_MAIN_ENTRIES.ACTIVITY_FINDER then
			insertPosition = i
			break
		end
	end
	if insertPosition == 0 then
		return
	end

	local function CreateEntry(id, data)
		local name = data.name
		if type(name) == "function" then
			name = "" --will be updated whenever the list is generated
		end

		local entry = ZO_GamepadEntryData:New(name, data.icon, nil, nil, data.isNewCallback)
		entry:SetIconTintOnSelection(true)
		entry:SetIconDisabledTintOnSelection(true)

		local header = data.header
		if header then
			entry:SetHeader(header)
		end

		entry.canLevel = data.canLevel
		entry.narrationText = data.narrationText
		entry.subLabelsNarrationText = data.subLabelsNarrationText

		if data.subMenu then
			entry.subMenu = {}
			for submenuEntryId, subMenuData in ipairs(data.subMenu) do
				entry.subMenu[#entry.subMenu + 1] = CreateEntry(submenuEntryId, subMenuData)
			end
		end

		entry.data = data
		entry.id = id
		return entry
	end

	local subItems = {}
	for i = 1, #LibHarvensAddonSettings.addons do
		local addon = LibHarvensAddonSettings.addons[i]
		addon.control = self.container
		addon:InitHandlers()

		local addonName = addon.name
		local author, name = addonName:match("^(.+)'s%s(.+)")
		if name == nil then
			name = addonName
		end
		if addon.author then
			author = addon.author
		end

		subItems[#subItems + 1] = {
			name = name,
			icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_collections.dds",
			addon = addon,
			activatedCallback = function()
				addon:Select()

				headerData.titleText = name
				headerData.subtitleText = addon.version
				headerData.messageText = author and zo_strformat(GetString(SI_ADD_ON_AUTHOR_LINE), author)
				ZO_GamepadGenericHeader_RefreshData(self.scrollList.header, headerData)

				SCENE_MANAGER:Push("LibHarvensAddonSettingsScene")
			end,
			enabled = true
		}
	end
	table.sort(
		subItems,
		function(el1, el2)
			return el1.name < el2.name
		end
	)

	local title = GetString(SI_GAME_MENU_ADDONS)
	if LibAddonMenu2 then
		title = title .. " 2"
	end
	table.insert(
		ZO_MENU_ENTRIES,
		insertPosition,
		CreateEntry(
			"LibHarvensAddonSettings",
			{
				customTemplate = "ZO_GamepadMenuEntryTemplateWithArrow",
				name = title,
				icon = "/esoui/art/options/gamepad/gp_options_addons.dds",
				subMenu = subItems
			}
		)
	)
	MAIN_MENU_GAMEPAD:RefreshMainList()

	local control = WINDOW_MANAGER:CreateControlFromVirtual("LibHarvensAddonSettingsList", GuiRoot, "LibHarvensAddonSettingsGamepadTopLevel")

	local fragment = ZO_FadeSceneFragment:New(control)

	self.container = control:GetNamedChild("MaskContainer")

	local scene = ZO_Scene:New("LibHarvensAddonSettingsScene", SCENE_MANAGER)
	scene:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
	scene:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD_OPTIONS)
	scene:AddFragment(FRAME_EMOTE_FRAGMENT_SYSTEM)
	scene:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
	scene:AddFragment(MINIMIZE_CHAT_FRAGMENT)
	scene:AddFragment(GAMEPAD_MENU_SOUND_FRAGMENT)
	scene:AddFragment(fragment)
	self.scene = scene

	self.scrollList = Settings_ParametricList:New(control)
	self.list = self.scrollList:GetMainList()

	CALLBACK_MANAGER:RegisterCallback(
		"LibHarvensAddonSettings_AddonSelected",
		function(_, addonSettings)
			currentSettings = addonSettings
			addonSettings:CreateControls()
		end
	)
end

function LibHarvensAddonSettings:CreateControlPools()
	local function extendFactory(templateName, func)
		local pool = self.list.dataTypes[templateName].pool
		local orgFactory = pool.m_Factory
		pool.m_Factory = function(...)
			local control = orgFactory(...)
			func(control)
			return control
		end
	end
	local function update(control, data)
		data.control = control
		control.data = data
		data:SetEnabled(not data:IsDisabled())
		updateControlFunctions[data.type](data, control)
	end
	local function reset(control)
		local data = control.data
		if data then
			cleanControlFunctions[data.type](data, control)
			data.control = nil
			control.data = nil
		end
	end
	local function AddPool(type, suffix, factory)
		self.list:AddDataTemplate(Templates[type], update, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, suffix, reset)
		if factory then
			extendFactory(Templates[type], factory)
		end
	end
	AddPool(
		self.ST_CHECKBOX,
		"Checkbox",
		function(control)
			local checkbox = control:GetNamedChild("Checkbox")
			checkbox.SetText = function(control, text)
			end
			function control:SetValue()
				local data = control.data
				if data then
					updateControlFunctions[data.type](data, self)
				end
			end
			control.checkbox = checkbox
		end
	)
	AddPool(
		self.ST_SLIDER,
		"Slider",
		function(control)
			local slider = control.slider
			slider.label = control:GetNamedChild("ValueLabel")
			function control:Activate()
				self.slider:Activate()
			end
			function control:Deactivate()
				self.slider:Deactivate()
			end
			function control:SetValue(...)
				local slider = self.slider
				slider:SetValue(...)
			end
		end
	)

	local function setupDropDown(control, data, selected, reselectingDuringRebuild, enabled, selectedFromParent)
		control:SetText(data.name)

		local color = selectedFromParent and ZO_SELECTED_TEXT or ZO_DISABLED_TEXT
		control:SetColor(color:UnpackRGBA())
	end
	local function equalityFunctionDropDown(leftData, rightData)
		return leftData == rightData.name or rightData == leftData.name or leftData.data == rightData.data
	end
	AddPool(
		self.ST_DROPDOWN,
		"DropDown",
		function(control)
			local horizontalListObject = control.horizontalListObject
			horizontalListObject.setupFunction = setupDropDown
			horizontalListObject.equalityFunction = equalityFunctionDropDown
			function control:Activate()
				self:GetDropDown():Activate()
			end
			function control:Deactivate()
				self:GetDropDown():Deactivate()
			end
			function control:GetDropDown()
				return self.horizontalListObject
			end
			function control:SetValue(data)
				local combobox = self:GetDropDown()
				combobox:SetSelectedIndex(combobox:FindIndexFromData(data, combobox.equalityFunction), false, false)
			end
		end
	)

	local function editGetData(editControl)
		return editControl:GetParent():GetParent():GetParent().data
	end
	local function editOnEnter(control)
		local data = editGetData(control)
		data:ValueChanged(control:GetText())
		control:LoseFocus()
	end
	local function editOnEscape(control)
		local data = editGetData(control)
		control:SetText(data.getFunction() or "")
		control:LoseFocus()
	end
	local function editOnFocusLost(control)
		local data = editGetData(control)
		data:ValueChanged(control:GetText())
		control:SetColor(ZO_NORMAL_TEXT:UnpackRGB())
		control:SetText(data.getFunction() or "")
		control:SetCursorPosition(0)
	end
	local function editOnFocusGained(control)
		local data = editGetData(control)
		control:SetColor(ZO_HIGHLIGHT_TEXT:UnpackRGB())
		control:SetCursorPosition(ZoUTF8StringLength(control:GetText()) + 1)
		control:TakeFocus()
	end
	AddPool(
		self.ST_EDIT,
		"Edit",
		function(control)
			local editControl = control:GetNamedChild("ValueTextFieldEdit")
			editControl:SetHandler("OnEnter", editOnEnter)
			editControl:SetHandler("OnEscape", editOnEscape)
			editControl:SetHandler("OnFocusLost", editOnFocusLost)
			editControl:SetHandler("OnFocusGained", editOnFocusGained)
			control.editBox = editControl
			function control:Activate()
				editOnFocusGained(editControl)
			end
			function control:SetValue(value)
				local editControl = self.editBox
				editControl:SetText(value)
			end
		end
	)

	local function colorOnSelect(control)
		local data = control.data
		local function colorOnColorSet(r, g, b, a)
			data:ValueChanged(r, g, b, a)
			control.texture:SetColor(data.getFunction())
		end
		SYSTEMS:GetObject("colorPicker"):Show(colorOnColorSet, data.getFunction())
	end
	AddPool(
		self.ST_COLOR,
		"Color",
		function(control)
			control.texture = control:GetNamedChild("Color")
			function control:ShowDialog()
				return colorOnSelect(self)
			end
			function control:SetValue(...)
				self.texture:SetColor(...)
			end
		end
	)

	AddPool(self.ST_BUTTON, "Button")
	AddPool(self.ST_LABEL, "Label")
	AddPool(
		self.ST_SECTION,
		"SectionLabel",
		function(control)
			local label = control:GetNamedChild("Label")
			control.label = label
			label:SetFont("ZoFontGamepad34")
			control:SetWidth(ZO_GAMEPAD_CONTENT_WIDTH)
			label:SetWidth(ZO_GAMEPAD_CONTENT_WIDTH)
		end
	)

	self.list:SetNoItemText(GetString(SI_GAMEPAD_MARKET_LOCKED_TITLE))
end

function LibHarvensAddonSettings:CreateAddonList()
	self.scene:RegisterCallback("StateChange", OptionsWindowFragmentStateChangeRefresh)
end

local function OptionsWindowFragmentStateChange(oldState, newState)
	if newState ~= SCENE_FRAGMENT_SHOWING or LibHarvensAddonSettings.initialized then
		return
	end

	MAIN_MENU_GAMEPAD_SCENE:UnregisterCallback("StateChange", OptionsWindowFragmentStateChange)

	LibHarvensAddonSettings:Initialize()
end

MAIN_MENU_GAMEPAD_SCENE:RegisterCallback("StateChange", OptionsWindowFragmentStateChange)
