-- LibGPS3 & its files © sirinsidiator                          --
-- Distributed under The Artistic License 2.0 (see LICENSE)     --
------------------------------------------------------------------

local lib = LibGPS3
local logger = lib.internal.logger
local adapter = lib.internal.adapter
local DEFAULT_TAMRIEL_SIZE = 2500000

--- This object contains all the data about a map WorldSize and offers some convenience functions to interact with them.
--- Undocumented methods are for internal use only.
local WorldSize = ZO_Object:Subclass()
lib.internal.class.WorldSize = WorldSize

function WorldSize:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function WorldSize:Initialize()
    self.id = 0
    self.zoneId = 0

    self.width = DEFAULT_TAMRIEL_SIZE
    self.height = DEFAULT_TAMRIEL_SIZE
end

--- Returns a unique id for the WorldSize which is used to store it in the saved variables. Details are implementation specific and may change between versions.
function WorldSize:GetId()
    return self.id + self.zoneId * 100000
end

function WorldSize:GetMapId()
    return self.id
end

function WorldSize:SetMapId(id)
    self.id = id
end

function WorldSize:SetZoneId(zoneId)
    self.zoneId = zoneId
end

--- Returns the zoneId for the WorldSize. Keep in mind that a map can have multiple zoneIds within its borders and a zoneId can also span multiple maps.
function WorldSize:GetZoneId()
    return self.zoneId
end

function WorldSize:SetSize(width, height)
    self.width = width
    self.height = height
end

--- Returns the scale in the global coordinate space for the current map.
function WorldSize:GetSize()
    return self.width, self.height
end

--- Returns true if the WorldSize contains valid data.
function WorldSize:IsValid()
    return self.id > 0 and self.zoneId > 0
end

--- Returns the map name including localization info.
function WorldSize:GetName()
    return GetMapNameById(self:GetMapId())
end

local temp = {}
local SEPARATOR = ":"
local VERSION = "1"

local VERSION_INDEX = 1
local MAP_ID_INDEX = 2
local ZONE_ID_INDEX = 3
local WIDTH_INDEX = 4
local HEIGHT_INDEX = 5

function WorldSize:Serialize()
    temp[VERSION_INDEX] = VERSION
    temp[MAP_ID_INDEX] = self.id
    temp[ZONE_ID_INDEX] = self.zoneId
    temp[WIDTH_INDEX] = self.width
    temp[HEIGHT_INDEX] = self.height
    return table.concat(temp, SEPARATOR)
end

function WorldSize:Deserialize(data)
    local splitData = {zo_strsplit(SEPARATOR, data)}
    if(splitData[VERSION_INDEX] == VERSION) then
        self.id = tonumber(splitData[MAP_ID_INDEX])
        self.zoneId = tonumber(splitData[ZONE_ID_INDEX])
        self.width = tonumber(splitData[WIDTH_INDEX])
        self.height = tonumber(splitData[HEIGHT_INDEX])
    else
        logger:Warn("Tried to deserialize from unknown version", data)
    end
end
