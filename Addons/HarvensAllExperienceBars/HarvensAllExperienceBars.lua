local HarvensAllExperienceBars = {}

---- HarvensExperienceBar ----

local HarvensExperienceBar = ZO_Object:Subclass()

function HarvensExperienceBar:Initialize()
	self.FONT_SKILL_NAME_INSIDE = "$(MEDIUM_FONT)|14|thick-outline"
	self.FONT_SKILL_NAME_OUTSIDE = "ZoFontGameLargeBoldShadow"
	self.FONT_RANK_INSIDE = "$(MEDIUM_FONT)|14|thick-outline"
	self.FONT_RANK_OUTSIDE = "ZoFontGameLargeBoldShadow"
	self.FONT_RANK_SIDE = "ZoFontAnnounceLarge"
	self.FONT_EXPERIENCE_GAIN = "ZoFontAnnounceMedium"
	self.FONT_SKILL_PROGRESS = "$(MEDIUM_FONT)|12|thick-outline"

	self.queuedXP = {}
	local function factory(bar)
		bar:SetMouseEnabled(true)
		bar:SetMinMax(0, 100)
		bar:SetHeight(26)
		bar:SetClampedToScreen(true)
		if not bar.alignment then
			bar.alignment = BAR_ALIGNMENT_NORMAL
		end
		bar:SetHandler(
			"OnMouseDown",
			function(control, ...)
				control.m_object:ShowMenu(control, ...)
			end
		)
		bar:SetHandler(
			"OnDragStart",
			function(control)
				control:SetMovable(true)
				control:StartMoving()
			end
		)
		bar:SetHandler(
			"OnMouseUp",
			function(control)
				control:StopMovingOrResizing()
				control:SetMovable(false)
				control:ApplyGrid()
			end
		)
		bar:SetHandler(
			"OnMouseWheel",
			function(control, delta, ctr, alt, shift)
				if not shift then
					local scale = control:GetScale()
					local width = control:GetWidth()
					width = width + delta
					control:SetWidth(width / scale)
					control.m_object.barSettings.width = width / scale
				else
					local scale = control:GetScale()
					scale = scale + 0.1 * delta
					control:SetScale(scale)
					control.m_object.barSettings.scale = scale
				end
			end
		)
		bar.gainLabel = bar:GetNamedChild("Gain")
		bar.gainLabel:SetHidden(true)
		bar.sparkle = bar.gainLabel:GetNamedChild("Sparkle")
		local sparkle2 = bar.sparkle:GetNamedChild("CCW")
		bar.sparkle:SetHidden(true)

		bar.sparkleRotate = ANIMATION_MANAGER:CreateTimelineFromVirtual("Harvens_ExperienceBarSparkleAnim", bar.sparkle)
		local sparkle2Rotate = bar.sparkleRotate:GetAnimation(2)
		sparkle2Rotate:SetAnimatedControl(sparkle2)
		bar.sparkleRotate:SetHandler(
			"OnStop",
			function(...)
				bar.sparkle:SetHidden(true)
			end
		)

		bar.gainFade = ANIMATION_MANAGER:CreateTimelineFromVirtual("Harvens_ExperienceBarGainFade", bar.gainLabel)
		bar.gainFade:SetHandler(
			"OnStop",
			function()
				bar.gainLabel:SetHidden(true)
				bar.gainLabel:SetAlpha(1.0)
			end
		)

		bar.barFade = ANIMATION_MANAGER:CreateTimelineFromVirtual("Harvens_ExperienceBarFade", bar)
		bar.barFade:SetHandler(
			"OnStop",
			function()
				bar:SetHidden(true)
				bar:SetAlpha(1.0)
			end
		)
		local function startAnim(self)
			self.gainFade:PlayFromStart()

			self.sparkle:SetHidden(false)
			self.sparkleRotate:PlayFromStart()
		end
		function bar:PlayGainAnim()
			if HUD_SCENE:IsShowing() then
				startAnim(self)
			else
				local inst = self
				SCENE_MANAGER:CallWhen(
					HUD_SCENE:GetName(),
					SCENE_SHOWN,
					function()
						startAnim(inst)
					end
				)
			end
		end
		function bar:PlayAutoHideAnim()
			if HarvensAllExperienceBars.sv.autoHide then
				bar:SetHidden(false)
				bar.barFade:PlayFromStart()
			end
		end
		function bar.ApplyGrid(control)
			local gridSize = HarvensAllExperienceBars.account.gridSize
			local x, y = control:GetScreenRect()
			local xgrid, ygrid = zo_round(x / gridSize) * gridSize, zo_round(y / gridSize) * gridSize
			xgrid, ygrid = xgrid - x, ygrid - y
			local _, pos, _, relPos, x, y = control:GetAnchor(0)
			x, y = x + xgrid, y + ygrid
			control:SetAnchor(pos, HarvensAllExperienceBars.container, relPos, x, y)
			control.m_object.barSettings.anchor = {pos = pos, relPos = relPos, x = x, y = y}
		end
	end
	local function release(bar)
		if bar.m_object then
			bar.m_object:UnregisterHandlers()
			bar.m_object.skillLineData = nil
			bar.m_object = nil
		end
	end
	self.barsPool = ZO_ControlPool:New("Harvens_ExperienceBar", HarvensAllExperienceBars.container, "Bar")
	self.barsPool:SetCustomFactoryBehavior(factory)
	self.barsPool:SetCustomResetBehavior(release)
end

function HarvensExperienceBar:SwitchBarTextureAlignment(left, middle, right)
	local _, po1, _, popa1 = right:GetAnchor(0)
	local _, po2, _, popa2 = right:GetAnchor(1)
	local _, po3, _, popa3 = middle:GetAnchor(0)
	local _, po4, _, popa4 = middle:GetAnchor(1)
	right:ClearAnchors()
	middle:ClearAnchors()
	right:SetAnchor(select(2, left:GetAnchor(0)))
	right:SetAnchor(select(2, left:GetAnchor(1)))
	left:ClearAnchors()
	left:SetAnchor(po1, left:GetParent(), popa1)
	left:SetAnchor(po2, left:GetParent(), popa2)
	middle:SetAnchor(po3, right, popa3)
	middle:SetAnchor(po4, left, popa4)

	local le, ri, to, bo = left:GetTextureCoords()
	left:SetTextureCoords(ri, le, to, bo)
	le, ri, to, bo = right:GetTextureCoords()
	right:SetTextureCoords(ri, le, to, bo)
end

function HarvensExperienceBar:ToggleAlignment()
	if self.bar.alignment == BAR_ALIGNMENT_REVERSE then
		self:SetAlignment(BAR_ALIGNMENT_NORMAL)
	else
		self:SetAlignment(BAR_ALIGNMENT_REVERSE)
	end
