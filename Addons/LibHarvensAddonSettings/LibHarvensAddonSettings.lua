local version = 10900

if LibHarvensAddonSettings then return end

LibHarvensAddonSettings = {}
LibHarvensAddonSettings.version = version
local LibHarvensAddonSettings = LibHarvensAddonSettings

-----
-- Control Types
-----
LibHarvensAddonSettings.ST_CHECKBOX = 1
LibHarvensAddonSettings.ST_SLIDER = 2
LibHarvensAddonSettings.ST_EDIT = 3
LibHarvensAddonSettings.ST_DROPDOWN = 4
LibHarvensAddonSettings.ST_COLOR = 5
LibHarvensAddonSettings.ST_BUTTON = 6
LibHarvensAddonSettings.ST_LABEL = 7
LibHarvensAddonSettings.ST_SECTION = 8
-----

LibHarvensAddonSettings.addons = { }

local AddonSettings = ZO_Object:Subclass()
local AddonSettingsControl = ZO_Object:Subclass()

LibHarvensAddonSettings.AddonSettings = AddonSettings
LibHarvensAddonSettings.AddonSettingsControl = AddonSettingsControl

local TOOLTIPS =
{
	ItemTooltip,
	InformationTooltip,
	GameTooltip,
	AbilityTooltip,
	AchievementTooltip,
	KeepUpgradeTooltip,
	PopupTooltip,
	SkillTooltip,
}

local currentSettings
local needUpdate = true

-----
-- Control specific functions tables
-----
local ALPHA_STATES =
{
	[true] = 1,
	[false] = 0.5,
}

local function GetAlphaFromState(state)
	return ALPHA_STATES[state]
end

local changeControlStateFunctions = {
	[LibHarvensAddonSettings.ST_CHECKBOX] = function(control, state)
		local boxControl = GetControl(control, "Checkbox")
		if state == false then
			ZO_CheckButton_Disable(boxControl)
		else
			ZO_CheckButton_Enable(boxControl)
		end
		boxControl:SetAlpha(GetAlphaFromState(state))
	end,
	[LibHarvensAddonSettings.ST_DROPDOWN] = function(control, state)
		local dropdown = control.dropdown
		if state == false then
			ZO_ComboBox_Disable(dropdown)
		else
			ZO_ComboBox_Enable(dropdown)
		end
		local alpha = GetAlphaFromState(state)
		GetControl(dropdown, "SelectedItemText"):SetAlpha(alpha)
		GetControl(dropdown, "BG"):SetAlpha(alpha)
		GetControl(dropdown, "OpenDropdown"):SetAlpha(alpha)
	end,
	[LibHarvensAddonSettings.ST_SLIDER] = function(control, state)
		GetControl(control, "Slider"):SetEnabled(state)
		local alpha = GetAlphaFromState(state)
		GetControl(control, "SliderBackdrop"):SetAlpha(alpha)
		GetControl(control, "ValueLabel"):SetAlpha(alpha)
	end,
	[LibHarvensAddonSettings.ST_BUTTON] = function(control, state)
		GetControl(control, "Button"):SetEnabled(state)
	end,
	[LibHarvensAddonSettings.ST_EDIT] = function(control, state)
		local editBackdrop = GetControl(control, "EditBackdrop")
		editBackdrop:SetAlpha(GetAlphaFromState(state))
		GetControl(editBackdrop, "Edit"):SetEditEnabled(state)
	end,
	[LibHarvensAddonSettings.ST_COLOR] = function(control, state)
		local color = GetControl(control, "ColorSection")
		color:SetMouseEnabled(state)
		color:SetAlpha(GetAlphaFromState(state))
	end
}

