local addon = iChat

local orgAddCommandHistory
local history
addon.events:RegisterCallback("OnPreInit", function() addon.accountDefaults.commands = { } end)
addon.events:RegisterCallback("OnLoad", function() history = addon.account.commands end)

local maxHistory = 10
local function AddHistory(entry)
	local count = #history
	if count >= maxHistory then
		for i = 2, maxHistory do history[i - 1] = history[i] end
		history[maxHistory] = entry
		for i = count, maxHistory + 1, -1 do history[i] = nil end
	else
		history[count + 1] = entry
	end
end

local function HookAddCommandHistory(chat)
	orgAddCommandHistory = chat.textEntry.AddCommandHistory
	for _, entry in ipairs(history) do chat.textEntry:AddCommandHistory(entry[1]) end
	function chat.textEntry.AddCommandHistory(...)
		local self, text = ...
		AddHistory( { text, chat.currentChannel or 0, chat.currentTarget or 0 })
		return orgAddCommandHistory(...)
	end
end
local function callback(chat)
	addon.events:UnregisterCallback("ChatSystemReady", callback)
	return HookAddCommandHistory(chat)
end

addon.events:RegisterCallback("ChatSystemReady", callback)
