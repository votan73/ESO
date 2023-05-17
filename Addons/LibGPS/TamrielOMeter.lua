-- LibGPS3 & its files © sirinsidiator                          --
-- Distributed under The Artistic License 2.0 (see LICENSE)     --
------------------------------------------------------------------

local lib = LibGPS3
local internal = lib.internal
local Measurement = internal.class.Measurement
local MapStack = internal.class.MapStack

local logger = internal.logger
local mabs = math.abs

local TAMRIEL_MAP_INDEX = internal.TAMRIEL_MAP_INDEX
local BLACKREACH_ROOT_MAP_INDEX = internal.BLACKREACH_ROOT_MAP_INDEX
local SCALE_INACCURACY_WARNING_THRESHOLD = 1e-3
local DEFAULT_TAMRIEL_SIZE = 2500000
local MAP_CENTER = 0.5

local TamrielOMeter = ZO_Object:Subclass()
internal.class.TamrielOMeter = TamrielOMeter

function TamrielOMeter:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function TamrielOMeter:Initialize(adapter)
    self.adapter = adapter
    self.mapStack = MapStack:New(self, adapter)
    self.measurements = {}
    self.savedMeasurements = {}
    self.rootMaps = {}
    self.measuring = false

    self:RegisterRootMap(BLACKREACH_ROOT_MAP_INDEX) -- BlackReach
    self:RegisterRootMap(GetMapIndexByZoneId(347)) -- Coldhabour
    self:RegisterRootMap(GetMapIndexByZoneId(980)) -- Clockwork City
    self:RegisterRootMap(GetMapIndexByZoneId(1027)) -- Artaeum
    self:RegisterRootMap(GetMapIndexByZoneId(1283)) -- Fargrave
    self:RegisterRootMap(GetMapIndexByZoneId(1286)) -- Deathlands
    if GetNumMaps() >= 50 then
        self:RegisterRootMap(GetMapIndexByZoneId(1413)) -- Aphocrypha
    end
    -- Any future extra dimensional map here
    self:RegisterRootMap(TAMRIEL_MAP_INDEX) -- Tamriel
end

function TamrielOMeter:Reset()
    logger:Info("Removing all measurements")
    ZO_ClearTable(self.measurements)
end

function TamrielOMeter:RegisterRootMap(mapIndex)
    logger:Debug("Register root map", self.adapter:GetFormattedMapName(mapIndex))
    self.rootMaps[mapIndex] = false
end

function TamrielOMeter:GetRootMapMeasurement(mapIndex)
    return self.rootMaps[mapIndex]
end

function TamrielOMeter:GetMeasurement(id)
    return self.measurements[id]
end

function TamrielOMeter:SetMeasurement(measurement, isRootMap)
    self.measurements[measurement:GetId()] = measurement
    if(isRootMap) then
        self.rootMaps[measurement:GetMapIndex()] = measurement
    end
end

function TamrielOMeter:SetMeasuring(measuring)
    local changed = (self.measuring ~= measuring)
    self.measuring = measuring
    if(changed) then
        CALLBACK_MANAGER:FireCallbacks(lib.LIB_EVENT_STATE_CHANGED, measuring)
    end
end

function TamrielOMeter:IsMeasuring()
    return self.measuring
end

function TamrielOMeter:ClearCurrentMapMeasurement()
    local mapId = self.adapter:GetCurrentMapIdentifier()
    local measurement = self:GetMeasurement(mapId)

    if(measurement and measurement.mapIndex ~= TAMRIEL_MAP_INDEX) then
        logger:Info("Removing current map measurements")
        self.measurements[measurement:GetId()] = nil
        self.rootMaps[measurement.mapIndex] = false
    end
end

function TamrielOMeter:GetCurrentMapMeasurement()
    local mapId = self.adapter:GetCurrentMapIdentifier()
    local measurement = self:GetMeasurement(mapId)

    if (not measurement) then
        -- try to calculate the measurement if it does not yet exist
        self:CalculateMapMeasurement()
    end

    return self.measurements[mapId]
end

function TamrielOMeter:GetMapMeasurementByMapId(mapId)
    local measurement = self:GetMeasurement(mapId)

    if (not measurement) then 
        -- try to calculate the measurement if it does not yet exist
        self:CalculateMapMeasurement(mapId)
    end

    return self.measurements[mapId]
end