local updateControlFunctions = {
	[LibHarvensAddonSettings.ST_CHECKBOX] = function(self, lastControl)
		self:SetAnchor(lastControl)
		self.control:GetNamedChild("Name"):SetText(self:GetValueOrCallback(self.labelText))

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
		GetControl(self.control, "Name"):SetText(self:GetValueOrCallback(self.labelText))
		local slider = GetControl(self.control, "Slider")
		slider:SetMinMax(self.min, self.max)
		slider:SetValue(self.getFunction())
		local label = GetControl(self.control, "ValueLabel")
		local value = self.getFunction() or "0"
		if self.unit and #self.unit > 0 then
			label:SetText(value .. self:GetValueOrCallback(self.unit))
		else
			label:SetText(value)
		end
		slider:SetValueStep(self.step)
		slider.label = label
	end,
	[LibHarvensAddonSettings.ST_BUTTON] = function(self, lastControl)
		self.control:SetHidden(false)
		self:SetAnchor(lastControl)
		GetControl(self.control, "Name"):SetText(self:GetValueOrCallback(self.labelText))
		local button = GetControl(self.control, "Button")
		button:SetText(self:GetValueOrCallback(self.buttonText))
	end,
	[LibHarvensAddonSettings.ST_EDIT] = function(self, lastControl)
		self.control:SetHidden(false)
		self:SetAnchor(lastControl)
		GetControl(self.control, "Name"):SetText(self:GetValueOrCallback(self.labelText))
		local editControl = self.control:GetNamedChild("EditBackdrop"):GetNamedChild("Edit")
		editControl:SetTextType(self.textType or TEXT_TYPE_ALL)
		editControl:SetMaxInputChars(self.maxInputChars or MAX_HELP_DESCRIPTION_BODY)
		editControl:SetText(self.getFunction() or "")
		editControl:SetColor(ZO_NORMAL_TEXT:UnpackRGB())
	end,
	[LibHarvensAddonSettings.ST_DROPDOWN] = function(self, lastControl)
		self:SetAnchor(lastControl)
		GetControl(self.control, "Name"):SetText(self:GetValueOrCallback(self.labelText))
		local combobox = ZO_ComboBox_ObjectFromContainer(self.control.dropdown)
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
		local label = GetControl(self.control, "Name")
		label:SetText(self:GetValueOrCallback(self.labelText))
		self.control:SetHeight(label:GetTextHeight())
	end,
	[LibHarvensAddonSettings.ST_SECTION] = function(self, lastControl)
		self:SetAnchor(lastControl)
		local label = GetControl(self.control, "Label")
		label:SetText(self:GetValueOrCallback(self.labelText))
		self.control:SetHeight(label:GetTextHeight() + 4)
	end,
	[LibHarvensAddonSettings.ST_COLOR] = function(self, lastControl)
		self:SetAnchor(lastControl)
		local label = GetControl(self.control, "Name")
		label:SetText(self:GetValueOrCallback(self.labelText))
		self.control:GetNamedChild("Color"):SetColor(self.getFunction())
		return self.control
	end,
}

local createControlFunctions = {
	[LibHarvensAddonSettings.ST_CHECKBOX] = function(self, lastControl)
		self.control, self.controlKey = LibHarvensAddonSettings.checkboxPool:AcquireObject()
		self.control.data = ZO_Object:New(self)
		updateControlFunctions[LibHarvensAddonSettings.ST_CHECKBOX](self, lastControl)

		ZO_CheckButton_SetToggleFunction(self.control:GetNamedChild("Checkbox"), function(control, state)
			if state then
				control:GetParent():GetNamedChild("Name"):SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGB())
			else
				control:GetParent():GetNamedChild("Name"):SetColor(ZO_DEFAULT_DISABLED_COLOR:UnpackRGB())
			end
			self:ValueChanged(state)
		end)
	end,
	[LibHarvensAddonSettings.ST_SLIDER] = function(self, lastControl)
		self.control, self.controlKey = LibHarvensAddonSettings.sliderPool:AcquireObject()
		self.control.data = ZO_Object:New(self)
		local slider = GetControl(self.control, "Slider")
		-- Reset the template (ZO_Options_Slider) before calling InitializeControl
		slider:SetHandler("OnValueChanged", nil)
		ZO_SharedOptions:InitializeControl(self.control, nil)
		updateControlFunctions[LibHarvensAddonSettings.ST_SLIDER](self, lastControl)
		slider:SetHandler("OnValueChanged", function(control, value)
			local formattedValue = tonumber(string.format(self.format, value))
			if self.unit and #self.unit > 0 then
				control.label:SetText(formattedValue .. self:GetValueOrCallback(self.unit))
			else
				control.label:SetText(formattedValue)
			end
			self:ValueChanged(formattedValue)
		end)
	end,
	[LibHarvensAddonSettings.ST_BUTTON] = function(self, lastControl)
		self.control, self.controlKey = LibHarvensAddonSettings.buttonPool:AcquireObject()
		self.control.data = ZO_Object:New(self)
		updateControlFunctions[LibHarvensAddonSettings.ST_BUTTON](self, lastControl)
		local button = GetControl(self.control, "Button")
		button:SetHandler("OnClicked", function(...) self:ValueChanged(...) end)
		self.button = button
	end,
	[LibHarvensAddonSettings.ST_EDIT] = function(self, lastControl)
		self.control, self.controlKey = LibHarvensAddonSettings.editPool:AcquireObject()
		self.control.data = ZO_Object:New(self)
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
		self.control.data = ZO_Object:New(self)
		updateControlFunctions[LibHarvensAddonSettings.ST_DROPDOWN](self, lastControl)
	end,
	[LibHarvensAddonSettings.ST_LABEL] = function(self, lastControl)
		self.control, self.controlKey = LibHarvensAddonSettings.labelPool:AcquireObject()
		self.control.data = ZO_Object:New(self)
		updateControlFunctions[LibHarvensAddonSettings.ST_LABEL](self, lastControl)
	end,
	[LibHarvensAddonSettings.ST_SECTION] = function(self, lastControl)
		self.control, self.controlKey = LibHarvensAddonSettings.sectionPool:AcquireObject()
		self.control.data = ZO_Object:New(self)
		updateControlFunctions[LibHarvensAddonSettings.ST_SECTION](self, lastControl)
	end,
	[LibHarvensAddonSettings.ST_COLOR] = function(self, lastControl)
		self.control, self.controlKey = LibHarvensAddonSettings.colorPool:AcquireObject()
		self.control.data = ZO_Object:New(self)
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
}

