local RELEVANT_VISUAL_TYPES =
{
	ATTRIBUTE_VISUAL_POWER_SHIELDING,
	ATTRIBUTE_VISUAL_TRAUMA
}

UnitFramesRebirth_PowerShieldModule = ZO_UnitAttributeVisualizerModuleBase:Subclass()

function UnitFramesRebirth_PowerShieldModule:New(...)
	return ZO_UnitAttributeVisualizerModuleBase.New(self, ...)
end

function UnitFramesRebirth_PowerShieldModule:Initialize(layoutData)
	self.layoutData = layoutData
end

function UnitFramesRebirth_PowerShieldModule:CreateInfoTable(control, oldInfo, stat, attribute, power)
	if control then
		local info = oldInfo or { visualInfo = {} }

		for _, visualType in ipairs(RELEVANT_VISUAL_TYPES) do
			if not info.visualInfo[visualType] then
				info.visualInfo[visualType] = {}
			end
			local visualInfo = info.visualInfo[visualType]

			visualInfo.value, visualInfo.maxValue = self:GetInitialValueAndMarkMostRecent(visualType, stat, attribute, power)
			if visualInfo.lastValue == nil then
				visualInfo.lastValue = 0
			end
		end

		return info
	end
	return nil
end

function UnitFramesRebirth_PowerShieldModule:OnAdded(healthBarControl)
	self.attributeBarControls =
	{
		[ATTRIBUTE_HEALTH] = healthBarControl,
	}

	if IsPlayerActivated() then
		self:InitializeBarValues()
	end

	local function OnSizeChanged(resizing, bar, size)
		if bar == healthBarControl then
			local info = self.attributeInfo and self.attributeInfo[ATTRIBUTE_HEALTH]
			if info then
				info.isResizing = resizing
				self:OnUpdate()
			end
		end
	end

	local STARTING_RESIZE = true
	local STOPPING_RESIZE = false
	local owner = self:GetOwner()
	owner:RegisterCallback("AttributeBarSizeChangingStart", function(...) OnSizeChanged(STARTING_RESIZE, ...) end)
	owner:RegisterCallback("AttributeBarSizeChangingStopped", function(...) OnSizeChanged(STOPPING_RESIZE, ...) end)

	EVENT_MANAGER:RegisterForEvent("UnitFramesRebirth_PowerShield", EVENT_PLAYER_ACTIVATED, function() self:InitializeBarValues() end)
end

function UnitFramesRebirth_PowerShieldModule:InitializeBarValues()
	local healthBarControl = self.attributeBarControls[ATTRIBUTE_HEALTH]

	local oldBarInfo = self.attributeInfo
	self.attributeInfo =
	{
		[ATTRIBUTE_HEALTH] = self:CreateInfoTable(healthBarControl, oldBarInfo and oldBarInfo[ATTRIBUTE_HEALTH], STAT_MITIGATION, ATTRIBUTE_HEALTH, POWERTYPE_HEALTH),
	}

	for attribute, bar in pairs(self.attributeBarControls) do
		local barInfo = self.attributeInfo[attribute]
		for visualType, _ in pairs(barInfo.visualInfo) do
			self:OnValueChanged(bar, barInfo, visualType)
		end
	end
end

function UnitFramesRebirth_PowerShieldModule:OnUnitChanged()
	self:InitializeBarValues()
end

function UnitFramesRebirth_PowerShieldModule:OnUpdate()
	if self.attributeInfo then
		for attribute, info in pairs(self.attributeInfo) do
			if info.isResizing then
				self:UpdateValue(self.attributeBarControls[attribute], info)
			end
		end
	end
end

function UnitFramesRebirth_PowerShieldModule:IsUnitVisualRelevant(visualType, stat, attribute, powerType)
	if self.attributeInfo == nil or self.attributeInfo[attribute] == nil then
		return false
	end

	for _, currentVisualType in ipairs(RELEVANT_VISUAL_TYPES) do
		if visualType == currentVisualType then
			return true
		end
	end

	return false
end

function UnitFramesRebirth_PowerShieldModule:OnUnitAttributeVisualAdded(visualType, stat, attribute, powerType, value, maxValue)
	local barInfo = self.attributeInfo[attribute]
	local info = barInfo.visualInfo[visualType]
	info.value = info.value + value
	info.maxValue = info.maxValue + maxValue
	self:OnValueChanged(self.attributeBarControls[attribute], barInfo, visualType)
end

function UnitFramesRebirth_PowerShieldModule:OnUnitAttributeVisualUpdated(visualType, stat, attribute, powerType, oldValue, newValue, oldMaxValue, newMaxValue)
	local barInfo = self.attributeInfo[attribute]
	local info = barInfo.visualInfo[visualType]
	info.value = info.value + (newValue - oldValue)
	info.maxValue = info.maxValue + (newMaxValue - oldMaxValue)
	self:OnValueChanged(self.attributeBarControls[attribute], barInfo, visualType)
