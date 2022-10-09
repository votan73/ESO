local addon = VOTANS_FISHERMAN

local VotansFishermanStats = VotansFishermanStats
VotansFishermanStats:SetParent(PopupTooltipTopLevel)

local rs, gs, bs = ZO_SELECTED_TEXT:UnpackRGB()
local rn, gn, bn = ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB()
-- local rd, gd, bd = ZO_DISABLED_TEXT:UnpackRGB()

local statValuePairPool = ZO_ControlPool:New("ZO_TooltipStatValuePair", SetItemTooltip, "VotansFishermanStatValuePair")
statValuePairPool:SetCustomFactoryBehavior( function(self)
	self.statLabel = self:GetNamedChild("Stat")
	self.valueLabel = self:GetNamedChild("Value")
	self.statLabel:SetFont("ZoFontWinT2")
	self.valueLabel:SetFont("ZoFontGame")
	-- self.statLabel:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)

	self.statLabel:SetColor(rn, gn, bn)
	self.valueLabel:SetColor(rs, gs, bs)
	self:SetDimensions(300, 20)
	self.statLabel:ClearAnchors()
	self.valueLabel:ClearAnchors()
	self.statLabel:SetAnchor(BOTTOMLEFT, nil, BOTTOMLEFT)
	self.valueLabel:SetAnchor(BOTTOMRIGHT, nil, BOTTOMRIGHT)
end )

do
	local orgClearLines = VotansFishermanStats.ClearLines
	function VotansFishermanStats:ClearLines()
		statValuePairPool:ReleaseAllObjects()
		return orgClearLines(self)
	end
end

local function AddLine(tooltip, text, color, alignment)
	local r, g, b = color:UnpackRGB()
	tooltip:AddLine(text, "", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, alignment, alignment ~= TEXT_ALIGN_LEFT)
end

local function AddLineCenter(tooltip, text, color)
	if not color then color = ZO_TOOLTIP_DEFAULT_COLOR end
	AddLine(tooltip, text, color, TEXT_ALIGN_CENTER)
end

local function AddLineTitle(tooltip, text, color)
	if not color then color = ZO_SELECTED_TEXT end
	local r, g, b = color:UnpackRGB()
	tooltip:AddLine(text, "ZoFontHeader3", r, g, b, CENTER, MODIFY_TEXT_TYPE_UPPERCASE, TEXT_ALIGN_CENTER, true)
end

local function AddStat(tooltip, text, value)
	value = tostring(value)
	local statValuePair = statValuePairPool:AcquireObject()
	statValuePair:ClearAnchors()
	statValuePair.statLabel:SetWidth(0)
	statValuePair.statLabel:SetText(text)
	statValuePair.statLabel:SetDimensions(statValuePair.statLabel:GetTextDimensions(text))
	statValuePair.valueLabel:SetWidth(0)
	statValuePair.valueLabel:SetText(value)
	statValuePair.valueLabel:SetDimensions(statValuePair.valueLabel:GetTextDimensions(value))
	statValuePair:SetParent(tooltip)
	tooltip:AddControl(statValuePair)
	statValuePair:SetAnchor(CENTER)
	tooltip:AddVerticalPadding(-14)
	return statValuePair
end

function VotansFishermanStats:Initialize(id)
	self:ClearLines()
	if not self:IsHidden() and self.lastId == id then
		self:SetHidden(true)
		return false
	end
	self.lastId = id

	self:SetHeaderRowSpacing(0)
	self:SetHeaderVerticalOffset(10)

	ZO_ItemIconTooltip_OnAddGameData(self, TOOLTIP_GAME_DATA_ITEM_ICON, "VotansFisherman/fishing_node.dds")
	return true
end

local function AddTitle(self, title)
	self:AddVerticalPadding(16)
	AddLineTitle(self, title)
	self:AddVerticalPadding(-12)
	ZO_Tooltip_AddDivider(self)
end