local cleanControlFunctions = {
	[LibHarvensAddonSettings.ST_CHECKBOX] = function(self)
		ZO_CheckButton_SetToggleFunction(self.control:GetNamedChild("Checkbox"), nil)
		LibHarvensAddonSettings.checkboxPool:ReleaseObject(self.controlKey)
	end,
	[LibHarvensAddonSettings.ST_SLIDER] = function(self)
		GetControl(self.control, "Slider"):SetHandler("OnValueChanged", nil)
		LibHarvensAddonSettings.sliderPool:ReleaseObject(self.controlKey)
	end,
	[LibHarvensAddonSettings.ST_BUTTON] = function(self)
		GetControl(self.control, "Button"):SetHandler("OnClicked", nil)
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
		local combobox = ZO_ComboBox_ObjectFromContainer(self.control.dropdown)
		combobox:ClearItems()
		LibHarvensAddonSettings.dropdownPool:ReleaseObject(self.controlKey)
	end,
	[LibHarvensAddonSettings.ST_LABEL] = function(self)
		GetControl(self.control, "Name"):SetText(nil)
		LibHarvensAddonSettings.labelPool:ReleaseObject(self.controlKey)
	end,
	[LibHarvensAddonSettings.ST_SECTION] = function(self)
		GetControl(self.control, "Label"):SetText(nil)
		LibHarvensAddonSettings.sectionPool:ReleaseObject(self.controlKey)
	end,
	[LibHarvensAddonSettings.ST_COLOR] = function(self)
		GetControl(self.control, "Name"):SetText(nil)
		self.control:GetNamedChild("ColorSection"):SetHandler("OnMouseUp", nil)
		LibHarvensAddonSettings.colorPool:ReleaseObject(self.controlKey)
	end,
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
}
-----

-----
-- AddonSettingsControl class - represents single option control
-----
function AddonSettingsControl:New(callbackManager, type)
	local object = ZO_Object.New(self)
	object.type = type
	object.callbackManager = callbackManager
	if object.callbackManager then
		object.callbackManager:RegisterCallback("ValueChanged", object.SettingValueChangedCallback, object)
	end
	return object
end

function AddonSettingsControl:SetupControl(params)
	if setupControlFunctions[self.type] then
		setupControlFunctions[self.type](self, params)
	end
end

function AddonSettingsControl:IsDisabled()
	return(self.disable == true) or(type(self.disable) == "function" and self.disable())
end

function AddonSettingsControl:SettingValueChangedCallback(changedSetting)
	if self == changedSetting then
		return
	end

	if self.getFunction then
		self:SetValue(self.getFunction())
	end

	if self.type == LibHarvensAddonSettings.ST_LABEL or self.type == LibHarvensAddonSettings.ST_SECTION then
		return
	end

	self:SetEnabled(not self:IsDisabled())
end

function AddonSettingsControl:SetEnabled(state)
	if self.type ~= LibHarvensAddonSettings.ST_CHECKBOX then
		local nameControl = GetControl(self.control, "Name")
		if not nameControl then
			nameControl = GetControl(self.control, "Label")
		end

		if nameControl then
			if state then
				nameControl:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGB())
			else
				nameControl:SetColor(ZO_DEFAULT_DISABLED_COLOR:UnpackRGB())
			end
		end
	end

	if changeControlStateFunctions[self.type] then
		changeControlStateFunctions[self.type](self.control, state)
	end
