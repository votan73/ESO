if LibHarvensAddonSettings then
	error("Library loaded already. Please remove all LibHarvensAddonSettings in sub folders.")
end

LibHarvensAddonSettings = {}
LibHarvensAddonSettings.version = 20002
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
LibHarvensAddonSettings.ST_ICONPICKER = 9
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

function AddonSettingsControl:GetValueOrCallback(arg)
	return type(arg) == "function" and arg(self) or arg
end

function AddonSettingsControl:GetString(strOrId)
	return type(strOrId) == "number" and GetString(strOrId) or strOrId
end

function AddonSettingsControl:SetValue(...)
	if not self.control or not self.control.SetValue then
		return
	end
	return self.control:SetValue(...)
end

function AddonSettingsControl:ResetToDefaults()
	if self.ignoreDefault then return end
	if self.type == LibHarvensAddonSettings.ST_DROPDOWN then
		self:SetValue(self.default)
		if self.control then
			local itemIndex = 1
			local items = self:GetValueOrCallback(self.items)
			for i = 1, #items do
				if self.items[i].name == self.default then
					itemIndex = i
					break
				end
			end
			local combobox = self.control:GetDropDown()
			self.setFunction(combobox, self.default, self.items[itemIndex])
		end
	elseif self.type == LibHarvensAddonSettings.ST_COLOR then
		self:SetValue(unpack(self.default))
		self.setFunction(unpack(self.default))
	elseif self.type == LibHarvensAddonSettings.ST_ICONPICKER then
		self:SetValue(self.default or 1)
		local items = self:GetValueOrCallback(self.items)
		local combobox = self.control:GetDropDown()
		self.setFunction(combobox, self.default, self.items[self.default])
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

function AddonSettings:AddSetting(params, index, playAnimation)
	--Append if invalid or empty index
	if index == nil or index < 1 then index = #self.settings + 1 end 
	
	--Prevent an attempt at cleaning up the new control before it gets created.
	if self.selected then
		self:CleanUp()
	end

	local setting = AddonSettingsControl:New(self.callbackManager, params.type)
	table.insert(self.settings, index, setting)
	setting:SetupControl(params)

	--Force the settings page to update immediately if currently showing.
	--The cleanup earlier prevents duplicate controls from being created.
	if self.selected then
		self:CreateControls()
	end

	--Update the container height in pc mode
	if not IsConsoleUI() and self.selected then
		LibHarvensAddonSettings.container.endHeight = self:GetOverallHeight() + 8
		--Conditionally show the animation. Useful for simulating submenus
		if not playAnimation then
			LibHarvensAddonSettings.openTimeline:PlayInstantlyToEnd()
		else
			LibHarvensAddonSettings.openTimeline:PlayFromStart()
		end
	end

	return setting, index
end

function AddonSettings:AddSettings(params, index, playAnimation)
	--It should be possible to set for i = (index or 1), #params + index and let the indexes be
	--built into the returned table, but that might be less intuitive to iterate through.
	local ret = {}
	local indexes = {}
	for i = 1, #params do
		ret[i], indexes[i] = self:AddSetting(params[i], index, playAnimation)
		if index ~= nil and index > 0 then index = index + 1 end --Increment the index to add them in-order, not reverse order.
	end
	return ret, indexes
end

--removes up to count settings at index.
--always refreshes list to ensure proper cleanup.
function AddonSettings:RemoveSettings(index, count, playAnimation)
	--It is important to cleanup before removing from table or else we can get stuck with the controls forever.
	if self.selected then
		self:CleanUp()
	end
	local removedSettingsList = {}
	if not count then count = 1 end
	for i = 1, count do
		if not self.settings[index] then break end
		table.insert(removedSettingsList, table.remove(self.settings, index))
	end
	--Force immediate page update
	if self.selected then
		self:CreateControls()
	end

	--Update the container height in pc mode
	if not IsConsoleUI() and self.selected then
		LibHarvensAddonSettings.container.endHeight = self:GetOverallHeight() + 8
		--Conditionally show the animation. Useful for simulating submenus
		if not playAnimation then 
			LibHarvensAddonSettings.openTimeline:PlayInstantlyToEnd()
		else
			LibHarvensAddonSettings.openTimeline:PlayFromStart()
		end
	end

	return removedSettingsList
end

--removes all settings
--always refreshes list to ensure proper cleanup.
function AddonSettings:RemoveAllSettings(playAnimation)
	if self.selected then
		self:CleanUp()
	end
	
	local oldSettingsList = {}
	while #self.settings > 0 do
		table.insert(oldSettingsList, table.remove(self.settings, 1))
	end

	--Update the container height in pc mode
	if not IsConsoleUI() and self.selected then
		LibHarvensAddonSettings.container.endHeight = self:GetOverallHeight() + 8
		--Conditionally show the animation. Useful for simulating submenus
		if not playAnimation then 
			LibHarvensAddonSettings.openTimeline:PlayInstantlyToEnd()
		else
			LibHarvensAddonSettings.openTimeline:PlayFromStart()
		end
	end

	return oldSettingsList
end

--Find the index of the first setting made from these params.
--This uses shallow table comparisons, which feels very unoptimal.
--If a setting's index position is static, it would be better to use the return value of AddSetting(s)
function AddonSettings:GetIndexOf(setting, areParams)
	if areParams then
		local tempSetting = AddonSettingsControl:New(self.callbackManager, setting.type)
		tempSetting:SetupControl(setting)
		setting = tempSetting
	end

	local isMatch = false
	for index, existing in pairs(self.settings) do
		isMatch = true
		for k, v in pairs(setting) do
			local t = type(v)
			if t ~= "table" and t ~= "userdata" and existing[k] ~= v then 
				isMatch = false
				break
			end
		end
		if isMatch then return index end
	end
	return nil
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
		self:UpdateControls()
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

function AddonSettings:Clear()
	self.settings = {}
	self.selected = false
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

function LibHarvensAddonSettings:Initialize()
	if self.initialized then
		return
	end

	self:CreateAddonSettingsPanel()
	self:CreateControlPools()
	self:CreateAddonList()

	self.initialized = true
end
