if VOTANS_ACHIEVEMENTS then
	return
end

local addon = {
	name = "VotansAchievementsOvw",
	localTimeShift = 0
}

local em = GetEventManager()
local ROW_TYPE_ID = 1
local selectedColor = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED))
local disabledColor = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED))

local function GoToAchievement(rowControl)
	if not rowControl then
		return
	end
	local rowData = ZO_ScrollList_GetData(rowControl)
	if not rowData then
		return
	end
	local achievements = SYSTEMS:GetObject("achievements")

	local achievementId = rowData.achievementId

	local categoryIndex, subCategoryIndex = GetCategoryInfoFromAchievementId(achievementId)
	if not achievements:OpenCategory(categoryIndex, subCategoryIndex) then
		if achievements.contentSearchEditBox:GetText() ~= "" then
			achievements.contentSearchEditBox:SetText("")
			local REFRESH_IMMEDIATELY = true
			ACHIEVEMENTS_MANAGER:ClearSearch(REFRESH_IMMEDIATELY)
		end
	end
	if achievements:OpenCategory(categoryIndex, subCategoryIndex) then
		if not achievements.achievementsById then
			return
		end
		local parentAchievementIndex = achievements:GetBaseAchievementId(achievementId)
		if not achievements.achievementsById[parentAchievementIndex] then
			achievements:ResetFilters()
		end
		if not achievements.achievementsById[parentAchievementIndex] then
			for id, row in pairs(achievements.achievementsById) do
				if row.achievementId == achievementId then
					parentAchievementIndex = id
					break
				end
			end
		end
		if achievements.achievementsById[parentAchievementIndex] then
			achievements.achievementsById[parentAchievementIndex]:Expand()
			local identifier = "VotansAchievementsOvwGoToAchievement"

			local function DelayGoto()
				em:UnregisterForUpdate(identifier)
				if achievements.achievementsById and achievements.achievementsById[parentAchievementIndex] then
					ZO_Scroll_ScrollControlIntoCentralView(achievements.contentList, achievements.achievementsById[parentAchievementIndex]:GetControl())
				end
			end
			em:UnregisterForUpdate(identifier)
			em:RegisterForUpdate(identifier, 250, DelayGoto)
		end
	end
end

function addon:AddContextMenuItem(rowControl, rowData)
	AddCustomMenuItem(
		GetString(SI_ITEM_ACTION_LINK_TO_CHAT),
		function()
			ZO_LinkHandler_InsertLink(ZO_LinkHandler_CreateChatLink(GetAchievementLink, rowData.achievementId))
		end
	)
	AddCustomMenuItem(
		GetString(SI_DYEING_SWATCH_VIEW_ACHIEVEMENT),
		function()
			GoToAchievement(rowControl)
		end
	)
end

local function HideRowHighlight(rowControl, hidden)
	if not rowControl then
		return
	end
	if not ZO_ScrollList_GetData(rowControl) then
		return
	end

	local highlight = rowControl:GetNamedChild("Highlight")

	if highlight then
		if not highlight.animation then
			highlight.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ShowOnMouseOverLabelAnimation", highlight)
		end

		if highlight.animation:IsPlaying() then
			highlight.animation:Stop()
		end
		if hidden then
			highlight.animation:PlayBackward()
			ClearTooltip(AchievementTooltip)
		else
			highlight.animation:PlayForward()

			InitializeTooltip(AchievementTooltip, rowControl, TOPRIGHT, 0, -104, TOPLEFT)
			local rowData = ZO_ScrollList_GetData(rowControl)
			addon:ShowTooltip(rowData.achievementId)
		end
	end
end