end

function AddonSettingsControl:SetAnchor(lastControl)
	self.control:ClearAnchors()
	if lastControl == LibHarvensAddonSettings.container then
		self.control:SetAnchor(TOPLEFT, lastControl, TOPLEFT, 0, 8)
	else
		self.control:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT, 0, 8)
	end

end

function AddonSettingsControl:ValueChanged(...)
	if type(self.setFunction) == "function" then
		self.setFunction(...)
	elseif type(self.clickHandler) == "function" then
		self.clickHandler(...)
	end
	if self.callbackManager then
		self.callbackManager:FireCallbacks("ValueChanged", self)
	end
end

function AddonSettingsControl:SetupTooltip(control)
	control:SetHandler("OnMouseEnter", function(sender, ...)
		local exitHandler = self.tooltipText(self, sender)
		self.control:SetHandler("OnMouseExit", function(sender, ...)
			if type(exitHandler) == "function" then
				exitHandler(self, sender)
			else
				for _, tooltip in ipairs(TOOLTIPS) do
					ClearTooltip(tooltip)
				end
			end

			if self.OnMouseExitOriginal then self.OnMouseExitOriginal(sender, ...) end
		end)
	end)
end

function AddonSettingsControl:CreateControl(lastControl)
	if createControlFunctions[self.type] then
		createControlFunctions[self.type](self, lastControl)
	else
		return lastControl
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

function AddonSettingsControl:GetValueOrCallback(arg)
	if type(arg) == "function" then
		return arg(self)
	else
		return arg
	end
end

function AddonSettingsControl:UpdateControl(lastControl)
	if self.control == nil then
		return self:CreateControl(lastControl)
	end

	if updateControlFunctions[self.type] then
		updateControlFunctions[self.type](self, lastControl)
	end

	self:SetEnabled(not self:IsDisabled())

	return self.control
end

function AddonSettingsControl:CleanUp()
	self.control:SetHandler("OnMouseEnter", self.OnMouseEnterOriginal)
	self.control:SetHandler("OnMouseExit", self.OnMouseExitOriginal)

	self:SetEnabled(true)

	if cleanControlFunctions[self.type] then
		cleanControlFunctions[self.type](self)
	end
end

function AddonSettingsControl:SetValue(...)
	if self.type == LibHarvensAddonSettings.ST_CHECKBOX then
		local checked = ...
		if checked then
			ZO_CheckButton_SetChecked(self.control:GetNamedChild("Checkbox"))
			self.control:GetNamedChild("Name"):SetColor(1, 1, 1, 1)
		else
			ZO_CheckButton_SetUnchecked(self.control:GetNamedChild("Checkbox"))
			self.control:GetNamedChild("Name"):SetColor(0.3, 0.3, 0.3, 1)
		end
	elseif self.type == LibHarvensAddonSettings.ST_SLIDER then
		local slider = GetControl(self.control, "Slider")
		slider:SetValue(...)
	elseif self.type == LibHarvensAddonSettings.ST_EDIT then
		local editControl = self.control:GetNamedChild("EditBackdrop"):GetNamedChild("Edit")
		local value = ...
		editControl:SetText(value)
	elseif self.type == LibHarvensAddonSettings.ST_DROPDOWN then
		local combobox = ZO_ComboBox_ObjectFromContainer(self.control.dropdown)
		combobox:SetSelectedItem(...)
	elseif self.type == LibHarvensAddonSettings.ST_COLOR then
		self.control.texture:SetColor(...)
	end
end

function AddonSettingsControl:ResetToDefaults()
	if self.type == LibHarvensAddonSettings.ST_DROPDOWN then
		self:SetValue(self.default)
		local itemIndex = 1
		for i = 1, #self.items do
			if self.items[i].name == self.default then
				itemIndex = i
				break
			end
		end
		local combobox = ZO_ComboBox_ObjectFromContainer(self.control.dropdown)
		self.setFunction(combobox, self.default, self.items[itemIndex])
	elseif self.type == LibHarvensAddonSettings.ST_COLOR then
		self:SetValue(unpack(self.default))
		self.setFunction(unpack(self.default))
	elseif self.setFunction then
		self:SetValue(self.default)
		self.setFunction(self.default)
	end
end

function AddonSettingsControl:GetHeight()
	return self.control:GetHeight() + 8
end
-----

