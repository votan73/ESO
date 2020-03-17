local addon = ZO_Object:Subclass()
addon.name = "iChat"
addon.defaults = {}
addon.accountDefaults = {}
addon.events = ZO_CallbackObject:New()

local em = GetEventManager()

do
	local identifier = "iCHAT_ASYNC_TASK"
	local async = LibAsync
	addon.task = async:Create(identifier)
end

function addon:Initialize()
	self.events:FireCallbacks("OnPreInit")

	self.account = ZO_SavedVars:NewAccountWide("iChatSavedVar", 1, nil, self.accountDefaults)
	self.player = ZO_SavedVars:NewCharacterIdSettings("iChatSavedVar", 1, nil, self.defaults)
	iChatHistory = iChatHistory or {}

	self.events:FireCallbacks("OnLoad")
	-- Give someone a chance to do something after all others did something.
	self.events:FireCallbacks("OnLoaded")
end

-- do
-- local function UpdateControls()
-- 	if addon.settingsControls.selected then
-- 		addon.settingsControls:UpdateControls()
-- 	end
-- end
-- function addon.ToggleShowHUD()
-- 	local self = addon
-- 	self.account.showHUD = not self.account.showHUD
-- 	self:UpdateVisibility()
-- 	UpdateControls()
-- end
-- function addon.ToggleShowCombat()
-- 	local self = addon
-- 	self.account.showCombat = not self.account.showCombat
-- 	self:UpdateVisibility()
-- 	UpdateControls()
-- end
-- end

function addon:InitSettings()
	local LibHarvensAddonSettings = LibHarvensAddonSettings or LibStub("LibHarvensAddonSettings-1.0", LibStub.SILENT)
	if not LibHarvensAddonSettings then
		return
	end

	local settings = LibHarvensAddonSettings:AddAddon("iChat")
	if not settings then
		return
	end
	addon.settingsControls = settings
	settings.version = "1.0.6"
	settings.allowDefaults = true
	-- settings.website = "http://www.esoui.com/downloads/"
end

-------------------------------------------------------------------------------

local function GetLocalTimeStamp()
	local utc = GetTimeStamp()
	local localTimeShift = GetSecondsSinceMidnight() - (utc % 86400)
	if localTimeShift < -12 * 60 * 60 then
		localTimeShift = localTimeShift + 86400
	end
	return utc + localTimeShift
end

local function FormatTime(eventArgs)
	local text = eventArgs.formattedEventText
	if not text then
		return
	end
	return string.format("|cCCCCCC[%s]|r %s", ZO_FormatTime(eventArgs.localTimeStamp % 86400, TIME_FORMAT_STYLE_CLOCK_TIME, TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR), text)
end

