if LibHarvensAddonSettings then
	error("Library loaded already. Please remove all LibHarvensAddonSettings in sub folders.")
end

LibHarvensAddonSettings = {}
LibHarvensAddonSettings.version = 10901
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

LibHarvensAddonSettings.addons = {}

local AddonSettings = ZO_Object:Subclass()
local AddonSettingsControl = ZO_Object:Subclass()

LibHarvensAddonSettings.AddonSettings = AddonSettings
LibHarvensAddonSettings.AddonSettingsControl = AddonSettingsControl

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

function AddonSettingsControl:IsDisabled()
	return (self.disable == true) or (type(self.disable) == "function" and self.disable())
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

function AddonSettingsControl:SetAnchor(lastControl)
	if IsConsoleUI() then
		return
	end
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
	if not IsConsoleUI() then
		self:SetupTooltip_Keyboard(control)
	end
end

function AddonSettingsControl:CreateControl(lastControl)
	if IsConsoleUI() then
		return self:CreateControl_Gamepad(lastControl)
	else
		return self:CreateControl_Keyboard(lastControl)
	end
end

function AddonSettingsControl:SetupControl(params)
	if IsConsoleUI() then
		self:SetupControl_Gamepad(params)
	else
		self:SetupControl_Keyboard(params)
	end
end

function AddonSettingsControl:SetEnabled(state)
	if IsConsoleUI() then
		return self:SetEnabled_Gamepad(state)
	else
		return self:SetEnabled_Keyboard(state)
	end
end

function AddonSettingsControl:CleanUp()
	if IsConsoleUI() then
		return self:CleanUp_Gamepad()
	else
		return self:CleanUp_Keyboard()
	end
end

function AddonSettingsControl:GetValueOrCallback(arg)
	if type(arg) == "function" then
		return arg(self)
	else
		return arg
	end
end

function AddonSettingsControl:UpdateControl(lastControl)
	if IsConsoleUI() then
		return self:UpdateControl_Gamepad(lastControl)
	else
		return self:UpdateControl_Keyboard(lastControl)
	end
end

function AddonSettingsControl:SetValue(...)
	if not self.control or not self.control.SetValue then
		return
	end
	return self.control:SetValue(...)
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
		local combobox = IsConsoleUI() and self.control.horizontalListObject or ZO_ComboBox_ObjectFromContainer(self.control.dropdown)
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
	object.settings = {}
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
	self.settings[#self.settings + 1] = setting
	setting:SetupControl(params)
	return setting
end

function AddonSettings:AddSettings(params)
	local ret = {}
	for i = 1, #params do
		ret[i] = self:AddSetting(params[i])
	end
	return ret
end

function AddonSettings:Select()
	if self.selected then
		return
	end
	local isConsoleUI = IsConsoleUI()
	if not isConsoleUI then
		LibHarvensAddonSettings:DetachContainer()
	end
	CALLBACK_MANAGER:FireCallbacks("LibHarvensAddonSettings_AddonSelected", self.name, self)

	if not isConsoleUI then
		LibHarvensAddonSettings:AttachContainerToControl(self.control)
		if self.prev then
			self.control:ClearAnchors()
			self.control:SetAnchor(TOPLEFT, self.prev.control, BOTTOMLEFT, 0, 8)
		end
		if self.next then
			LibHarvensAddonSettings:AttachControlToContainer(self.next.control)
		end
	end

	self.selected = true
	self:UpdateHighlight()
end

function AddonSettings:InitHandlers()
	if IsConsoleUI() then
		self:InitHandlers_Gamepad()
	else
		self:InitHandlers_Keyboard()
	end
end

function AddonSettings:UpdateHighlight()
	if IsConsoleUI() then
		return
	end
	if self.selected then
		self.control:GetNamedChild("Label"):SetColor(ZO_SELECTED_TEXT:UnpackRGB())
	elseif self.mouseOver then
		self.control:GetNamedChild("Label"):SetColor(ZO_HIGHLIGHT_TEXT:UnpackRGB())
	else
		self.control:GetNamedChild("Label"):SetColor(ZO_NORMAL_TEXT:UnpackRGB())
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
	if IsConsoleUI() then
		return
	end
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

function AddonSettings:CreateControls()
	if IsConsoleUI() then
		self:CreateControls_Gamepad()
	else
		self:CreateControls_Keyboard()
	end
end

function AddonSettings:UpdateControls()
	if IsConsoleUI() then
		self:UpdateControls_Gamepad()
	else
		self:UpdateControls_Keyboard()
	end
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
	if IsConsoleUI() then
		return
	end
	self.container:ClearAnchors()
	if self.container.attached then
		self.container.attached:ClearAnchors()
		self.container.attached = nil
	end
end

function LibHarvensAddonSettings:AttachControlToContainer(control)
	if IsConsoleUI() then
		return
	end
	control:ClearAnchors()
	control:SetAnchor(TOPLEFT, self.container, BOTTOMLEFT, 0, 8)
	self.container.attached = control
end

function LibHarvensAddonSettings:AttachContainerToControl(control)
	if IsConsoleUI() then
		return
	end
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

function LibHarvensAddonSettings:RefreshAddonSettings()
	if IsConsoleUI() then
		self:RefreshAddonSettings_Gamepad()
	else
		self:RefreshAddonSettings_Keyboard()
	end
end

function LibHarvensAddonSettings:SelectFirstAddon()
	if IsConsoleUI() then
		self:SelectFirstAddon_Gamepad()
	else
		self:SelectFirstAddon_Keyboard()
	end
end

function LibHarvensAddonSettings:Initialize()
	if self.initialized then
		return
	end
	if #LibHarvensAddonSettings.addons > 0 then
		self:CreateAddonSettingsPanel()
		self:CreateControlPools()
		self:CreateAddonList()
	end
	self.initialized = true
end
