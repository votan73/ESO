-- LibGPS3 & its files © sirinsidiator                          --
-- Distributed under The Artistic License 2.0 (see LICENSE)     --
------------------------------------------------------------------

local LIB_IDENTIFIER = "LibGPS3"
local VERSION = 4

assert(not _G[LIB_IDENTIFIER], LIB_IDENTIFIER .. " is already loaded")

local lib = {}
_G[LIB_IDENTIFIER] = lib

lib.internal = {
    class = {},
    logger = LibDebugLogger(LIB_IDENTIFIER),
    chat = LibChatMessage(LIB_IDENTIFIER, "LGPS"),
    TAMRIEL_MAP_INDEX = 1,
    BLACKREACH_ROOT_MAP_INDEX = 40,
}

function lib.internal:InitializeSaveData()
    local saveData = LibGPS_Data

    if(not saveData or saveData.version ~= VERSION or saveData.apiVersion ~= GetAPIVersion()) then
        self.logger:Info("Creating new saveData")
        saveData = {
            version = VERSION,
            apiVersion = GetAPIVersion(),
            sizeIdWorldSize = {}
        }
    end

    for id, data in pairs(self.mapAdapter.sizeIdWorldSize) do
        saveData.sizeIdWorldSize[id] = data:Serialize()
    end

    LibGPS_Data = saveData
    self.saveData = saveData
end

function lib.internal:Initialize()
    local class = self.class
    local logger = self.logger

    logger:Debug("Initializing LibGPS3...")
    local internal = lib.internal

    local mapAdapter = class.MapAdapter:New()
    local meter = class.TamrielOMeter:New(mapAdapter)
    local waypointManager = class.WaypointManager:New(mapAdapter, meter)
    mapAdapter:SetWaypointManager(waypointManager)
    meter:SetWaypointManager(waypointManager)

    internal.mapAdapter = mapAdapter
    internal.meter = meter

    EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_ADD_ON_LOADED, function(event, name)
        if(name ~= "LibGPS") then return end
        EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_ADD_ON_LOADED)
        internal:InitializeSaveData()
        logger:Debug("Saved Variables loaded")
        SetMapToPlayerLocation() -- initial measurement so we can get back to where we are currently
    end)

    SLASH_COMMANDS["/libgpsreset"] = function()
        meter:Reset()
        self.chat:Print("All measurements have been cleared")
    end

    logger:Debug("Initialization complete")
end
