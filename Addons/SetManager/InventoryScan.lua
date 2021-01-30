local addon = SET_MANAGER
local em = GetEventManager()

function addon:InitInventoryScan()
	local function ScanInventory(bagId, list, addTo)
		list = list or {}
		if not addTo then
			ZO_ClearNumericallyIndexedTable(list)
		end

		local IsEquipable, GetItemLink, GetItemLinkSetInfo, ZO_GetNextBagSlotIndex = IsEquipable, GetItemLink, GetItemLinkSetInfo, ZO_GetNextBagSlotIndex

		local slotIndex = ZO_GetNextBagSlotIndex(bagId, nil)
		while slotIndex do
			if IsEquipable(bagId, slotIndex) then
				local itemLink = GetItemLink(bagId, slotIndex)
				local hasSet = GetItemLinkSetInfo(itemLink, false)
				if hasSet then
					list[#list + 1] = itemLink
				end
			end
			slotIndex = ZO_GetNextBagSlotIndex(bagId, slotIndex)
		end

		return list
	end
	local function ScanBags()
		addon.account.sets = ScanInventory(BAG_BANK, addon.account.sets)
		addon.account.sets = ScanInventory(BAG_SUBSCRIBER_BANK, addon.account.sets, true)
		addon.player.worn = ScanInventory(BAG_WORN, addon.player.worn)
		addon.player.sets = ScanInventory(BAG_BACKPACK, addon.player.sets)
	end
	local function ScanCrafting(list)
		list = list or {}
		ZO_ClearNumericallyIndexedTable(list)

		return list
	end

	local function PlayerDeactivated()
		ScanBags()
		addon.player.crafting = ScanCrafting(addon.player.crafting)
	end
	SETMANAGER_CHARACTER_FRAGMENT:RegisterCallback(
		"StateChange",
		function(oldState, newState)
			if newState == SCENE_FRAGMENT_SHOWING then
				ScanBags()
			end
		end
	)

	em:RegisterForEvent(addon.name, EVENT_PLAYER_DEACTIVATED, PlayerDeactivated)
end

local nameToSet, styleNameToId, qualityNameToId, itemNameToTypeInfo
local function InitLookups(self)
	self.Selector:CreateSetNameToData()

	nameToSet = {}
	for _, set in pairs(self.Selector.setNameToData) do
		nameToSet[zo_strformat("<<C:1>>", set.name)] = set
	end

	styleNameToId = {}
	for itemStyleId = 1, GetHighestItemStyleId() do
		styleNameToId[zo_strformat("<<C:1>>", GetItemStyleName(itemStyleId))] = itemStyleId
	end
	self.styleNameToId = styleNameToId

	local traitNameToId = {}
	for traitId = 1, ITEM_TRAIT_TYPE_MAX_VALUE do
		traitNameToId[GetString("SI_ITEMTRAITTYPE", traitId)] = traitId
	end
	self.traitNameToId = traitNameToId

	qualityNameToId = {}
	for quality = ITEM_QUALITY_MIN_VALUE, ITEM_QUALITY_MAX_VALUE do
		qualityNameToId[GetString("SI_ITEMDISPLAYQUALITY", quality)] = quality
	end
	self.qualityNameToId = qualityNameToId

	itemNameToTypeInfo = {}
	local subId = self:CreateSubItemId(50, 150, 1)
	for itemId = 43529, 43561 do
		local itemLink = string.format("|H1:item:%i:%i:%i:0:0:0:0:0:0:0:0:0:0:0:0:%i:1:0:0:10000:0|h|h", itemId, subId, 50, 1)
		local name = ZO_CachedStrFormat("<<C:1>>", GetItemLinkName(itemLink))
		itemNameToTypeInfo[name] = {GetItemLinkEquipType(itemLink), GetItemLinkWeaponType(itemLink), GetItemLinkArmorType(itemLink)}
	end
	itemNameToTypeInfo["Platinkette"] = itemNameToTypeInfo["Platinhalskette"]
	self.itemNameToTypeInfo = itemNameToTypeInfo
end

local language = GetCVar("language.2") or "en"

local GetInfo
if language == "de" then
	function GetInfo(text)
		local set, style, trait, quality = select(3, zo_strsplit("\r\n", text))
		return set, style, trait, quality
	end
elseif language == "fr" then
	function GetInfo(text)
		local quality, trait, set, style = select(3, zo_strsplit("\r\n", text:gsub("; ", "\r\n")))
		return set, style, trait, quality
	end
elseif language == "ru" then
	function GetInfo(text)
		local set, style, trait, quality = select(2, zo_strsplit("\n", text))
		df("%s %s %s %s!", set, style, trait, quality)
		return set, style, trait, quality
	end
else
	function GetInfo(text)
		local quality, trait, set, style = select(3, zo_strsplit("\r\n", text:gsub("; ", "\r\n")))
		return set, style, trait, quality
	end
end

function addon:GetWritInfo(writItemLink)
	if not writItemLink or #writItemLink == 0 then
		return
	end

	if not nameToSet then
		InitLookups(self)
	end

	local text = GenerateMasterWritBaseText(writItemLink)

	local set, style, trait, quality = GetInfo(text)
	if not trait then
		return
	end
	if quality then
		set = set:match(":%s*(.+)")
		style = style:match(":%s*(.+)")
		trait = trait:match(":%s*(.+)")
		quality = quality:match(":%s*(.+)")

		set = nameToSet[set]
		style = styleNameToId[style] or -1
		quality = qualityNameToId[quality] or -1
	else
		set = set:match(":%s*(.+)")
		quality = trait:match(":%s*(.+)")
		trait = style:match(":%s*(.+)")

		set = nameToSet[set]
		style = 0
		quality = qualityNameToId[quality] or 0
	end
	if not set then
		return
	end

	local equipType, weaponType, armorType = nil, nil, nil
	for name, typeInfo in pairs(itemNameToTypeInfo) do
		if zo_plainstrfind(text, name) then
			equipType, weaponType, armorType = unpack(typeInfo)
			break
		end
	end
	if not equipType then
		return
	end

	local level = 50
	local subId = self:CreateSubItemId(level, 150, quality)
	for i = 1, #set.items do
		local itemId = set.items[i]
		local itemLink = string.format("|H1:item:%i:%i:%i:0:0:0:0:0:0:0:0:0:0:0:0:%i:1:0:0:10000:0|h|h", itemId, subId, level, style)
		if GetItemLinkEquipType(itemLink) == equipType and GetItemLinkWeaponType(itemLink) == weaponType and GetItemLinkArmorType(itemLink) == armorType and GetString("SI_ITEMTRAITTYPE", GetItemLinkTraitInfo(itemLink)) == trait then
			return itemLink, equipType, weaponType, armorType
		end
	end
end