end

function HarvensExperienceBar:SetAlignment(alignment)
	local left, right, leftBG, rightBG
	if alignment == BAR_ALIGNMENT_NORMAL then
		left = self.bar:GetNamedChild("Overlay"):GetNamedChild("Left")
		right = self.bar:GetNamedChild("Overlay"):GetNamedChild("Right")
		leftBG = self.bar:GetNamedChild("BG"):GetNamedChild("Left")
		rightBG = self.bar:GetNamedChild("BG"):GetNamedChild("Right")
	else
		left = self.bar:GetNamedChild("Overlay"):GetNamedChild("Right")
		right = self.bar:GetNamedChild("Overlay"):GetNamedChild("Left")
		leftBG = self.bar:GetNamedChild("BG"):GetNamedChild("Right")
		rightBG = self.bar:GetNamedChild("BG"):GetNamedChild("Left")
	end
	self.bar:SetBarAlignment(alignment)
	self.bar:GetNamedChild("Gloss"):SetBarAlignment(alignment)

	if self.bar.alignment ~= alignment then
		self:SwitchBarTextureAlignment(right, self.bar:GetNamedChild("Overlay"):GetNamedChild("Middle"), left)
		self:SwitchBarTextureAlignment(rightBG, self.bar:GetNamedChild("BG"):GetNamedChild("Middle"), leftBG)
	end
	self.bar.alignment = alignment
	self.barSettings.alignment = alignment
	self:setupNameLabel()
end

function HarvensExperienceBar:ToggleNamePosition()
	self.isLabelInside = not self.isLabelInside
	self:setupNameLabel()
	self.barSettings.isLabelInside = self.isLabelInside
end

function HarvensExperienceBar:ToggleRank()
	self.showRank = not self.showRank
	self:setupNameLabel()
	self.barSettings.showRank = self.showRank
end

function HarvensExperienceBar:ToggleRankPosition()
	self.rankNextToName = not self.rankNextToName
	self:setupNameLabel()
	self.barSettings.rankNextToName = self.rankNextToName
end

function HarvensExperienceBar:SetBarColor(newR, newG, newB, newA)
	self.barSettings.barColor = {newR, newG, newB, newA}
	self.bar:SetGradientColors(newR, newG, newB, newA, newR, newG, newB, newA)
end

function HarvensExperienceBar:SetLabelsColor(newR, newG, newB, newA)
	self.barSettings.labelsColor = {newR, newG, newB, newA}
	self.rankLabel:SetColor(newR, newG, newB, newA)
	self.skillProgressLabel:SetColor(newR, newG, newB, newA)
	self.nameLabel:SetColor(newR, newG, newB, newA)
end

function HarvensExperienceBar:ShowBarSubMenu()
	AddCustomMenuItem(
		"Remove",
		function()
			local key = HarvensExperienceBar.CreateKey(self.skillType, self.skillLine, self.abilityIndex, self.skillsMode)
			HarvensAllExperienceBars:RemoveStatusBar(key)
		end
	)
	AddCustomMenuItem(
		"Switch Alignment",
		function()
			self:ToggleAlignment()
		end
	)
	AddCustomMenuItem(
		self.isLabelInside and "Name Above" or "Name Inside",
		function()
			self:ToggleNamePosition()
		end
	)

	if self.showRank then
		AddCustomMenuItem(
			self.rankNextToName and "Rank on Bar Side" or "Rank Next to Name",
			function()
				self:ToggleRankPosition()
			end
		)
	end

	AddCustomMenuItem(
		self.showRank and "Hide Rank" or "Show Rank",
		function()
			self:ToggleRank()
		end
	)
	AddCustomMenuItem(
		"Change Color",
		function()
			COLOR_PICKER:Show(
				function(...)
					self:SetBarColor(...)
				end,
				unpack(self.barSettings.barColor)
			)
		end
	)
	AddCustomMenuItem(
		"Change Text Color",
		function()
			COLOR_PICKER:Show(
				function(...)
					self:SetLabelsColor(...)
				end,
				unpack(self.barSettings.labelsColor)
			)
		end
	)
end

function HarvensExperienceBar:ShowMenu(control, button)
	if button ~= MOUSE_BUTTON_INDEX_RIGHT then
		return
	end

	ClearMenu()
	self:ShowBarSubMenu()
	ShowMenu(self.bar, 2)
end

function HarvensExperienceBar:UpdateProgress(lastRankXP, nextRankXP, currentXP)
	if not nextRankXP or nextRankXP <= 0 then
		self.nameLabel:SetText(self.skillName)
		self.skillProgressLabel:SetText("")
		return
	end
	if not currentXP then
		return
	end

	local gain = 0
	local gainHidden = self.gainLabel:IsHidden()
	if not gainHidden then
		gain = self.gainLabel.gain or 0
	end

	gain = gain + currentXP - self.currentXP
	if gain > 0 or (self.skillType == -101 and gain < 0) then
		self.bar:PlayAutoHideAnim()
		if gain > 0 then
			self.gainLabel:SetText("+" .. gain)
		else
			self.gainLabel:SetText(gain)
		end
		self.gainLabel.gain = gain
		if gainHidden then
			self.gainLabel:SetHidden(false)
		end

		self.bar:PlayGainAnim()
	end
	self.currentXP = currentXP

	if HarvensAllExperienceBars.sv.displayPercentage then
		local perc = 100 * (currentXP - lastRankXP) / (nextRankXP - lastRankXP)
		perc = string.format("%.1f%%", perc)
		self.skillProgressLabel:SetText(perc)
	else
		self.skillProgressLabel:SetText(string.format("%i/%i", (currentXP - lastRankXP), (nextRankXP - lastRankXP)))
	end
	self.nameLabel:SetText(self.skillName)

	self:AddXPToAnimate(lastRankXP, nextRankXP, currentXP)
end

function HarvensExperienceBar:PlayAnimations()
	local queuedXP = table.remove(self.queuedXP, 1)
	if queuedXP then
		ZO_StatusBar_SmoothTransition(
			self.bar,
			(queuedXP.current - queuedXP.last) / (queuedXP.next - queuedXP.last) * 100,
			100,
			nil,
			function()
				self:PlayAnimations()
			end
		)
	end
end

function HarvensExperienceBar:AddXPToAnimate(lastRankXP, nextRankXP, currentXP)
	table.insert(self.queuedXP, {last = lastRankXP, next = nextRankXP, current = currentXP})

	self:PlayAnimations()
end

