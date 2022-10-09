-- LibGPS3 & its files © sirinsidiator                          --
-- Distributed under The Artistic License 2.0 (see LICENSE)     --
------------------------------------------------------------------

local lib = LibGPS3
local logger = lib.internal.logger
local tremove = table.remove

local MapStack = ZO_Object:Subclass()
lib.internal.class.MapStack = MapStack

function MapStack:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function MapStack:Initialize(meter, adapter)
    self.meter = meter
    self.adapter = adapter
    self.stack = {}
end

function MapStack:Push()
    local adapter = self.adapter
    local mapId = adapter:GetCurrentMapIdentifier()
    local zoom = adapter:GetCurrentZoom()
    local offsetX, offsetY = adapter:GetCurrentOffset()
    logger:Verbose("Push map on stack")

    local mapStack = self.stack
    mapStack[#mapStack + 1] = {
        mapId,
        zoom,
        offsetX, offsetY,
    }
end

function MapStack:Pop()
    local mapStack = self.stack
    local data = tremove(mapStack, #mapStack)
    if(not data) then
        logger:Debug("Pop map failed. No data on map stack.")
        return SET_MAP_RESULT_FAILED
    end

    local adapter = self.adapter
    local meter = self.meter
    local mapId, zoom, offsetX, offsetY = unpack(data)
    local result = adapter:SetMapToMapIdWithoutMeasuring(mapId)
    logger:Verbose("Pop map from stack")

    if (result ~= SET_MAP_RESULT_FAILED) then
        adapter:SetCurrentZoom(zoom)
        adapter:SetCurrentOffset(offsetX, offsetY)
    end

    return result
end
