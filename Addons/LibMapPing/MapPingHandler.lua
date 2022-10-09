-- LibMapPing & its files © sirinsidiator                       --
-- Distributed under The Artistic License 2.0 (see LICENSE)     --
------------------------------------------------------------------

local lib = LibMapPing2
local internal = lib.internal
local logger = internal.logger
local callback = internal.callback
local MapPingState = internal.MapPingState
local LeakyBucket = internal.class.LeakyBucket

local MapPingHandler = ZO_Object:Subclass()
internal.class.MapPingHandler = MapPingHandler

local MAP_PIN_TYPE_PLAYER_WAYPOINT = MAP_PIN_TYPE_PLAYER_WAYPOINT
local MAP_PIN_TYPE_PING = MAP_PIN_TYPE_PING
local MAP_PIN_TYPE_RALLY_POINT = MAP_PIN_TYPE_RALLY_POINT

local MAP_PIN_TAG_PLAYER_WAYPOINT = "waypoint"
local MAP_PIN_TAG_RALLY_POINT = "rally"
local PING_CATEGORY = "pings"

local PING_EVENT_TYPE_INDEX = 1
local PING_EVENT_WATCHDOG_TIME = 400 -- ms

local KEY_TEMPLATE = "%d_%s"

local MAP_PIN_TAG = {
    [MAP_PIN_TYPE_PLAYER_WAYPOINT] = MAP_PIN_TAG_PLAYER_WAYPOINT,
    --[MAP_PIN_TYPE_PING] = group pings have individual tags for each member
    [MAP_PIN_TYPE_RALLY_POINT] = MAP_PIN_TAG_RALLY_POINT,
}

local function GetPingTagFromType(pingType)
    return MAP_PIN_TAG[pingType] or GetGroupUnitTagByIndex(GetGroupIndexByUnitTag("player")) or ""
end

function MapPingHandler:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function MapPingHandler:Initialize()
    self.mapPinManager = ZO_WorldMap_GetPinManager()
    self.bucket = LeakyBucket:New()
    self.mutePing = {}
    self.suppressPing = {}
    self.pingState = {}
    self.pendingPing = {}

    self.original = {}
    self.getter = {}
    self.rawGetter = {}
    self.remover = {}

    self:ReplaceFunction("PingMap")
    self:ReplaceFunction("SetPlayerWaypointByWorldLocation")
    -- we use the original getters
    self.getter[MAP_PIN_TYPE_PLAYER_WAYPOINT], self.rawGetter[MAP_PIN_TYPE_PLAYER_WAYPOINT] = self:ReplaceFunction("GetMapPlayerWaypoint")
    self.getter[MAP_PIN_TYPE_PING], self.rawGetter[MAP_PIN_TYPE_PING] = self:ReplaceFunction("GetMapPing")
    self.getter[MAP_PIN_TYPE_RALLY_POINT], self.rawGetter[MAP_PIN_TYPE_RALLY_POINT] = self:ReplaceFunction("GetMapRallyPoint")
    -- but the custom removers
    self.remover[MAP_PIN_TYPE_PLAYER_WAYPOINT] = self:ReplaceFunction("RemovePlayerWaypoint")
    self.remover[MAP_PIN_TYPE_PING] = function(...) return self:RemoveMapPing(...) end -- has no api equivalent
    self.remover[MAP_PIN_TYPE_RALLY_POINT] = self:ReplaceFunction("RemoveRallyPoint")

    self.watchDogCallback = function()
        return self:HandleMapPingEventNotFired()
    end

    local handle
    handle = internal.RegisterForEvent(EVENT_ADD_ON_LOADED, function(_, addonName)
        if addonName == "ZO_Ingame" then
            internal.UnregisterForEvent(handle, EVENT_ADD_ON_LOADED)
            -- don't let worldmap do anything as we manage it instead
            internal.UnregisterForEvent("ZO_WorldMap", EVENT_MAP_PING)
            WORLD_MAP_MANAGER.control:UnregisterForEvent(EVENT_MAP_PING)
            internal.RegisterForEvent(EVENT_MAP_PING, function(...)
                self:HandleMapPing(...)
            end)
        end
    end)
end

function MapPingHandler:ReplaceFunction(name)
    self.original[name] = _G[name]
    _G[name] = function(...) return self[name](self, ...) end
    return _G[name], self.original[name]
end

function MapPingHandler:GetKey(pingType, pingTag)
    pingTag = pingTag or GetPingTagFromType(pingType)
    return KEY_TEMPLATE:format(pingType, pingTag)
end

-- TODO keep an eye on worldmap.lua for changes
function MapPingHandler:HandleMapPing(eventCode, pingEventType, pingType, pingTag, x, y, isPingOwner)
    local key = self:GetKey(pingType, pingTag)
    local data = self.pendingPing[key]
    if data and data[PING_EVENT_TYPE_INDEX] == pingEventType then
        self.pendingPing[key] = nil
    end

    if pingEventType == PING_EVENT_ADDED then
        self:HandleMapPingAdded(key, pingType, pingTag, x, y, isPingOwner)
    elseif pingEventType == PING_EVENT_REMOVED then
        self:HandleMapPingRemoved(key, pingType, pingTag, x, y, isPingOwner)
    end