function HarvensExperienceBar:UpdateRank(rank)
	if not self.showRank then
		self.rankLabel:SetText("")
		return
	end
	if not rank then
		if self.ability then
			if self.skillLineData:IsPassive() then
				rank = ""
			else
				local progression = self.skillLineData:GetCurrentProgressionData()
				if progression:HasRankData() then
					rank = progression:GetCurrentRank() or 0
				else
					rank = ""
				end
			end
		elseif self.skillType == -1 then
			rank = GetUnitLevel("player")
		elseif self.skillType == -2 then
			rank = GetUnitAvARank("player")
		elseif self.skillType == -3 then
			rank = GetPlayerChampionPointsEarned()
		elseif self.skillType == -4 then
			if RequestTributeClubData() == TRIBUTE_PLAYER_INITIALIZATION_STATE_SUCCESS then
				rank = GetTributePlayerClubRank() + 1
			else
				rank = "?"
			end
		elseif self.skillType == -100 then
			rank = ZO_COMPANION_MANAGER:GetLevelInfo()
		elseif self.skillType == -101 then
			rank = GetActiveCompanionRapportLevel()
		elseif self.skillLineData and self.skillLineData.GetCurrentRank then
			rank = self.skillLineData:GetCurrentRank()
		else
			rank = ""
		end
	end
	if self.rankLabel.lastRank ~= rank then
		self.rankLabel.lastRank = rank
		self.bar:PlayAutoHideAnim()
		self.rankLabel:SetText(tostring(rank))
	end
end

do
	local function OnSkillLineUpdated(self, skillLineData)
		if self.skillLineData ~= skillLineData then
			return
		end
		local lastRankXP, nextRankXP, currentXP = skillLineData:GetRankXPValues()
		self:UpdateProgress(lastRankXP, nextRankXP, currentXP)
	end
	local function OnSkillLineRankUpdated(self, skillLineData)
		if self.skillLineData ~= skillLineData then
			return
		end
		local rank = skillLineData:GetCurrentRank()
		self:UpdateRank(rank)
	end
	local function OnSkillLineXPUpdated(self, skillLineData)
		return OnSkillLineUpdated(self, skillLineData)
	end
	local function OnSkillProgressionUpdated(self, skillData)
		if self.skillLineData ~= skillData then
			return
		end
		local progression = skillData:GetCurrentProgressionData()
		local rank = progression:GetCurrentRank()
		local lastRankXP, nextRankXP = progression:GetRankXPExtents(rank)
		local currentXP = progression:GetCurrentXP()
		self:UpdateProgress(lastRankXP, nextRankXP, currentXP)
		self:UpdateRank(rank)
	end
	function HarvensExperienceBar:RegisterHandlers()
		if self.ability then
			self.dataManager:RegisterCallback("SkillLineUpdated", OnSkillLineUpdated, self)
			self.dataManager:RegisterCallback("SkillLineRankUpdated", OnSkillLineRankUpdated, self)
			self.dataManager:RegisterCallback("SkillProgressionUpdated", OnSkillProgressionUpdated, self)
		elseif self.skillType == -1 then
			self.bar:RegisterForEvent(
				EVENT_EXPERIENCE_UPDATE,
				function(_, _, currentExp, maxExp, reason)
					if maxExp > 0 then
						self:UpdateProgress(0, maxExp, currentExp)
					end
				end
			)
			self.bar:RegisterForEvent(
				EVENT_LEVEL_UPDATE,
				function(_, unit, level)
					if unit ~= "player" then
						return
					end
					self:UpdateRank(level)
				end
			)
		elseif self.skillType == -2 then
			self.bar:RegisterForEvent(
				EVENT_ALLIANCE_POINT_UPDATE,
				function(_, alliancePoints)
					local currentXP = GetUnitAvARankPoints("player")
					self:UpdateRank()
					local _, _, lastRankXP, nextRankXP = GetAvARankProgress(currentXP)
					self:UpdateProgress(lastRankXP, nextRankXP, currentXP)
				end
			)
		elseif self.skillType == -3 then
			self.bar:RegisterForEvent(
				EVENT_EXPERIENCE_GAIN,
				function(_, _, _, _, _, championPoints)
					self:UpdateProgress(0, GetNumChampionXPInChampionPoint(GetPlayerChampionPointsEarned()), GetPlayerChampionXP())
				end
			)
			self.bar:RegisterForEvent(
				EVENT_CHAMPION_POINT_GAINED,
				function()
					self:UpdateRank()
				end
			)
		elseif self.skillType == -4 then
			self.bar:RegisterForEvent(
				EVENT_TRIBUTE_CLUB_EXPERIENCE_GAINED,
				function()
					self:UpdateRank()
					local currentXP, nextRankXP = GetTributePlayerExperienceInCurrentClubRank()
					self:UpdateProgress(0, nextRankXP, currentXP)
				end
			)
			self.bar:RegisterForEvent(
				EVENT_TRIBUTE_CLUB_RANK_CHANGED,
				function()
					self:UpdateRank()
				end
			)
			self.bar:RegisterForEvent(
				EVENT_TRIBUTE_CLUB_INIT,
				function(_, success)
					if success then
						self:UpdateRank()
						self:UpdateProgress(0, GetNumChampionXPInChampionPoint(GetPlayerChampionPointsEarned()), GetPlayerChampionXP())
					end
				end
			)
		elseif self.skillType == -100 then
			self.bar:RegisterForEvent(
				EVENT_COMPANION_EXPERIENCE_GAIN,
				function()
					local level, currentXP, nextRankXP = ZO_COMPANION_MANAGER:GetLevelInfo()
					self:UpdateRank(level)
					self:UpdateProgress(0, nextRankXP, currentXP)
				end
			)
		elseif self.skillType == -101 then
			self.bar:RegisterForEvent(
				EVENT_COMPANION_RAPPORT_UPDATE,
				function(_, _, _, currentXP)
					self:UpdateRank()
					local lastRankXP, nextRankXP = GetMinimumRapport(), GetMaximumRapport()
					self:UpdateProgress(lastRankXP, nextRankXP, currentXP)
				end
			)
		else
			self.dataManager:RegisterCallback("SkillLineUpdated", OnSkillLineUpdated, self)
			self.dataManager:RegisterCallback("SkillLineXPUpdated", OnSkillLineXPUpdated, self)
			self.dataManager:RegisterCallback("SkillLineRankUpdated", OnSkillLineRankUpdated, self)
		end
	end

	function HarvensExperienceBar:UnregisterHandlers()
		if self.ability then
			self.dataManager:UnregisterCallback("SkillLineUpdated", OnSkillLineUpdated, self)
			self.dataManager:UnregisterCallback("SkillLineRankUpdated", OnSkillLineRankUpdated, self)
			self.dataManager:UnregisterCallback("SkillProgressionUpdated", SkillProgressionUpdated, self)
		elseif self.skillType == -1 then
			self.bar:UnregisterForEvent(EVENT_EXPERIENCE_UPDATE)
			self.bar:UnregisterForEvent(EVENT_LEVEL_UPDATE)
		elseif self.skillType == -2 then
			self.bar:UnregisterForEvent(EVENT_ALLIANCE_POINT_UPDATE)
		elseif self.skillType == -3 then
			self.bar:UnregisterForEvent(EVENT_EXPERIENCE_GAIN)
			self.bar:UnregisterForEvent(EVENT_CHAMPION_POINT_GAINED)
		elseif self.skillType == -4 then
			self.bar:UnregisterForEvent(EVENT_TRIBUTE_CLUB_EXPERIENCE_GAINED)
			self.bar:UnregisterForEvent(EVENT_TRIBUTE_CLUB_RANK_CHANGED)
			self.bar:UnregisterForEvent(EVENT_TRIBUTE_CLUB_INIT)
		elseif self.skillType == -100 then
			self.bar:UnregisterForEvent(EVENT_COMPANION_EXPERIENCE_GAIN)
		elseif self.skillType == -101 then
			self.bar:UnregisterForEvent(EVENT_COMPANION_RAPPORT_UPDATE)
		else
			self.dataManager:UnregisterCallback("SkillLineUpdated", OnSkillLineUpdated, self)
			self.dataManager:UnregisterCallback("SkillLineXPUpdated", OnSkillLineXPUpdated, self)
			self.dataManager:UnregisterCallback("SkillLineRankUpdated", OnSkillLineRankUpdated, self)
		end
	end
