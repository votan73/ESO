local addon = iChat

local function FormattingWithNotification()
	-- Who ever hooked it till now, hook that.
	local orgPostFormatting = addon.PostFormatting
	function addon.PostFormatting(...)
		local targetChannel = select(3, ...)
		if targetChannel == CHAT_CHANNEL_WHISPER then
			PlaySound(SOUNDS.NEW_MAIL)
		end
		return orgPostFormatting(...)
	end
end

local function callback()
	addon.events:UnregisterCallback("HistoryRestored", callback)
	return FormattingWithNotification()
end
addon.events:RegisterCallback("HistoryRestored", callback)