local addon = iChat

local task = addon.task

local orgAddMessage = SharedChatSystem.AddMessage
local buffer = { }
function SharedChatSystem:AddMessage(text)
	buffer[#buffer + 1] = text
end
local function callback(self)
	addon.events:UnregisterCallback("HistoryRestored", callback)
	SharedChatSystem.AddMessage = orgAddMessage
	task:For(1, #buffer):Do( function(i) self:AddMessage(buffer[i]) end)
	:Then( function() buffer = nil end)
end
addon.events:RegisterCallback("HistoryRestored", callback)