-----
-- AddonSettings class - represents addon settings panel
-----
function AddonSettings:New(name, options)
	local object = ZO_Object.New(self)
	if type(options) == "table" then
		object.allowDefaults = options.allowDefaults
		object.defaultsFunction = options.defaultsFunction
		if options.allowRefresh then
			object.callbackManager = ZO_CallbackObject:New()
		end
	end
	object.name = name
	object.selected = false
	object.mouseOver = false
	object.settings = { }
	return object
end

function AddonSettings:SetAnchor(prev)
	if prev then
		self.prev = prev
		prev.next = self
		self.control:SetAnchor(TOPLEFT, prev.control, BOTTOMLEFT, 0, 8)
	else
		self.control:SetAnchor(TOPLEFT)
	end
end

function AddonSettings:AddSetting(params)
	local setting = AddonSettingsControl:New(self.callbackManager, params.type)
	table.insert(self.settings, setting)
	setting:SetupControl(params)
	return setting
end

function AddonSettings:AddSettings(params)
	local ret = { }
	for i = 1, #params do
		ret[i] = self:AddSetting(params[i])
	end
	return ret
end

function AddonSettings:Select()
	LibHarvensAddonSettings:DetachContainer()
	CALLBACK_MANAGER:FireCallbacks("LibHarvensAddonSettings_AddonSelected", self.name, self)
	LibHarvensAddonSettings:AttachContainerToControl(self.control)
	if self.prev then
		self.control:ClearAnchors()
		self.control:SetAnchor(TOPLEFT, self.prev.control, BOTTOMLEFT, 0, 8)
	end
	if self.next then
		LibHarvensAddonSettings:AttachControlToContainer(self.next.control)
	end

	self.selected = true
	self:UpdateHighlight()
end

function AddonSettings:InitHandlers()
	local label = GetControl(self.control, "Label")
	label:SetText(self.name)

	self.control:SetResizeToFitDescendents(false)
	self.control:SetHeight(label:GetHeight())
	self.control:SetWidth(label:GetWidth())

	self.control:SetMouseEnabled(true)
	self.control:SetHandler("OnMouseUp", function(control, isInside)
		if not isInside or self.selected then
			return
		end
		PlaySound(SOUNDS.DEFAULT_CLICK)

		self:Select()
	end)
	self.control:SetHandler("OnMouseEnter", function(control)
		self.mouseOver = true
		self:UpdateHighlight()
	end)
	self.control:SetHandler("OnMouseExit", function(control)
		self.mouseOver = false
		self:UpdateHighlight()
	end)
	self:UpdateHighlight()

	CALLBACK_MANAGER:RegisterCallback("LibHarvensAddonSettings_AddonSelected", function(_, title)
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
	end)
end

function AddonSettings:UpdateHighlight()
	if self.selected then
		GetControl(self.control, "Label"):SetColor(ZO_SELECTED_TEXT:UnpackRGB())
	elseif self.mouseOver then
		GetControl(self.control, "Label"):SetColor(ZO_HIGHLIGHT_TEXT:UnpackRGB())
	else
		GetControl(self.control, "Label"):SetColor(ZO_NORMAL_TEXT:UnpackRGB())
	end
end

function AddonSettings:ResetToDefaults()
	if self.selected and self.allowDefaults then
		for i = 1, #self.settings do
			self.settings[i]:ResetToDefaults()
		end
		if type(self.defaultsFunction) == "function" then
			self.defaultsFunction()
		end
	end
end

function AddonSettings:AddToOptionsPanel(panelID)
	self.control.data = {
		panel = panelID,
		controlType = OPTIONS_CUSTOM,
		customResetToDefaultsFunction = function() self:ResetToDefaults() end,
		visible = true,
		system = SETTING_TYPE_UI,
		settingsId = 0
	}
	ZO_OptionsWindow_InitializeControl(self.control)
end

function AddonSettings:CreateControls()
	local last = LibHarvensAddonSettings.container
	for i = 1, #self.settings do
		last = self.settings[i]:CreateControl(last)
	end
	needUpdate = false
end

function AddonSettings:UpdateControls()
	local last = LibHarvensAddonSettings.container
	for i = 1, #self.settings do
		last = self.settings[i]:UpdateControl(last)
	end
	needUpdate = false
end

function AddonSettings:CleanUp()
	for i = 1, #self.settings do
		self.settings[i]:CleanUp()
	end
end

function AddonSettings:GetOverallHeight()
	local sum = 0
	for i = 1, #self.settings do
		sum = sum + self.settings[i]:GetHeight()
	end
	return sum
