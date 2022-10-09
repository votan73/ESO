-- LibMapPing & its files © sirinsidiator                       --
-- Distributed under The Artistic License 2.0 (see LICENSE)     --
------------------------------------------------------------------

local lib = LibMapPing2
local internal = lib.internal

--- MapPingState is an enumeration of the possible states of a map ping.
local MapPingState = internal.MapPingState
lib.MapPingState = MapPingState
--- MapPingState.NOT_SET - There is no ping.
--- MapPingState.NOT_SET_PENDING - The ping has been removed, but EVENT_MAP_PING has not been processed.
--- MapPingState.SET_PENDING - A ping was added, but EVENT_MAP_PING has not been processed.
--- MapPingState.SET - There is a ping.

--- Wrapper for PingMap and SetPlayerWaypointByWorldLocation.
--- pingType is one of the three possible MapDisplayPinType for map pings (MAP_PIN_TYPE_PLAYER_WAYPOINT, MAP_PIN_TYPE_PING or MAP_PIN_TYPE_RALLY_POINT) or false.
--- when pingType is set to false, the function calls SetPlayerWaypointByWorldLocation and the arguments will be the worldX, worldY and worldZ and the return a boolean success.
--- for all other pingTypes nothing is returned and the arguments are as follows:
--- mapType is usually MAP_TYPE_LOCATION_CENTERED.
--- x and y are the normalized coordinates on the current map.
function lib:SetMapPing(pingType, mapTypeOrWorldX, xOrWorldY, yOrWorldZ)
    if pingType == false then
        return internal.handler:SetPlayerWaypointByWorldLocation(mapTypeOrWorldX, xOrWorldY, yOrWorldZ)
    else
        internal.handler:PingMap(pingType, mapTypeOrWorldX, xOrWorldY, yOrWorldZ)
    end
end

--- Wrapper for the different ping removal functions.
--- For waypoints and rally points it calls their respective removal function
--- For group pings it just sets the position to 0, 0 as there is no function to clear them
function lib:RemoveMapPing(pingType)
    internal.handler:RemoveMapPingByType(pingType)
end

--- Wrapper for the different get ping functions.
--- pingType is the same as for SetMapPing.
--- pingTag is optionally used if another group member's MAP_PIN_TYPE_PING should be returned (possible values: group1 .. group24).
function lib:GetMapPing(pingType, pingTag)
    return internal.handler:GetMapPingByType(pingType, pingTag)
end

--- Wrapper for the different get ping functions. Returns coordinates regardless of their suppression state.
--- The replaced game API functions will return 0, 0 while a ping type is suppressed.
--- Parameters are identical to GetMapPing.
function lib:GetRawMapPing(pingType, pingTag)
    return internal.handler:GetRawMapPingByType(pingType, pingTag)
end

--- Returns the MapPingState for the pingType and pingTag.
function lib:GetMapPingState(pingType, pingTag)
    return internal.handler:GetMapPingState(pingType, pingTag)
end

--- Returns true if ping state is MAP_PING_SET_PENDING or MAP_PING_SET
function lib:HasMapPing(pingType, pingTag)
    return internal.handler:HasMapPing(pingType, pingTag)
end

--- Refreshes the pin icon for the pingType on the worldmap
--- Returns true if the pin has been refreshed.
function lib:RefreshMapPin(pingType, pingTag)
    return internal.handler:RefreshMapPin(pingType, pingTag)
end

--- Returns true if the normalized position is within 0 and 1.
function lib:IsPositionOnMap(x, y)
    return internal.handler:IsPositionOnMap(x, y)
end

--- Mutes the map ping of the specified type, so it does not make a sound when it is set.
--- Do not forget to call UnmutePing later, otherwise the sound will be permanently muted!
function lib:MutePing(pingType, pingTag)
    internal.handler:MutePing(pingType, pingTag)
end

--- Unmutes the map ping of the specified type.
--- Do not call this more often than you called MutePing, or you might interfere with other addons.
--- The sounds are played between the BeforePing* and AfterPing* callbacks are fired.
function lib:UnmutePing(pingType, pingTag)
    internal.handler:UnmutePing(pingType, pingTag)
end

--- Returns true if the map ping has been muted
function lib:IsPingMuted(pingType, pingTag)
    internal.handler:IsPingMuted(pingType, pingTag)
end

--- Suppresses the map ping of the specified type, so that it neither makes a sound nor shows up on the map.
--- This also makes the API functions return 0, 0 for that ping.
--- In order to access the actual coordinates lib:GetMapPing has to be used.
--- Do not forget to call UnsuppressPing later, otherwise map pings won't work anymore for the user and other addons!
function lib:SuppressPing(pingType, pingTag)
    internal.handler:SuppressPing(pingType, pingTag)
end

--- Unsuppresses the map ping so it shows up again
--- Do not call this more often than you called SuppressPing, or you might interfere with other addons.
function lib:UnsuppressPing(pingType, pingTag)
    internal.handler:UnsuppressPing(pingType, pingTag)
end

--- Returns true if the map ping has been suppressed
function lib:IsPingSuppressed(pingType, pingTag)
    return internal.handler:IsPingSuppressed(pingType, pingTag)
end

--- Register to callbacks from the library.
--- Valid events are BeforePingAdded, AfterPingAdded, BeforePingRemoved and AfterPingRemoved.
--- These are fired at certain points during handling EVENT_MAP_PING.
function lib:RegisterCallback(eventName, callback)
    return internal:RegisterCallback(eventName, callback)
end

--- Unregister from callbacks. See lib:RegisterCallback.
function lib:UnregisterCallback(eventName, callback)
    return internal:UnregisterCallback(eventName, callback)
end

internal:Initialize()
