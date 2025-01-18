local LIB_IDENTIFIER = "LibChatMessage"

assert(not _G[LIB_IDENTIFIER], LIB_IDENTIFIER .. " is already loaded")

local lib = {}
_G[LIB_IDENTIFIER] = lib

local TAG_FORMAT = "[%s]"
local COLOR_FORMAT = "|c%s%s|r"
local MESSAGE_TEMPLATE = "%s %s"
local SYSTEM_TAG = TAG_FORMAT:format(GetString("SI_CHATCHANNELCATEGORIES", CHAT_CATEGORY_SYSTEM))

local TIME_FORMAT_AUTO = "[%X]"
local TIME_FORMAT_12 = "[%I:%M:%S %p]"
local TIME_FORMAT_24 = "[%T]"
local TIME_FORMATS = { TIME_FORMAT_AUTO, TIME_FORMAT_12, TIME_FORMAT_24 }
local TIME_FORMAT_MAPPING = {
    ["auto"] = TIME_FORMAT_AUTO,
    ["12h"] = TIME_FORMAT_12,
    ["24h"] = TIME_FORMAT_24,
}
local REVERSE_TIME_FORMAT_MAPPING = {}
for label, format in pairs(TIME_FORMAT_MAPPING) do
    REVERSE_TIME_FORMAT_MAPPING[format] = label
end

local TAG_PREFIX_OFF = 1
local TAG_PREFIX_LONG = 2
local TAG_PREFIX_SHORT = 3

local TIMESTAMP_INDEX = 1
local MAX_HISTORY_LENGTH = 10000
local TRIMMED_HISTORY_LENGTH = 9000

local strlower = string.lower
local tconcat = table.concat
local osdate = os.date
local GetTimeStamp = GetTimeStamp
local CHAT_ROUTER = CHAT_ROUTER

lib.defaultSettings = {
    version = 1,
    timePrefixEnabled = false,
    timePrefixOnRegularChat = true,
    timePrefixFormat = TIME_FORMAT_AUTO,
    tagPrefixMode = TAG_PREFIX_LONG,
    historyEnabled = false,
    historyMaxAge = 3600,
}
lib.chatHistory = {}
lib.chatHistoryActive = true

lib.registeredChatLinks = {}

-- internal functions

local function GetFormattedTime(timeStamp)
    return osdate(lib.settings.timePrefixFormat, timeStamp)
end

local function GetTimeStampForEvent()
    if(lib.nextEventTimeStamp) then
        return lib.nextEventTimeStamp, true
    end
    return GetTimeStamp(), false
end

