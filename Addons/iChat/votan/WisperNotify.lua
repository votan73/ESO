local addon = iChat

local lastNotification = 0

local function FormattingWithNotification()
	-- Who ever hooked it till now, hook that.
	local orgPostFormatting = addon.PostFormatting
	function addon.PostFormatting(...)
		local targetChannel = select(3, ...)
		if targetChannel == CHAT_CHANNEL_WHISPER then
            local now = GetFrameTimeMilliseconds()
            if (now - lastNotification) > 2000 then
                lastNotification = now
			    PlaySound(SOUNDS.NEW_MAIL)
            end
		end
		return orgPostFormatting(...)
	end
end

local function callback()
	addon.events:UnregisterCallback("HistoryRestored", callback)
	return FormattingWithNotification()
end
addon.events:RegisterCallback("HistoryRestored", callback)