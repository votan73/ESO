SHIELD_COLOR_GRADIENT = { ZO_ColorDef:New(.5, .5, 1, .3), ZO_ColorDef:New(.25, .25, .5, .5) }

UnitFramesRebirth_Shield = ZO_Object:Subclass()

function UnitFramesRebirth_Shield:New(...)
	local warner = ZO_Object.New(self)
	warner:Initialize(...)
	return warner
end

function UnitFramesRebirth_Shield:Initialize(parent, unitTag, hide)
	local barControls = parent:GetBarControls()
	if not barControls or #barControls <= 0 then return end

	self.shield = barControls[1].shield
	if not self.shield then return end

	self.unitTag = unitTag
	self.parent = parent
	self.hide = hide or false

	self.shield:SetValue(1)
	self.shield:SetMinMax(0, 1)
end

function UnitFramesRebirth_Shield:SetPaused(hide)
	if self.hide ~= hide then
		self.hide = hide
		if hide then
			self.shield:SetHidden(true)
		else
			local value, maxValue = GetUnitAttributeVisualizerEffectInfo(self.unitTag, ATTRIBUTE_VISUAL_POWER_SHIELDING, STAT_MITIGATION, ATTRIBUTE_HEALTH, POWERTYPE_HEALTH)
			self:UpdateStatusBar(value or 0, maxValue or 0)
		end
	end
end

function UnitFramesRebirth_Shield:UpdateStatusBar(value, maxValue)
	if not self.hide then
		-- arbitrary hardcoded threshold to avoid "too-small" values
		if zo_clamp(value / maxValue, 0, 1.0) <= .01 then
			self.shield:SetHidden(true)
			return
		else
			self.shield:SetHidden(false)
		end

		local customApproach = UnitFramesRebirth_GetStatusBarCustomApproachAmountMs()
		if customApproach and customApproach ~= 0 then
			ZO_StatusBar_SmoothTransition(self.shield, value, maxValue, false, nil, customApproach)
		else
			ZO_StatusBar_SmoothTransition(self.shield, value, maxValue, FORCE_INIT_SMOOTH_STATUS_BAR)
		end
	end
end
