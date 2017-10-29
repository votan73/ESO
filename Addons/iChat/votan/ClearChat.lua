local addon = iChat

local function ClearChat(container, tabIndex)
	PlaySound(SOUNDS.DEFAULT_CLICK)
	container.currentBuffer:Clear()
	container:SyncScrollToBuffer()
	--ToDo: Cleanup iChatHistory of those messages
end
addon.events:RegisterCallback("ContextMenuInsertBefore", function(container, tabIndex)
	AddCustomMenuItem("Clear Chat", function() ClearChat(container, tabIndex) end)
end )