end
-----

-----
-- LibHarvensAddonSettings singleton
-----
local function RemoveColorMarkup(name)
	name = zo_strgsub(name, "|[Cc][%w][%w][%w][%w][%w][%w]", "")
	name = zo_strgsub(name, "|[Rr]", "")
	return name
end

function LibHarvensAddonSettings:AddAddon(name, options)
	name = RemoveColorMarkup(name)

	for i = 1, #self.addons do
		if self.addons[i].name == name then
			return self.addons[i]
		end
	end
	local addonSettings = AddonSettings:New(name, options)
	table.insert(self.addons, addonSettings)

	return addonSettings
end

function LibHarvensAddonSettings:DetachContainer()
	self.container:ClearAnchors()
	if self.container.attached then
		self.container.attached:ClearAnchors()
		self.container.attached = nil
	end
end

function LibHarvensAddonSettings:AttachControlToContainer(control)
	control:ClearAnchors()
	control:SetAnchor(TOPLEFT, self.container, BOTTOMLEFT, 0, 8)
	self.container.attached = control
end

function LibHarvensAddonSettings:AttachContainerToControl(control)
	self.container:ClearAnchors()
	self.container:SetParent(control)
	self.container:SetAnchor(TOPLEFT, control, BOTTOMLEFT, 0, 0)
	self.container:SetHidden(false)
	self.container:SetHeight(0)
	self.container.currentHeight = 0
end

function LibHarvensAddonSettings:SetContainerHeightPercentage(progress)
	self.container.currentHeight = self.container.endHeight * progress
	self.container:SetHeight(self.container.currentHeight)
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
	return control
end

local function EditPoolCreateEdit(pool)
	local control, id = PoolCreateControlBase("HarvensAddonSettingsEdit", pool)

	local editBackdrop = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)EditBackdrop", control, "ZO_EditBackdrop")
	editBackdrop:SetDimensions(200, 26)
	editBackdrop:SetAnchor(RIGHT, control, RIGHT, 0, 0)

	local editBox = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)Edit", editBackdrop, "ZO_DefaultEditForBackdrop")
	editBox:SetFont("ZoFontWinH4")
	editBox:SetAllowMarkupType(ALLOW_MARKUP_TYPE_NONE)
	return control
end

local function LabelPoolCreateLabel(pool)
	local control, id = PoolCreateControlBase("HarvensAddonSettingsLabel", pool)
	control:GetNamedChild("Name"):SetDimensions(510, 0)
	return control
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

function LibHarvensAddonSettings:CreateAddonSettingsPanel()
	ZO_OptionsWindow_AddUserPanel("HarvensAddonSettingsPanel", GetString(SI_GAME_MENU_ADDONS), PANEL_TYPE_SETTINGS)
	self.panelID = _G["HarvensAddonSettingsPanel"]

	self.container = WINDOW_MANAGER:CreateControl("LibHarvensAddonSettingsContainer", GuiRoot, CT_SCROLL)
	self.container:SetDimensions(550, 0)
	self.container:SetHidden(true)
	self.container.currentHeight = 0
	self.container.endHeight = 0

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
	self.checkboxPool = ZO_ControlPool:New("ZO_Options_Checkbox", self.container, "Checkbox")
	self.sliderPool = ZO_ControlPool:New("ZO_Options_Slider", self.container, "Slider")
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
	end
	self.dropdownPool:SetCustomFactoryBehavior(comboboxSetup)
	self.labelPool = ZO_ObjectPool:New(LabelPoolCreateLabel, ZO_ObjectPool_DefaultResetControl)
	self.sectionPool = ZO_ControlPool:New("ZO_Options_SectionTitle_WithDivider", self.container, "SectionLabel")
	self.colorPool = ZO_ControlPool:New("ZO_Options_Color", self.container, "Color")
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

function LibHarvensAddonSettings:Initialize()
	if self.initialized then return end
	self:CreateAddonSettingsPanel()
	self:CreateControlPools()
	self:CreateAddonList()
	self.initialized = true
end

local function OptionsWindowFragmentStateChange(oldState, newState)
	if newState ~= SCENE_FRAGMENT_SHOWING then
		return
	end

	if LibHarvensAddonSettings.initialized then
		GAME_MENU_SCENE:UnregisterCallback("StateChange", OptionsWindowFragmentStateChange)
		return
	end

	LibHarvensAddonSettings:Initialize()
end

GAME_MENU_SCENE:RegisterCallback("StateChange", OptionsWindowFragmentStateChange)