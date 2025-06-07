local LibHarvensAddonSettings = LibHarvensAddonSettings

local TOOLTIPS = {
	ItemTooltip,
	InformationTooltip,
	GameTooltip,
	AbilityTooltip,
	AchievementTooltip,
	KeepUpgradeTooltip,
	PopupTooltip,
	SkillTooltip
}

local currentSettings
local needUpdate = true

-----
-- Control specific functions tables
-----
local ALPHA_STATES = {
	[true] = 1,
	[false] = 0.5
}

local function GetAlphaFromState(state)
	return ALPHA_STATES[state]
end

local function SetNameControlState(control, enabled)
	local nameControl = control:GetNamedChild("Name")
	if not nameControl then
		nameControl = control:GetNamedChild("Label")
	end

	if nameControl then
		if enabled then
			nameControl:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGB())
		else
			nameControl:SetColor(ZO_DEFAULT_DISABLED_COLOR:UnpackRGB())
		end
	end
end

local changeControlStateFunctions = {
	[LibHarvensAddonSettings.ST_CHECKBOX] = function(control, state)
		local boxControl = control.boxControl or control:GetNamedChild("Checkbox")
		SetNameControlState(control, state and ZO_CheckButton_IsChecked(boxControl))
		if state == false then
			ZO_CheckButton_Disable(boxControl)
		else
			ZO_CheckButton_Enable(boxControl)
		end
		boxControl:SetAlpha(GetAlphaFromState(state))
		control.boxControl = boxControl
	end,
	[LibHarvensAddonSettings.ST_DROPDOWN] = function(control, state)
		SetNameControlState(control, state)
		local dropdown = control.dropdown
		if state == false then
			ZO_ComboBox_Disable(dropdown)
		else
			ZO_ComboBox_Enable(dropdown)
		end
		local alpha = GetAlphaFromState(state)
		dropdown:GetNamedChild("SelectedItemText"):SetAlpha(alpha)
		dropdown:GetNamedChild("BG"):SetAlpha(alpha)
		dropdown:GetNamedChild("OpenDropdown"):SetAlpha(alpha)
	end,
	[LibHarvensAddonSettings.ST_SLIDER] = function(control, state)
		SetNameControlState(control, state)
		control.slider:SetEnabled(state)
		local alpha = GetAlphaFromState(state)
		control:GetNamedChild("SliderBackdrop"):SetAlpha(alpha)
		control:GetNamedChild("ValueLabel"):SetAlpha(alpha)
	end,
	[LibHarvensAddonSettings.ST_BUTTON] = function(control, state)
		SetNameControlState(control, state)
		control:GetNamedChild("Button"):SetEnabled(state)
	end,
	[LibHarvensAddonSettings.ST_EDIT] = function(control, state)
		SetNameControlState(control, state)
		local editBackdrop = control:GetNamedChild("EditBackdrop")
		editBackdrop:SetAlpha(GetAlphaFromState(state))
		editBackdrop:GetNamedChild("Edit"):SetEditEnabled(state)
	end,
	[LibHarvensAddonSettings.ST_COLOR] = function(control, state)
		SetNameControlState(control, state)
		local color = control:GetNamedChild("ColorSection")
		color:SetMouseEnabled(state)
		color:SetAlpha(GetAlphaFromState(state))
	end,
	[LibHarvensAddonSettings.ST_ICONPICKER] = function(control, state)
		SetNameControlState(control, state)
		local checkBox = control.checkBox
		if state == false then
			ZO_CheckButton_Disable(checkBox)
		else
			ZO_CheckButton_Enable(checkBox)
		end
		local alpha = GetAlphaFromState(state)
		control.button:SetAlpha(alpha)
		control:SetHidden(false)
	end
}

