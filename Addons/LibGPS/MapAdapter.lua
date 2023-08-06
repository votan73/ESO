-- LibGPS3 & its files © sirinsidiator                          --
-- Distributed under The Artistic License 2.0 (see LICENSE)     --
------------------------------------------------------------------

local lib = LibGPS3
local logger = lib.internal.logger

local MapAdapter = ZO_Object:Subclass()
lib.internal.class.MapAdapter = MapAdapter

function MapAdapter:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

local calibrateX, calibrateY

function MapAdapter:Initialize()
    self.anchor = ZO_Anchor:New()
    self.panAndZoom = ZO_WorldMap_GetPanAndZoom()
    self.sizeIdWorldSize = {}
    self.original = {}
    self:HookSetMapToFunction("SetMapToQuestCondition")
    self:HookSetMapToFunction("SetMapToQuestStepEnding")
    self:HookSetMapToFunction("SetMapToQuestZone")
    self:HookSetMapToFunction("SetMapToMapListIndex")
    self:HookSetMapToFunction("SetMapToAutoMapNavigationTargetPosition")
    self:HookSetMapToFunction("SetMapToDigSitePosition")
    self:HookSetMapToFunction("SetMapToPlayerLocation")
    self:HookSetMapToFunction("SetMapToMapId")
    self:HookSetMapToFunction("ProcessMapClick", true, true) -- Returning is done via clicking already
    self:HookSetMapToFunction("SetMapFloor", true)

    local TAMRIEL_MAP_ID = 27
    calibrateX, calibrateY = GetUniversallyNormalizedMapInfo(TAMRIEL_MAP_ID)
end

function MapAdapter:HookSetMapToFunction(funcName, returnToInitialMap, skipSecondCall)
    local orgFunction = _G[funcName]
    self.original[funcName] = orgFunction
    _G[funcName] = function(...)
        local result = orgFunction(...)
        if(result ~= SET_MAP_RESULT_FAILED and not lib:GetCurrentMapMeasurement()) then
            logger:Debug(funcName)

            local success, mapResult = lib:CalculateMapMeasurement(returnToInitialMap)
            if(mapResult ~= SET_MAP_RESULT_CURRENT_MAP_UNCHANGED) then
                result = mapResult
            end

            if(skipSecondCall) then return end
            orgFunction(...)
        end

        -- All stuff is done before anyone triggers an "OnWorldMapChanged" event due to this result
        return result
    end
end

local function FakeZO_WorldMap_IsMapChangingAllowed() return true end
local function FakeSetMapToMapListIndex() return SET_MAP_RESULT_MAP_CHANGED end
local FakeCALLBACK_MANAGER = { FireCallbacks = function() end }

-- TODO: investigate if there is a better way now
function MapAdapter:SetPlayerChoseCurrentMap()
    -- replace the original functions
    local oldIsChangingAllowed = ZO_WorldMap_IsMapChangingAllowed
    ZO_WorldMap_IsMapChangingAllowed = FakeZO_WorldMap_IsMapChangingAllowed

    local oldSetMapToMapListIndex = SetMapToMapListIndex
    SetMapToMapListIndex = FakeSetMapToMapListIndex

    local oldCALLBACK_MANAGER = CALLBACK_MANAGER
    CALLBACK_MANAGER = FakeCALLBACK_MANAGER

    -- make our rigged call to set the player chosen flag
    ZO_WorldMap_SetMapByIndex()

    -- cleanup
    ZO_WorldMap_IsMapChangingAllowed = oldIsChangingAllowed
    SetMapToMapListIndex = oldSetMapToMapListIndex
    CALLBACK_MANAGER = oldCALLBACK_MANAGER
end

function MapAdapter:SetCurrentZoom(zoom)
    return self.panAndZoom:SetCurrentNormalizedZoom(zoom)
end

function MapAdapter:GetCurrentZoom()
    return self.panAndZoom:GetCurrentNormalizedZoom()
end

function MapAdapter:SetCurrentOffset(offsetX, offsetY)
    return self.panAndZoom:SetCurrentOffset(offsetX, offsetY)
end

function MapAdapter:GetCurrentOffset()
    local anchor = self.anchor
    anchor:SetFromControlAnchor(ZO_WorldMapContainer, 0)
    return anchor:GetOffsetX(), anchor:GetOffsetY()
end

function MapAdapter:GetPlayerPosition()
    return GetMapPlayerPosition("player")
end

function MapAdapter:GetPlayerWorldPosition()
    local zoneId, pwx, pwh, pwy = GetUnitRawWorldPosition("player")
    return zoneId, pwx, pwh, pwy
end

function MapAdapter:GetNormalizedPositionFromWorld(zoneId, worldX, worldY, worldZ)
    return GetNormalizedWorldPosition(zoneId, worldX, worldY, worldZ)
end

function MapAdapter:GetPlayerZoneId()
    local zoneId = GetUnitWorldPosition("player")
    return zoneId
end

function MapAdapter:GetCurrentMapIndex()
    return GetCurrentMapIndex()
end

function MapAdapter:GetCurrentZoneId()
    return GetZoneId(GetCurrentMapZoneIndex())
end

function MapAdapter:GetCurrentMapIdentifier()
    return GetCurrentMapId()
end

function MapAdapter:GetMapFloorInfo()
    return GetMapFloorInfo()
end

function MapAdapter:IsCurrentMapPlayerLocation()
    return DoesCurrentMapMatchMapForPlayerLocation()
end

function MapAdapter:GetFormattedMapName(mapIndex)
    return zo_strformat("<<C:1>>", GetMapNameByIndex(mapIndex))
end

function MapAdapter:IsCurrentMapZoneMap()
    return GetMapType() == MAPTYPE_ZONE and GetMapContentType() ~= MAP_CONTENT_DUNGEON
end

function MapAdapter:IsCurrentMapCosmicMap()
    return GetMapType() == MAPTYPE_COSMIC
end

function MapAdapter:MapZoomOut()
    return MapZoomOut()
end

function MapAdapter:SetMapToMapListIndexWithoutMeasuring(mapIndex)
    return self.original.SetMapToMapListIndex(mapIndex)
end

function MapAdapter:ProcessMapClickWithoutMeasuring(x, y)
    return self.original.ProcessMapClick(x, y)
end

function MapAdapter:SetMapToMapIdWithoutMeasuring(mapId)
    return self.original.SetMapToMapId(mapId)
end

function MapAdapter:GetUniversallyNormalizedMapInfo(mapId)
    local offsetX, offsetY, scaleX, scaleY = GetUniversallyNormalizedMapInfo(mapId or self:GetCurrentMapIdentifier())
    offsetX, offsetY = offsetX - calibrateX, offsetY - calibrateY
    return offsetX, offsetY, scaleX, scaleY
end

function MapAdapter:GetWorldSize(sizeId)
    local size = self.sizeIdWorldSize[sizeId]
    if not size then
        size = lib.internal.class.WorldSize:New()
    end
    return size
end

function MapAdapter:SetWorldSize(sizeId, size, notSaving)
    self.sizeIdWorldSize[sizeId] = size
end