do
	local eventArgs = {}
	local function PreFormatting(orgFormatter, ...)
		eventArgs.cancel, eventArgs.isHandled = false, false
		addon.events:FireCallbacks("PreFormatting", eventArgs)
		if eventArgs.cancel then
			return
		end
		if eventArgs.isHandled then
			return eventArgs.formattedEventText, eventArgs.targetChannel, eventArgs.shownDisplayName, eventArgs.rawMessageText
		else
			return orgFormatter(...)
		end
	end
	function addon:PostFormatting(formattedEventText, targetChannel, shownDisplayName, rawMessageText)
		eventArgs.formattedEventText, eventArgs.targetChannel, eventArgs.shownDisplayName = formattedEventText, targetChannel, shownDisplayName
		eventArgs.rawMessageText = rawMessageText or eventArgs.rawMessageText

		addon.events:FireCallbacks("PostFormatting", eventArgs)

		eventArgs.formattedEventText = FormatTime(eventArgs)

		return eventArgs.formattedEventText, eventArgs.targetChannel, eventArgs.shownDisplayName, eventArgs.rawMessageText
	end

	local function NewEvent(event, localTimeStamp, messageType, fromCharacterName, fromDisplayName, rawMessageText)
		eventArgs.event, eventArgs.messageType = event, messageType

		eventArgs.formattedEventText, eventArgs.targetChannel, eventArgs.shownDisplayName = nil, nil, nil
		eventArgs.isFromCustomerService, eventArgs.oldStatus, eventArgs.newStatus = nil, nil, nil
		eventArgs.largeGroup, eventArgs.response, eventArgs.restrictionType = nil, nil, nil
		eventArgs.reason, eventArgs.isLocalPlayer, eventArgs.isLeader, eventArgs.actionRequiredVote = nil, nil, nil, nil

		eventArgs.localTimeStamp, eventArgs.rawMessageText = localTimeStamp or GetLocalTimeStamp(), rawMessageText
		eventArgs.messageType, eventArgs.fromCharacterName, eventArgs.fromDisplayName = messageType, fromCharacterName, fromDisplayName
	end

	-- The new formatters are in the original table
	local newFormatter = ZO_ChatSystem_GetEventHandlers()
	-- The original formatters are saved in a new table. Sounds odd, but is right.
	local orgFormatter = ZO_ShallowTableCopy(newFormatter)

	newFormatter[EVENT_CHAT_MESSAGE_CHANNEL] = function(messageType, fromName, text, isFromCustomerService, fromDisplayName, localTimeStamp)
		NewEvent(EVENT_CHAT_MESSAGE_CHANNEL, localTimeStamp, messageType, fromName, fromDisplayName, text)
		eventArgs.isFromCustomerService = isFromCustomerService
		return addon:PostFormatting(PreFormatting(orgFormatter[EVENT_CHAT_MESSAGE_CHANNEL], messageType, fromName, text, isFromCustomerService, fromDisplayName))
	end

	newFormatter[EVENT_BROADCAST] = function(message, localTimeStamp)
		NewEvent(EVENT_BROADCAST, localTimeStamp, CHAT_CHANNEL_SYSTEM, nil, nil, message)
		return addon:PostFormatting(PreFormatting(orgFormatter[EVENT_BROADCAST], message))
	end

	newFormatter[EVENT_FRIEND_PLAYER_STATUS_CHANGED] = function(displayName, characterName, oldStatus, newStatus, localTimeStamp)
		NewEvent(EVENT_FRIEND_PLAYER_STATUS_CHANGED, localTimeStamp, characterName, displayName)
		eventArgs.oldStatus, eventArgs.newStatus = oldStatus, newStatus
		return addon:PostFormatting(PreFormatting(orgFormatter[EVENT_FRIEND_PLAYER_STATUS_CHANGED], displayName, characterName, oldStatus, newStatus))
	end

	newFormatter[EVENT_IGNORE_ADDED] = function(displayName, localTimeStamp)
		NewEvent(EVENT_IGNORE_ADDED, localTimeStamp, CHAT_CHANNEL_SYSTEM, nil, displayName)
		return addon:PostFormatting(PreFormatting(orgFormatter[EVENT_IGNORE_ADDED], displayName))
	end

	newFormatter[EVENT_IGNORE_REMOVED] = function(displayName, localTimeStamp)
		NewEvent(EVENT_IGNORE_REMOVED, localTimeStamp, CHAT_CHANNEL_SYSTEM, nil, displayName)
		return addon:PostFormatting(PreFormatting(orgFormatter[EVENT_IGNORE_REMOVED], displayName))
	end

	newFormatter[EVENT_GROUP_TYPE_CHANGED] = function(largeGroup, localTimeStamp)
		NewEvent(EVENT_GROUP_TYPE_CHANGED, localTimeStamp, CHAT_CHANNEL_SYSTEM)
		eventArgs.largeGroup = largeGroup
		return addon:PostFormatting(PreFormatting(orgFormatter[EVENT_GROUP_TYPE_CHANGED], largeGroup))
	end

	newFormatter[EVENT_GROUP_INVITE_RESPONSE] = function(characterName, response, displayName, localTimeStamp)
		NewEvent(EVENT_GROUP_INVITE_RESPONSE, localTimeStamp, CHAT_CHANNEL_SYSTEM, characterName, displayName)
		eventArgs.response = response
		return addon:PostFormatting(PreFormatting(orgFormatter[EVENT_GROUP_INVITE_RESPONSE], characterName, response, displayName))
	end

	newFormatter[EVENT_SOCIAL_ERROR] = function(error, localTimeStamp)
		NewEvent(EVENT_SOCIAL_ERROR, localTimeStamp, CHAT_CHANNEL_SYSTEM, nil, nil, error)
		return addon:PostFormatting(PreFormatting(orgFormatter[EVENT_SOCIAL_ERROR], error))
	end

	newFormatter[EVENT_TRIAL_FEATURE_RESTRICTED] = function(restrictionType, localTimeStamp)
		NewEvent(EVENT_TRIAL_FEATURE_RESTRICTED, localTimeStamp, CHAT_CHANNEL_SYSTEM)
		eventArgs.restrictionType = restrictionType
		return addon:PostFormatting(PreFormatting(orgFormatter[VENT_TRIAL_FEATURE_RESTRICTED], restrictionType))
	end

	newFormatter[EVENT_GROUP_MEMBER_LEFT] = function(characterName, reason, isLocalPlayer, isLeader, displayName, actionRequiredVote, localTimeStamp)
		NewEvent(EVENT_GROUP_MEMBER_LEFT, localTimeStamp, CHAT_CHANNEL_SYSTEM, characterName, displayName)
		eventArgs.reason, eventArgs.isLocalPlayer, eventArgs.isLeader, eventArgs.actionRequiredVote = reason, isLocalPlayer, isLeader, actionRequiredVote
		return addon:PostFormatting(PreFormatting(orgFormatter[EVENT_GROUP_MEMBER_LEFT], characterName, reason, isLocalPlayer, isLeader, displayName, actionRequiredVote))
	end

	newFormatter[EVENT_BATTLEGROUND_INACTIVITY_WARNING] = function(localTimeStamp)
		NewEvent(EVENT_BATTLEGROUND_INACTIVITY_WARNING, localTimeStamp, CHAT_CHANNEL_SYSTEM)
		return addon:PostFormatting(PreFormatting(orgFormatter[EVENT_BATTLEGROUND_INACTIVITY_WARNING]))
	end