local MAX_SAVE_DATA_LENGTH = 1999 -- buffer length used by ZOS
local function WriteToSavedVariable(value)
    local output = value
    if type(value) == "string" then
        local byteLength = #value
        if(byteLength > MAX_SAVE_DATA_LENGTH) then
            output = {}
            local startPos = 1
            local endPos = startPos + MAX_SAVE_DATA_LENGTH - 1
            while startPos <= byteLength do
                output[#output + 1] = value:sub(startPos, endPos)
                startPos = endPos + 1
                endPos = startPos + MAX_SAVE_DATA_LENGTH - 1
            end
        end
    end
    return output
end

local function ReadFromSavedVariable(value)
    if(type(value) == "table") then
        return table.concat(value, "")
    end
    return value
end

local function StoreChatEvent(timeStamp, type, ...)
    if(not lib.chatHistoryActive) then return end
    local entry = { timeStamp, type }
    for i = 1, select("#", ...) do
        entry[2 + i] = WriteToSavedVariable(select(i, ...))
    end

    local chatHistory = lib.chatHistory
    chatHistory[#chatHistory + 1] = entry
    if(#chatHistory > MAX_HISTORY_LENGTH) then
        local newHistory = {}
        for i = #chatHistory - TRIMMED_HISTORY_LENGTH, #chatHistory do
            newHistory[#newHistory + 1] = chatHistory[i]
        end
        chatHistory = newHistory
    end
end

local function ApplyTimeAndTagPrefix(formattedEventText, targetChannel, fromDisplayName, rawMessageText, timeStamp)
    if(formattedEventText) then
        if(lib.settings and lib.settings.tagPrefixMode ~= TAG_PREFIX_OFF) then
            formattedEventText = MESSAGE_TEMPLATE:format(SYSTEM_TAG, formattedEventText)
        end
        if(lib.settings and lib.settings.timePrefixEnabled) then
            formattedEventText = MESSAGE_TEMPLATE:format(GetFormattedTime(timeStamp), formattedEventText)
        end
    end
    return formattedEventText, targetChannel, fromDisplayName, rawMessageText
end

-- chat system hooks
local messageFormatters = CHAT_ROUTER:GetRegisteredMessageFormatters()
local newFormatter = {}
do
    local redirect = {}
    setmetatable(newFormatter, redirect)
    redirect.__index = function(_, key)
        -- Called, if newFormatter has no entry: use original.
        return messageFormatters[key]
    end
    local orgOnChatEvent = CHAT_ROUTER.FormatAndAddChatMessage
    ZO_PreHook(CHAT_ROUTER, "FormatAndAddChatMessage", function(self)
        if IsChatSystemAvailableForCurrentPlatform() then
            -- Replace Formatters for ZOS
            self.registeredMessageFormatters = newFormatter
        end
    end)
    SecurePostHook(CHAT_ROUTER, "FormatAndAddChatMessage", function(self)
        -- Restore Formatters for addons
        self.registeredMessageFormatters = messageFormatters
    end)
end

local function dummyPreHook(...) return ... end
local function PostHookFormatter(eventType, postHook, preHook)
    preHook = preHook or dummyPreHook
    newFormatter[eventType] = function(...)
        local timeStamp, isRestoring = GetTimeStampForEvent()
        if(not isRestoring) then
            StoreChatEvent(timeStamp, eventType, ...)
        end
        local originalFormatter = messageFormatters[eventType]
        local formattedEventText, targetChannel, fromDisplayName, rawMessageText = originalFormatter(preHook(...))
        return postHook(formattedEventText, targetChannel, fromDisplayName, rawMessageText, timeStamp)
    end
end

----------------------------------------------

local UNKNOWN_LINK_TYPE = "unknown"
lib.UNKNOWN_LINK_TYPE = UNKNOWN_LINK_TYPE
local LINK_GMATCH_PATTERN = "||H(%d):(.-):(.-)||h(.-)||h"
local function unknownTypeReformatter(linkStyle, linkType, data, displayText)
    return ZO_LinkHandler_CreateLinkWithoutBrackets(displayText, nil, UNKNOWN_LINK_TYPE, linkType)
end
local function decodeCustomLinks(linkStyle, linkType, data, displayText)
    local reformatter = lib.registeredChatLinks[linkType] or unknownTypeReformatter
    linkStyle = tonumber(linkStyle)
    return reformatter(linkStyle, linkType, data, displayText)
end
-- The chat event escapes unknown links. Here it gets unescaped.
local function customLinkFormatter(messageType, fromName, text, ...)
    text = text:gsub(LINK_GMATCH_PATTERN, decodeCustomLinks)
    return messageType, fromName, text, ...
end

local function defaultReformatter(linkStyle, linkType, data, displayText)
    return ZO_LinkHandler_CreateLinkWithFormat(displayText, nil, linkType, linkStyle, data)
end

function lib:RegisterCustomChatLink(linkType, optionalReformatter)
    assert(not optionalReformatter or type(optionalReformatter) == "function", "Reformatter has to be a function")
    self.registeredChatLinks[linkType] = optionalReformatter or defaultReformatter
	ZO_VALID_LINK_TYPES_CHAT[linkType] = true
end

----------------------------------------------

-- CHAT_ROUTER:FormatAndAddChatMessage(EVENT_CHAT_MESSAGE_CHANNEL, CHAT_CHANNEL_SAY, "test", "test", false, "test")
PostHookFormatter(EVENT_CHAT_MESSAGE_CHANNEL, function(formattedEventText, targetChannel, fromDisplayName, rawMessageText, timeStamp)
    if(formattedEventText and lib.settings and lib.settings.timePrefixEnabled and lib.settings.timePrefixOnRegularChat) then
        formattedEventText = MESSAGE_TEMPLATE:format(GetFormattedTime(timeStamp), formattedEventText)
    end
    return formattedEventText, targetChannel, fromDisplayName, rawMessageText
end, customLinkFormatter)

-- CHAT_ROUTER:FormatAndAddChatMessage(EVENT_BROADCAST, "test")
PostHookFormatter(EVENT_BROADCAST, function(formattedEventText, targetChannel, fromDisplayName, rawMessageText, timeStamp)
    if(formattedEventText and lib.settings and lib.settings.timePrefixEnabled) then
        if(lib.settings.tagPrefixMode == TAG_PREFIX_OFF) then
            formattedEventText = formattedEventText:gsub("%[.-%] ", "")
        end
        formattedEventText = MESSAGE_TEMPLATE:format(GetFormattedTime(timeStamp), formattedEventText)
    end
    return formattedEventText, targetChannel, fromDisplayName, rawMessageText
end)

-- CHAT_ROUTER:FormatAndAddChatMessage(EVENT_FRIEND_PLAYER_STATUS_CHANGED, "test", "test", PLAYER_STATUS_OFFLINE, PLAYER_STATUS_ONLINE)
PostHookFormatter(EVENT_FRIEND_PLAYER_STATUS_CHANGED, ApplyTimeAndTagPrefix)

-- CHAT_ROUTER:FormatAndAddChatMessage(EVENT_IGNORE_ADDED, "test")
PostHookFormatter(EVENT_IGNORE_ADDED, ApplyTimeAndTagPrefix)

-- CHAT_ROUTER:FormatAndAddChatMessage(EVENT_IGNORE_REMOVED, "test")
PostHookFormatter(EVENT_IGNORE_REMOVED, ApplyTimeAndTagPrefix)

-- CHAT_ROUTER:FormatAndAddChatMessage(EVENT_GROUP_TYPE_CHANGED, false)
PostHookFormatter(EVENT_GROUP_TYPE_CHANGED, ApplyTimeAndTagPrefix)

-- CHAT_ROUTER:FormatAndAddChatMessage(EVENT_GROUP_INVITE_RESPONSE, "test", GROUP_INVITE_RESPONSE_PLAYER_NOT_FOUND, "test")
PostHookFormatter(EVENT_GROUP_INVITE_RESPONSE, ApplyTimeAndTagPrefix)

-- CHAT_ROUTER:FormatAndAddChatMessage(EVENT_SOCIAL_ERROR, SOCIAL_RESULT_ACCOUNT_NOT_FOUND)
PostHookFormatter(EVENT_SOCIAL_ERROR, ApplyTimeAndTagPrefix)

-- CHAT_ROUTER:FormatAndAddChatMessage(EVENT_TRIAL_FEATURE_RESTRICTED, TRIAL_RESTRICTION_CANNOT_WHISPER)
PostHookFormatter(EVENT_TRIAL_FEATURE_RESTRICTED, ApplyTimeAndTagPrefix)

-- CHAT_ROUTER:FormatAndAddChatMessage(EVENT_GROUP_MEMBER_LEFT, "test", GROUP_LEAVE_REASON_KICKED, true, false, "test", true)
PostHookFormatter(EVENT_GROUP_MEMBER_LEFT, ApplyTimeAndTagPrefix)

-- CHAT_ROUTER:FormatAndAddChatMessage(EVENT_BATTLEGROUND_INACTIVITY_WARNING)
PostHookFormatter(EVENT_BATTLEGROUND_INACTIVITY_WARNING, ApplyTimeAndTagPrefix)

local _, SimpleEventToCategoryMappings = ZO_ChatSystem_GetEventCategoryMappings()
SimpleEventToCategoryMappings[LIB_IDENTIFIER] = CHAT_CATEGORY_SYSTEM
CHAT_ROUTER:RegisterMessageFormatter(LIB_IDENTIFIER, function(tag, rawMessageText)
    local timeStamp, isRestoring = GetTimeStampForEvent()
    if(not isRestoring) then
        StoreChatEvent(timeStamp, LIB_IDENTIFIER, tag, rawMessageText)
    end

    local formattedEventText = rawMessageText
    if(lib.settings and lib.settings.tagPrefixMode ~= TAG_PREFIX_OFF) then
        formattedEventText = MESSAGE_TEMPLATE:format(tag, formattedEventText)
    end
    if(lib.settings and lib.settings.timePrefixEnabled) then
        formattedEventText = MESSAGE_TEMPLATE:format(GetFormattedTime(timeStamp), formattedEventText)
    end
    return formattedEventText, nil, tag, rawMessageText
end)

-- chat proxy
local ChatProxy = ZO_Object:Subclass()

function ChatProxy:New(longTag, shortTag)
    local obj = ZO_Object.New(self)
    obj.longTag = longTag
    obj.shortTag = shortTag
    obj.enabled = true
    return obj
end

-- public API

--- Method to a change the color of the tag for the next printed message.
--- @param color - A ZO_ColorDef or hex color string ("RRGGBB")
--- @return self, so you can chain the call like this: chat:SetTagColor:Print(message)
function ChatProxy:SetTagColor(color)
    if(self.enabled) then
        if(type(color) == "table") then
            color = color:ToHex()
        end
        self.tagColor = color
    end
    return self
end

--- Internal method to retrieve the colored tag. Resets the tag color when called.
--- @return string, the colored tag
function ChatProxy:GetTag()
    local tag = (lib.settings and lib.settings.tagPrefixMode == TAG_PREFIX_SHORT) and self.shortTag or self.longTag
    tag = TAG_FORMAT:format(tag)
    if(self.tagColor) then
        tag = COLOR_FORMAT:format(self.tagColor, tag)
        self.tagColor = nil
    end
    return tag
end

--- Method to a print regular messages to chat. The message will automatically be prefixed with the time and tag based on user preferences.
--- @param message - The message to print.
function ChatProxy:Print(message)
    if(not self.enabled) then return end
    local tag = self:GetTag()
    CHAT_ROUTER:FormatAndAddChatMessage(LIB_IDENTIFIER, tag, message)
end

--- Method to a print formatted messages to chat. The message will automatically be prefixed with the time and tag based on user preferences.
--- @param formatString - The formatting string passed to string.format
--- @param ... - values passed to string.format
function ChatProxy:Printf(formatString, ...)
    if(not self.enabled) then return end
    local tag = self:GetTag()
    CHAT_ROUTER:FormatAndAddChatMessage(LIB_IDENTIFIER, tag, formatString:format(...))
end

--- setter to turn this proxy  off, so it no longer print anything to chat when one of its methods is called.
--- @param enabled - boolean which turns the output on or off
function ChatProxy:SetEnabled(enabled)
    self.enabled = enabled
end


--- @param longTag - a string identifier that is used to identify messages printed via this object. e.g. MyCoolAddon
--- @param shortTag - a string identifier that is used to identify messages printed via this object. e.g. MCA
--- @return a new print proxy instance with the passed tags
function lib.Create(...)
    return ChatProxy:New(...)
end
setmetatable(lib, { __call = function(_, ...) return lib.Create(...) end })

-- public library functions

--- Clears all chat windows
function lib:ClearChat()
    local activeWindows = CHAT_SYSTEM.windowPool:GetActiveObjects()
    for _, window in pairs(activeWindows) do
        window.buffer:Clear()
    end
end

--- Clears the stored chat history for the current session
function lib:ClearHistory()
    self.chatHistory = {}
    if(self.saveDataKey) then
        LibChatMessageHistory[self.saveDataKey] = self.chatHistory
    end
end

--- @return the stored chat history for the current session
function lib:GetHistory()
    return self.chatHistory
end

--- @param enabled - controls the time prefix for chat messages
function lib:SetTimePrefixEnabled(enabled)
    if(self.settings) then
        self.settings.timePrefixEnabled = enabled
    end
end

--- @return true, if the time prefix is enabled
function lib:IsTimePrefixEnabled()
    if(self.settings) then
        return self.settings.timePrefixEnabled
    end
    return self.defaultSettings.timePrefixEnabled
end

--- @param enabled - controls the time prefix for regular chat messages sent by players
function lib:SetRegularChatMessageTimePrefixEnabled(enabled)
    if(self.settings) then
        self.settings.timePrefixOnRegularChat = enabled
    end
end

--- @return true, if the time prefix is enabled for regular chat messages sent by players
function lib:IsRegularChatMessageTimePrefixEnabled()
    if(self.settings) then
        return self.settings.timePrefixOnRegularChat
    end
    return self.defaultSettings.timePrefixOnRegularChat
end

lib.TIME_FORMATS = TIME_FORMATS

--- @param format - sets the format used for the time prefix. see os.date and TIME_FORMAT constants for details.
function lib:SetTimePrefixFormat(format)
    if(self.settings) then
        self.settings.timePrefixFormat = format
    end
end

--- @return the format used for the time prefix. see os.date and TIME_FORMAT constants for details.
function lib:GetTimePrefixFormat()
    if(self.settings) then
        return self.settings.timePrefixFormat
    end
    return self.defaultSettings.timePrefixFormat
end

lib.TAG_PREFIX_OFF = TAG_PREFIX_OFF
lib.TAG_PREFIX_LONG = TAG_PREFIX_LONG
lib.TAG_PREFIX_SHORT = TAG_PREFIX_SHORT

--- @param mode - controls how add-ons should print the tag prefix for their messages.
--- Turning it off will still save the long tag in case the history is enabled
function lib:SetTagPrefixMode(mode)
    if(self.settings) then
        self.settings.tagPrefixMode = mode
    end
end

--- @return The mode how add-ons should print the tag prefix for their messages.
function lib:GetTagPrefixMode()
    if(self.settings) then
        return self.settings.tagPrefixMode
    end
    return self.defaultSettings.tagPrefixMode
end

--- @param enabled - controls if add-ons should print a long or short tag prefix for their messages.
--- @deprecated - use SetTagPrefixMode instead
function lib:SetShortTagPrefixEnabled(enabled)
    self:SetTagPrefixMode(enabled and TAG_PREFIX_SHORT or TAG_PREFIX_LONG)
end

--- @return true, if add-ons should print a short tag prefix for their messages.
--- @deprecated - use GetTagPrefixMode instead
function lib:IsShortTagPrefixEnabled()
    return self:GetTagPrefixMode() == TAG_PREFIX_SHORT
end

--- @param enabled - controls if the chat history should be enabled on the next UI load.
function lib:SetChatHistoryEnabled(enabled)
    if(self.settings) then
        self.settings.historyEnabled = enabled
    end
end

--- @return true, if the chat history will be enabled on the next UI load.
function lib:IsChatHistoryEnabled()
    if(self.settings) then
        return self.settings.historyEnabled
    end
    return self.defaultSettings.historyEnabled
end

--- @return true, if the chat history is currently running.
function lib:IsChatHistoryActive()
    return self.chatHistoryActive
end

--- @param maxAge - number of seconds a chat message can be stored before it is no longer restored on UI load.
function lib:SetChatHistoryMaxAge(maxAge)
    if(self.settings) then
        self.settings.historyMaxAge = maxAge
    end
end

--- @return number of seconds a chat message can be stored before it is no longer restored on UI load.
function lib:GetChatHistoryMaxAge()
    if(self.settings) then
        return self.settings.historyMaxAge
    end
    return self.defaultSettings.historyMaxAge
end

EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_ADD_ON_LOADED, function(event, name)
    if(name ~= LIB_IDENTIFIER) then return end

    lib.saveDataKey = GetWorldName() .. GetDisplayName()

    local chat = lib.Create("LibChatMessage", "LCM")
    SLASH_COMMANDS["/chatmessage"] = function(params)
        local handled = false
        local command, arg = zo_strsplit(" ", params)
        command = strlower(command)
        arg = strlower(arg)

        if(command == "time") then
            if(arg == "on") then
                lib:SetTimePrefixEnabled(true)
                chat:Print("Enabled time prefix")
            elseif(arg == "off") then
                lib:SetTimePrefixEnabled(false)
                chat:Print("Disabled time prefix")
            else
                local enabled = lib:IsTimePrefixEnabled()
                chat:Printf("Time prefix is currently %s", enabled and "enabled" or "disabled")
            end
            handled = true
        elseif(command == "chat") then
            if(arg == "on") then
                lib:SetRegularChatMessageTimePrefixEnabled(true)
                chat:Print("Enabled player chat message time prefix")
            elseif(arg == "off") then
                lib:SetRegularChatMessageTimePrefixEnabled(false)
                chat:Print("Disabled player chat message time prefix")
            else
                local enabled = lib:IsRegularChatMessageTimePrefixEnabled()
                chat:Printf("Player chat message time prefix is currently %s", enabled and "enabled" or "disabled")
            end
            handled = true
        elseif(command == "format") then
            local format = TIME_FORMAT_MAPPING[arg]
            if(format) then
                lib:SetTimePrefixFormat(format)
                chat:Printf("Set time prefix to %s format", arg)
            else
                format = lib:GetTimePrefixFormat()
                if(REVERSE_TIME_FORMAT_MAPPING[format]) then
                    format = REVERSE_TIME_FORMAT_MAPPING[format]
                end
                chat:Printf("Time prefix format is currently set to %s", format)
            end
            handled = true
        elseif(command == "tag") then
            if(arg == "short") then
                lib:SetTagPrefixMode(TAG_PREFIX_SHORT)
                chat:Print("Set tag prefix to short format")
            elseif(arg == "long") then
                lib:SetTagPrefixMode(TAG_PREFIX_LONG)
                chat:Print("Set tag prefix to long format")
            elseif(arg == "off") then
                lib:SetTagPrefixMode(TAG_PREFIX_OFF)
                chat:Print("Disabled showing a tag prefix")
            else
                local mode = lib:GetTagPrefixMode()
                if(mode == TAG_PREFIX_OFF) then
                    chat:Print("Tag prefix is currently disabled")
                else
                    local enabled = (mode == TAG_PREFIX_SHORT)
                    chat:Printf("Tag prefix is currently set to %s format", enabled and "short" or "long")
                end
            end
            handled = true
        elseif(command == "history") then
            if(arg == "on") then
                lib:SetChatHistoryEnabled(true)
                chat:Print("Set chat history enabled on the next UI load")
            elseif(arg == "off") then
                lib:SetChatHistoryEnabled(false)
                chat:Print("Set chat history disabled on the next UI load")
            else
                local active = lib:IsChatHistoryActive()
                local enabled = lib:IsChatHistoryEnabled()
                chat:Printf("Chat history is currently %s and will be %s on the next UI load", active and "active" or "inactive", enabled and "enabled" or "disabled")
            end
            handled = true
        elseif(command == "age") then
            local maxAge = tonumber(arg)
            if(maxAge and maxAge > 0) then
                lib:SetChatHistoryMaxAge(maxAge)
                chat:Printf("Set maximum history age to %d seconds", maxAge)
            else
                maxAge = lib:GetChatHistoryMaxAge()
                chat:Printf("Maximum history age currently set to %d seconds", maxAge)
            end
            handled = true
        end

        if(not handled) then
            local out = {}
            out[#out + 1] = "/chatmessage <command> [argument]"
            out[#out + 1] = "<time>|u129%:0:  :|u[on/off]|u286%:0:       :|uEnables or disables the time prefix"
            out[#out + 1] = "<chat>|u125%:0:  :|u[on/off]|u288%:0:       :|uShow time prefix on regular chat"
            out[#out + 1] = "<format>|u62%:0: :|u[auto/12h/24h]|u68%:0:  :|uChanges the time format used"
            out[#out + 1] = "<tag>|u165%:0:   :|u[off/short/long]|u50%:0::|uControls how a message is tagged"
            out[#out + 1] = "<history>|u50%:0::|u[on/off]|u286%:0:       :|uRestore old chat after login"
            out[#out + 1] = "<age>|u147%:0:   :|u[seconds]|u200%:0:      :|uThe maximum age of restored chat"
            out[#out + 1] = "Example: /chatmessage tag short"
            chat:Print(tconcat(out, "\n"))
        end
    end

    LibChatMessageSettings = LibChatMessageSettings or {}
    LibChatMessageHistory = LibChatMessageHistory or {}

    lib.settings = LibChatMessageSettings[lib.saveDataKey] or ZO_ShallowTableCopy(lib.defaultSettings)
    LibChatMessageSettings[lib.saveDataKey] = lib.settings

    for key, value in pairs(lib.defaultSettings) do
        if(lib.settings[key] == nil) then
            lib.settings[key] = value
        end
    end

    for key in pairs(lib.settings) do
        if(lib.defaultSettings[key] == nil) then
            lib.settings[key] = nil
        end
    end

    lib.chatHistoryActive = lib.settings.historyEnabled

    local function RestoreChatHistoryEntry(entry, timeStamp)
        lib.nextEventTimeStamp = entry[TIMESTAMP_INDEX]
        local args = {}
        for i = TIMESTAMP_INDEX + 1, #entry do
            args[#args + 1] = ReadFromSavedVariable(entry[i])
        end
        CHAT_ROUTER:FormatAndAddChatMessage(unpack(args))
    end

    local function RestoreChatHistory()
        if(not lib.chatHistoryActive) then return end
        lib:ClearChat()

        local newHistory = {}
        local oldHistory = LibChatMessageHistory[lib.saveDataKey]
        local tempHistory = lib.chatHistory

        if(oldHistory) then
            local ageThreshold = GetTimeStamp() - lib.settings.historyMaxAge
            for i = 1, #oldHistory do
                if(oldHistory[i][TIMESTAMP_INDEX] > ageThreshold) then
                    newHistory[#newHistory + 1] = RestoreChatHistoryEntry(oldHistory[i])
                end
            end
        end

        if(lib.nextEventTimeStamp ~= nil) then
            -- small hack to avoid storing the message in the history
            lib.nextEventTimeStamp = GetTimeStamp()
            chat:Print("End of restored chat history")
        end

        for i = 1, #tempHistory do
            newHistory[#newHistory + 1] = RestoreChatHistoryEntry(tempHistory[i])
        end

        lib.nextEventTimeStamp = nil
        lib.chatHistory = newHistory
        LibChatMessageHistory[lib.saveDataKey] = newHistory
    end

    EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_PLAYER_ACTIVATED, function()
        EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_PLAYER_ACTIVATED)
        -- make sure we restore it after other addons had a chance to set up their formatters
        zo_callLater(RestoreChatHistory, 0)
    end)

    if(not lib.chatHistoryActive) then
        lib:ClearHistory()
    end

    local function OnLinkClicked(link, button, text, color, linkType, ...)
        if linkType ~= UNKNOWN_LINK_TYPE then
            return
        end
        if button == MOUSE_BUTTON_INDEX_LEFT then
            local unknownType = ...
            ZO_Alert(EVENT_UI_ERROR, SOUNDS.NEGATIVE_CLICK, zo_strformat(LIB_CHATMESSAGE_UNKNOWN_DESCRIPTION, unknownType))
            return true
        end
    end
	LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_CLICKED_EVENT, OnLinkClicked)
	LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_MOUSE_UP_EVENT, OnLinkClicked)
    if KEYBOARD_CHAT_SYSTEM then
    	KEYBOARD_CHAT_SYSTEM:GetEditControl():SetAllowMarkupType(ALLOW_MARKUP_TYPE_ALL)
    end
    if GAMEPAD_CHAT_SYSTEM then
    	GAMEPAD_CHAT_SYSTEM:GetEditControl():SetAllowMarkupType(ALLOW_MARKUP_TYPE_ALL)
    end
end)