local updateControlFunctions = {
	[LibHarvensAddonSettings.ST_CHECKBOX] = function(self, lastControl)
		self:SetAnchor(lastControl)
		self.control:GetNamedChild("Name"):SetText(self:GetString(self:GetValueOrCallback(self.labelText)))

		if self.getFunction() then
			ZO_CheckButton_SetChecked(self.control:GetNamedChild("Checkbox"))
			self.control:GetNamedChild("Name"):SetColor(1, 1, 1, 1)
		else
			ZO_CheckButton_SetUnchecked(self.control:GetNamedChild("Checkbox"))
			self.control:GetNamedChild("Name"):SetColor(0.3, 0.3, 0.3, 1)
		end
	end,
	[LibHarvensAddonSettings.ST_SLIDER] = function(self, lastControl)
		self:SetAnchor(lastControl)
		self.control:GetNamedChild("Name"):SetText(self:GetString(self:GetValueOrCallback(self.labelText)))
		local slider = self.control.slider
		slider:SetMinMax(self.min, self.max)
		slider:SetValue(self.getFunction())
		local label = slider.label or self.control:GetNamedChild("ValueLabel")
		local value = self.getFunction() or "0"
		if self.unit and #self.unit > 0 then
			label:SetText(value .. self:GetString(self:GetValueOrCallback(self.unit)))
		else
			label:SetText(value)
		end
		slider:SetValueStep(self.step)
		slider.label = label
	end,
	[LibHarvensAddonSettings.ST_BUTTON] = function(self, lastControl)
		self.control:SetHidden(false)
		self:SetAnchor(lastControl)
		self.control:GetNamedChild("Name"):SetText(self:GetString(self:GetValueOrCallback(self.labelText)))
		local button = self.control:GetNamedChild("Button")
		button:SetText(self:GetString(self:GetValueOrCallback(self.buttonText)))
	end,
	[LibHarvensAddonSettings.ST_EDIT] = function(self, lastControl)
		self.control:SetHidden(false)
		self:SetAnchor(lastControl)
		self.control:GetNamedChild("Name"):SetText(self:GetString(self:GetValueOrCallback(self.labelText)))
		local editControl = self.control:GetNamedChild("EditBackdrop"):GetNamedChild("Edit")
		editControl:SetTextType(self.textType or TEXT_TYPE_ALL)
		editControl:SetMaxInputChars(self.maxInputChars or MAX_HELP_DESCRIPTION_BODY)
		editControl:SetText(self.getFunction() or "")
		editControl:SetColor(ZO_NORMAL_TEXT:UnpackRGB())
	end,
	[LibHarvensAddonSettings.ST_DROPDOWN] = function(self, lastControl)
		self:SetAnchor(lastControl)
		self.control:GetNamedChild("Name"):SetText(self:GetString(self:GetValueOrCallback(self.labelText)))
		local combobox = self.control:GetDropDown()
		combobox:ClearItems()
		local itemEntry
		local callback = function(...) self:ValueChanged(...) end
		local items = self:GetValueOrCallback(self.items)
		for i = 1, #items do
			itemEntry = combobox:CreateItemEntry(items[i].name, callback)
			itemEntry.data = items[i].data
			combobox:AddItem(itemEntry)
		end
		combobox:SetSelectedItem(self.getFunction())
	end,
	[LibHarvensAddonSettings.ST_LABEL] = function(self, lastControl)
		self.control:SetHidden(false)
		self:SetAnchor(lastControl)
		local label = self.control:GetNamedChild("Name")
		label:SetText(self:GetString(self:GetValueOrCallback(self.labelText)))
		self.control:SetHeight(label:GetTextHeight())
	end,
	[LibHarvensAddonSettings.ST_SECTION] = function(self, lastControl)
		self:SetAnchor(lastControl)
		local label = self.control:GetNamedChild("Label")
		label:SetText(self:GetString(self:GetValueOrCallback(self.labelText)))
		self.control:SetHeight(label:GetTextHeight() + 4)
	end,
	[LibHarvensAddonSettings.ST_COLOR] = function(self, lastControl)
		self:SetAnchor(lastControl)
		local label = self.control:GetNamedChild("Name")
		label:SetText(self:GetString(self:GetValueOrCallback(self.labelText)))
		self.control:GetNamedChild("Color"):SetColor(self.getFunction())
		return self.control
	end,
	[LibHarvensAddonSettings.ST_ICONPICKER] = function(self, lastControl)
		self:SetAnchor(lastControl)
		self.control:GetNamedChild("Name"):SetText(self:GetString(self:GetValueOrCallback(self.labelText)))
		local value = self.getFunction() or 1
		self.control.items = self:GetValueOrCallback(self.items)
		self.control:SetValue(value)
		local function OnIconPickerClicked()
			HarvensAddonSettingsIconPickerDialog.setting = self
			ZO_Dialogs_ShowDialog("LibHarvensAddonSettingsIconPicker")
		end
		self.control.checkBox:SetHandler("OnClicked", OnIconPickerClicked)
	end
}