end

function HarvensExperienceBar:Destroy()
	self.barsPool:ReleaseObject(self.barKey)
end

function HarvensExperienceBar:setupNameLabel()
	self.nameLabel:ClearAnchors()
	self.skillProgressLabel:ClearAnchors()
	self.rankLabel:ClearAnchors()
	self.gainLabel:ClearAnchors()

	local align = self.bar.alignment == BAR_ALIGNMENT_REVERSE and RIGHT or LEFT
	local notAlign = self.bar.alignment == BAR_ALIGNMENT_REVERSE and LEFT or RIGHT
	local sign = self.bar.alignment == BAR_ALIGNMENT_REVERSE and -1 or 1

	if self.showRank then
		if self.rankNextToName then
			if self.isLabelInside then
				self.rankLabel:SetAnchor(align, self.bar, align, 2 * sign, 0)
				self.rankLabel:SetFont(self.FONT_RANK_INSIDE)
			else
				self.rankLabel:SetAnchor(align, self.bar, align, 5 * sign, -24)
				self.rankLabel:SetFont(self.FONT_RANK_OUTSIDE)
			end
		else
			self.rankLabel:SetAnchor(notAlign, self.bar, align, -5 * sign, -2)
			self.rankLabel:SetFont(self.FONT_RANK_SIDE)
		end
	end

	if self.isLabelInside then
		if self.showRank and self.rankNextToName then
			self.nameLabel:SetAnchor(align, self.rankLabel, notAlign, 5 * sign, 0)
		else
			self.nameLabel:SetAnchor(align, self.bar, align, 2 * sign, 0)
		end
		self.nameLabel:SetFont(self.FONT_SKILL_NAME_INSIDE)
		self.skillProgressLabel:SetAnchor(align, self.nameLabel, notAlign, 5 * sign, 0)
	else
		if self.showRank and self.rankNextToName then
			self.nameLabel:SetAnchor(align, self.rankLabel, notAlign, 6 * sign, 0)
		else
			self.nameLabel:SetAnchor(align, self.bar, align, 5 * sign, -24)
		end
		self.nameLabel:SetFont(self.FONT_SKILL_NAME_OUTSIDE)
		self.skillProgressLabel:SetAnchor(align, self.bar, align, 5 * sign, 0)
	end
	self:UpdateRank()
	self.nameLabel:SetText(ZO_CachedStrFormat(SI_SKILLS_ENTRY_LINE_NAME_FORMAT, self.skillName))
	self.gainLabel:SetAnchor(align, self.bar, notAlign, 5 * sign)
	self.gainLabel:SetFont(self.FONT_EXPERIENCE_GAIN)
	self.skillProgressLabel:SetFont(self.FONT_SKILL_PROGRESS)
end

do
	local temp = {}
	function HarvensExperienceBar.CreateKey(skillType, skillLine, abilityIndex, skillsMode)
		skillsMode = skillsMode or "p"
		if skillsMode == "p" then -- legacy
			temp[1], temp[2], temp[3], temp[4] = skillType, skillLine, abilityIndex
		else
			temp[1], temp[2], temp[3], temp[4] = skillsMode, skillType, skillLine, abilityIndex
		end
		return table.concat(temp, " ")
	end
end

local function intersects(rectA, rectB)
	return rectA.left < rectB.right and rectB.left < rectA.right and rectA.top < rectB.bottom and rectB.top < rectA.bottom
end

