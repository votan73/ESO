local addon = SET_MANAGER
addon.ChatLinkHandler = { }
local handler = SET_MANAGER.ChatLinkHandler

local LINK_COL_PER_ITEM = 8

do
	local parts = { }
	function handler:CreateChatLink(setTemplate)
		ZO_ClearNumericallyIndexedTable(parts)

		parts[#parts + 1] = "|H1:settemplate"
		for slotId = EQUIP_SLOT_MIN_VALUE, EQUIP_SLOT_MAX_VALUE do
			local itemLink = setTemplate[slotId]
			if itemLink then
				local itemId, subId, level, enchantId, enchantSubId, enchantLevel, itemStyle = itemLink:match("^|H[^:]+:item:([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:([^:]+):[^:]+:[^:]+:[^:]+:[^:]+:[^|]+|h")
				parts[#parts + 1] = slotId
				parts[#parts + 1] = itemId
				parts[#parts + 1] = subId
				parts[#parts + 1] = level
				parts[#parts + 1] = enchantId
				parts[#parts + 1] = enchantSubId
				parts[#parts + 1] = enchantLevel
				parts[#parts + 1] = itemStyle
			end
		end
		if setTemplate.name then
			return string.format("%s%s%s%s", table.concat(parts, ":"), "|h[", setTemplate.name, "]|h")
		else
			return table.concat(parts, ":") .. "|h[No Name]|h"
		end
	end
end 

function handler.HandleClickEvent(rawLink, button, name, linkStyle, linkType, ...)
	if linkType == "settemplate" then
		if select("#", ...) % LINK_COL_PER_ITEM ~= 0 then
			return false
		end

		local setTemplate = { name = name }
		local createLink = string.format
		local index = 1
		while true do
			local slotId, itemId, subId, level, enchantId, enchantSubId, enchantLevel, itemStyle = select(index, ...)
			if not slotId then break end
			local itemLink = createLink("|H1:item:%s:%s:%s:%s:%s:%s:0:0:0:0:0:0:0:0:0:%s:0:0:0:10000:0|h|h", itemId, subId, level, enchantId, enchantSubId, enchantLevel, itemStyle)
			setTemplate[tonumber(slotId)] = itemLink
			index = index + LINK_COL_PER_ITEM
		end
		addon:SetPopupTooltipSetTemplate(setTemplate)

		-- Returning true means that the link type was handled
		-- and shouldn't use the default tooltip functionality.
		return true
	end
end

LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_MOUSE_UP_EVENT, handler.HandleClickEvent)
LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_CLICKED_EVENT, handler.HandleClickEvent)