local createControlFunctions = {
	[LibHarvensAddonSettings.ST_CHECKBOX] = function(self, lastControl)
		self.control, self.controlKey = LibHarvensAddonSettings.checkboxPool:AcquireObject()
		self.control.data = self.control.data or ZO_Object:New(self)
		updateControlFunctions[LibHarvensAddonSettings.ST_CHECKBOX](self, lastControl)

		ZO_CheckButton_SetToggleFunction(
			self.control:GetNamedChild("Checkbox"),
			function(control, state)
				if state then
					control:GetParent():GetNamedChild("Name"):SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGB())
				else
					control:GetParent():GetNamedChild("Name"):SetColor(ZO_DEFAULT_DISABLED_COLOR:UnpackRGB())
				end
				self:ValueChanged(state)
			end
		)
	end,
	[LibHarvensAddonSettings.ST_SLIDER] = function(self, lastControl)
		self.control, self.controlKey = LibHarvensAddonSettings.sliderPool:AcquireObject()
		self.control.data = self.control.data or ZO_Object:New(self)
		local slider = self.control.slider or self.control:GetNamedChild("Slider")
		self.control.slider = slider
		-- Reset the template (ZO_Options_Slider) before calling InitializeControl
		slider:SetHandler("OnValueChanged", nil)
		updateControlFunctions[LibHarvensAddonSettings.ST_SLIDER](self, lastControl)
		slider:SetHandler("OnValueChanged", function(control, value)
				local formattedValue = tonumber(string.format(self.format, value))
				if self.unit and #self.unit > 0 then
					control.label:SetText(formattedValue .. self:GetString(self:GetValueOrCallback(self.unit)))
				else
					control.label:SetText(formattedValue)
				end
				self:ValueChanged(formattedValue)
		end)
	end,
	[LibHarvensAddonSettings.ST_BUTTON] = function(self, lastControl)
		self.control, self.controlKey = LibHarvensAddonSettings.buttonPool:AcquireObject()
		self.control.data = self.control.data or ZO_Object:New(self)
		updateControlFunctions[LibHarvensAddonSettings.ST_BUTTON](self, lastControl)
		local button = self.control:GetNamedChild("Button")
		button:SetHandler("OnClicked", function(...) self:ValueChanged(...) end)
		self.button = button
	end,
	[LibHarvensAddonSettings.ST_EDIT] = function(self, lastControl)
		self.control, self.controlKey = LibHarvensAddonSettings.editPool:AcquireObject()
		self.control.data = self.control.data or ZO_Object:New(self)
		updateControlFunctions[LibHarvensAddonSettings.ST_EDIT](self, lastControl)
		local editControl = self.control:GetNamedChild("EditBackdrop"):GetNamedChild("Edit")
		editControl:SetHandler("OnEnter", function(control)
				self:ValueChanged(control:GetText())
				control:LoseFocus()
		end)
		editControl:SetHandler("OnEscape", function(control)
				control:SetText(self.getFunction() or "")
				control:LoseFocus()
		end)
		editControl:SetHandler("OnFocusLost", function(editControl)
				self:ValueChanged(editControl:GetText())
				editControl:SetColor(ZO_NORMAL_TEXT:UnpackRGB())
				editControl:SetText(self.getFunction() or "")
				editControl:SetCursorPosition(0)
		end)
		editControl:SetHandler("OnFocusGained", function(control)
				control:SetColor(ZO_HIGHLIGHT_TEXT:UnpackRGB())
				control:TakeFocus()
		end)
	end,
	[LibHarvensAddonSettings.ST_DROPDOWN] = function(self, lastControl)
		self.control, self.controlKey = LibHarvensAddonSettings.dropdownPool:AcquireObject()
		self.control.data = self.control.data or ZO_Object:New(self)
		updateControlFunctions[LibHarvensAddonSettings.ST_DROPDOWN](self, lastControl)
	end,
	[LibHarvensAddonSettings.ST_LABEL] = function(self, lastControl)
		self.control, self.controlKey = LibHarvensAddonSettings.labelPool:AcquireObject()
		self.control.data = self.control.data or ZO_Object:New(self)
		updateControlFunctions[LibHarvensAddonSettings.ST_LABEL](self, lastControl)
	end,
	[LibHarvensAddonSettings.ST_SECTION] = function(self, lastControl)
		self.control, self.controlKey = LibHarvensAddonSettings.sectionPool:AcquireObject()
		self.control.data = self.control.data or ZO_Object:New(self)
		updateControlFunctions[LibHarvensAddonSettings.ST_SECTION](self, lastControl)
	end,
	[LibHarvensAddonSettings.ST_COLOR] = function(self, lastControl)
		self.control, self.controlKey = LibHarvensAddonSettings.colorPool:AcquireObject()
		self.control.data = self.control.data or ZO_Object:New(self)
		self.control.texture = self.control:GetNamedChild("Color")
		updateControlFunctions[LibHarvensAddonSettings.ST_COLOR](self, lastControl)
		local function OnColorSet(r, g, b, a)
			self:ValueChanged(r, g, b, a)
			self.control.texture:SetColor(self.getFunction())
		end
		self.control:GetNamedChild("ColorSection"):SetHandler("OnMouseUp", function()
				COLOR_PICKER:Show(OnColorSet, self.getFunction())
		end)
		return self.control
	end,
	[LibHarvensAddonSettings.ST_ICONPICKER] = function(self, lastControl)
		self.control, self.controlKey = LibHarvensAddonSettings.iconpickerPool:AcquireObject()
		self.control.data = self.control.data or ZO_Object:New(self)
		updateControlFunctions[LibHarvensAddonSettings.ST_ICONPICKER](self, lastControl)
	end
}