function VotansFishermanStats:AddZone(zoneId)
	AddTitle(self, ZO_CachedStrFormat(SI_WINDOW_TITLE_WORLD_MAP, GetZoneNameByIndex(GetZoneIndex(zoneId))))

	local zoneToLure = addon:GetZoneToLure()[zoneId]

	local watertypeCount = { 0, 0, 0, 0, 0 }
	local totalCount = 0

	if zoneToLure then
		for _, lure in pairs(zoneToLure) do
			if next(lure.lureType) then
				for watertype in pairs(lure.lureType) do
					watertypeCount[watertype] = watertypeCount[watertype] + 1
					totalCount = totalCount + 1
				end
			else
				watertypeCount[5] = watertypeCount[5] + 1
				totalCount = totalCount + 1
			end
		end
	end

	AddStat(self, GetString(SI_FISHERMAN_INTERACT2), watertypeCount[2])
	AddStat(self, GetString(SI_FISHERMAN_INTERACT4), watertypeCount[4])
	AddStat(self, GetString(SI_FISHERMAN_INTERACT3), watertypeCount[3])
	AddStat(self, GetString(SI_FISHERMAN_INTERACT1), watertypeCount[1])
	AddStat(self, GetString(SI_FISHERMAN_STATS_UNKNOWN), watertypeCount[5])
	ZO_Tooltip_AddDivider(self)
	self:AddVerticalPadding(-12)
	AddStat(self, GetString(SI_FISHERMAN_STATS_TOTAL), totalCount)

	totalCount = 0
	local zoneStats = addon.settings.zoneStats
	local info = zoneStats[zoneId]
	if info then
		self:AddVerticalPadding(12)
		local itemsTotal = { }
		for charId, items in pairs(info.stats) do
			for itemId, count in pairs(items) do
				local total = itemsTotal[itemId] or 0
				total = total + count
				itemsTotal[itemId] = total
				totalCount = totalCount + count
			end
		end
		local forSort = { }
		local list = { }
		local GetItemLinkName = GetItemLinkName
		for itemId, count in pairs(itemsTotal) do
			local itemLink
			if addon.lootTypes[itemId] then
				itemLink = addon:CreateDefaultCaughtLink(itemId)
			else
				itemLink = addon:CreateRareCaughtLink(itemId)
			end
			list[itemLink] = count
			forSort[#forSort + 1] = { itemLink = itemLink, name = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(itemLink)) }
		end
		table.sort(forSort, function(a, b) return a.name < b.name end)
		for _, entry in ipairs(forSort) do
			AddStat(self, entry.itemLink, list[entry.itemLink])
		end
		ZO_Tooltip_AddDivider(self)
		self:AddVerticalPadding(-12)
		AddStat(self, GetString(SI_FISHERMAN_STATS_TOTAL), totalCount)
	end

	return self
end

function VotansFishermanStats:AddCharacter(charId)
	AddTitle(self, ZO_CachedStrFormat(SI_WINDOW_TITLE_WORLD_MAP, GetString(SI_MAIN_MENU_CHARACTER)))

	local totalCount = 0
	local zoneStats = addon.settings.zoneStats
	local chars = { }
	local forSort = { }
	local GetCharacterInfo = GetCharacterInfo
	for i = 1, GetNumCharacters() do
		local name, _, _, _, _, _, characterId = GetCharacterInfo(i)
		chars[characterId] = 0
		forSort[#forSort + 1] = { name = name, characterId = characterId }
	end

	for zoneId, info in pairs(zoneStats) do
		local itemsTotal = { }
		for charId, items in pairs(info.stats) do
			local total = chars[charId]
			if total then
				for itemId, count in pairs(items) do
					total = total + count
					totalCount = totalCount + count
				end
				chars[charId] = total
			end
		end
	end
	table.sort(forSort, function(a, b) return a.name < b.name end)
	for _, entry in ipairs(forSort) do
		AddStat(self, ZO_CachedStrFormat(SI_UNIT_NAME, entry.name), chars[entry.characterId])
	end
	ZO_Tooltip_AddDivider(self)
	self:AddVerticalPadding(-12)
	AddStat(self, GetString(SI_FISHERMAN_STATS_TOTAL), totalCount)

	return self
end

SLASH_COMMANDS["/vf"] = function(kindOfStats)
	kindOfStats = kindOfStats ~= "" and kindOfStats or "zone"

	if kindOfStats == "zone" then
		local zoneIndex = ZO_WorldMap_IsWorldMapShowing() and GetCurrentMapZoneIndex() or GetUnitZoneIndex("player")
		local zoneId = GetZoneId(zoneIndex)
		if VotansFishermanStats:Initialize(zoneId) then
			VotansFishermanStats:AddZone(zoneId):SetHidden(false)
		end
	elseif kindOfStats == "char" then
		local charId = GetCurrentCharacterId()
		if VotansFishermanStats:Initialize(charId) then
			VotansFishermanStats:AddCharacter(charId):SetHidden(false)
		end
	end
end