local HEALTH_ALPHA_PULSE_THRESHOLD = 0.50
local HEALTH_WARNER_FLASH_TIME = 300

UnitFramesRebirth_HealthWarner = ZO_Object:Subclass()

function UnitFramesRebirth_HealthWarner:New(...)
	local warner = ZO_Object.New(self)
	warner:Initialize(...)
	return warner
end

function UnitFramesRebirth_HealthWarner:Initialize(parent, unitTag)
	local barControls = parent:GetBarControls()
	if not barControls or #barControls <= 0 then return end

	self.warning = barControls[1].warnerContainer
	if not self.warning then return end

	local orgUpdate = parent.Update
	function parent.Update(...)
		local powerType = select(2, ...)
		if powerType == POWERTYPE_HEALTH then
			self:OnHealthUpdate(select(3, ...))
		end
		return orgUpdate(...)
	end

	self.unitTag = unitTag

	self.warnAnimation = ZO_AlphaAnimation:New(self.warning)
	self.statusBar = parent
	self.paused = false
end

function UnitFramesRebirth_HealthWarner:OnHealthUpdate(health, maxHealth)
	if health / maxHealth <= HEALTH_ALPHA_PULSE_THRESHOLD then
		if not self.warnAnimation:IsPlaying() then
			self.warnAnimation:PingPong(0, 1, HEALTH_WARNER_FLASH_TIME)
		end
	else
		if self.warnAnimation:IsPlaying() then
			self.warnAnimation:Stop()
			self.warning:SetAlpha(0)
		end
	end
end