local cleanControlFunctions = {
	[LibHarvensAddonSettings.ST_CHECKBOX] = function(self)
		ZO_CheckButton_SetToggleFunction(self.control:GetNamedChild("Checkbox"), nil)
		LibHarvensAddonSettings.checkboxPool:ReleaseObject(self.controlKey)
	end,
	[LibHarvensAddonSettings.ST_SLIDER] = function(self)
		self.control.slider:SetHandler("OnValueChanged", nil)
		LibHarvensAddonSettings.sliderPool:ReleaseObject(self.controlKey)
	end,
	[LibHarvensAddonSettings.ST_BUTTON] = function(self)
		self.control:GetNamedChild("Button"):SetHandler("OnClicked", nil)
		LibHarvensAddonSettings.buttonPool:ReleaseObject(self.controlKey)
	end,
	[LibHarvensAddonSettings.ST_EDIT] = function(self)
		local editControl = self.control:GetNamedChild("EditBackdrop"):GetNamedChild("Edit")
		editControl:SetHandler("OnEnter", nil)
		editControl:SetHandler("OnEscape", nil)
		editControl:SetHandler("OnFocusLost", nil)
		editControl:SetHandler("OnFocusGained", nil)
		LibHarvensAddonSettings.editPool:ReleaseObject(self.controlKey)
	end,
	[LibHarvensAddonSettings.ST_DROPDOWN] = function(self)
		local combobox = self.control:GetDropDown()
		combobox:ClearItems()
		LibHarvensAddonSettings.dropdownPool:ReleaseObject(self.controlKey)
	end,
	[LibHarvensAddonSettings.ST_LABEL] = function(self)
		self.control:GetNamedChild("Name"):SetText(nil)
		LibHarvensAddonSettings.labelPool:ReleaseObject(self.controlKey)
	end,
	[LibHarvensAddonSettings.ST_SECTION] = function(self)
		self.control:GetNamedChild("Label"):SetText(nil)
		LibHarvensAddonSettings.sectionPool:ReleaseObject(self.controlKey)
	end,
	[LibHarvensAddonSettings.ST_COLOR] = function(self)
		self.control:GetNamedChild("Name"):SetText(nil)
		self.control:GetNamedChild("ColorSection"):SetHandler("OnMouseUp", nil)
		LibHarvensAddonSettings.colorPool:ReleaseObject(self.controlKey)
	end,
	[LibHarvensAddonSettings.ST_ICONPICKER] = function(self)
		self.control.iconControl:SetTexture(nil)
		self.control.checkBox:SetHandler("OnClicked", nil)
		self.control.items = nil
		LibHarvensAddonSettings.iconpickerPool:ReleaseObject(self.controlKey)
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
	end,
	[LibHarvensAddonSettings.ST_ICONPICKER] = function(self, params)
		self.items = params.items
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

function LibHarvensAddonSettings.AddonSettingsControl:SetupTooltip(control)
	control:SetHandler(
		"OnMouseEnter",
		function(sender, ...)
			local exitHandler = self.tooltipText(self, sender)
			self.control:SetHandler(
				"OnMouseExit",
				function(sender, ...)
					if type(exitHandler) == "function" then
						exitHandler(self, sender)
					else
						for _, tooltip in ipairs(TOOLTIPS) do
							ClearTooltip(tooltip)
						end
					end

					if self.OnMouseExitOriginal then
						self.OnMouseExitOriginal(sender, ...)
					end
				end
			)
		end
	)
end

function LibHarvensAddonSettings.AddonSettingsControl:SetEnabled(state)
	if self.control and changeControlStateFunctions[self.type] then
		changeControlStateFunctions[self.type](self.control, state)
	end
end

function LibHarvensAddonSettings.AddonSettingsControl:UpdateControl(lastControl)
	if self.control == nil then
		return self:CreateControl(lastControl)
	end

	local updateFunc = updateControlFunctions[self.type]
	if self.control and updateFunc then
		updateFunc(self, lastControl)
	end

	self:SetEnabled(not self:IsDisabled())

	return self.control
end

function LibHarvensAddonSettings.AddonSettingsControl:CleanUp()
	self.control:SetHandler("OnMouseEnter", self.OnMouseEnterOriginal)
	self.control:SetHandler("OnMouseExit", self.OnMouseExitOriginal)

	self:SetEnabled(true)

	if cleanControlFunctions[self.type] then
		cleanControlFunctions[self.type](self)
	end
end

function LibHarvensAddonSettings.AddonSettingsControl:CreateControl(lastControl)
	if createControlFunctions[self.type] then
		createControlFunctions[self.type](self, lastControl)
	end

	self.OnMouseEnterOriginal = self.control:GetHandler("OnMouseEnter")
	self.OnMouseExitOriginal = self.control:GetHandler("OnMouseExit")

	-- Attach tooltip
	if type(self.tooltipText) == "function" then
		self:SetupTooltip(self.control)
	elseif self.tooltipText and #self.tooltipText > 0 then
		self.control:SetHandler("OnMouseEnter", function(...)
				InitializeTooltip(InformationTooltip, self.control, BOTTOMLEFT, 0, 0, TOPLEFT)
				SetTooltipText(InformationTooltip, self.tooltipText, ZO_TOOLTIP_INSTRUCTIONAL_COLOR)
				if self.OnMouseEnterOriginal then
					self.OnMouseEnterOriginal(...)
				end
		end)
		self.control:SetHandler("OnMouseExit", function(...)
				ClearTooltip(InformationTooltip)
				if self.OnMouseExitOriginal then
					self.OnMouseExitOriginal(...)
				end
		end)
	end

	self:SetEnabled(not self:IsDisabled())

	return self.control
end

-----
-- AddonSettings class - represents addon settings panel
-----
function LibHarvensAddonSettings.AddonSettings:AddToOptionsPanel(panelID)
	self.control.data = {
		panel = panelID,
		controlType = OPTIONS_CUSTOM,
		customResetToDefaultsFunction = function()
			self:ResetToDefaults()
		end,
		visible = true,
		system = SETTING_TYPE_UI,
		settingsId = 0
	}
	ZO_OptionsWindow_InitializeControl(self.control)
end

function LibHarvensAddonSettings.AddonSettings:InitHandlers()
	local label = self.control:GetNamedChild("Label")
	label:SetText(self.name)

	self.control:SetResizeToFitDescendents(false)
	self.control:SetHeight(label:GetHeight())
	self.control:SetWidth(label:GetWidth())

	self.control:SetMouseEnabled(true)
	self.control:SetHandler(
		"OnMouseUp",
		function(control, isInside)
			if not isInside or self.selected then
				return
			end
			PlaySound(SOUNDS.DEFAULT_CLICK)

			self:Select()
		end
	)
	self.control:SetHandler(
		"OnMouseEnter",
		function(control)
			self.mouseOver = true
			self:UpdateHighlight()
		end
	)
	self.control:SetHandler(
		"OnMouseExit",
		function(control)
			self.mouseOver = false
			self:UpdateHighlight()
		end
	)
	self:UpdateHighlight()

	CALLBACK_MANAGER:RegisterCallback(
		"LibHarvensAddonSettings_AddonSelected",
		function(_, title)
			if self.selected then
				self:CleanUp()
				self.selected = false
				if self.prev and self.prev ~= title then
					self.control:ClearAnchors()
					self.control:SetAnchor(TOPLEFT, self.prev.control, BOTTOMLEFT, 0, 8)
				end
				if self.next and self.next ~= title then
					self.next.control:ClearAnchors()
					self.next.control:SetAnchor(TOPLEFT, self.control, BOTTOMLEFT, 0, 8)
				end
				self:UpdateHighlight()
			end
		end
	)
end

function LibHarvensAddonSettings.AddonSettings:CreateControls()
	local last = LibHarvensAddonSettings.container
	local hasDefaults = false
	for i = 1, #self.settings do
		last = self.settings[i]:CreateControl(last)
		hasDefaults = hasDefaults or self.settings[i].default ~= nil
	end
	self.hasDefaults = hasDefaults
	needUpdate = false
end

function LibHarvensAddonSettings.AddonSettings:UpdateControls()
	local last = LibHarvensAddonSettings.container
	for i = 1, #self.settings do
		last = self.settings[i]:UpdateControl(last)
	end
	needUpdate = false
end

----- end -----

function LibHarvensAddonSettings:SetContainerHeightPercentage(progress)
	self.container.currentHeight = self.container.endHeight * progress
	self.container:SetHeight(self.container.currentHeight)
end

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

local function PoolCreateControlBase(name, pool)
	local id = pool:GetNextControlId()
	local controlNamespace = name .. id

	local control = WINDOW_MANAGER:CreateControl(controlNamespace, LibHarvensAddonSettings.container, CT_CONTROL)
	control:SetMouseEnabled(true)
	control:SetDimensions(510, 26)

	local label = WINDOW_MANAGER:CreateControl("$(parent)Name", control, CT_LABEL)
	label:SetFont("ZoFontWinH4")
	label:SetDimensions(300, 26)
	label:SetAnchor(LEFT, control, LEFT, 0, 0)
	label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
	return control, id
end

local function ButtonPoolCreateButton(pool)
	local control, id = PoolCreateControlBase("HarvensAddonSettingsButton", pool)
	local button = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)Button", control, "ZO_DefaultButton")
	button:SetAnchor(RIGHT, control, RIGHT, 0, 0)
	button:SetDimensions(200, 26)
	return control, id