end

function MapPingHandler:HandleMapPingAdded(key, pingType, pingTag, x, y, isPingOwner)
    logger:Verbose("Ping added", key)
    internal:FireCallbacks(callback.BEFORE_PING_ADDED, pingType, pingTag, x, y, isPingOwner)

    self.pingState[key] = MapPingState.SET
    self.mapPinManager:RemovePins(PING_CATEGORY, pingType, pingTag)

    if not self:IsPingSuppressed(pingType, pingTag) then
        logger:Verbose("Create pin")
        self.mapPinManager:CreatePin(pingType, pingTag, x, y)

        if isPingOwner and not self:IsPingMuted(pingType, pingTag) then
            logger:Verbose("Play sound")
            PlaySound(SOUNDS.MAP_PING)
        end
    end

    internal:FireCallbacks(callback.AFTER_PING_ADDED, pingType, pingTag, x, y, isPingOwner)
end

function MapPingHandler:HandleMapPingRemoved(key, pingType, pingTag, x, y, isPingOwner)
    logger:Verbose("Ping removed", key)
    internal:FireCallbacks(callback.BEFORE_PING_REMOVED, pingType, pingTag, x, y, isPingOwner)

    self.pingState[key] = MapPingState.NOT_SET
    self.mapPinManager:RemovePins(PING_CATEGORY, pingType, pingTag)

    if isPingOwner and not (self:IsPingSuppressed(pingType, pingTag) or self:IsPingMuted(pingType, pingTag)) then
        logger:Verbose("Play sound")
        PlaySound(SOUNDS.MAP_PING_REMOVE)
    end

    internal:FireCallbacks(callback.AFTER_PING_REMOVED, pingType, pingTag, x, y, isPingOwner)
end

function MapPingHandler:HandleMapPingEventNotFired()
    if self.updateHandle then internal.UnregisterForUpdate(self.updateHandle) end
    for key, data in pairs(self.pendingPing) do
        local pingEventType, pingType, x, y, mapId = unpack(data)
        local pingTag = GetPingTagFromType(pingType)
        -- The event is delayed and thus may not match the current map anymore.
        if GetCurrentMapId() ~= mapId then
            -- The coords do not match the current map. Do not draw a pin.
            self:SuppressPing(pingType, pingTag) -- Will be set to zero afterwards, see below.
        end
        self:HandleMapPing(0, pingEventType, pingType, pingTag, x, y, true)
        self.pendingPing[key] = nil
        self.mutePing[key] = 0
        self.suppressPing[key] = 0
    end
end

function MapPingHandler:ResetEventWatchdog(key, ...)
    self.pendingPing[key] = {...}
    if self.updateHandle then internal.UnregisterForUpdate(self.updateHandle) end
    self.updateHandle = internal.RegisterForUpdate(PING_EVENT_WATCHDOG_TIME, self.watchDogCallback)
end

function MapPingHandler:PingMap(pingType, mapType, x, y)
    if(pingType == MAP_PIN_TYPE_PING and not IsUnitGrouped("player")) then return end
    if(pingType == MAP_PIN_TYPE_PLAYER_WAYPOINT or self.bucket:Take()) then
        local key = self:GetKey(pingType)
        self.pingState[key] = MapPingState.SET_PENDING
        self:ResetEventWatchdog(key, PING_EVENT_ADDED, pingType, x, y, GetCurrentMapId())
        return self.original.PingMap(pingType, mapType, x, y)
    end
end

function MapPingHandler:SetPlayerWaypointByWorldLocation(worldX, worldY, worldZ)
    local success = self.original.SetPlayerWaypointByWorldLocation(worldX, worldY, worldZ)
    if success then
        local key = self:GetKey(MAP_PIN_TYPE_PLAYER_WAYPOINT)
        self.pingState[key] = MapPingState.SET_PENDING
        -- can't use a watchdog here, since we don't know where the ping would show
    end
    return success
end

function MapPingHandler:GetMapPlayerWaypoint()
    if(self:IsPingSuppressed(MAP_PIN_TYPE_PLAYER_WAYPOINT, MAP_PIN_TAG_PLAYER_WAYPOINT)) then
        return 0, 0
    end
    return self.original.GetMapPlayerWaypoint()
end

function MapPingHandler:GetMapPing(pingTag)
    if(self:IsPingSuppressed(MAP_PIN_TYPE_PING, pingTag)) then
        return 0, 0
    end
    return self.original.GetMapPing(pingTag)
end

function MapPingHandler:GetMapRallyPoint()
    if(lib:IsPingSuppressed(MAP_PIN_TYPE_RALLY_POINT, MAP_PIN_TAG_RALLY_POINT)) then
        return 0, 0
    end
    return self.original.GetMapRallyPoint()