function TamrielOMeter:TryCalculateRootMapMeasurement(rootMapIndex)
    local mapId = GetMapIdByIndex(rootMapIndex)
    local measurement = self:GetMeasurement(mapId)
    if(not measurement) then
        -- calculate the measurements of map without worrying about the waypoint
        local offsetX, offsetY, scaleX, scaleY = self.adapter:GetUniversallyNormalizedMapInfo(mapId)
        local zoneIndex = select(4, GetMapInfoById(mapId))
        local zoneId = GetZoneId(zoneIndex)

        local measurement = Measurement:New()
        measurement:SetId(mapId)
        measurement:SetMapIndex(rootMapIndex)
        measurement:SetZoneId(zoneId)
        measurement:SetScale(scaleX, scaleY)
        measurement:SetOffset(offsetX, offsetY)
        self:SetMeasurement(measurement, true)
    end

    return measurement
end


function TamrielOMeter:CalculateMapMeasurement(mapId)
    local adapter = self.adapter
    local mapId = mapId

    -- if no valid mapId was provided, assume current map
    if (mapId == nil or type(mapId) ~= "number") then

        -- no need to take measurements more than once
        mapId = adapter:GetCurrentMapIdentifier()

    end


    if(mapId == 0 or self:GetMeasurement(mapId)) then return false, SET_MAP_RESULT_CURRENT_MAP_UNCHANGED end

    local offsetX, offsetY, scaleX, scaleY = adapter:GetUniversallyNormalizedMapInfo(mapId)
    local zoneId = adapter:GetCurrentZoneId()
    local mapIndex = adapter:GetCurrentMapIndex()

    local measurement = Measurement:New()
    measurement:SetId(mapId)
    measurement:SetMapIndex(mapIndex)
    measurement:SetZoneId(zoneId)
    measurement:SetScale(scaleX, scaleY)
    measurement:SetOffset(offsetX, offsetY)
    self:SetMeasurement(measurement, self.rootMaps[mapIndex] ~= nil)

    return true, SET_MAP_RESULT_CURRENT_MAP_UNCHANGED
end

function TamrielOMeter:FindRootMapMeasurementForCoordinates(x, y)
    logger:Debug("FindRootMapMeasurementForCoordinates(%f, %f)", x, y)
    for rootMapIndex, measurement in pairs(self.rootMaps) do
        if(not measurement) then
            measurement = self:TryCalculateRootMapMeasurement(rootMapIndex)
        end

        if(measurement and measurement:Contains(x, y)) then
            logger:Debug("Point is inside " .. self.adapter:GetFormattedMapName(rootMapIndex))
            return measurement
        end
    end
    logger:Warn("No matching root map found for coordinates (%f, %f)", x, y)
end

function TamrielOMeter:PushCurrentMap()
    return self.mapStack:Push()
end

function TamrielOMeter:PopCurrentMap()
    return self.mapStack:Pop()
end

local function getMapSizeId(self, mapId)
    local zoneId = self.adapter:GetPlayerZoneId()
    return string.format("%i:%i:%s:%s", mapId, zoneId, GetPlayerLocationName(), GetPlayerActiveSubzoneName()), zoneId