end

local function EditPoolCreateEdit(pool)
	local control, id = PoolCreateControlBase("HarvensAddonSettingsEdit", pool)

	local editBackdrop = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)EditBackdrop", control, "ZO_EditBackdrop")
	editBackdrop:SetDimensions(200, 26)
	editBackdrop:SetAnchor(RIGHT, control, RIGHT, 0, 0)

	local editBox = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)Edit", editBackdrop, "ZO_DefaultEditForBackdrop")
	editBox:SetFont("ZoFontWinH4")
	editBox:SetAllowMarkupType(ALLOW_MARKUP_TYPE_NONE)
	control.editBox = editBox

	function control:SetValue(value)
		editBox:SetText(value)
	end
	return control, id
end

local function LabelPoolCreateLabel(pool)
	local control, id = PoolCreateControlBase("HarvensAddonSettingsLabel", pool)
	control:GetNamedChild("Name"):SetDimensions(510, 0)
	return control, id
end

local function IconPickerPoolCreate(pool)
	local control, id = PoolCreateControlBase("HarvensAddonSettingsIconPicker", pool)
	local button = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)Button", control, "ZO_GuildRank_RankIconPickerIcon_Keyboard_Control")
	control:SetHeight(button:GetHeight())
	button:SetAnchor(LEFT, control, RIGHT, -208, 0)
	control.button = button
	control.checkBox = button:GetNamedChild("IconContainerFrame")
	control.iconControl = button:GetNamedChild("IconContainerIcon")
	function control:SetValue(index)
		self.iconControl:SetTexture(control.items and control.items[index])
	end
	return control, id
