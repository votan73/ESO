local addon = iChat

local task = addon.task

local orgAddMessage = SharedChatSystem.AddMessage
local buffer = { }

local orgGetGuiHidden = GetGuiHidden
function GetGuiHidden(...)
	if buffer then return true end
	return orgGetGuiHidden(...)
end

local function AddToBuffer(self, text)
	buffer[#buffer + 1] = text
	return orgAddMessage(self, text)
end

local redirect = AddToBuffer
function SharedChatSystem.AddMessage(...)
	return redirect(...)
end
local function callback(self)
	addon.events:UnregisterCallback("HistoryRestored", callback)
	redirect = orgAddMessage
	task:For(1, #buffer):Do( function(i) self:AddMessage(buffer[i]) end)
	:Then( function() buffer = nil end)
end
addon.events:RegisterCallback("HistoryRestored", callback)