function HarvensExperienceBar:Create(barSettings, skillType, skillLine, abilityIndex, skillsMode)
	skillsMode = skillsMode or "p"

	self.skillType = skillType
	self.skillLine = skillLine
	self.abilityIndex = abilityIndex
	self.skillsMode = skillsMode

	local dataManager = skillsMode == "p" and SKILLS_DATA_MANAGER or COMPANION_SKILLS_DATA_MANAGER
	self.dataManager = dataManager

	if skillsMode == "p" then
		self.skillLineData = dataManager:GetSkillDataByIndices(skillType, skillLine, abilityIndex)
	else
		self.skillLineData = dataManager:GetSkillDataByAbilityId(skillLine)
	end
	if self.skillLineData then
		-- skillLineData is skillData
		self.ability = true
	else
		self.skillLineData = dataManager:GetSkillLineDataByIndices(skillType, skillLine)
		self.ability = false
	end

	local lastRankXP, nextRankXP = 0, 0
	if not self.ability then
		if skillType == -1 then
			lastRankXP = 0
			self.skillName = GetString(SI_EXPERIENCE_LEVEL_LABEL)
			self.currentXP = GetUnitXP("player")
			nextRankXP = GetUnitXPMax("player")
		elseif skillType == -2 then
			self.currentXP = GetUnitAvARankPoints("player")
			_, _, lastRankXP, nextRankXP = GetAvARankProgress(self.currentXP)
			self.skillName = GetString(SI_CHATCHANNELCATEGORIES48)
		elseif skillType == -3 then
			lastRankXP = 0
			self.currentXP = GetPlayerChampionXP()
			self.skillName = GetString(SI_EXPERIENCE_CHAMPION_LABEL)
			nextRankXP = GetNumChampionXPInChampionPoint(GetPlayerChampionPointsEarned())
		elseif skillType == -4 then
			lastRankXP = 0
			self.currentXP, nextRankXP = GetTributePlayerExperienceInCurrentClubRank()
			self.skillName = GetString(SI_ACTIVITY_FINDER_CATEGORY_TRIBUTE)
		elseif skillType == -100 then
			lastRankXP = 0
			self.currentXP, nextRankXP = select(2, ZO_COMPANION_MANAGER:GetLevelInfo())
			self.skillName = GetString(SI_COMPANION_LEVEL_LABEL)
		elseif skillType == -101 then
			lastRankXP, nextRankXP = GetMinimumRapport(), GetMaximumRapport()
			self.currentXP = GetActiveCompanionRapport()
			self.skillName = GetString(SI_COMPANION_OVERVIEW_RAPPORT)
		elseif self.skillLineData then
			lastRankXP, nextRankXP, self.currentXP = self.skillLineData:GetRankXPValues()
			self.skillName = self.skillLineData:GetFormattedName()
		else
			lastRankXP, nextRankXP, self.currentXP = 0, 0, 0
			self.skillName = "-"
		end
	elseif self.skillLineData then
		local progression = self.skillLineData:GetCurrentProgressionData() -- is skillData
		if progression then
			if progression.GetCurrentRank and not self.skillLineData:IsPassive() then
				local rank = progression:GetCurrentRank()
				lastRankXP, nextRankXP = progression:GetRankXPExtents(rank)
				self.currentXP = progression:GetCurrentXP()
			elseif self.skillLineData.GetNumRanks then
				lastRankXP, nextRankXP = 0, self.skillLineData:GetNumRanks()
				self.currentXP = self.skillLineData:IsPurchased() and self.skillLineData:GetCurrentRank() or 0
			end
		else
			-- lastRankXP, nextRankXP = 0, 1
			-- self.currentXP = self.skillLineData:IsPurchased() and 1 or 0
			lastRankXP, nextRankXP, self.currentXP = 0, 0, 0
		end
		self.skillName = progression and progression:GetFormattedName()
	else
		lastRankXP, nextRankXP, self.currentXP = 0, 0, 0
		self.skillName = "-"
	end

	local bar, barKey = self.barsPool:AcquireObject()
	self.bar = bar
	self.barKey = barKey
	bar.m_object = self

	local defaults = HarvensAllExperienceBars.sv.defaults

	bar:ClearAnchors()
	local labelsColor = defaults.textColor
	local autoHide = false
	local barColor = defaults.color
	if barSettings then
		local anchor = barSettings.anchor
		bar:SetAnchor(anchor.pos, HarvensAllExperienceBars.container, anchor.relPos, anchor.x, anchor.y)
		self.isLabelInside = barSettings.isLabelInside
		self.showRank = barSettings.showRank
		self.rankNextToName = barSettings.rankNextToName
		autoHide = HarvensAllExperienceBars.sv.autoHide
		if barSettings.scale then
			bar:SetScale(barSettings.scale)
		else
			bar:SetScale(defaults.scale)
		end
		if barSettings.width then
			bar:SetWidth(barSettings.width)
		else
			bar:SetWidth(defaults.width)
		end
		if barSettings.barColor then
			local cr, cb, cg, ca = unpack(barSettings.barColor)
			bar:SetGradientColors(cr, cb, cg, ca, cr, cb, cg, ca)
		else
			local cr, cb, cg, ca = unpack(barColor)
			bar:SetGradientColors(cr, cb, cg, ca, cr, cb, cg, ca)
			barSettings.barColor = {cr, cb, cg, ca}
		end
		if barSettings.labelsColor then
			labelsColor = barSettings.labelsColor
		else
			local cr, cb, cg, ca = unpack(labelsColor)
			barSettings.labelsColor = {cr, cb, cg, ca}
		end
	else
		bar:SetAnchor(CENTER, HarvensAllExperienceBars.container, CENTER)
		self.isLabelInside = not defaults.nameOutside
		self.rankNextToName = not defaults.rankOnSide
		self.showRank = defaults.showRank
		bar:SetScale(defaults.scale)
		bar:SetWidth(defaults.width)
		local cr, cb, cg, ca = unpack(barColor)
		bar:SetGradientColors(cr, cb, cg, ca, cr, cb, cg, ca)
	end

	self.rankLabel = bar:GetNamedChild("SkillRank")
	self.rankLabel:SetColor(unpack(labelsColor))
	self.skillProgressLabel = bar:GetNamedChild("SkillProgress")
	self.skillProgressLabel:SetColor(unpack(labelsColor))
	self.nameLabel = bar:GetNamedChild("SkillName")
	self.nameLabel:SetColor(unpack(labelsColor))

	self.gainLabel = bar:GetNamedChild("Gain")
	self.gainLabel:SetHidden(true)
	self.gainLabel:SetColor(unpack(labelsColor))

	nextRankXP = nextRankXP or 0
	if nextRankXP <= lastRankXP then
		bar:SetValue(100)
	else
		bar:SetValue((self.currentXP - lastRankXP) / (nextRankXP - lastRankXP) * 100)
	end

	if nextRankXP > 0 then
		if HarvensAllExperienceBars.sv.displayPercentage then
			local perc = 100 * (self.currentXP - lastRankXP) / (nextRankXP - lastRankXP)
			perc = string.format("%.1f%%", perc)
			self.skillProgressLabel:SetText(perc)
		else
			self.skillProgressLabel:SetText(string.format("%i/%i", (self.currentXP - lastRankXP), (nextRankXP - lastRankXP)))
		end
	else
		self.skillProgressLabel:SetText("")
	end
	self:setupNameLabel()

	if not barSettings then
		local startTop, endTop = GuiRoot:GetHeight() / 4, GuiRoot:GetHeight() * 3 / 5

		self.bar:ClearAnchors()
		self.bar:SetAnchor(TOPLEFT, nil, TOPLEFT, 96, GuiRoot:GetHeight() / 4)

		local left, mostBottom = 0, 0
		local rectA = {left = bar:GetLeft() - 96, right = bar:GetRight() + 96, top = bar:GetTop() - 22, bottom = bar:GetBottom()}
		local h, w = rectA.bottom - rectA.top, rectA.right - rectA.left
		local others = {}
		for _, bar in pairs(self.barsPool:GetActiveObjects()) do
			if bar ~= self.bar then
				local rectB = {left = bar:GetLeft() - 96, right = bar:GetRight() + 96, top = bar:GetTop() - 22, bottom = bar:GetBottom()}
				others[#others + 1] = rectB
			end
		end
		local overlapped
		repeat
			overlapped = false
			for _, rectB in pairs(others) do
				if intersects(rectA, rectB) then
					overlapped = true
					break
				end
			end
			if overlapped then
				rectA.top = rectA.top + h
				if rectA.top > endTop then
					rectA.top = startTop
					rectA.left = rectA.left + w
					rectA.right = rectA.left + w
				end
				rectA.bottom = rectA.top + h
			end
		until not overlapped

		self.bar:ClearAnchors()
		self.bar:SetAnchor(TOPLEFT, nil, TOPLEFT, rectA.left + 96, rectA.top + 22)

		local _, pos, _, relPos, x, y = self.bar:GetAnchor(0)
		local scale = self.bar:GetScale()
		local width = self.bar:GetWidth()
		local lr, lg, lb, la = unpack(labelsColor)
		local br, bg, bb, ba = unpack(barColor)
		barSettings = {
			autoHide = autoHide,
			labelsColor = {lr, lg, lb, la},
			barColor = {br, bg, bb, ba},
			skillType = skillType,
			skillLine = skillLine,
			abilityIndex = abilityIndex,
			skillsMode = skillsMode,
			alignment = defaults.alignLeft and BAR_ALIGNMENT_NORMAL or BAR_ALIGNMENT_REVERSE,
			isLabelInside = self.isLabelInside,
			showRank = self.showRank,
			rankNextToName = self.rankNextToName,
			scale = self.scale,
			width = self.width,
			anchor = {
				pos = pos,
				relPos = relPos,
				x = x,
				y = y
			}
		}
	end
	self.barSettings = barSettings

	self:SetAlignment(barSettings.alignment)
	bar:ApplyGrid()
	bar:SetHidden(autoHide)

	self:RegisterHandlers()

	return self.barSettings
end

---- HarvensAllExperienceBars ----

function HarvensAllExperienceBars:ToggleHidden()
	for k in pairs(self.experienceBars) do
		self.experienceBars[k].bar:SetHidden(self.sv.autoHide)
	end
end

function HarvensAllExperienceBars:RebuildList()
	for _, bar in pairs(self.experienceBars) do
		bar:Destroy()
	end
	ZO_ClearTable(self.experienceBars)
	local companionId = GetActiveCompanionDefId()
	if companionId > 0 then
		self.companions = ZO_SavedVars:New("HarvensAllExperienceBars_SavedVariables", 1, nil, {bars = {}}, GetWorldName(), GetDisplayName(), nil, companionId, ZO_SAVED_VARS_CHARACTER_ID_KEY)
	else
		self.companions = {bars = {}}
	end
	for _, bar in pairs(self.sv.bars) do
		self:AddStatusBar(bar, bar.skillType, bar.skillLine, bar.abilityIndex, bar.skillsMode)
	end
	for _, bar in pairs(self.companions.bars) do
		self:AddStatusBar(bar, bar.skillType, bar.skillLine, bar.abilityIndex, bar.skillsMode)
	end
end

function HarvensAllExperienceBars:SetupOptions()
	local LibHarvensAddonSettings = LibHarvensAddonSettings
	local settings = LibHarvensAddonSettings:AddAddon("Harven's All Experience Bars")
	if not settings then
		return
	end
	settings.version = "2.8.4"

	local autoHide = {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Auto Hide Experience Bars",
		getFunction = function()
			return self.sv.autoHide
		end,
		setFunction = function(state)
			self.sv.autoHide = state
			self:ToggleHidden()
		end
	}

	local defaultSection = {
		type = LibHarvensAddonSettings.ST_SECTION,
		label = "Default Settings"
	}

	local defaultAlignment = {
		type = LibHarvensAddonSettings.ST_DROPDOWN,
		label = "Default Alignment",
		getFunction = function()
			if self.sv.defaults.alignLeft then
				return "Left"
			end
			return "Right"
		end,
		setFunction = function(_, align)
			if align == "Left" then
				self.sv.defaults.alignLeft = true
			else
				self.sv.defaults.alignLeft = false
			end
		end,
		items = {{name = "Left"}, {name = "Right"}}
	}

	local defaultNamePos = {
		type = LibHarvensAddonSettings.ST_DROPDOWN,
		label = "Ability/Skill Name Default Position",
		getFunction = function()
			if self.sv.defaults.nameOutside then
				return "Outside"
			end
			return "Inside"
		end,
		setFunction = function(_, namePos)
			if namePos == "Outside" then
				self.sv.defaults.nameOutside = true
			else
				self.sv.defaults.nameOutside = false
			end
		end,
		items = {{name = "Outside"}, {name = "Inside"}}
	}

	local defaultRankPos = {
		type = LibHarvensAddonSettings.ST_DROPDOWN,
		label = "Ability/Skill Rank Default Position",
		getFunction = function()
			if self.sv.defaults.rankOnSide then
				return "On Bar Side"
			end
			return "Next To Name"
		end,
		setFunction = function(_, rankPos)
			if rankPos == "On Bar Side" then
				self.sv.defaults.rankOnSide = true
			else
				self.sv.defaults.rankOnSide = false
			end
		end,
		items = {{name = "Next To Name"}, {name = "On Bar Side"}}
	}

	local showRank = {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Show Rank",
		getFunction = function()
			return self.sv.defaults.showRank
		end,
		setFunction = function(state)
			self.sv.defaults.showRank = state
		end
	}

	local defaultColor = {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = "Default Background Color",
		getFunction = function()
			return unpack(self.sv.defaults.color)
		end,
		setFunction = function(re, br, bl, al)
			self.sv.defaults.color = {re, br, bl, al}
		end
	}

	local defaultTextColor = {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = "Default Text Color",
		getFunction = function()
			return unpack(self.sv.defaults.textColor)
		end,
		setFunction = function(re, br, bl, al)
			self.sv.defaults.textColor = {re, br, bl, al}
		end
	}

	local defaultScale = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Default Scale",
		getFunction = function()
			return self.sv.defaults.scale
		end,
		setFunction = function(value)
			self.sv.defaults.scale = value
		end,
		format = "%.1f",
		min = 0.1,
		max = 10,
		step = 0.1
	}

	local defaultWidth = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Default Width",
		getFunction = function()
			return self.sv.defaults.width
		end,
		setFunction = function(value)
			self.sv.defaults.width = value
		end,
		format = "%d",
		min = 10,
		max = 1500,
		step = 10
	}

	local gridSize = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Grid Size",
		getFunction = function()
			return self.account.gridSize
		end,
		setFunction = function(value)
			self.account.gridSize = value
		end,
		format = "%d",
		min = 1,
		max = 48,
		step = 1
	}
	local applyGrid = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		buttonText = "Apply Grid",
		clickHandler = function(control)
			for _, bar in pairs(HarvensExperienceBar.barsPool:GetActiveObjects()) do
				bar:ApplyGrid()
			end
		end
	}

	local progressDisplay = {
		type = LibHarvensAddonSettings.ST_DROPDOWN,
		label = "Progress Display",
		getFunction = function()
			if self.sv.displayPercentage then
				return "Percentage"
			end
			return "Min/Max"
		end,
		tooltip = "Requires /reloadui",
		setFunction = function(_, val)
			if val == "Percentage" then
				self.sv.displayPercentage = true
			else
				self.sv.displayPercentage = false
			end
		end,
		items = {{name = "Min/Max"}, {name = "Percentage"}}
	}

	settings:AddSettings(
		{
			autoHide,
			progressDisplay,
			defaultSection,
			defaultAlignment,
			defaultNamePos,
			defaultRankPos,
			defaultColor,
			defaultTextColor,
			defaultScale,
			defaultWidth,
			showRank,
			gridSize,
			applyGrid,
			{
				type = LibHarvensAddonSettings.ST_SECTION,
				label = "Setup"
			},
			{
				type = LibHarvensAddonSettings.ST_CHECKBOX,
				label = "New Character Template Bars",
				tooltip = "",
				getFunction = function()
					return self.account.createTemplateBars
				end,
				setFunction = function(state)
					self.account.createTemplateBars = state
				end
			},
			{
				type = LibHarvensAddonSettings.ST_LABEL,
				label = string.format("%s\n%s", ZO_HINT_TEXT:Colorize("How to use:"), ZO_TOOLTIP_DEFAULT_COLOR:Colorize("Open the skills, alliance war or character menu and hover the ability/skill line/bar you want to track on HUD and press the keybind showing."))
			}
		}
	)