end
local function getCurrentWorldSize(self, notMeasuring)
    local adapter = self.adapter
    SetMapToPlayerLocation()
    local mapId = adapter:GetCurrentMapIdentifier()
    if(mapId == 0) then
        return adapter:GetWorldSize(0)
    end

    local mapSizeId, zoneId = getMapSizeId(self, mapId)
    local size = adapter:GetWorldSize(mapSizeId)
    if not size:IsValid() then
        -- This can happend, e.g. by porting
        -- no need to take measurements more than once

        -- There are maps, where GetPlayerPosition is "frozen", while GetPlayerRawWorldPosition is still working
        local _, pwx, pwh, pwy = adapter:GetPlayerWorldPosition()
        -- get the player position on the current map
        local localX, localY = adapter:GetNormalizedPositionFromWorld(zoneId, pwx, pwh, pwy)
        if (localX == 0 and localY == 0) then
            -- cannot take measurements while player position is not initialized
            return adapter:GetWorldSize(0)
        end

        logger:Debug("Calculate current world size of", mapId, "for zone", zoneId, ", Id", mapSizeId)

        local worldSizeX, worldSizeY = DEFAULT_TAMRIEL_SIZE, DEFAULT_TAMRIEL_SIZE

        local wx1, wy1
        -- Make sure the ref-point is at a different location, but not too far for blackreach
        local measurement = self:GetCurrentMapMeasurement()
        if measurement.scaleX < 0.0025 then
            -- for small (sub-)zones
            wx1, wy1 = adapter:GetNormalizedPositionFromWorld(zoneId, pwx + (localX < 0.5 and 2475 or -2475), pwh, pwy + (localY < 0.5 and 2475 or -2475)) -- 3500 world units
        else
            -- for all other zones
            wx1, wy1 = adapter:GetNormalizedPositionFromWorld(zoneId, pwx + (localX < 0.5 and 7071 or -7071), pwh, pwy + (localY < 0.5 and 7071 or -7071)) -- 10000 world units
        end

        logger:Debug("ref-point (normalized): ", wx1, "x", wy1)

        size:SetMapId(mapId)
        size:SetZoneId(zoneId)
        adapter:SetWorldSize(mapSizeId, size, true) -- Assume default scale, do not serialize

        local wwX, wwZ, wwY = measurement:ToWorld(wx1, wy1)
        logger:Debug("ref-point (calulated world): ", wwX, "x", wwY)
        -- The assumed scale may wrong. Lets see how wrong:
        local wpX1, wpY1 = adapter:GetNormalizedPositionFromWorld(zoneId, wwX, wwZ, wwY)
        logger:Debug("ref-point (normalized real): ", wpX1, "x", wpY1)
        -- correct scale, so that we get the values we want:
        local dx, dy = wx1 - localX, wy1 - localY
        local correctScale = dx * dx + dy * dy
        dx, dy = wpX1 - localX, wpY1 - localY
        correctScale = math.sqrt(correctScale / (dx * dx + dy * dy))
        worldSizeX, worldSizeY = math.floor(correctScale * worldSizeX * 0.01 + 0.25) * 100, math.floor(correctScale * worldSizeY * 0.01 + 0.25) * 100
        logger:Debug("worldSize corrected: ", worldSizeX, "x", worldSizeY)

        size:SetSize(worldSizeX, worldSizeY)
        adapter:SetWorldSize(mapSizeId, size)
    end
    return size
end

function TamrielOMeter:GetCurrentWorldSize()
    local adapter = self.adapter
    local size

    local mapId = adapter:GetCurrentMapIdentifier()
    if adapter:IsCurrentMapPlayerLocation() then
        local mapSizeId = getMapSizeId(self, mapId)
        size = adapter:GetWorldSize(mapSizeId)
        if size:IsValid() then
            return size
        end
    end

    size = getCurrentWorldSize(self)
    SetMapToMapId(mapId)
    return size
end

function TamrielOMeter:GetLocalDistanceInMeters(lx1, ly1, lx2, ly2)
    if not (lx1 or ly1 or lx2 or ly2) then return 0 end
    lx1, ly1 = lx1 - lx2, ly1 - ly2
    local worldSizeX, worldSizeY = self:GetWorldGlobalRatio()
    local measurement = self:GetCurrentMapMeasurement()
    return math.sqrt(lx1*lx1 * measurement.scaleX * worldSizeX + ly1*ly1 * measurement.scaleY * worldSizeY) * 0.01 * DEFAULT_TAMRIEL_SIZE
end

function TamrielOMeter:GetGlobalDistanceInMeters(gx1, gy1, gx2, gy2)
    if not (gx1 or gy1 or gx2 or gy2) then return 0 end
    gx1, gy1 = gx1 - gx2, gy1 - gy2
    local worldSize = self:GetWorldGlobalRatio() * DEFAULT_TAMRIEL_SIZE
    return math.sqrt(gx1*gx1 + gy1*gy1) * 0.01 * worldSize
end

local scaleIdToGlobalRatio = {}
function TamrielOMeter:GetWorldGlobalRatio()
    local adapter = self.adapter
    local mapId = adapter:GetCurrentMapIdentifier()
    local mapSizeId, zoneId = getMapSizeId(self, mapId)
    local worldSizeX, worldSizeY

    worldSizeX = scaleIdToGlobalRatio[mapSizeId]
    if not worldSizeX then
        local size = self:GetCurrentWorldSize()
        worldSizeX, worldSizeY = size:GetSize()
        worldSizeX, worldSizeY = worldSizeX / DEFAULT_TAMRIEL_SIZE, worldSizeY / DEFAULT_TAMRIEL_SIZE

        scaleIdToGlobalRatio[mapSizeId] = { worldSizeX, worldSizeY }
    else
        worldSizeX, worldSizeY = unpack(worldSizeX)
    end
    return worldSizeX, worldSizeY
end

function TamrielOMeter:GetGlobalWorldRatio()
    local worldSizeX, worldSizeY = self:GetWorldGlobalRatio()
    return 1 / worldSizeX, 1 / worldSizeY
end