function addon:ShowTooltip(achievementId)
	AchievementTooltip:VotanClearStatusBars()
	AchievementTooltip:SetAchievement(achievementId)

	local numCriteria = GetAchievementNumCriteria(achievementId)
	if numCriteria == 0 then
		return
	end

	AchievementTooltip:AddVerticalPadding(8)

	local hasMultipleCriteria = numCriteria > 1
	local showProgressBarDescriptions = hasMultipleCriteria
	local lines = nil
	local gender = GetUnitGender("player")
	for i = 1, numCriteria do
		local description, numCompleted, numRequired = GetAchievementCriterion(achievementId, i)
		if numRequired > 1 then
			local statusBar = AchievementTooltip:VotanAddStatusBar()
			statusBar:SetMinMax(0, numRequired)
			statusBar:SetValue(numCompleted)
			statusBar.progress:SetText(string.format("%i/%i", numCompleted, numRequired))
			if hasMultipleCriteria then
				local width = statusBar.progress:GetWidth()
				statusBar.label:SetDimensionConstraints(width, 0, width, 0)
				statusBar.label:SetText(zo_strformat("<<1>>", description, gender))
				statusBar.label:SetColor(((numRequired == numCompleted) and selectedColor or disabledColor):UnpackRGB())
			else
				statusBar.label:SetText("")
			end
		elseif hasMultipleCriteria and (numRequired == 1) then
			lines = lines or {}
			lines[#lines + 1] = (numCompleted == 1 and selectedColor or disabledColor):Colorize(zo_strformat("<<1>>", description, gender))
		end
	end
	if lines and #lines > 0 then
		AchievementTooltip:AddLine(table.concat(lines, "\n"), "ZoFontWinH4", 1, 1, 1, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
	end

	lines = nil
	local function addReward(text, stepCompleted)
		lines = lines or {}
		lines[#lines + 1] = (stepCompleted and selectedColor or disabledColor):Colorize(text)
	end
	local hasReward, completedReward = false, false
	local nextAchievement = ACHIEVEMENTS:GetBaseAchievementId(achievementId)
	local hasRewardOfType, d1, d2, stepCompleted
	while nextAchievement ~= 0 do
		hasReward = hasReward or GetAchievementNumRewards(nextAchievement) > 1
		stepCompleted = select(5, GetAchievementInfo(nextAchievement))
		completedReward = completedReward or (hasReward and stepCompleted)

		hasRewardOfType, d1, d2 = GetAchievementRewardItem(nextAchievement)
		if hasRewardOfType then
			addReward(zo_iconTextFormat(d2, 40, 40, d1), stepCompleted)
		end
		hasRewardOfType, d1 = GetAchievementRewardTitle(nextAchievement)
		if hasRewardOfType then
			addReward(string.format("%s%s", GetString(SI_ACHIEVEMENTS_TITLE), d1), stepCompleted)
		end

		hasRewardOfType, d1 = GetAchievementRewardDye(nextAchievement)
		if hasRewardOfType then
			d1 = GetDyeInfoById(d1)
			addReward(string.format("%s%s", GetString(SI_ACHIEVEMENTS_DYE), zo_strformat(SI_ACHIEVEMENTS_DYE_NAME, d1)), stepCompleted)
		end

		hasRewardOfType, d1 = GetAchievementRewardCollectible(nextAchievement)
		if hasRewardOfType then
			d1 = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(d1)
			addReward(string.format("%s: %s", d1:GetCategoryTypeDisplayName(), d1:GetFormattedName()), stepCompleted)
		end

		nextAchievement = GetNextAchievementInLine(nextAchievement)
	end

	if hasReward then
		if lines and #lines > 0 then
			local rewardThumb = completedReward and "|t32:32:EsoUI/Art/Achievements/achievements_reward_earned.dds|t" or "|t32:32:EsoUI/Art/Achievements/achievements_reward_unearned.dds|t"
			table.insert(lines, 1, rewardThumb)

			AchievementTooltip:AddLine(table.concat(lines, "\n"), "ZoFontWinH4", 1, 1, 1, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
		end
	end
end

function addon:InitScrollList()
	local function onMouseEnter(rowControl)
		HideRowHighlight(rowControl, false)
	end
	local function onMouseExit(rowControl)
		HideRowHighlight(rowControl, true)
	end
	local function onMouseDoubleClick(rowControl)
		GoToAchievement(rowControl)
	end

	local function onClicked(rowControl, button)
		if not rowControl then
			return
		end
		local rowData = ZO_ScrollList_GetData(rowControl)
		if not rowData then
			return
		end
		if button == MOUSE_BUTTON_INDEX_RIGHT and IsChatSystemAvailableForCurrentPlatform() then
			ClearMenu()
			addon:AddContextMenuItem(rowControl, rowData)
			ShowMenu(rowControl)
		end
	end

	local function setupDataRow(rowControl, rowData, scrollList)
		local icon = rowControl:GetNamedChild("Texture")
		local nameLabel = rowControl:GetNamedChild("Name")
		local recentLabel = rowControl:GetNamedChild("Recent")
		local originLabel = rowControl:GetNamedChild("Origin")

		icon:SetTexture(rowData.icon)
		nameLabel:SetText(zo_strformat(rowData.name))
		nameLabel:SetColor((rowData.completed and selectedColor or disabledColor):UnpackRGB())

		local timeStamp = rowData.lastUpdate
		local timeStr = ZO_FormatTime(timeStamp % 86400, TIME_FORMAT_STYLE_CLOCK_TIME, self.ClockFormat)
		recentLabel:SetText(string.format("%s\n%s", timeStr, GetDateStringFromTimestamp(timeStamp - addon.localTimeShift)))

		local topLevelIndex, categoryIndex = GetCategoryInfoFromAchievementId(rowData.achievementId)
		if topLevelIndex then
			local topName = GetAchievementCategoryInfo(topLevelIndex)
			local subName
			if categoryIndex then
				subName = GetAchievementSubCategoryInfo(topLevelIndex, categoryIndex)
			else
				local _, numSubCategories = GetAchievementCategoryInfo(topLevelIndex)
				subName = numSubCategories > 0 and GetString(SI_JOURNAL_PROGRESS_CATEGORY_GENERAL) or ""
			end
			topName = topName:gsub("-", "")
			originLabel:SetText(subName ~= "" and string.format("%s - %s", topName, subName) or topName)
		else
			originLabel:SetText("")
		end

		rowControl:SetHandler("OnMouseEnter", onMouseEnter)
		rowControl:SetHandler("OnMouseExit", onMouseExit)
		rowControl:SetHandler("OnMouseUp", onClicked)
		rowControl:SetHandler("OnMouseDoubleClick", onMouseDoubleClick)
	end
	ZO_ScrollList_AddDataType(self.RecentScrollList, ROW_TYPE_ID, "VotansAchievementRow", 60, setupDataRow)
end

function addon:UpdateScrollList()
	local scrollList = self.RecentScrollList
	local dataList = ZO_ScrollList_GetDataList(scrollList)

	ZO_ScrollList_Clear(scrollList)

	local progress = self.player.progress
	local achievementIds = {}
	for id in pairs(progress) do
		achievementIds[#achievementIds + 1] = id
	end

	table.sort(
		achievementIds,
		function(a, b)
			return (progress[a] == progress[b]) and (a < b) or progress[a] > progress[b]
		end
	)

	local maxEntries = 15
	local top = {}
	local GetAchievementInfo, GetCategoryInfoFromAchievementId, ZO_ScrollList_CreateDataEntry = GetAchievementInfo, GetCategoryInfoFromAchievementId, ZO_ScrollList_CreateDataEntry
	for i = 1, #achievementIds do
		local achievementId = achievementIds[i]
		local name, description, _, icon, completed = GetAchievementInfo(achievementId)
		if not completed then
			if #dataList < maxEntries then
				local topLevelIndex, categoryIndex, achievementIndex = GetCategoryInfoFromAchievementId(achievementId)
				topLevelIndex = topLevelIndex or 0
				categoryIndex = categoryIndex or 0
				achievementIndex = achievementIndex or 0
				local sub = top[topLevelIndex] or {}
				top[topLevelIndex] = sub
				local ach = sub[categoryIndex] or {}
				sub[categoryIndex] = ach
				if not ach[achievementIndex] then
					ach[achievementIndex] = achievementId
					local rowData = {
						name = name,
						icon = icon,
						achievementId = achievementId,
						lastUpdate = progress[achievementId] or 0
					}
					dataList[#dataList + 1] = ZO_ScrollList_CreateDataEntry(ROW_TYPE_ID, rowData, 1)
				end
			end
		else
			progress[achievementId] = nil
		end
	end

	ZO_ScrollList_Commit(scrollList)
end

function addon:SetupControls()
	local function AchievementsStateChange(oldState, newState)
		if newState == SCENE_SHOWING then
			self:UpdateScrollList()
		end
	end

	self.SummaryInset = ZO_AchievementsContents:GetNamedChild("SummaryInset")
	self.ProgressBars = self.SummaryInset:GetNamedChild("ProgressBars")
	self.ProgressBars:SetHidden(true)

	local parent = self.ProgressBars:GetNamedChild("ScrollChild")
	self.SummaryInsetTotal = parent:GetNamedChild("Total")
	self.SummaryInsetTotal:SetParent(self.SummaryInset)
	self.SummaryInsetRecent = self.SummaryInset:GetNamedChild("Recent")

	self.RecentScrollList = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)VotansAchievementsList", self.SummaryInset, "ZO_ScrollList")
	self.RecentScrollList:SetWidth(542)
	self.RecentScrollList:SetAnchor(TOPLEFT, self.SummaryInsetTotal, BOTTOMLEFT, 0, 10)
	self.RecentScrollList:SetAnchor(BOTTOMLEFT, self.SummaryInsetRecent, TOPLEFT, 0, -10)

	self:InitScrollList()

	self.achievementsScene = SCENE_MANAGER:GetScene("achievements")
	self.achievementsScene:RegisterCallback("StateChange", AchievementsStateChange)
end

function addon:HookAchievementRow()
	local function MouseEnter(achievement)
		if achievement.collapsed then
			InitializeTooltip(AchievementTooltip, achievement.control, TOPRIGHT, 0, -104, TOPLEFT)
			addon:ShowTooltip(achievement.achievementId)
		end
	end
	local function MouseExit(control)
		ClearTooltip(AchievementTooltip)
	end

	local orgFactory = ACHIEVEMENTS.achievementPool.m_Factory
	ACHIEVEMENTS.achievementPool.m_Factory = function(...)
		local achievement = orgFactory(...)
		ZO_PreHook(achievement, "OnMouseEnter", MouseEnter)
		ZO_PreHook(achievement, "OnMouseExit", MouseExit)
		return achievement
	end
end

local function SetStatusBar(name, earnedPoints, totalPoints)
	local statusBar = AchievementTooltip:VotanAddStatusBar()
	statusBar:SetMinMax(0, totalPoints)
	statusBar:SetValue(earnedPoints)
	statusBar.label:SetColor(selectedColor:UnpackRGB())
	statusBar.label:SetText(name)
	statusBar.progress:SetText(string.format("%i/%i", earnedPoints, totalPoints))
end

do
	local function AddLine(tooltip, text, color, alignment)
		local r, g, b = color:UnpackRGB()
		tooltip:AddLine(text, "", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, alignment, alignment ~= TEXT_ALIGN_LEFT)
	end

	local function AddLineCenter(tooltip, text, color)
		if not color then
			color = ZO_TOOLTIP_DEFAULT_COLOR
		end
		AddLine(tooltip, text, color, TEXT_ALIGN_CENTER)
	end

	local percentText = {}
	local function GetPercentText(earnedPointsSum, totalPointsSum)
		local percent = zo_round(100 * earnedPointsSum / totalPointsSum)
		if not percentText[percent] then
			percentText[percent] = string.format("%s%%", percent)
		end
		return percentText[percent]
	end
	local nameText = {}
	local function GetCategory(lines, categoryIndex)
		local name, numSubCategories, _, earnedPointsSum, totalPointsSum = GetAchievementCategoryInfo(categoryIndex)

		if not nameText[name] then
			local icon = GetAchievementCategoryKeyboardIcons(categoryIndex)
			nameText[name] = string.format("|t32:32:%s|t %s", icon, zo_strformat("<<1>>", name))
		end

		lines[#lines + 1] = string.format("%s |cfafafa%s|r", nameText[name], GetPercentText(earnedPointsSum, totalPointsSum))
	end
	function addon:ShowSummaryTooltip()
		local lines = {}
		AchievementTooltip:VotanClearStatusBars()
		local rootNode, data = ACHIEVEMENTS.categoryTree.rootNode
		for _, category in ipairs(rootNode:GetChildren()) do
			data = category:GetData()
			if not data.summary then
				GetCategory(lines, ACHIEVEMENTS:GetCategoryIndicesFromData(data))
			end
		end
		if #lines > 0 then
			AddLineCenter(AchievementTooltip, table.concat(lines, "\n"))
		end
	end
end

function addon:ShowCategoryTooltip(data)
	AchievementTooltip:VotanClearStatusBars()
	local ACHIEVEMENTS, GetAchievementSubCategoryInfo = ACHIEVEMENTS, GetAchievementSubCategoryInfo

	local categoryIndex = ACHIEVEMENTS:GetCategoryIndicesFromData(data)
	local numCategories, _, generalEarnedPoints, generalTotalPoints = select(2, GetAchievementCategoryInfo(categoryIndex))
	for i = 1, numCategories do
		local earnedPoints, totalPoints = select(3, GetAchievementSubCategoryInfo(categoryIndex, i))
		generalEarnedPoints, generalTotalPoints = generalEarnedPoints - earnedPoints, generalTotalPoints - totalPoints
	end

	if generalTotalPoints > 0 then
		SetStatusBar(GetString(SI_JOURNAL_PROGRESS_CATEGORY_GENERAL), generalEarnedPoints, generalTotalPoints)
	end

	for i = 1, numCategories do
		local name, _, earnedPoints, totalPoints = GetAchievementSubCategoryInfo(categoryIndex, i)
		SetStatusBar(name, earnedPoints, totalPoints)
	end
end

function addon:HookCategoriesRow()
	local function MouseEnter(category)
		local row = category.node:GetData()
		if row.isFavorits then
			return
		end

		InitializeTooltip(AchievementTooltip, category, TOPRIGHT, 0, -104, TOPLEFT)
		AchievementTooltip:AddVerticalPadding(8)
		if row.summary then
			self:ShowSummaryTooltip()
		else
			self:ShowCategoryTooltip(row)
		end
	end
	local function MouseExit(control)
		ClearTooltip(AchievementTooltip)
	end

	local rootNode = ACHIEVEMENTS.categoryTree.rootNode
	if rootNode and rootNode:GetChildren() then
		for _, category in pairs(rootNode:GetChildren()) do
			local control = category:GetControl()
			ZO_PreHook(control, "OnMouseEnter", MouseEnter)
			ZO_PreHook(control, "OnMouseExit", MouseExit)
			control:SetMouseEnabled(true)
		end
	else
		local function initControl(node, control, data, open)
			ZO_PreHook(control, "OnMouseEnter", MouseEnter)
			ZO_PreHook(control, "OnMouseExit", MouseExit)
		end
		SecurePostHook(ACHIEVEMENTS.categoryTree.templateInfo["ZO_IconHeader"], "setupFunction", initControl)
		SecurePostHook(ACHIEVEMENTS.categoryTree.templateInfo["ZO_IconChildlessHeader"], "setupFunction", initControl)
		SecurePostHook(ACHIEVEMENTS.categoryTree.templateInfo["ZO_TreeLabelSubCategory"], "setupFunction", initControl)
	end
end

function addon:RegisterAchievementEvents()
	local function AchievementsUpdated(eventCode)
		if not SCENE_MANAGER:IsShowing("achievements") then
			return
		end
		self:UpdateScrollList()
	end
	local function AchievementUpdated(eventCode, id)
		self.player.progress[id] = GetTimeStamp() + self.localTimeShift
	end
	local function AchievementAwarded(eventCode, name, points, id)
		self.player.progress[id] = nil
	end

	em:RegisterForEvent(addon.name, EVENT_ACHIEVEMENTS_UPDATED, AchievementsUpdated)
	em:RegisterForEvent(addon.name, EVENT_ACHIEVEMENT_UPDATED, AchievementUpdated)
	em:RegisterForEvent(addon.name, EVENT_ACHIEVEMENT_AWARDED, AchievementAwarded)
end

function addon:InitialAchievements()
	local now = GetTimeStamp() + self.localTimeShift
	local progress = self.player.progress
	local function GetAchievements(topLevelIndex, categoryIndex, numAchievements)
		for achievementIndex = 1, numAchievements do
			local achievementId = GetAchievementId(topLevelIndex, categoryIndex, achievementIndex)
			local _, _, _, _, completed = GetAchievementInfo(achievementId)
			if not completed then
				local numCriteria = GetAchievementNumCriteria(achievementId)
				for i = 1, numCriteria do
					local _, numCompleted = GetAchievementCriterion(achievementId, i)
					if numCompleted > 0 and not progress[achievementId] then
						progress[achievementId] = now
					end
				end
			end
		end
	end

	local numCategories = GetNumAchievementCategories()
	for topLevelIndex = 1, numCategories do
		local _, numSubCatgories, numAchievements = GetAchievementCategoryInfo(topLevelIndex)
		-- General
		GetAchievements(topLevelIndex, nil, numAchievements)
		for subCategoryIndex = 1, numSubCatgories do
			local _, numAchievements = GetAchievementSubCategoryInfo(topLevelIndex, subCategoryIndex)
			GetAchievements(topLevelIndex, subCategoryIndex, numAchievements)
		end
	end
end

function addon:InitSettings()
	local localTimeShift = GetSecondsSinceMidnight() - (GetTimeStamp() % 86400)
	if localTimeShift < -12 * 60 * 60 then
		localTimeShift = localTimeShift + 86400
	end
	self.localTimeShift = localTimeShift
	self.ClockFormat = (GetCVar("Language.2") == "en") and TIME_FORMAT_PRECISION_TWELVE_HOUR or TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR

	local defaults = {progress = {}}
	self.player = ZO_SavedVars:NewCharacterIdSettings("VotansAchievementsOvw_Data", 1, nil, defaults)
	if next(self.player.progress) == nil then
		-- Initial
		self:InitialAchievements()
	end
	defaults = {categoryFilter = SI_ACHIEVEMENT_FILTER_SHOW_ALL}
	self.account = ZO_SavedVars:NewAccountWide("VotansAchievementsOvw_Data", 1, nil, defaults)
end

function addon:InitializeCategoryFilter()
	local comboBox = ZO_ComboBox_ObjectFromContainer(ACHIEVEMENTS.categoryFilter)
	local function hookFilterChanged(item)
		local orgCallback = item.callback
		item.callback = function(...)
			local entry = select(3, ...)
			self.account.categoryFilter = entry.filterType
			return orgCallback(...)
		end
	end

	for _, item in ipairs(comboBox:GetItems()) do
		if item.filterType == self.account.categoryFilter then
			comboBox:SelectItem(item)
		end
		hookFilterChanged(item)
	end
end

function addon:Initialize()
	self:SetupControls()
	self:InitSettings()
	if ACHIEVEMENTS.categoryTree then
		self:HookAchievementRow()
		self:HookCategoriesRow()
		self:InitializeCategoryFilter()
	else
		local function initializeCategories()
			self:HookAchievementRow()
			self:HookCategoriesRow()
			self:InitializeCategoryFilter()
		end
		SecurePostHook(ACHIEVEMENTS, "InitializeCategories", initializeCategories)
	end
	self:RegisterAchievementEvents()
end

local function OnAddOnLoaded(event, addonName)
	if addonName == addon.name then
		em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)
		addon:Initialize()
	end
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)

VOTANS_ACHIEVEMENTS = addon