end

function HarvensAllExperienceBars:UpdateKeybinds()
	if KEYBIND_STRIP:HasKeybindButtonGroup(self.keybindStripDescriptor) then
		KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
	end
end

function HarvensAllExperienceBars:InitializeKeybindDescriptors()
	if self.keybindStripDescriptor then
		return
	end

	self.keybindStripDescriptor = {
		alignment = KEYBIND_STRIP_ALIGN_RIGHT,
		{
			name = function()
				if not (self.selectedSkillProgressionData or self.selectedSkillLineData) then
					return ""
				end
				local skillType, skillLineIndex, skillIndex
				if self.skillsMode == "p" then
					skillType, skillLineIndex, skillIndex = (self.selectedSkillLineData or self.selectedSkillProgressionData):GetIndices()
				elseif self.skillsMode == "c" then
					if self.selectedSkillProgressionData then
						local skillData = self.selectedSkillProgressionData:GetSkillData()
						skillType, skillLineIndex, skillIndex = skillData:GetCompanionIndices()
					elseif self.selectedSkillLineData then
						skillType, skillLineIndex, skillIndex = self.selectedSkillLineData:GetIndices()
					end
				end
				local key = HarvensExperienceBar.CreateKey(skillType, skillLineIndex, skillIndex, self.skillsMode)
				if self.experienceBars[key] then
					return "Remove from HUD"
				else
					return "Track on HUD"
				end
			end,
			keybind = "UI_SHORTCUT_PRIMARY", -- UI_SHORTCUT_TERTIARY
			callback = function()
				local skillType, skillLineIndex, skillIndex
				if self.skillsMode == "p" then
					skillType, skillLineIndex, skillIndex = (self.selectedSkillLineData or self.selectedSkillProgressionData):GetIndices()
				elseif self.skillsMode == "c" then
					if self.selectedSkillProgressionData then
						local skillData = self.selectedSkillProgressionData:GetSkillData()
						skillType, skillLineIndex = skillData:GetCompanionIndices()
						skillIndex = skillData:GetAbilityId()
					elseif self.selectedSkillLineData then
						skillType, skillLineIndex, skillIndex = self.selectedSkillLineData:GetIndices()
					end
				end
				local key = HarvensExperienceBar.CreateKey(skillType, skillLineIndex, skillIndex, self.skillsMode)
				if self.skillsMode == "c" then
					self.companions.bars[key] = self:AddStatusBar(nil, skillType, skillLineIndex, skillIndex, self.skillsMode)
				else
					self.sv.bars[key] = self:AddStatusBar(nil, skillType, skillLineIndex, skillIndex, self.skillsMode)
				end

				PlaySound(SOUNDS["DEFAULT_CLICK"])
				self:UpdateKeybinds()
			end,
			visible = function()
				return (self.selectedSkillLineData or self.selectedSkillProgressionData) ~= nil
			end
		}
	}

	local function exit()
		self.selectedSkillLineData = nil
		self.selectedSkillProgressionData = nil
		self:UpdateKeybinds()
	end
	SecurePostHook(
		_G,
		"ZO_Skills_AbilitySlot_OnMouseEnter",
		function(control)
			local skillProgressionData = control.skillProgressionData
			if skillProgressionData and skillProgressionData.GetIndices then
				self.selectedSkillProgressionData = skillProgressionData
				self:UpdateKeybinds()
			end
		end
	)
	SecurePostHook(_G, "ZO_Skills_AbilitySlot_OnMouseExit", exit)

	SecurePostHook(
		_G,
		"ZO_SkillInfoXPBar_OnMouseEnter",
		function(control)
			self.selectedSkillLineData = control.skillLineData
			self:UpdateKeybinds()
		end
	)
	SecurePostHook(_G, "ZO_SkillInfoXPBar_OnMouseExit", exit)

	SecurePostHook(
		PLAYER_PROGRESS_BAR,
		"Bar_OnMouseEnter",
		function(PlayerProgress)
			local barTypeInfo = PlayerProgress:GetBarTypeInfo()
			if not barTypeInfo then
				return
			end
			if barTypeInfo.barTypeId == PPB_CLASS_XP then
				self.selectedSkillLineData = {
					GetIndices = function()
						return -1
					end
				}
				self:UpdateKeybinds()
			elseif barTypeInfo.barTypeId == PPB_CLASS_CP then
				self.selectedSkillLineData = {
					GetIndices = function()
						return -3
					end
				}
				self:UpdateKeybinds()
			end
		end
	)
	SecurePostHook(PLAYER_PROGRESS_BAR, "Bar_OnMouseExit", exit)

	SecurePostHook(
		_G,
		"ZO_CampaignAvARankStatusBar_OnMouseEnter",
		function(PlayerProgress)
			self.selectedSkillLineData = {
				GetIndices = function()
					return -2
				end
			}
			self:UpdateKeybinds()
		end
	)
	SecurePostHook(_G, "ZO_CampaignAvARankStatusBar_OnMouseExit", exit)

	if COMPANION_PROGRESS_KEYBOARD then
		local function onMouseEnter()
			if not HasActiveCompanion() then
				return
			end
			self.selectedSkillLineData = {
				GetIndices = function()
					return -100
				end
			}
			self:UpdateKeybinds()
		end
		SecurePostHook(COMPANION_PROGRESS_KEYBOARD.progressBar, "OnMouseEnter", onMouseEnter)
		SecurePostHook(COMPANION_PROGRESS_KEYBOARD.progressBar, "OnMouseExit", exit)
		SecurePostHook(COMPANION_OVERVIEW_KEYBOARD.levelBar, "OnMouseEnter", onMouseEnter)
		SecurePostHook(COMPANION_OVERVIEW_KEYBOARD.levelBar, "OnMouseExit", exit)
	end
	if COMPANION_OVERVIEW_KEYBOARD then
		local function onMouseEnter()
			if not HasActiveCompanion() then
				return
			end
			self.selectedSkillLineData = {
				GetIndices = function()
					return -101
				end
			}
			self:UpdateKeybinds()
		end
		local control = COMPANION_OVERVIEW_KEYBOARD.rapportBar.control
		control:SetMouseEnabled(true)
		control:SetHandler("OnMouseEnter", onMouseEnter, "HarvensAllExperienceBars")
		control:SetHandler("OnMouseExit", exit, "HarvensAllExperienceBars")
	end
	if TRIBUTE_FINDER_MANAGER then
		local function onMouseEnter()
			self.selectedSkillLineData = {
				GetIndices = function()
					return -4
				end
			}
			self:UpdateKeybinds()
		end
		local control = TRIBUTE_FINDER_MANAGER.keyboardObject.clubRankObject.statusBar
		control:SetMouseEnabled(true)
		control:SetHandler("OnMouseEnter", onMouseEnter, "HarvensAllExperienceBars")
		control:SetHandler("OnMouseExit", exit, "HarvensAllExperienceBars")
	end
