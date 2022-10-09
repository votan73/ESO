LibRunebox = LibRunebox or {}
local lib = LibRunebox

lib.name = "LibRunebox"
lib.version = 5
lib.svVersion = 2

local MAJOR, MINOR = lib.name, lib.version

local p = function(...)
    CHAT_ROUTER:AddDebugMessage(string.format(...))
end

lib.itemIdToCollectibleId = {}
lib.collectibleIdToItemId = {}
local function BuildLists()
    for _, entry in ipairs(lib.savedData.dataList) do
        lib.itemIdToCollectibleId[entry.containerItemId] = entry.collectibleId
		if not lib.collectibleIdToItemId[entry.collectibleId] then -- there might be multiple items that unlock the same collectible
			lib.collectibleIdToItemId[entry.collectibleId] = entry.containerItemId
		end
    end
end

local function PostBuildLists()

	-- 
end

local function LoadSavedVariables()
    if not LibRunebox_SV_Data then LibRunebox_SV_Data = {} end
    lib.savedData = LibRunebox_SV_Data
    if lib.savedData.version ~= lib.svVersion then
        lib.savedData.version  = lib.svVersion
        lib.savedData.dataList = lib.preloadedRuneboxList
        lib.savedData.lastAPIVersion = lib.lastAPIVersion
        lib.savedData.lastScannedItemId = lib.lastScannedItemId
    end
    
    if lib.savedData.lastAPIVersion ~= GetAPIVersion() then
        BuildLists()
        lib.savedData.lastAPIVersion = GetAPIVersion()
        lib.savedData.lastScannedItemId = lib:CollectAndDump(lib.savedData.dataList)
		PostBuildLists()
    end
end

function lib:IsRuneboxCollected(runeboxItemId)
    return IsCollectibleUnlocked(self:GetRuneboxCollectibleId(runeboxItemId))
end

function lib:GetRuneboxCollectibleId(runeboxItemId)
	if self.fragmentsToRunebox[runeboxItemId] then
		runeboxItemId = self.fragmentsToRunebox[runeboxItemId]
	end
    return self.itemIdToCollectibleId[ runeboxItemId ]
end

function lib:GetRuneboxFragments(runeboxItemId)
    return self.runeboxFragments[ runeboxItemId ]
end

function lib:GetRuneboxForFragment(fragmentItemId)
    return self.fragmentsToRunebox[ fragmentItemId ]
end

function lib:GetItemIdForCollectibleId(collectibleId)
	return lib.collectibleIdToItemId[collectibleId]
end

-- returns table of the components' collectibleIds
function lib:GetCollectibleComponents(collectibleId, mustHaveItem)
	local combinationId = GetCollectibleReferenceId(collectibleId)
	local results = {}
	if combinationId > 0 then
		for i=1, GetCombinationNumCollectibleComponents(combinationId) do
			local compCollectibleId = GetCombinationCollectibleComponentId(combinationId, i)
			if not mustHaveItem or lib:GetItemIdForCollectibleId(compCollectibleId) then
				table.insert(results, compCollectibleId)
			end
		end
	end
	return results
end

local ITEM_LINK_TEMPLATE = "|H1:item:%d:124:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
local FRAGMENT_ITEM_LINK_TEMPLATE = "|H1:item:%d:5:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
function lib:CollectAndDump(fullList)

    p("Collecting runeboxes...")
    local minId, maxId = lib.savedData.lastScannedItemId, lib.savedData.lastScannedItemId + 200000

    local containerType
    
    local lastScannedItemId = minId

    local itemLink, itemType, specType, collectibleId
    for itemId=minId, maxId do
        itemLink = ITEM_LINK_TEMPLATE:format(itemId)
        itemType, specType = GetItemLinkItemType(itemLink)
        if itemType == ITEMTYPE_CONTAINER or specType == SPECIALIZED_ITEMTYPE_TROPHY_COLLECTIBLE_FRAGMENT then
            collectibleId = GetItemLinkContainerCollectibleId(itemLink)
            if collectibleId > 0 then 
                if specType == SPECIALIZED_ITEMTYPE_CONTAINER_STYLE_PAGE then
                    if GetItemLinkBindType(itemLink) == BIND_TYPE_NONE then
                        containerType = LibRunebox.TYPE_STYLEPAGE
                    else
                        containerType = LibRunebox.TYPE_BOUNDSTYLEPAGE
                    end
                elseif specType == SPECIALIZED_ITEMTYPE_TROPHY_COLLECTIBLE_FRAGMENT then
					containerType = LibRunebox.TYPE_COLLECTIBLE_FRAGMENT
				else 
                    containerType = LibRunebox.TYPE_CONTAINER
                end
                if not lib.itemIdToCollectibleId[itemId] then 
                    lib.itemIdToCollectibleId[itemId] = collectibleId
					if not lib.collectibleIdToItemId[collectibleId] then
						lib.collectibleIdToItemId[collectibleId] = itemId
					end
                    local entry = {
                        containerItemId = itemId,
                        containerName = GetItemLinkName(itemLink),
                        containerType = containerType,
                        collectibleId = collectibleId,
                        p("Found new collectible container: %d: %s", itemId, itemLink)
                    }
                    if fullList then 
                        table.insert(fullList, entry)
                    end
                end
            end
        end
    end
    return lastScannedItemId
end

--GetCollectibleReferenceId

--    Search on ESOUI Source Code GetCombinationCollectibleComponentId(number combinationId, number componentIndex)
--       Returns: number collectibleId 
--
--   Search on ESOUI Source Code GetCombinationDescription(number combinationId)
--       Returns: string combinationDescription 
--
--   Search on ESOUI Source Code GetCombinationFirstNonFragmentCollectibleComponentId(number combinationId)
--       Returns: number firstNonFragmentCollectibleId 
--
--   Search on ESOUI Source Code GetCombinationNumCollectibleComponents(number combinationId)
--       Returns: number numCollectibleComponents 
--
--   Search on ESOUI Source Code GetCombinationUnlockedCollectible(number combinationId)
--       Returns: number unlockedCollectibleId 


SLASH_COMMANDS["/rune"] = function() LibRunebox:CollectAndDump() end

--Addon loaded function
local function OnLibraryLoaded(event, name)
	if name ~= MAJOR then return end
	EVENT_MANAGER:UnregisterForEvent(MAJOR, EVENT_ADD_ON_LOADED)

	LoadSavedVariables()
    BuildLists()
    --lib:CollectAndDump()
end

--Load the addon now
EVENT_MANAGER:UnregisterForEvent(MAJOR, EVENT_ADD_ON_LOADED)
EVENT_MANAGER:RegisterForEvent(MAJOR, EVENT_ADD_ON_LOADED, OnLibraryLoaded)