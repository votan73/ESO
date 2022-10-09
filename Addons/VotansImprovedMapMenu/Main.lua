local addon = {
	name = "VotansImprovedMapMenu",
	hideReason = "VotansImprovedMapMenu_TabNotShown"
}

local em = GetEventManager()

local function findButtonData(descriptor)
	local buttons = WORLD_MAP_INFO.modeBar.buttonData
	local buttonData
	for i = 1, #buttons do
		buttonData = buttons[i]
		if buttonData.descriptor == descriptor then
			break
		end
	end
	return buttonData
end

local function findDescriptorById(id)
	local buttons = WORLD_MAP_INFO.modeBar.buttonData
	local buttonData
	for i = 1, #buttons do
		buttonData = buttons[i]
		if buttonData.normal == id then
			break
		end
	end
	return buttonData and buttonData.descriptor
end

local function GetContext()
	return (IsUnitGrouped("player") and 1 or 0) + (IsInAvAZone() and 2 or 0) + 1
end

function addon:OnTabChanged(buttonData)
	if buttonData then
		local descriptor = buttonData.descriptor
		if self.selectedTab ~= descriptor then
			self.selectedTab = descriptor
			local mode = WORLD_MAP_MANAGER:GetMode()
			local modeTab = self.sv[mode]
			if modeTab then
				local context = GetContext()
				modeTab[context] = buttonData.normal
			end
		end
	end
end

function addon:SetupWorldMapInfo()
	LibWorldMapInfoTab:SetMinimumUnscaledButtons(8)

	local function getDescriptor()
		local mode = WORLD_MAP_MANAGER:GetMode()
		local modeTab = self.sv[mode]
		if modeTab then
			local id = modeTab[GetContext()]
			return id and findDescriptorById(id)
		end
	end

	local descriptor = getDescriptor()
	self.selectedTab = descriptor
	if descriptor then
		WORLD_MAP_INFO.modeBar:SetStartingFragment(descriptor)
	end

	local orgSetClickedButton = WORLD_MAP_INFO.modeBar.menuBar.m_object.SetClickedButton
	function WORLD_MAP_INFO.modeBar.menuBar.m_object.SetClickedButton(...)
		local button = select(2, ...)
		if button then
			self:OnTabChanged(button.m_buttonData)
		end
		return orgSetClickedButton(...)
	end

	local WorldMapInfo = getmetatable(WORLD_MAP_INFO).__index
	local orgOnShowing = WorldMapInfo.OnShowing
	function WorldMapInfo.OnShowing(...)
		local descriptor = getDescriptor()
		if descriptor and self.selectedTab ~= descriptor then
			local info = ...
			info.modeBar:SetStartingFragment(descriptor)
		end
		return orgOnShowing(...)
	end
end

function addon:SetupZoneGuide()
	local control = ZO_WorldMapZoneStoryTopLevel_Keyboard
	control:ClearAnchors()
	WINDOW_MANAGER:ApplyTemplateToControl(control, "ZO_WorldMapInfoContent")

	control:GetNamedChild("Title"):SetFont("ZoFontWindowSubtitle")
	control:GetNamedChild("TitleDivider"):SetHidden(true)

	self.zoneStoryFragment = WORLD_MAP_ZONE_STORY_KEYBOARD_FRAGMENT

	local tabData = {
		normal = "esoui/art/lfg/lfg_indexicon_zonestories_up.dds",
		pressed = "esoui/art/lfg/lfg_indexicon_zonestories_down.dds",
		highlight = "esoui/art/lfg/lfg_indexicon_zonestories_over.dds",
		disabled = "esoui/art/lfg/lfg_indexicon_zonestories_disabled.dds",
		callback = function(tabData)
			self.zoneStoryFragment:SetHiddenForReason(addon.hideReason, false)
		end
	}
	self.zoneStoryFragment:SetHiddenForReason(addon.hideReason, true)
	self.zoneStoryFragment:Refresh()
	self.zoneStoryFragment:RegisterCallback(
		"StateChange",
		function(oldState, newState)
			self.zoneStoryFragment:SetHiddenForReason(addon.hideReason,newState==SCENE_HIDDEN or WORLD_MAP_INFO.modeBar:GetLastFragment()~=SI_ZONE_STORY_INFO_HEADER)
		end
	)
	WORLD_MAP_INFO.modeBar:Add(SI_ZONE_STORY_INFO_HEADER, {self.zoneStoryFragment}, tabData)

	function ZO_WorldMapZoneStory_Keyboard:GetBackgroundFragment()
		return WORLD_MAP_INFO_BG_FRAGMENT
	end

	local orgShowActivityCompletionTooltip = ZO_ZoneStories_Keyboard.ShowActivityCompletionTooltip
	local DESCRIPTION_TO_ACHIEVEMENT_ANCHOR = ZO_Anchor:New(TOPRIGHT, ACHIEVEMENTS:GetAchievementDetailedTooltipControl(), TOPLEFT, -5)
	local OFFSET_X = -40
	function ZO_ZoneStories_Keyboard.ShowActivityCompletionTooltip(self, zoneId, completionType, anchor, descriptionToAchievementAnchor, ...)
		anchor:SetMyPoint(RIGHT)
		anchor:SetRelativePoint(LEFT)
		anchor:SetOffsets(OFFSET_X)
		descriptionToAchievementAnchor = DESCRIPTION_TO_ACHIEVEMENT_ANCHOR
		return orgShowActivityCompletionTooltip(self, zoneId, completionType, anchor, descriptionToAchievementAnchor, ...)
	end
end

function addon:Initialize()
	local function getDefault()
		local defaultButtonData = findButtonData(SI_MAP_INFO_MODE_LOCATIONS)
		local defaultTab = defaultButtonData.normal
		return {
			-- [MAP_MODE_SMALL_CUSTOM] = { defaultTab, defaultTab, defaultTab, defaultTab },
			[MAP_MODE_LARGE_CUSTOM] = {defaultTab, defaultTab, defaultTab, defaultTab},
			[MAP_MODE_KEEP_TRAVEL] = {defaultTab, defaultTab, defaultTab, defaultTab},
			[MAP_MODE_FAST_TRAVEL] = {defaultTab, defaultTab, defaultTab, defaultTab}
			-- [MAP_MODE_AVA_RESPAWN] = { defaultTab, defaultTab, defaultTab, defaultTab },
			-- [MAP_MODE_AVA_KEEP_RECALL] = { defaultTab, defaultTab, defaultTab, defaultTab },
		}
	end
	VotansImprovedMapMenu_Data = VotansImprovedMapMenu_Data or getDefault()
	self.sv = VotansImprovedMapMenu_Data

	self:SetupWorldMapInfo()
end

addon:SetupZoneGuide()

local function OnAddonLoaded(event, name)
	if name ~= addon.name then
		return
	end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)
	addon:Initialize()
	-- addon:InitSettings()
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

VOTANS_IMPROVED_MAPMENU = addon