end

function UnitFramesRebirth_PowerShieldModule:OnUnitAttributeVisualRemoved(visualType, stat, attribute, powerType, value, maxValue)
	local barInfo = self.attributeInfo[attribute]
	local info = barInfo.visualInfo[visualType]
	info.value = info.value - value
	info.maxValue = info.maxValue - maxValue
	self:OnValueChanged(self.attributeBarControls[attribute], barInfo, visualType)
end

local function ApplyPlatformStyleToShield(control, overlay)
	ApplyTemplateToControl(control, ZO_GetPlatformTemplate(overlay))
end

local SHIELD_COLOR_GRADIENT = { ZO_ColorDef:New(.5, .5, 1, .3), ZO_ColorDef:New(.25, .25, .5, .5) }
function UnitFramesRebirth_PowerShieldModule:ShowOverlay(attributeBar, info)
	if not info.shieldOverlay then
		local attributeBarControl = unpack(attributeBar.barControls)

		info.shieldOverlay = CreateControlFromVirtual("$(parent)PowerShieldOverlay", attributeBar, self.layoutData.template)

		local overlay = info.shieldOverlay
		ZO_StatusBar_SetGradientColor(overlay, SHIELD_COLOR_GRADIENT)
		overlay:SetValue(1)

		ZO_PreHookHandler(attributeBarControl, "OnMinMaxValueChanged", function(_, min, max)
			info.attributeMax = max
			self:OnStatusBarValueChanged(attributeBar, info)
		end)

		ZO_PreHookHandler(attributeBarControl, "OnValueChanged", function(_, value)
			info.attributeValue = value
			self:OnStatusBarValueChanged(attributeBar, info)
		end)

		info.attributeMax = select(2, attributeBarControl:GetMinMax())
		info.attributeValue = attributeBarControl:GetValue()
	end

	ApplyPlatformStyleToShield(info.shieldOverlay, self.layoutData.template)

	local owner = self:GetOwner()
	owner:NotifyTakingControlOf(attributeBar)
	owner:NotifyEndingControlOf(attributeBar)
end

function UnitFramesRebirth_PowerShieldModule:ShouldHideBar(barInfo)
	for _, visualInfo in pairs(barInfo.visualInfo) do
		if visualInfo.value > 0 then
			return false
		end
	end
	return true
end

function UnitFramesRebirth_PowerShieldModule:ApplyValueToBar(attributeBar, barInfo, barControl, value)
	local percentOfBarRequested = zo_clamp(value / barInfo.attributeMax, 0, 1.0)
	-- arbitrary hardcoded threshold to avoid "too-small" values
	if percentOfBarRequested <= .01 then
		barControl:SetHidden(true)
		return
	else
		barControl:SetHidden(false)
	end

	local attributeBarControl = unpack(attributeBar.barControls)
	local healthWidth = attributeBarControl:GetWidth()
	local rightOffsetX = healthWidth * (1 - percentOfBarRequested)

	barControl:ClearAnchors()
	barControl:SetAnchor(TOPLEFT, attributeBarControl, TOPLEFT)
	barControl:SetAnchor(BOTTOMRIGHT, attributeBarControl, BOTTOMRIGHT, -rightOffsetX)
end

function UnitFramesRebirth_PowerShieldModule:OnStatusBarValueChanged(attributeBar, barInfo)
	local shieldInfo, traumaInfo = barInfo.visualInfo[ATTRIBUTE_VISUAL_POWER_SHIELDING], barInfo.visualInfo[ATTRIBUTE_VISUAL_TRAUMA]
	local overlayControl = barInfo.shieldOverlay
	if not self:ShouldHideBar(barInfo) then
		self:ApplyValueToBar(attributeBar, barInfo, overlayControl, shieldInfo.value)
	else
		overlayControl:SetHidden(true)
	end
end

function UnitFramesRebirth_PowerShieldModule:UpdateValue(attributeBar, info)
	if info.shieldOverlay then
		self:OnStatusBarValueChanged(attributeBar, info)
	end
end

function UnitFramesRebirth_PowerShieldModule:OnValueChanged(attributeBar, barInfo, visualType)
	local visualInfo = barInfo.visualInfo[visualType]
	local value = visualInfo.value
	local lastValue = visualInfo.lastValue
	visualInfo.lastValue = value

	if value > 0 and lastValue <= 0 then
		self:ShowOverlay(attributeBar, barInfo)
	end

	self:UpdateValue(attributeBar, barInfo)
end

function UnitFramesRebirth_PowerShieldModule:ApplyPlatformStyle()
	if self.attributeInfo then
		for _, info in pairs(self.attributeInfo) do
			if info.shieldOverlay then
				ApplyPlatformStyleToShield(info.shieldOverlay, self.layoutData.template)
			end
		end
	end
end