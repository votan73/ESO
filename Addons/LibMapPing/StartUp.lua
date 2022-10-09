-- LibMapPing & its files © sirinsidiator                       --
-- Distributed under The Artistic License 2.0 (see LICENSE)     --
------------------------------------------------------------------

local LIB_IDENTIFIER = "LibMapPing2"

assert(not _G[LIB_IDENTIFIER], LIB_IDENTIFIER .. " is already loaded")

local lib = {}
_G[LIB_IDENTIFIER] = lib

local nextNamespaceId = 1

local function RegisterForEvent(event, callback)
    local namespace = LIB_IDENTIFIER .. nextNamespaceId
    EVENT_MANAGER:RegisterForEvent(namespace, event, callback)
    nextNamespaceId = nextNamespaceId + 1
    return namespace
end

local function UnregisterForEvent(namespace, event)
    return EVENT_MANAGER:UnregisterForEvent(namespace, event)
end

local function RegisterForUpdate(interval, callback)
    local namespace = LIB_IDENTIFIER .. nextNamespaceId
    EVENT_MANAGER:RegisterForUpdate(namespace, interval, callback)
    nextNamespaceId = nextNamespaceId + 1
    return namespace
end

local function UnregisterForUpdate(namespace)
    return EVENT_MANAGER:UnregisterForUpdate(namespace)
end

lib.internal = {
    callbackObject = ZO_CallbackObject:New(),
    callback = {
        BEFORE_PING_ADDED = "BeforePingAdded",
        AFTER_PING_ADDED = "AfterPingAdded",
        BEFORE_PING_REMOVED = "BeforePingRemoved",
        AFTER_PING_REMOVED = "AfterPingRemoved",
    },
    RegisterForEvent = RegisterForEvent,
    UnregisterForEvent = UnregisterForEvent,
    RegisterForUpdate = RegisterForUpdate,
    UnregisterForUpdate = UnregisterForUpdate,
    class = {},
    logger = LibDebugLogger(LIB_IDENTIFIER),
    MapPingState = {
        NOT_SET = 0,
        NOT_SET_PENDING = 1,
        SET_PENDING = 2,
        SET = 3
    }
}

local internal = lib.internal

function internal:FireCallbacks(...)
    return self.callbackObject:FireCallbacks(...)
end

function internal:RegisterCallback(...)
    return self.callbackObject:RegisterCallback(...)
end

function internal:UnregisterCallback(...)
    return self.callbackObject:UnregisterCallback(...)
end

function internal:Initialize()
    local class = self.class
    local logger = self.logger

    logger:Debug("Initializing LibMapPing2...")
    self.handler = class.MapPingHandler:New()
    logger:Debug("Initialization complete")
end
