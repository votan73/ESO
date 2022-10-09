-- LibGPS3 & its files © sirinsidiator                          --
-- Distributed under The Artistic License 2.0 (see LICENSE)     --
------------------------------------------------------------------

local lib = LibGPS3
local logger = lib.internal.logger
local adapter = lib.internal.adapter

--- This object contains all the data about a map measurement and offers some convenience functions to interact with them.
--- Undocumented methods are for internal use only.
local Measurement = ZO_Object:Subclass()
lib.internal.class.Measurement = Measurement

function Measurement:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function Measurement:Initialize()
    self.id = ""
    self.mapIndex = 0
    self.zoneId = 0

    self.scaleX = 1
    self.scaleY = 1
    self.offsetX = 0
    self.offsetY = 0
end

--- Returns a unique id for the measurement which is used to store it in the saved variables. Details are implementation specific and may change between versions.
function Measurement:GetId()
    return self.id
end

function Measurement:SetId(id)
    self.id = id
end

function Measurement:SetMapIndex(mapIndex)
    self.mapIndex = mapIndex
end

--- Returns the mapIndex or nil if the measured map doesn't have one.
function Measurement:GetMapIndex()
    return self.mapIndex
end

function Measurement:SetZoneId(zoneId)
    self.zoneId = zoneId
end

--- Returns the zoneId for the measurement. Keep in mind that a map can have multiple zoneIds within its borders and a zoneId can also span multiple maps.
function Measurement:GetZoneId()
    return self.zoneId
end

function Measurement:SetScale(scaleX, scaleY)
    self.scaleX = scaleX
    self.scaleY = scaleY
end

--- Returns the scale in the global coordinate space for the current map.
function Measurement:GetScale()
    return self.scaleX, self.scaleY
end

function Measurement:SetOffset(offsetX, offsetY)
    self.offsetX = offsetX
    self.offsetY = offsetY
end

--- Returns the offset in the global coordinate space for the current map.
function Measurement:GetOffset()
    return self.offsetX, self.offsetY
end

--- Returns true if the measurement contains valid data.
function Measurement:IsValid()
    return self.id and (self.mapIndex or self.zoneId) > 0
end

--- Converts and returns global coordinates for a given local coordinate pair.
function Measurement:ToGlobal(x, y)
    x = x * self.scaleX + self.offsetX
    y = y * self.scaleY + self.offsetY
    return x, y
end

function Measurement:ToWorld(x, y)
    local adapter = lib.internal.mapAdapter
    local _, pwx, pwh, pwy = adapter:GetPlayerWorldPosition()
    local playerX, playerY = adapter:GetPlayerPosition()
    local scaleX, scaleY = lib.internal.meter:GetCurrentWorldSize():GetSize()
    local scaleX, scaleY = scaleX * self.scaleX, scaleY * self.scaleY
    local worldX, worldY = (x - playerX) * scaleX + pwx, (y - playerY) * scaleY + pwy
    return worldX, pwh, worldY
end

-- Converts and returns local coordinates for a given global coordinate pair.
function Measurement:ToLocal(x, y)
    x = (x - self.offsetX) / self.scaleX
    y = (y - self.offsetY) / self.scaleY
    return x, y
end

--- Returns the center of the measured map as global coordinates.
function Measurement:GetCenter()
    local x = self.offsetX + (self.scaleX / 2)
    local y = self.offsetY + (self.scaleY / 2)
    return x, y
end

--- Returns true if the given global coordinates are inside the measured map.
function Measurement:Contains(x, y)
    return not (x <= self.offsetX
        or x >= (self.offsetX + self.scaleX)
        or y <= self.offsetY
        or y >= (self.offsetY + self.scaleY))
end

--- Returns the map name including localization info.
function Measurement:GetName()
    return GetMapNameById(self:GetId())
end

-- Returns the parent zone id
function Measurement:GetParentZoneId()
    return GetParentZoneId(self:GetZoneId())
end

local temp = {}
local SEPARATOR = ":"
local VERSION = "1"

local VERSION_INDEX = 1
local MAP_INDEX_INDEX = 2
local ZONE_ID_INDEX = 3
local SCALE_X_INDEX = 4
local SCALE_Y_INDEX = 5
local OFFSET_X_INDEX = 6
local OFFSET_Y_INDEX = 7

function Measurement:Serialize()
    temp[VERSION_INDEX] = VERSION
    temp[MAP_INDEX_INDEX] = self.mapIndex
    temp[ZONE_ID_INDEX] = self.zoneId
    temp[SCALE_X_INDEX] = self.scaleX
    temp[SCALE_Y_INDEX] = self.scaleY
    temp[OFFSET_X_INDEX] = self.offsetX
    temp[OFFSET_Y_INDEX] = self.offsetY
    return table.concat(temp, SEPARATOR)
end

function Measurement:Deserialize(id, data)
    local splitData = {zo_strsplit(SEPARATOR, data)}
    if(splitData[VERSION_INDEX] == VERSION) then
        self.id = id
        self.mapIndex = tonumber(splitData[MAP_INDEX_INDEX])
        self.zoneId = tonumber(splitData[ZONE_ID_INDEX])
        self.scaleX = tonumber(splitData[SCALE_X_INDEX])
        self.scaleY = tonumber(splitData[SCALE_Y_INDEX])
        self.offsetX = tonumber(splitData[OFFSET_X_INDEX])
        self.offsetY = tonumber(splitData[OFFSET_Y_INDEX])
    else
        logger:Warn("Tried to deserialize from unknown version", data)
    end
end