end

local function OptionsWindowFragmentStateChangeRefresh(oldState, newState)
	if newState == SCENE_FRAGMENT_HIDING then
		needUpdate = true
	elseif newState == SCENE_FRAGMENT_SHOWING then
		if needUpdate and currentSettings ~= nil then
			LibHarvensAddonSettings:RefreshAddonSettings()
		elseif #LibHarvensAddonSettings.addons == 1 then
			LibHarvensAddonSettings:SelectFirstAddon()
		end
	end
end

function LibHarvensAddonSettings:CreateAddonSettingsPanel()
	local title = GetString(SI_GAME_MENU_ADDONS)
	if LibAddonMenu2 then
		title = title .. " 2"
	end
	ZO_OptionsWindow_AddUserPanel("HarvensAddonSettingsPanel", title, PANEL_TYPE_SETTINGS)
	self.panelID = _G["HarvensAddonSettingsPanel"]

	self.container = WINDOW_MANAGER:CreateControl("LibHarvensAddonSettingsContainer", GuiRoot, CT_SCROLL)
	self.container:SetDimensions(550, 0)
	self.container:SetHidden(true)
	self.container.currentHeight = 0
	self.container.endHeight = 0
	--self.container:ClearClips()

	self.openTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TreeOpenAnimation")
	local anim = self.openTimeline:GetFirstAnimation()
	anim:SetUpdateFunction( function(animation, progress) self:SetContainerHeightPercentage(progress) end)
	anim:SetEasingFunction(ZO_EaseOutQuadratic)

	CALLBACK_MANAGER:RegisterCallback("LibHarvensAddonSettings_AddonSelected", function(_, addonSettings)
			currentSettings = addonSettings
			addonSettings:CreateControls()
			self.container.endHeight = addonSettings:GetOverallHeight() + 8
			self.openTimeline:PlayFromStart()
	end)

	local orgUpdatePanelVisibility = ZO_KeyboardOptions.UpdatePanelVisibility
	function ZO_KeyboardOptions.UpdatePanelVisibility(...)
		local options, panelId = ...
		if panelId == self.panelID then
			options.control:GetNamedChild("Settings"):SetHidden(false)
		end
		return orgUpdatePanelVisibility(...)
	end
