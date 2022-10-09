-- LibGPS3 & its files © sirinsidiator                          --
-- Distributed under The Artistic License 2.0 (see LICENSE)     --
------------------------------------------------------------------

local lib = LibGPS3
local internal = lib.internal
local logger = internal.logger

--- identifier for the measurement change callback
lib.LIB_EVENT_STATE_CHANGED = "OnLibGPSMeasurementChanged"

--- Returns true as long as the player exists.
function lib:IsReady()
    return DoesUnitExist("player")
end

--- Returns true if the library is currently doing any measurements.
function lib:IsMeasuring()
    return internal.meter:IsMeasuring()
end

--- Removes all cached measurement values.
function lib:ClearMapMeasurements()
    internal.meter:Reset()
end

--- Removes the cached measurement for the map that is currently active.
function lib:ClearCurrentMapMeasurement()
    internal.meter:ClearCurrentMapMeasurement()
end

--- Returns a Measurement object for the active map or nil if the measurement could not be calculated for some reason.
--- See Measurement.lua for details on the return value.
function lib:GetCurrentMapMeasurement()
    return internal.meter:GetCurrentMapMeasurement()
end

--- Returns a Measurement object for specified map ID or nil if the measurement could not be calculated for some reason.
function lib:GetMapMeasurementByMapId(mapId)
    return internal.meter:GetMapMeasurementByMapId(mapId)
end

--- Returns the mapIndex and zoneIndex of the parent zone for the currently set map.
--- return[1] number - The mapIndex of the parent zone
--- return[2] number - The zoneIndex of the parent zone
--- return[3] number - The zoneId of the parent zone
function lib:GetCurrentMapParentZoneIndices()
    local measurement = internal.meter:GetCurrentMapMeasurement()
    local mapIndex = measurement:GetMapIndex()
    local zoneId = measurement:GetZoneId()

    if(zoneId == 0) then
        internal.meter:PushCurrentMap()
        SetMapToMapListIndex(mapIndex)
        zoneId = internal.mapAdapter:GetCurrentZoneId()
        measurement:SetZoneId(zoneId)
        internal.meter:PopCurrentMap()
    end

    local zoneIndex = GetZoneIndex(zoneId)
    return mapIndex, zoneIndex, zoneId
end

--- Calculates the measurement for the current map and all parent maps.
--- This method does nothing if there is already a cached measurement for the active map.
--- return[1] boolean - True, if a valid measurement was calculated
--- return[2] SetMapResultCode - Specifies if the map has changed or failed during measurement (independent of the actual result of the measurement)
function lib:CalculateMapMeasurement(returnToInitialMap)
    return internal.meter:CalculateMapMeasurement(returnToInitialMap)
end

--- Converts the given map coordinates on the current map into coordinates on the Tamriel map.
--- Returns x and y on the world map or nil if the measurements of the active map are not available.
function lib:LocalToGlobal(x, y)
    local measurement = internal.meter:GetCurrentMapMeasurement()
    if(measurement) then
        return measurement:ToGlobal(x, y)
    end
end

--- Converts the given global coordinates into a position on the active map.
--- Returns x and y on the current map or nil if the measurements of the active map are not available.
function lib:GlobalToLocal(x, y)
    local measurement = internal.meter:GetCurrentMapMeasurement()
    if(measurement) then
        return measurement:ToLocal(x, y)
    end
end

--- Converts the given map coordinates on the current map into world coordinates.
--- Returns x and y in world coordinates or nil if the measurements of the active map are not available.
function lib:LocalToWorld(x, y)
    local measurement = internal.meter:GetCurrentMapMeasurement()
    if(measurement) then
        return measurement:ToWorld(x, y)
    end
end

--- Converts the given global coordinates on the current map into world coordinates.
--- Returns x and y in world coordinates or nil if the measurements of the active map are not available.
function lib:GlobalToWorld(x, y)
    local measurement = internal.meter:GetCurrentMapMeasurement()
    if(measurement) then
        return measurement:ToWorld(measurement:ToLocal(x, y))
    end
end

--- This function sets the current map as player chosen so it won't switch back to the previous map.
function lib:SetPlayerChoseCurrentMap()
    return internal.mapAdapter:SetPlayerChoseCurrentMap()
end

--- Sets the best matching root map: Tamriel, Cold Harbour or Clockwork City and what ever will come.
--- Returns SET_MAP_RESULT_FAILED, SET_MAP_RESULT_MAP_CHANGED depending on the result of the API calls.
function lib:SetMapToRootMap(x, y)
    local measurement = internal.meter:FindRootMapMeasurementForCoordinates(x, y)
    if(not measurement) then return SET_MAP_RESULT_FAILED end

    return internal.mapAdapter:SetMapToMapListIndexWithoutMeasuring(measurement:GetMapIndex())
end

--- Repeatedly calls ProcessMapClick on the given global position starting on the Tamriel map until nothing more would happen.
--- Returns SET_MAP_RESULT_FAILED, SET_MAP_RESULT_MAP_CHANGED or SET_MAP_RESULT_CURRENT_MAP_UNCHANGED depending on the result of the API calls.
function lib:MapZoomInMax(x, y)
    local result = lib:SetMapToRootMap(x, y)

    if (result ~= SET_MAP_RESULT_FAILED) then
        local localX, localY = lib:GlobalToLocal(x, y)

        while WouldProcessMapClick(localX, localY) do
            result = internal.mapAdapter:ProcessMapClickWithoutMeasuring(localX, localY)
            if (result == SET_MAP_RESULT_FAILED) then break end
            localX, localY = lib:GlobalToLocal(x, y)
        end
    end

    return result
end

--- Stores information about how we can back to this map on a stack.
function lib:PushCurrentMap()
    internal.meter:PushCurrentMap()
end

--- Switches to the map that was put on the stack last.
--- Returns SET_MAP_RESULT_FAILED, SET_MAP_RESULT_MAP_CHANGED or SET_MAP_RESULT_CURRENT_MAP_UNCHANGED depending on the result of the API calls.
function lib:PopCurrentMap()
    return internal.meter:PopCurrentMap()
end

--- Returns the current size of Tamriel in world-units.
function lib:GetCurrentWorldSize()
    local size = internal.meter:GetCurrentWorldSize()
    return size.width, size.height
end

--- Returns the distance in meters of given local coords.
function lib:GetLocalDistanceInMeters(lx1, ly1, lx2, ly2)
    return internal.meter:GetLocalDistanceInMeters(lx1, ly1, lx2, ly2)
end

--- Returns the distance in meters of given global coords.
function lib:GetGlobalDistanceInMeters(gx1, gy1, gx2, gy2)
    return internal.meter:GetGlobalDistanceInMeters(gx1, gy1, gx2, gy2)
end

--- Returns how much greater the level is compared to its size on the map.
function lib:GetWorldGlobalRatio()
    return internal.meter:GetWorldGlobalRatio()
end

--- Returns how much smaller global scaled values must be to fit the current level.
function lib:GetGlobalWorldRatio()
    return internal.meter:GetGlobalWorldRatio()
end

internal:Initialize()