end

function MapPingHandler:RemovePlayerWaypoint()
    local key = self:GetKey(MAP_PIN_TYPE_PLAYER_WAYPOINT, MAP_PIN_TAG_PLAYER_WAYPOINT)
    self.pingState[key] = MapPingState.NOT_SET_PENDING
    self:ResetEventWatchdog(key, PING_EVENT_REMOVED, MAP_PIN_TYPE_PLAYER_WAYPOINT, 0, 0, GetCurrentMapId())
    return self.original.RemovePlayerWaypoint()
end

function MapPingHandler:RemoveMapPing()
    -- there is no such function for group pings, but we can set it to 0, 0 which effectively hides it
    self:PingMap(MAP_PIN_TYPE_PING, MAP_TYPE_LOCATION_CENTERED, 0, 0)
end

function MapPingHandler:RemoveRallyPoint()
    local key = self:GetKey(MAP_PIN_TYPE_RALLY_POINT, MAP_PIN_TAG_RALLY_POINT)
    self.pingState[key] = MapPingState.NOT_SET_PENDING
    self:ResetEventWatchdog(key, PING_EVENT_REMOVED, MAP_PIN_TYPE_RALLY_POINT, 0, 0)
    self.original.RemoveRallyPoint()
end

function MapPingHandler:RemoveMapPingByType(pingType)
    if(self.remover[pingType]) then
        self.remover[pingType]()
    end
end

function MapPingHandler:GetMapPingByType(pingType, pingTag)
    local x, y = 0, 0
    if(self.getter[pingType]) then
        x, y = self.getter[pingType](pingTag or GetPingTagFromType(pingType))
    end
    return x, y
end

function MapPingHandler:GetRawMapPingByType(pingType, pingTag)
    local x, y = 0, 0
    if(self.rawGetter[pingType]) then
        x, y = self.rawGetter[pingType](pingTag or GetPingTagFromType(pingType))
    end
    return x, y
end

function MapPingHandler:GetMapPingState(pingType, pingTag)
    local key = self:GetKey(pingType, pingTag)
    local state = self.pingState[key]
    if state == nil then
        local x, y = self:GetRawMapPingByType(pingType, pingTag)
        state = (x ~= 0 or y ~= 0) and MapPingState.SET or MapPingState.NOT_SET
        self.pingState[key] = state
    end
    return self.pingState[key]
end

function MapPingHandler:HasMapPing(pingType, pingTag)
    local state = self:GetMapPingState(pingType, pingTag)
    return state == MapPingState.SET_PENDING or state == MapPingState.SET
end

function MapPingHandler:RefreshMapPin(pingType, pingTag)
    pingTag = pingTag or GetPingTagFromType(pingType)
    self.mapPinManager:RemovePins(PING_CATEGORY, pingType, pingTag)

    local x, y = self:GetMapPing(pingType, pingTag)
    if(self:IsPositionOnMap(x, y)) then
        self.mapPinManager:CreatePin(pingType, pingTag, x, y)
        return true
    end
    return false
end

function MapPingHandler:IsPositionOnMap(x, y)
    return not (x < 0 or y < 0 or x > 1 or y > 1 or (x == 0 and y == 0))
end

function MapPingHandler:MutePing(pingType, pingTag)
    local key = self:GetKey(pingType, pingTag)
    local mute = self.mutePing[key] or 0
    self.mutePing[key] = mute + 1
    logger:Verbose("Mute ping %s - new count: %d", key, self.mutePing[key])
end

function MapPingHandler:UnmutePing(pingType, pingTag)
    local key = self:GetKey(pingType, pingTag)
    local mute = (self.mutePing[key] or 0) - 1
    if(mute < 0) then mute = 0 end
    self.mutePing[key] = mute
    logger:Verbose("Unmute ping %s - new count: %d", key, self.mutePing[key])
end

function MapPingHandler:IsPingMuted(pingType, pingTag)
    local key = self:GetKey(pingType, pingTag)
    return self.mutePing[key] and self.mutePing[key] > 0
end

function MapPingHandler:SuppressPing(pingType, pingTag)
    local key = self:GetKey(pingType, pingTag)
    local suppress = self.suppressPing[key] or 0
    self.suppressPing[key] = suppress + 1
    logger:Verbose("Suppress ping %s - new count: %d", key, self.suppressPing[key])
end

function MapPingHandler:UnsuppressPing(pingType, pingTag)
    local key = self:GetKey(pingType, pingTag)
    local suppress = (self.suppressPing[key] or 0) - 1
    if(suppress < 0) then suppress = 0 end
    self.suppressPing[key] = suppress
    logger:Verbose("Unsuppress ping %s - new count: %d", key, self.suppressPing[key])
end

function MapPingHandler:IsPingSuppressed(pingType, pingTag)
    local key = self:GetKey(pingType, pingTag)
    return self.suppressPing[key] and self.suppressPing[key] > 0
end
