local async = LibAsync
local REFRESH_RATE = math.floor(GetCVar("MinFrameTime.2") * 1000)

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

function UnitFramesRebirth_PowerShieldModule:OnAdded(healthBarControl, magickaBarControl, staminaBarControl)
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
			end
		end
	end

	local STARTING_RESIZE = true
	local STOPPING_RESIZE = false
	local owner = self:GetOwner()
	owner:RegisterCallback("AttributeBarSizeChangingStart", function(...) OnSizeChanged(STARTING_RESIZE, ...) end)
	owner:RegisterCallback("AttributeBarSizeChangingStopped", function(...) OnSizeChanged(STOPPING_RESIZE, ...) end)

	local namespace = "UnitFramesRebirth_PowerShieldModule" .. self:GetModuleId()
	self.task = async:Create(namespace .. owner)
	EVENT_MANAGER:RegisterForEvent(namespace, EVENT_PLAYER_ACTIVATED, function() self:InitializeBarValues() end)
	EVENT_MANAGER:RegisterForUpdate(namespace, REFRESH_RATE, function() self.task:Call(function() self:OnUpdate() end) end)
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
local TRAUMA_COLOR_GRADIENT = { ZO_ColorDef:New("ab1c6473"), ZO_ColorDef:New("ab76bcc3") }
function UnitFramesRebirth_PowerShieldModule:ShowOverlay(attributeBar, info)
	if not info.overlayControl then
		local attributeBarControl = unpack(attributeBar.barControls)
		local overlayTemplate = self.layoutData.barOverlayTemplate

		info.shieldOverlay = CreateControlFromVirtual("$(parent)PowerShieldOverlay", attributeBar, overlayTemplate)

		local overlay = info.shieldOverlay
		ZO_StatusBar_SetGradientColor(overlay, SHIELD_COLOR_GRADIENT)
		ZO_StatusBar_SetGradientColor(overlay.traumaBar, TRAUMA_COLOR_GRADIENT)
		ZO_StatusBar_SetGradientColor(overlay.fakeHealthBar, ZO_POWER_BAR_GRADIENT_COLORS[POWERTYPE_HEALTH])
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

	ApplyPlatformStyleToShield(info.shieldOverlay, overlayTemplate)

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
	local halfWidth = attributeBarControl:GetWidth()
	local leftOffsetX = halfWidth * (1 - percentOfBarRequested)
	local rightOffsetX = leftOffsetX + halfWidth * percentOfBarRequested

	barControl:ClearAnchors()
	barControl:SetAnchor(LEFT, attributeBarControl, LEFT, leftOffsetX, 0)
	barControl:SetAnchor(RIGHT, attributeBarControl, LEFT, rightOffsetX, 0)
end

function UnitFramesRebirth_PowerShieldModule:OnStatusBarValueChanged(attributeBar, barInfo)
	local shieldInfo, traumaInfo = barInfo.visualInfo[ATTRIBUTE_VISUAL_POWER_SHIELDING], barInfo.visualInfo[ATTRIBUTE_VISUAL_TRAUMA]
	local overlayControl = unpack(barInfo.overlayControl)
	if not self:ShouldHideBar(barInfo) then
		-- This math just establishes the relationships between each bar: the clamping and scaling to turn these into actual control positions happens in ApplyValueToBar().
		-- Each bar is drawn on top of the last one in the sequence, so the actual amount of each bar the player will see will always be distance between the last bar and the next.

		local health = barInfo.attributeValue
		local shield = shieldInfo.value
		local trauma = traumaInfo.value

		-- Shields add to your original health bar, so they grow out of that value.
		-- When that amount extends beyond your max health we need shrink your fakehealth to compensate, which we carry over as shieldOverflow
		local shieldBarSize = health + shield
		self:ApplyValueToBar(attributeBar, barInfo, overlayControl, shieldBarSize)
		local shieldOverflow = zo_max(0, shieldBarSize - barInfo.attributeMax)

		-- Trauma starts at your current health value, minus any shield overflow.
		-- This means that you should perceive the size of this bar as being your "health", it just needs to be overhealed before you can benefit from extra heal.
		local traumaBarSize = health - shieldOverflow
		self:ApplyValueToBar(attributeBar, barInfo, overlayControl.traumaBar, traumaBarSize)

		-- Then the fakehealth starts at the step 2 interpretation of health minus any trauma experienced.
		-- Sometimes trauma and shield overflow will be 0, in which case this value is the same as your actual health, otherwise it shrinks to fit each effect.
		local fakeHealthSize = traumaBarSize - trauma
		self:ApplyValueToBar(attributeBar, barInfo, overlayControl.fakeHealthBar, fakeHealthSize)
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
				ApplyPlatformStyleToShield(info.shieldOverlay, self.layoutData.barOverlayTemplate)
			end
		end
	end
end