local addon = {
	name = "VotansMotifsHunter"
}
local em = GetEventManager()

local GetItemID = GetItemLinkItemId

local charId = GetCurrentCharacterId()
do
	local lines = {}
	local text = {}
	local ZO_ERROR_COLOR = ZO_ERROR_COLOR
	local MAGIC_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, ITEM_QUALITY_MAGIC))
	local ZO_DEFAULT_DISABLED_COLOR = ZO_DEFAULT_DISABLED_COLOR

	function addon:GetMotifInfoText(itemLink)
		local itemId = GetItemID(itemLink)
		local knownBy = self.settings.motifs[itemId]
		local scannedChars = self.settings.scannedChars
		if knownBy then
			ZO_ClearNumericallyIndexedTable(lines)
			ZO_ClearNumericallyIndexedTable(text)
			for i = 1, GetNumCharacters() do
				local _, _, _, _, _, _, id = GetCharacterInfo(i)
				if knownBy[id] then
					lines[#lines + 1] = addon.charToName[id]
				end
			end
			if #lines > 0 then
				text[#text + 1] = MAGIC_COLOR:Colorize(table.concat(lines, ", "))
			end

			ZO_ClearNumericallyIndexedTable(lines)
			for i = 1, GetNumCharacters() do
				local _, _, _, _, _, _, id = GetCharacterInfo(i)
				if knownBy[id] == nil and scannedChars[id] then
					lines[#lines + 1] = addon.charToName[id]
				end
			end
			if #lines > 0 then
				text[#text + 1] = ZO_ERROR_COLOR:Colorize(table.concat(lines, ", "))
			end

			ZO_ClearNumericallyIndexedTable(lines)
			for i = 1, GetNumCharacters() do
				local _, _, _, _, _, _, id = GetCharacterInfo(i)
				if not scannedChars[id] then
					lines[#lines + 1] = addon.charToName[id]
				end
			end
			if #lines > 0 then
				text[#text + 1] = ZO_DEFAULT_DISABLED_COLOR:Colorize(table.concat(lines, ", "))
			end
			return table.concat(text, ", ")
		end
		local collectibleId = LibRunebox:GetRuneboxCollectibleId(itemId)
		if collectibleId then
			return (GetCollectibleUnlockStateById(collectibleId) ~= COLLECTIBLE_UNLOCK_STATE_LOCKED and MAGIC_COLOR or ZO_ERROR_COLOR):Colorize(ZO_CachedStrFormat("<<C:1>>", GetCollectibleName(collectibleId)))
		end
		return nil
	end
end

local function AddMotifInfo(tooltip, info)
	if info then
		tooltip:AddVerticalPadding(8)
		local r, g, b = ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB()
		tooltip:AddLine(info, "", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
	end
end

local mystyle = {fontSize = 34, fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1}
local function AddMotifInfo_Gamepad(tooltip, info)
	if info then
		tooltip:AddLine(info, mystyle, tooltip:GetStyle("bodySection"))
	end
end

local function TooltipHook(tooltipControl, method, linkFunc)
	local origMethod = tooltipControl[method]

	tooltipControl[method] = function(self, ...)
		origMethod(self, ...)
		AddMotifInfo(self, addon:GetMotifInfoText(linkFunc(...)))
	end
end

local function TooltipHook_Gamepad(tooltipControl, method, linkFunc)
	local origMethod = tooltipControl[method]

	tooltipControl[method] = function(self, ...)
		local result = origMethod(self, ...)
		AddMotifInfo_Gamepad(self, addon:GetMotifInfoText(linkFunc(...)))
		return result
	end
end

local function ReturnItemLink(itemLink)
	return itemLink
end

local function HookBagTips()
	TooltipHook(ItemTooltip, "SetBagItem", GetItemLink)
	TooltipHook(ItemTooltip, "SetTradeItem", GetTradeItemLink)
	TooltipHook(ItemTooltip, "SetBuybackItem", GetBuybackItemLink)
	TooltipHook(ItemTooltip, "SetStoreItem", GetStoreItemLink)
	TooltipHook(ItemTooltip, "SetAttachedMailItem", GetAttachedItemLink)
	TooltipHook(ItemTooltip, "SetLootItem", GetLootItemLink)
	TooltipHook(ItemTooltip, "SetTradingHouseItem", GetTradingHouseSearchResultItemLink)
	TooltipHook(ItemTooltip, "SetTradingHouseListing", GetTradingHouseListingItemLink)
	TooltipHook(ItemTooltip, "SetLink", ReturnItemLink)

	TooltipHook(PopupTooltip, "SetLink", ReturnItemLink)

	TooltipHook_Gamepad(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_LEFT_TOOLTIP), "LayoutItem", ReturnItemLink)
	TooltipHook_Gamepad(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_RIGHT_TOOLTIP), "LayoutItem", ReturnItemLink)
	TooltipHook_Gamepad(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_MOVABLE_TOOLTIP), "LayoutItem", ReturnItemLink)
end

local function ScanMotifs()
	local motifs = addon.settings.motifs
	local format, GetItemLinkItemType = string.format, GetItemLinkItemType
	local ITEMTYPE_RACIAL_STYLE_MOTIF, SPECIALIZED_ITEMTYPE_RACIAL_MOTIF_CHAPTER = ITEMTYPE_RACIAL_STYLE_MOTIF, SPECIALIZED_ITEMTYPE_RACIAL_MOTIF_CHAPTER
	local IsItemLinkBookKnown = IsItemLinkBookKnown

	local debugstart = GetGameTimeMilliseconds()
	local format, createLink = zo_strformat, string.format

	local identifier = "VOTANS_MOTIFSHUNTER_SCAN"
	local itemId = 16424
	local maxItemId = itemId
	local GetFrameTimeMilliseconds, GetGameTimeMilliseconds = GetFrameTimeMilliseconds, GetGameTimeMilliseconds

	local function Scan()
		local start = GetFrameTimeMilliseconds()
		local spendTime = 12
		while (GetGameTimeMilliseconds() - start) <= spendTime do
			if itemId <= maxItemId then
				local itemLink = createLink("|H1:item:%i:4:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", itemId)
				local itemType, specialized = GetItemLinkItemType(itemLink)
				if itemType == ITEMTYPE_RACIAL_STYLE_MOTIF then
					local list = motifs[itemId]
					if not list then
						list = {}
						motifs[itemId] = list
					end
					if IsItemLinkBookKnown(itemLink) then
						list[charId] = 1
					end
				end
				if itemType ~= ITEMTYPE_NONE then
					maxItemId = itemId + 10000
				end
				itemId = itemId + 1
			else
				em:UnregisterForUpdate(identifier)
				em:RegisterForEvent(addon.name, EVENT_STYLE_LEARNED, ScanMotifs)
				CENTER_SCREEN_ANNOUNCE:AddMessage(0, CSA_CATECORY_SMALL_TEXT, SOUNDS.QUEST_OBJECTIVE_INCREMENT, string.format("Votan's Motifs Hunter initial scan done: %i full style and chapter motif books", NonContiguousCount(motifs)))
				addon.debugTime = GetGameTimeMilliseconds() - debugstart
				addon.settings.scannedChars[charId] = 1
				VotansMotifsHunter_Data.lastScanVersion = GetAPIVersion()
				addon.maxItemId = maxItemId - 10000
				return
			end
		end
	end
	local function Update()
		local start = GetFrameTimeMilliseconds()
		local spendTime = 12
		while (GetGameTimeMilliseconds() - start) < spendTime do
			if motifs[itemId] then
				local itemLink = createLink("|H1:item:%i:4:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", itemId)
				if IsItemLinkBookKnown(itemLink) then
					motifs[itemId][charId] = 1
				end
				itemId = next(addon.settings.motifs, itemId)
			else
				addon.settings.scannedChars[charId] = true
				em:UnregisterForUpdate(identifier)
				em:RegisterForEvent(addon.name, EVENT_STYLE_LEARNED, ScanMotifs)
				return
			end
		end
	end
	em:UnregisterForUpdate(identifier)
	em:UnregisterForEvent(addon.name, EVENT_STYLE_LEARNED)
	if VotansMotifsHunter_Data.lastScanVersion ~= GetAPIVersion() then
		em:RegisterForUpdate(identifier, 50, Scan)
	else
		itemId = next(addon.settings.motifs)
		em:RegisterForUpdate(identifier, 50, Update)
	end
end

do
	local function OnAddOnLoaded(event, addonName)
		if addonName ~= addon.name then
			return
		end
		em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)
		addon.settings = {}
		local world = GetWorldName()
		VotansMotifsHunter_Data = VotansMotifsHunter_Data or {}
		local scannedChars = VotansMotifsHunter_Data[world] or {}
		VotansMotifsHunter_Data[world] = scannedChars
		addon.settings.scannedChars = scannedChars

		addon.settings.motifs = VotansMotifsHunter_Data["motifs"] or {}
		VotansMotifsHunter_Data["motifs"] = addon.settings.motifs

		local charToName = {}
		local zo_strformat, SI_UNIT_NAME = zo_strformat, GetString(SI_UNIT_NAME)
		for i = 1, GetNumCharacters() do
			local name, _, _, _, _, _, id = GetCharacterInfo(i)
			name = zo_strformat(SI_UNIT_NAME, name)
			charToName[id] = name
		end
		addon.charToName = charToName

		HookBagTips()
		ScanMotifs()
	end

	em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
end

VOTANS_MOTIFS_HUNTER = addon
