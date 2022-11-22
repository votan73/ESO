local addon = iChat
local task = addon.task
local history

addon.events:RegisterCallback(
	"OnLoad",
	function()
		history = iChatHistory
	end
)

local maxHistory = 200
local function AddHistory(entry)
	local count = #history
	if count >= maxHistory then
		for i = 2, maxHistory do
			history[i - 1] = history[i]
		end
		history[maxHistory] = entry
		for i = count, maxHistory + 1, -1 do
			history[i] = nil
		end
	else
		history[count + 1] = entry
	end
end

local function AddChatToHistory(chat, entry)
	if entry[1] == EVENT_CHAT_MESSAGE_CHANNEL then
		AddHistory(entry)
	end
end

local function callback(chat)
	addon.events:UnregisterCallback("ChatSystemReady", callback)
	for _, container in pairs(chat.containers) do
		container.control:SetHidden(true)
	end

	task:For(1, #history):Do(
		function(i)
			if i <= #history then
				CHAT_ROUTER:FormatAndAddChatMessage(unpack(history[i]))
			end
		end
	):Then(
		function()
			for _, container in pairs(chat.containers) do
				container.control:SetHidden(false)
			end
			addon.events:RegisterCallback("OnChatEvent", AddChatToHistory)
			addon.events:FireCallbacks("HistoryRestored", chat)
		end
	)
end
addon.events:RegisterCallback("ChatSystemReady", callback)