end

function HarvensAllExperienceBars:AddStatusBar(barSettings, skillType, skillLine, abilityIndex, skillsMode)
	skillsMode = skillsMode or self.skillsMode
	local key = HarvensExperienceBar.CreateKey(skillType, skillLine, abilityIndex, skillsMode)
	if self.experienceBars[key] then
		self:RemoveStatusBar(key)
	else
		local newBar = HarvensExperienceBar:New()
		newBar:Create(barSettings, skillType, skillLine, abilityIndex, skillsMode)
		self.experienceBars[key] = newBar
		return newBar.barSettings
	end
end

function HarvensAllExperienceBars:RemoveStatusBar(key)
	local bar = self.experienceBars[key]
	if bar then
		bar:Destroy()
	end
	self.experienceBars[key] = nil
	if bar.skillsMode == "c" then
		self.companions.bars[key] = nil
	else
		self.sv.bars[key] = nil
	end
end

function HarvensAllExperienceBars:Initialize()
	HARVENS_ALL_EXPERIENCE_BARS = self

	self.container = CreateTopLevelWindow("HarvensAllExperienceBars")
	self.container:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT)
	self.container:SetAnchor(BOTTOMRIGHT, GuiRoot, BOTTOMRIGHT)
	self.container:SetHidden(false)

	local fragment = ZO_SimpleSceneFragment:New(self.container)
	local scene = SCENE_MANAGER:GetScene("hudui")
	scene:AddFragment(fragment)
	scene = SCENE_MANAGER:GetScene("hud")
	scene:AddFragment(fragment)

	HarvensExperienceBar:Initialize()
	self.experienceBars = {}
	local defaults = {bars = {}, first = true}
	self.sv = ZO_SavedVars:NewCharacterIdSettings("HarvensAllExperienceBars_SavedVariables", 1, nil, defaults)
	self.account = ZO_SavedVars:NewAccountWide("HarvensAllExperienceBars_SavedVariables", 1, nil, {createTemplateBars = true, gridSize = 1})

	if not self.sv.defaults then
		self.sv.defaults = {
			alignLeft = true,
			nameOutside = true,
			rankOnSide = true,
			showRank = true,
			color = {
				0.33,
				0.08,
				0.43,
				1
			},
			textColor = {
				1,
				1,
				1,
				1
			},
			scale = 1.0,
			width = 250
		}
	end

	if self.sv.first and self.account.createTemplateBars then
		for i = 1, GetNumSkillLines(SKILL_TYPE_WORLD) do
			local skillLineData = SKILLS_DATA_MANAGER:GetSkillLineDataByIndices(SKILL_TYPE_WORLD, i)
			if skillLineData:IsAvailable() then
				local key = HarvensExperienceBar.CreateKey(SKILL_TYPE_WORLD, i)
				self.sv.bars[key] = self:AddStatusBar(nil, SKILL_TYPE_WORLD, i)
			end
		end
		self.sv.first = false
	end
	self:RebuildList()

	self:SetupOptions()

	local function onStateChange(oldState, newState, skillsMode)
		if newState == SCENE_FRAGMENT_SHOWING then
			self:InitializeKeybindDescriptors()
		elseif newState == SCENE_SHOWN then
			self.skillsMode = skillsMode
			KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
		elseif newState == SCENE_HIDING then
			KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
		end
	end
	local function onStateChangePlayer(oldState, newState)
		return onStateChange(oldState, newState, "p")
	end
	STATS_SCENE:RegisterCallback("StateChange", onStateChangePlayer)
	KEYBOARD_SKILLS_SCENE:RegisterCallback("StateChange", onStateChangePlayer)
	CAMPAIGN_AVA_RANK_FRAGMENT:RegisterCallback("StateChange", onStateChangePlayer)

	if COMPANION_SKILLS_KEYBOARD_FRAGMENT then
		local function onStateChangeCompanion(oldState, newState)
			return onStateChange(oldState, newState, "c")
		end
		COMPANION_SKILLS_KEYBOARD_FRAGMENT:RegisterCallback("StateChange", onStateChangeCompanion)
		COMPANION_PROGRESS_BAR_FRAGMENT:RegisterCallback("StateChange", onStateChangeCompanion)
		COMPANION_CHARACTER_KEYBOARD_SCENE:RegisterCallback("StateChange", onStateChangeCompanion)
		COMPANION_SKILLS_DATA_MANAGER:RegisterCallback("FullSystemUpdated", self.RebuildList, self)
	end

	if TRIBUTE_FINDER_MANAGER then
		TRIBUTE_FINDER_MANAGER.keyboardObject:GetFragment():RegisterCallback("StateChange", onStateChangePlayer)
	end
end

local function HarvensAllExperienceBars_Initialize(eventType, addonName)
	if addonName ~= "HarvensAllExperienceBars" then
		return
	end
	EVENT_MANAGER:UnregisterForEvent("HarvensAllExperienceBarsInitialize", EVENT_ADD_ON_LOADED)

	HarvensAllExperienceBars:Initialize()
end

EVENT_MANAGER:RegisterForEvent("HarvensAllExperienceBarsInitialize", EVENT_ADD_ON_LOADED, HarvensAllExperienceBars_Initialize)
