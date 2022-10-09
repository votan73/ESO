-- LibGPS3 & its files © sirinsidiator                          --
-- Distributed under The Artistic License 2.0 (see LICENSE)     --
------------------------------------------------------------------

local lib
if LibStub then
    local MAJOR, MINOR = "LibGPS2", 22
    lib = LibStub:NewLibrary(MAJOR, MINOR)
    assert(lib, "LibGPS2 compatibility layer was loaded more than once. Please ensure that its files are not included from other addons.")
else
    lib ={}
end

LibGPS2 = lib

local libv3 = LibGPS3
local logger = libv3.internal.logger

--- Unregister handler from older libGPS ( < 3)
EVENT_MANAGER:UnregisterForEvent("LibGPS2_SaveWaypoint", EVENT_PLAYER_DEACTIVATED)
EVENT_MANAGER:UnregisterForEvent("LibGPS2_RestoreWaypoint", EVENT_PLAYER_ACTIVATED)

--- Unregister handler from older libGPS ( <= 5.1)
EVENT_MANAGER:UnregisterForEvent("LibGPS2_Init", EVENT_PLAYER_ACTIVATED)

--- Unregister handler from older libGPS, as it is now managed by LibMapPing ( >= 6)
EVENT_MANAGER:UnregisterForEvent("LibGPS2_UnmuteMapPing", EVENT_MAP_PING)

if (lib.Unload) then
    -- Undo action from older libGPS ( >= 5.2)
    lib:Unload()
    if (lib.suppressCount > 0) then
        logger:Warn("There is a measurement in progress before loading is completed.")

        local LMP = LibMapPing or LibStub("LibMapPing")
        EVENT_MANAGER:UnregisterForUpdate("LibGPS2_Finalize")
        while lib.suppressCount > 0 do
            LMP:UnsuppressPing(MAP_PIN_TYPE_PLAYER_WAYPOINT)
            lib.suppressCount = lib.suppressCount - 1
        end
    end
end

lib.LIB_EVENT_STATE_CHANGED = libv3.LIB_EVENT_STATE_CHANGED
-- propagate the callback in case someone registered to the old handle name
local OLD_LIB_EVENT_STATE_CHANGED = "OnLibGPS2MeasurementChanged"
CALLBACK_MANAGER:RegisterCallback(libv3.LIB_EVENT_STATE_CHANGED, function(measuring)
    CALLBACK_MANAGER:FireCallbacks(OLD_LIB_EVENT_STATE_CHANGED, measuring)
end)

function lib:IsReady()
    return libv3:IsReady()
end

function lib:IsMeasuring()
    return libv3:IsMeasuring()
end

function lib:ClearMapMeasurements()
    return libv3:ClearMapMeasurements()
end

function lib:ClearCurrentMapMeasurements()
    return libv3:ClearCurrentMapMeasurement()
end

function lib:GetCurrentMapMeasurements()
    return libv3:GetCurrentMapMeasurement()
end

function lib:GetCurrentMapParentZoneIndices()
    local mapIndex, zoneIndex = libv3:GetCurrentMapParentZoneIndices()
    return mapIndex, zoneIndex
end

function lib:CalculateMapMeasurements(returnToInitialMap)
    return libv3:CalculateMapMeasurement(returnToInitialMap)
end

function lib:LocalToGlobal(x, y)
    local measurement = libv3.internal.meter:GetCurrentMapMeasurement()
    if(measurement) then
        local x, y = measurement:ToGlobal(x, y)
        return x, y, measurement:GetMapIndex()
    end
end

function lib:GlobalToLocal(x, y)
    return libv3:GlobalToLocal(x, y)
end

function lib:ZoneToGlobal(mapIndex, x, y)
    lib:GetCurrentMapMeasurement()
    -- measurement done in here:
    SetMapToMapListIndex(mapIndex)
    x, y, mapIndex = lib:LocalToGlobal(x, y)
    return x, y, mapIndex
end

--- This function zooms and pans to the specified position on the active map.
--- @deprecated use ZO_WorldMap_GetPanAndZoom():PanToNormalizedPosition(x, y) instead
function lib:PanToMapPosition(x, y)
    return ZO_WorldMap_GetPanAndZoom():PanToNormalizedPosition(x, y)
end

function lib:SetPlayerChoseCurrentMap()
    return libv3:SetPlayerChoseCurrentMap()
end

function lib:SetMapToRootMap(x, y)
    return libv3:SetMapToRootMap(x, y)
end

function lib:MapZoomInMax(x, y)
    return libv3:MapZoomInMax(x, y)
end

function lib:PushCurrentMap()
    return libv3:PushCurrentMap()
end

function lib:PopCurrentMap()
    return libv3:PopCurrentMap()
end