end

do
	local orgOnChatEvent = CHAT_ROUTER.FormatAndAddChatMessage
	function CHAT_ROUTER.FormatAndAddChatMessage(self, ...)
		local chat, entry = self, {...}
		entry[#entry + 1] = GetLocalTimeStamp()
		local function PrePostMessage()
			addon.events:FireCallbacks("OnChatEvent", chat, entry)
		end

		local function PostMessage()
			orgOnChatEvent(chat, unpack(entry))
		end
		addon.task:Call(PrePostMessage):Then(PostMessage)
	end
end

do
	local orgLoadChatFromSettings = SharedChatSystem.LoadChatFromSettings
	function SharedChatSystem.LoadChatFromSettings(...)
		SharedChatSystem.LoadChatFromSettings = orgLoadChatFromSettings
		orgLoadChatFromSettings(...)
		local self = ...
		addon.events:FireCallbacks("ChatSystemReady", self)
	end
end

do
	local orgShowContextMenu = SharedChatContainer.ShowContextMenu
	function SharedChatContainer.ShowContextMenu(...)
		local orgClearMenu = ClearMenu
		local orgShowMenu = ShowMenu

		if not ZO_Dialogs_IsShowingDialog() then
			local container, tabIndex = ...
			function ClearMenu(...)
				ClearMenu = orgClearMenu
				ClearMenu(...)
				addon.events:FireCallbacks("ContextMenuInsertBefore", container, tabIndex)
			end
			function ShowMenu(...)
				ShowMenu = orgShowMenu
				addon.events:FireCallbacks("ContextMenuAppendAfter", container, tabIndex)
				return ShowMenu(...)
			end
		end
		return orgShowContextMenu(...)
	end
end

do
	local orgShowContextMenu = SharedChatSystem.ShowPlayerContextMenu
	function SharedChatSystem.ShowPlayerContextMenu(...)
		local orgClearMenu = ClearMenu
		local orgShowMenu = ShowMenu

		if not ZO_Dialogs_IsShowingDialog() then
			local chat, playerName, rawName = ...
			function ClearMenu(...)
				ClearMenu = orgClearMenu
				ClearMenu(...)
				addon.events:FireCallbacks("PlayerContextMenuInsertBefore", chat, playerName, rawName)
			end
			function ShowMenu(...)
				ShowMenu = orgShowMenu
				addon.events:FireCallbacks("PlayerContextMenuAppendAfter", chat, playerName, rawName)
				return ShowMenu(...)
			end
		end
		return orgShowContextMenu(...)
	end
end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then return end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	addon:Initialize()
	addon:InitSettings()
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

iChat = addon
