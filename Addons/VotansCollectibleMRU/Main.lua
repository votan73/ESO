local addon = {
	name = "VotansCollectibleMRU"
}

local categoryMRU
local function newMRU(categoryId)
	local list = {}
	categoryMRU[categoryId] = list
	return list
end

local maxRecent = 12

local function recent(collectibleData)
	if collectibleData.votanRecentIndex == -maxRecent then
		return
	end

	local ZO_COLLECTIBLE_DATA_MANAGER = ZO_COLLECTIBLE_DATA_MANAGER

	local categoryId = collectibleData:GetCategoryData():GetId()
	local list = categoryMRU[categoryId] or newMRU(categoryId)
	local id = collectibleData:GetId()
	for i = #list, 1, -1 do
		if list[i] == id then
			table.remove(list, i)
		end
	end

	local last = list[maxRecent] and ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(list[maxRecent])
	if last then
		last.votanRecentIndex = nil
	end

	local i = math.min(#list, maxRecent - 1)
	while i > 0 do
		list[i + 1] = list[i]
		ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(list[i]).votanRecentIndex = i - maxRecent
		i = i - 1
	end
	list[1] = id
	collectibleData.votanRecentIndex = -maxRecent
	collectibleData:GetCategoryData():GetSpecializedSortedCollectiblesObject().dirty = true
end

do
	local orgGetSortOrder = ZO_CollectibleData.GetSortOrder
	function ZO_CollectibleData.GetSortOrder(...)
		local collectibleData = ...
		return collectibleData.votanRecentIndex or orgGetSortOrder(...)
	end
end

function addon.OnCollectibleUpdated(collectibleId)
	local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
	if collectibleData and collectibleData:IsActive() and collectibleData:IsOwned() and collectibleData:IsUsable() then
		--SLASH_COMMANDS["/zgoo"](collectibleData)
		return recent(collectibleData)
	end
end

function addon:Init()
	local ZO_COLLECTIBLE_DATA_MANAGER = ZO_COLLECTIBLE_DATA_MANAGER
	local data
	for categoryId, list in pairs(categoryMRU) do
		data = ZO_COLLECTIBLE_DATA_MANAGER:GetCategoryDataById(categoryId)
		if data then
			data:GetSpecializedSortedCollectiblesObject().dirty = true
		end
		local index = -maxRecent
		for i, id in ipairs(list) do
			data = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(id)
			if data then
				data.votanRecentIndex = index
				index = index + 1
			end
		end
	end

	ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUpdated", addon.OnCollectibleUpdated)

	local function initCollections()
		local orgAddEntry = COLLECTIONS_BOOK.gridListPanelList.AddEntry
		function COLLECTIONS_BOOK.gridListPanelList.AddEntry(...)
			local collectibleData = select(2, ...)
			if collectibleData.votanRecentIndex then
				collectibleData.gridHeaderName = GetString(SI_VOTANS_COLLECTIBLE_MRU_RECENT)
			end
			return orgAddEntry(...)
		end
	end
	if COLLECTIONS_BOOK.gridListPanelList then
		initCollections()
	else
		SecurePostHook(COLLECTIONS_BOOK, "InitializeGridListPanel", initCollections)
	end

	local function AfterUse(collectibleData)
		if collectibleData:IsOwned() and not collectibleData:HasVisualAppearence() and not collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_COMBINATION_FRAGMENT) then
			--SLASH_COMMANDS["/zgoo"](collectibleData)
			return recent(collectibleData)
		end
	end
	SecurePostHook(ZO_CollectibleData, "Use", AfterUse)
end

----------------------------------------
local em = GetEventManager()
local function Loaded(event, addOn)
	if addOn ~= addon.name then
		return
	end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	VotansCollectibleMRU_Data = VotansCollectibleMRU_Data or {}
	VotansCollectibleMRU_Data.list = VotansCollectibleMRU_Data.list or {}
	local list = VotansCollectibleMRU_Data.list
	local id = GetCurrentCharacterId()
	list[id] = list[id] or {}
	categoryMRU = list[id]

	-- addon.settings = ZO_SavedVars:NewAccountWide("VotansAdaptiveSettings_Data", 1, nil, addon.defaults)

	-- addon:InitSettings()
	addon:Init()
end
em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, Loaded)

VOTANS_COLLECTIBLE_MRU = addon
