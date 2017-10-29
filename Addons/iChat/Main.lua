local addon = ZO_Object:Subclass()
addon.name = "iChat"
addon.defaults = { }
addon.accountDefaults = { }
addon.events = ZO_CallbackObject:New()

local em = GetEventManager()

do
	local identifier = "iCHAT_ASYNC_TASK"
	local async = LibStub("LibAsync")
	addon.task = async:Create(identifier)
end

function addon:Initialize()
	self.events:FireCallbacks("PreInit")

	self.account = ZO_SavedVars:NewAccountWide("iChatSavedVar", 1, nil, self.accountDefaults)
	self.player = ZO_SavedVars:NewCharacterIdSettings("iChatSavedVar", 1, nil, self.defaults)
	iChatHistory = iChatHistory or { }

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
	local LibHarvensAddonSettings = LibStub("LibHarvensAddonSettings-1.0")
	if not LibHarvensAddonSettings then return end

	local settings = LibHarvensAddonSettings:AddAddon("iChat")
	if not settings then return end
	addon.settingsControls = settings
	settings.version = "1.0.0"
	settings.allowDefaults = true
	-- settings.website = "http://www.esoui.com/downloads/"
end

-------------------------------------------------------------------------------

local function GetLocalTimeStamp()
	local utc = GetTimeStamp()
	local localTimeShift = GetSecondsSinceMidnight() -(utc % 86400)
	if localTimeShift < -12 * 60 * 60 then localTimeShift = localTimeShift + 86400 end
	return utc + localTimeShift
end

function addon:FormatTime(localTimeStamp, text)
	if not text then return end
	localTimeStamp = localTimeStamp or GetLocalTimeStamp()
	return string.format("|cCCCCCC[%s]|r %s", ZO_FormatTime(localTimeStamp % 86400, TIME_FORMAT_STYLE_CLOCK_TIME, TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR), text)
end

function addon:PostFormatting(formattedEventText, targetChannel, fromDisplayName, rawMessageText)
	return formattedEventText, targetChannel, fromDisplayName, rawMessageText
end

do
	local newFormatter = ZO_ChatSystem_GetEventHandlers()
	local orgFormatter = ZO_ShallowTableCopy(newFormatter)
	local function AddTime(localTimeStamp, formattedEventText, ...)
		formattedEventText = addon:FormatTime(localTimeStamp, formattedEventText, ...)
		return formattedEventText, ...
	end

	newFormatter[EVENT_CHAT_MESSAGE_CHANNEL] = function(messageType, fromName, text, isFromCustomerService, fromDisplayName, localTimeStamp)
		return AddTime(localTimeStamp, addon:PostFormatting(orgFormatter[EVENT_CHAT_MESSAGE_CHANNEL](messageType, fromName, text, isFromCustomerService, fromDisplayName)))
	end

	newFormatter[EVENT_BROADCAST] = function(message, localTimeStamp)
		return AddTime(localTimeStamp, addon:PostFormatting(orgFormatter[EVENT_BROADCAST](message)))
	end

	newFormatter[EVENT_FRIEND_PLAYER_STATUS_CHANGED] = function(displayName, characterName, oldStatus, newStatus, localTimeStamp)
		return AddTime(localTimeStamp, addon:PostFormatting(orgFormatter[EVENT_FRIEND_PLAYER_STATUS_CHANGED](displayName, characterName, oldStatus, newStatus)))
	end

	newFormatter[EVENT_IGNORE_ADDED] = function(displayName, localTimeStamp)
		return AddTime(localTimeStamp, addon:PostFormatting(orgFormatter[EVENT_IGNORE_ADDED](displayName)))
	end

	newFormatter[EVENT_IGNORE_REMOVED] = function(displayName, localTimeStamp)
		return AddTime(localTimeStamp, addon:PostFormatting(orgFormatter[EVENT_IGNORE_REMOVED](displayName)))
	end

	newFormatter[EVENT_GROUP_TYPE_CHANGED] = function(largeGroup, localTimeStamp)
		return AddTime(localTimeStamp, addon:PostFormatting(orgFormatter[EVENT_GROUP_TYPE_CHANGED](largeGroup)))
	end

	newFormatter[EVENT_GROUP_INVITE_RESPONSE] = function(characterName, response, displayName, localTimeStamp)
		return AddTime(localTimeStamp, addon:PostFormatting(orgFormatter[EVENT_GROUP_INVITE_RESPONSE](characterName, response, displayName, localTimeStamp)))
	end

	newFormatter[EVENT_SOCIAL_ERROR] = function(error, localTimeStamp)
		return AddTime(localTimeStamp, addon:PostFormatting(orgFormatter[EVENT_SOCIAL_ERROR](error)))
	end

	newFormatter[EVENT_TRIAL_FEATURE_RESTRICTED] = function(restrictionType, localTimeStamp)
		return AddTime(localTimeStamp, addon:PostFormatting(orgFormatter[VENT_TRIAL_FEATURE_RESTRICTED](restrictionType)))
	end

	newFormatter[EVENT_GROUP_MEMBER_LEFT] = function(characterName, reason, isLocalPlayer, isLeader, displayName, actionRequiredVote, localTimeStamp)
		return AddTime(localTimeStamp, addon:PostFormatting(orgFormatter[EVENT_GROUP_MEMBER_LEFT](characterName, reason, isLocalPlayer, isLeader, displayName, actionRequiredVote)))
	end

	newFormatter[EVENT_BATTLEGROUND_INACTIVITY_WARNING] = function(localTimeStamp)
		return AddTime(localTimeStamp, addon:PostFormatting(orgFormatter[EVENT_BATTLEGROUND_INACTIVITY_WARNING]()))
	end
end

do
	local orgOnChatEvent = SharedChatSystem.OnChatEvent
	function SharedChatSystem.OnChatEvent(chat, ...)
		local entry = { ...}
		entry[#entry + 1] = GetLocalTimeStamp()
		addon.task:Call( function() addon.events:FireCallbacks("OnChatEvent", chat, entry) end):Then( function() orgOnChatEvent(chat, unpack(entry)) end)
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

		local container, tabIndex = ...
		function ClearMenu(...)
			ClearMenu = orgClearMenu
			ClearMenu(...)
			if not ZO_Dialogs_IsShowingDialog() then
				addon.events:FireCallbacks("ContextMenuInsertBefore", container, tabIndex)
			end
		end
		function ShowMenu(...)
			ShowMenu = orgShowMenu
			if not ZO_Dialogs_IsShowingDialog() then
				addon.events:FireCallbacks("ContextMenuAppendAfter", container, tabIndex)
			end
			return ShowMenu(...)
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
