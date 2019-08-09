SHIELD_COLOR_GRADIENT = { ZO_ColorDef:New(.5, .5, 1, .5), ZO_ColorDef:New(.25, .25, .5, .65) }

local WITHOUT_ON_STOP_CALLBACK = nil

UnitFramesRebirth_Shield = ZO_Object:Subclass()

function UnitFramesRebirth_Shield:New(...)
	local shield = ZO_Object.New(self)
	shield:Initialize(...)
	return shield
end

function UnitFramesRebirth_Shield:Initialize(parent, unitTag)
	local barControls = parent:GetBarControls()
	if not barControls or #barControls <= 0 then return end

	local shield = barControls[1].shield
	if not shield then return end

	self.statusBarShield = shield

	self.parentBarControl = barControls[1]
	self.unitTag = unitTag
	self.paused = true

	self.parentBarControl:SetHandler("OnMinMaxValueChanged", function() self:OnMinMaxValueChangedUpdate() end)
end

function UnitFramesRebirth_Shield:SetPaused(paused)
	if self.paused ~= paused then
		self.paused = paused
		if paused then
			self.statusBarShield:SetHidden(true)
		else
			self:OnMinMaxValueChangedUpdate()
		end
	end
end

function UnitFramesRebirth_Shield:OnMinMaxValueChangedUpdate()
	local value, maxValue = GetUnitAttributeVisualizerEffectInfo(self.unitTag, ATTRIBUTE_VISUAL_POWER_SHIELDING, STAT_MITIGATION, ATTRIBUTE_HEALTH, POWERTYPE_HEALTH)
	self:UpdateStatusBar(value or 0, maxValue or 0)
end

function UnitFramesRebirth_Shield:UpdateStatusBar(value)
	if not self.paused then
		local healthBarMax = select(2, self.parentBarControl:GetMinMax())

		-- arbitrary hardcoded threshold to avoid "too-small" values
		if zo_clamp(value / healthBarMax, 0, 1.0) <= .01 then
			self.statusBarShield:SetHidden(true)
			return
		else
			self.statusBarShield:SetHidden(false)
		end

		local customApproach = UnitFramesRebirth_GetStatusBarCustomApproachAmountMs()
		if customApproach and customApproach ~= 0 then
			ZO_StatusBar_SmoothTransition(self.statusBarShield, value, healthBarMax, not FORCE_INIT_SMOOTH_STATUS_BAR, WITHOUT_ON_STOP_CALLBACK, customApproach)
		else
			ZO_StatusBar_SmoothTransition(self.statusBarShield, value, healthBarMax, FORCE_INIT_SMOOTH_STATUS_BAR)
		end
	end
end
