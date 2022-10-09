-- LibMapPing & its files © sirinsidiator                       --
-- Distributed under The Artistic License 2.0 (see LICENSE)     --
------------------------------------------------------------------

local libv2 = LibMapPing2

local lib
if LibStub then
    local MAJOR, MINOR = "LibMapPing", 13
    lib = LibStub:NewLibrary(MAJOR, MINOR)
    assert(lib, "LibMapPing compatibility layer was loaded more than once. Please ensure that its files are not included from other addons.")

    -- reuse existing variables
    local internal = libv2.internal
    local handler = internal.handler
    internal.callbackObject = lib.cm or internal.callbackObject
    handler.mutePing = lib.mutePing or handler.mutePing
    handler.suppressPing = lib.suppressPing or handler.suppressPing
    handler.pingState = lib.pingState or handler.pingState
    handler.pendingPing = lib.pendingPing or handler.pendingPing
else
    lib = {}
end

LibMapPing = lib

if (lib.Unload) then
    -- Undo actions from older LibMapPing
    lib:Unload()
end

local MapPingState = libv2.MapPingState
lib.MAP_PING_NOT_SET = MapPingState.NOT_SET
lib.MAP_PING_NOT_SET_PENDING = MapPingState.NOT_SET_PENDING
lib.MAP_PING_SET_PENDING = MapPingState.SET_PENDING
lib.MAP_PING_SET = MapPingState.SET

function lib:SetMapPing(...)
    return libv2.internal.handler:PingMap(...)
end

function lib:RemoveMapPing(...)
    return libv2:RemoveMapPing(...)
end

function lib:GetMapPing(...)
    return libv2:GetRawMapPing(...)
end

function lib:GetMapPingState(...)
    return libv2:GetMapPingState(...)
end

function lib:HasMapPing(...)
    return libv2:HasMapPing(...)
end

function lib:RefreshMapPin(...)
    return libv2:RefreshMapPin(...)
end

function lib:IsPositionOnMap(...)
    return libv2:IsPositionOnMap(...)
end

function lib:MutePing(...)
    return libv2:MutePing(...)
end

function lib:UnmutePing(...)
    return libv2:UnmutePing(...)
end

function lib:IsPingMuted(...)
    return libv2:IsPingMuted(...)
end

function lib:SuppressPing(...)
    return libv2:SuppressPing(...)
end

function lib:UnsuppressPing(...)
    return libv2:UnsuppressPing(...)
end

function lib:IsPingSuppressed(...)
    return libv2:IsPingSuppressed(...)
end

function lib:RegisterCallback(...)
    return libv2:RegisterCallback(...)
end

function lib:UnregisterCallback(...)
    return libv2:UnregisterCallback(...)
end
