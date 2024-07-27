local addon = {
	name = "VotansAchievementFavorites"
}

local em = GetEventManager()

local VotansFavorites = "VotansFavorites"
function addon:CreateFavorites()
	local Achievements = getmetatable(ACHIEVEMENTS).__index
	local SUMMARY_ICONS = {
		"esoui/art/market/keyboard/giftmessageicon_up.dds",
		"esoui/art/market/keyboard/giftmessageicon_down.dds",
		"esoui/art/market/keyboard/giftmessageicon_over.dds"
	}

	local orgAddTopLevelCategory = Achievements.AddTopLevelCategory
	function Achievements.AddTopLevelCategory(...)
		local self, name = ...
		if name then
			return orgAddTopLevelCategory(...)
		end

		local result = orgAddTopLevelCategory(...)
		local lookup, tree, numSubCategories, hidesUnearned = self.nodeLookupData, self.categoryTree, 0, false

		local normalIcon, pressedIcon, mouseoverIcon = unpack(SUMMARY_ICONS)

		local parentNode = self:AddCategory(lookup, tree, "ZO_IconChildlessHeader", nil, VotansFavorites, GetString(SI_VOTANS_ACHIEVEMENT_FAVORITES), hidesUnearned, normalIcon, pressedIcon, mouseoverIcon, true, true)
		local row = parentNode:GetData()
		row.isFavorits = true

		return result
	end
	if ACHIEVEMENTS.refreshGroups then
		ACHIEVEMENTS.refreshGroups:RefreshAll("FullUpdate")
	end

	local orgOnCategorySelected = Achievements.OnCategorySelected
	function Achievements.OnCategorySelected(...)
		local ACHIEVEMENTS, data, saveExpanded = ...
		if data.categoryIndex == VotansFavorites then
			ACHIEVEMENTS:HideSummary()
			ACHIEVEMENTS.UpdateCategoryLabels(...)
		else
			return orgOnCategorySelected(...)
		end
	end

	local orgGetCategoryInfoFromData = Achievements.GetCategoryInfoFromData
	function Achievements.GetCategoryInfoFromData(...)
		local ACHIEVEMENTS, data, parentData = ...
		if data.categoryIndex == VotansFavorites then
			local numAchievements, earnedPoints, totalPoints = 0, 0, 0
			local favorites, GetAchievementInfo = self.favorites, GetAchievementInfo
			local id, points, _, completed
			for id in pairs(favorites) do
				numAchievements = numAchievements + 1
				points, _, completed = select(3, GetAchievementInfo(id))
				totalPoints = totalPoints + points
				if completed then
					earnedPoints = earnedPoints + points
				end
			end
			local hidesPoints = totalPoints == 0
			return numAchievements, earnedPoints, totalPoints, hidesPoints
		else
			return orgGetCategoryInfoFromData(...)
		end
	end

	local orgOnAchievementUpdated = Achievements.OnAchievementUpdated
	function Achievements.OnAchievementUpdated(...)
		local ACHIEVEMENTS, id = ...
		local data = ACHIEVEMENTS.categoryTree:GetSelectedData()
		if data and data.categoryIndex == VotansFavorites then
			if self.favorites[id] and ZO_ShouldShowAchievement(ACHIEVEMENTS.categoryFilter.filterType, id) then
				ACHIEVEMENTS:UpdateCategoryLabels(data, true, false)
			end
		else
			return orgOnAchievementUpdated(...)
		end
	end

	local gender = GetUnitGender("player")
	local orgZO_GetAchievementIds = ZO_GetAchievementIds
	local idToName = {}
	local function addName(id)
		local name = GetAchievementInfo(id)
		name = zo_strformat(name, gender)
		idToName[id] = name
		return name
	end
	local function sortByName(a, b)
		return (idToName[a] or addName(a)) < (idToName[b] or addName(b))
	end
	function ZO_GetAchievementIds(...)
		local categoryIndex, subcategoryIndex, numAchievements, considerSearchResults = ...
		if categoryIndex == VotansFavorites then
			local result = {}

			local searchResults = considerSearchResults and ACHIEVEMENTS_MANAGER:GetSearchResults()
			if searchResults then
				local GetCategoryInfoFromAchievementId = GetCategoryInfoFromAchievementId
				local categoryIndex, subcategoryIndex, achievementIndex, searchResult
				for id in pairs(self.favorites) do
					categoryIndex, subcategoryIndex, achievementIndex = GetCategoryInfoFromAchievementId(id)
					searchResult = searchResults[categoryIndex]
					if searchResult then
						searchResult = searchResult[subcategoryIndex or ZO_ACHIEVEMENTS_ROOT_SUBCATEGORY]
						if searchResult and searchResult[achievementIndex] then
							result[#result + 1] = id
						end
					end
				end
			else
				for id in pairs(self.favorites) do
					result[#result + 1] = id
				end
			end
			table.sort(result, sortByName)
			return result
		else
			return orgZO_GetAchievementIds(...)
		end
	end

	local function RemoveAllOfThem(favorites, achievementId)
		while achievementId ~= 0 do
			favorites[achievementId] = nil
			achievementId = GetNextAchievementInLine(achievementId)
		end
	end
	function addon:AddToContextMenu(achievement)
		local id = ACHIEVEMENTS:GetBaseAchievementId(achievement:GetId())
		local isFav = self.favorites[id] or self.favorites[achievement:GetId()]

		if isFav then
			AddCustomMenuItem(
				GetString(SI_VOTANS_ACHIEVEMENT_FAVORITE_REMOVE),
				function()
					RemoveAllOfThem(self.favorites, id)
				end
			)
		else
			AddCustomMenuItem(
				GetString(SI_VOTANS_ACHIEVEMENT_FAVORITE_ADD),
				function()
					self.favorites[id] = true
				end
			)
		end
	end

	local function HookShowMenu(achievement)
		local orgShowMenu = ShowMenu
		function ShowMenu(...)
			ShowMenu = orgShowMenu
			if not ACHIEVEMENTS.control:IsHidden() then
				addon:AddToContextMenu(achievement)
			end
			return ShowMenu(...)
		end
	end

	local Achievement

	local function HookAchievement()
		local orgOnClicked = Achievement.OnClicked
		function Achievement:OnClicked(...)
			local button = ...
			if button == MOUSE_BUTTON_INDEX_LEFT then
				return orgOnClicked(self, ...)
			elseif button == MOUSE_BUTTON_INDEX_RIGHT and IsChatSystemAvailableForCurrentPlatform() then
				HookShowMenu(self)
				return orgOnClicked(self, ...)
			end
		end
	end
	-- Get Achievement class
	local orgFactory = ACHIEVEMENTS.achievementPool.m_Factory
	ACHIEVEMENTS.achievementPool.m_Factory = function(...)
		local achievement = orgFactory(...)
		if not Achievement and achievement then
			Achievement = getmetatable(achievement).__index
			HookAchievement()
		end
		return achievement
	end
end

function addon:Initialize()
	local defaults = {favorites = {}}
	self.account = ZO_SavedVars:NewAccountWide("VotansAchievementsOvw_Data", 1, nil, defaults)
	self.favorites = self.account.favorites
	self:CreateFavorites()
end

local function OnAddOnLoaded(event, addonName)
	if addonName == addon.name then
		em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)
		addon:Initialize()
	end
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)

VOTANS_ACHIEVEMENT_FAVORITES = addon