end

function LibHarvensAddonSettings:CreateControlPools()
	local function extendFactory(pool, func)
		local orgFactory = pool.m_Factory
		pool.m_Factory = function(...)
			local control = orgFactory(...)
			func(control)
			return control
		end
	end
	self.checkboxPool = ZO_ControlPool:New("ZO_Options_Checkbox", self.container, "Checkbox")
	extendFactory(
		self.checkboxPool,
		function(control)
			function control:SetValue(checked)
				if checked then
					ZO_CheckButton_SetChecked(self:GetNamedChild("Checkbox"))
					self:GetNamedChild("Name"):SetColor(1, 1, 1, 1)
				else
					ZO_CheckButton_SetUnchecked(self:GetNamedChild("Checkbox"))
					self:GetNamedChild("Name"):SetColor(0.3, 0.3, 0.3, 1)
				end
			end
		end
	)
	self.sliderPool = ZO_ControlPool:New("ZO_Options_Slider", self.container, "Slider")
	extendFactory(
		self.sliderPool,
		function(control)
			function control:SetValue(...)
				self.slider:SetValue(...)
			end
		end
	)
	self.buttonPool = ZO_ObjectPool:New(ButtonPoolCreateButton, ZO_ObjectPool_DefaultResetControl)
	self.editPool = ZO_ObjectPool:New(EditPoolCreateEdit, ZO_ObjectPool_DefaultResetControl)
	self.dropdownPool = ZO_ControlPool:New("ZO_Options_Dropdown", self.container, "Dropdown")
	local function comboboxSetup(control)
		control.dropdown = control:GetNamedChild("Dropdown")
		local combobox = ZO_ComboBox_ObjectFromContainer(control.dropdown)
		local popup = combobox.m_dropdown
		ZO_PreHook(combobox, "AddMenuItems", function(combobox)
				local items = combobox.m_sortedItems
				local width = control.dropdown:GetWidth()
				for i = 1, #items do
					width = math.max(width, ZO_LabelUtils_GetTextDimensions(items[i].name or "", "ZoFontGame") + 36)
				end
				popup:SetWidth(width)
		end)
		popup:ClearAnchors()
		popup:SetAnchor(TOPRIGHT, nil, BOTTOMRIGHT)
		popup:SetDrawTier(DT_HIGH)
		function control:SetValue(...)
			local combobox = self:GetDropDown()
			combobox:SetSelectedItem(...)
		end
		function control:GetDropDown()
			return ZO_ComboBox_ObjectFromContainer(self.dropdown)
		end
	end
	extendFactory(self.dropdownPool, comboboxSetup)
	self.labelPool = ZO_ObjectPool:New(LabelPoolCreateLabel, ZO_ObjectPool_DefaultResetControl)
	self.sectionPool = ZO_ControlPool:New("ZO_Options_SectionTitle_WithDivider", self.container, "SectionLabel")
	self.colorPool = ZO_ControlPool:New("ZO_Options_Color", self.container, "Color")
	extendFactory(
		self.colorPool,
		function(control)
			function control:SetValue(...)
				self.texture:SetColor(...)
			end
		end
	)

	self.iconpickerPool = ZO_ObjectPool:New(IconPickerPoolCreate, ZO_ObjectPool_DefaultResetControl)
	local dialog = HarvensAddonSettingsIconPickerDialog
	dialog.iconPickerGridListControl = dialog:GetNamedChild("IconPickerContainerPanel")
	dialog.iconPicker = ZO_GridScrollList_Keyboard:New(dialog.iconPickerGridListControl)
	local function iconPickerEntrySetup(control, item)
		local iconContainer = control:GetNamedChild("IconContainer")
		local checkButton = iconContainer:GetNamedChild("Frame")

		local isCurrent = item.index == item.data.getFunction()

		local function OnClick()
			item.data.setFunction(control, item.index, item.icon)
			item.data.control:SetValue(item.index)
		end

		iconContainer:GetNamedChild("Icon"):SetTexture(item.icon)
		ZO_CheckButton_SetCheckState(checkButton, isCurrent)
		ZO_CheckButton_SetToggleFunction(checkButton, OnClick)
	end
	dialog.iconPicker:AddEntryTemplate("ZO_GuildRank_RankIconPickerIcon_Keyboard_Control", 60, 60, iconPickerEntrySetup, nil, nil, 0, 0)

	ZO_Dialogs_RegisterCustomDialog(
		"LibHarvensAddonSettingsIconPicker",
		{
			title = {
				text = function()
					local data = dialog.setting
					return data:GetString(data:GetValueOrCallback(data.labelText))
				end
			},
			mainText = {
				text = ""
			},
			setup = function()
				dialog.iconPicker:ClearGridList()

				local data = dialog.setting
				local items = data:GetValueOrCallback(data.items)
				for i = 1, #items do
					local item = {
						index = i,
						icon = items[i],
						data = data
					}
					dialog.iconPicker:AddEntry(item, "ZO_GuildRank_RankIconPickerIcon_Keyboard_Control")
				end

				dialog.iconPicker:CommitGridList()
			end,
			customControl = dialog,
			buttons = {
				[1] = {
					control = dialog:GetNamedChild("Close"),
					text = SI_DIALOG_CLOSE
				}
			}
		}
	)
end

function LibHarvensAddonSettings:CreateAddonList()
	table.sort(LibHarvensAddonSettings.addons, function(el1, el2)
			return el1.name < el2.name
	end)

	local control, template
	local prev = nil
	for i = 1, #LibHarvensAddonSettings.addons do
		template = i > 1 and "ZO_Options_SectionTitle_WithDivider" or "ZO_Options_SectionTitle"
		control = WINDOW_MANAGER:CreateControlFromVirtual("LibHarvensAddonSettingsAddon" .. LibHarvensAddonSettings.addons[i].name .. "Name", ZO_OptionsWindowSettingsScrollChild, template)

		LibHarvensAddonSettings.addons[i].control = control
		control.addonSettings = LibHarvensAddonSettings.addons[i]
		LibHarvensAddonSettings.addons[i]:InitHandlers()
		LibHarvensAddonSettings.addons[i]:SetAnchor(prev)

		prev = LibHarvensAddonSettings.addons[i]
		LibHarvensAddonSettings.addons[i]:AddToOptionsPanel(LibHarvensAddonSettings.panelID)
	end
	if prev ~= nil then
		OPTIONS_WINDOW_FRAGMENT:RegisterCallback("StateChange", OptionsWindowFragmentStateChangeRefresh)
	end
end

local function OptionsWindowFragmentStateChange(oldState, newState)
	if newState ~= SCENE_SHOWING then
		return
	end

	GAME_MENU_SCENE:UnregisterCallback("StateChange", OptionsWindowFragmentStateChange)

	LibHarvensAddonSettings:Initialize()
end

GAME_MENU_SCENE:RegisterCallback("StateChange", OptionsWindowFragmentStateChange)
