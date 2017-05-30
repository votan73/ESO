local addon = SET_MANAGER
local em = GetEventManager()

local S_REQUIRED = 1
local S_DESCRIPTION = 2

function addon:cmdSetManager(text, ...)
	-- d("execute /setm")
	if (text == "dump") then
		self:dumpItems(5, true)
	elseif (text == "reset") then
		-- d("check")
		addon:DoCompleteProcess(...)
	elseif (text == "boni") then
		-- d("boni")
		addon:dumpBoni(...)
	elseif (text == "scan") then
		-- d("scan")
		addon:ScanSets(...)
	else
		d("use check/dump/scan")
	end
end

function addon:dumpItems(minNum, unbound)
	if (addon.sets ~= nil) then
		for set, info in pairs(addon.sets) do
			self:dumpSetInfo(set, info)
		end
	else
		d("No sets stored")
	end
end

function addon:ClearItems()
	if (addon.sets ~= nil) then
		for set, information in pairs(addon.sets) do
			information.items = { }
		end
	end
end

function addon:ClearBoni()
	addon.sets = { }
end

function addon:dumpSetInfo(name, info)
	d(name .. " with " .. #info.items .. " items" ..(info.crafted and "(crafted)" or ""))
	for i = 1, #info.boni do
		d(info.boni[i][S_REQUIRED] .. ":" .. info.boni[i][S_DESCRIPTION])
	end
end

function addon:getSortedKeys(dictionary, order)
	local keys = { }
	for k in pairs(dictionary) do
		keys[#keys + 1] = k
	end
	table.sort(keys, function(a, b) return order(dictionary, a, b) end)

	return keys
end

local function SortBoni(dict, a, b)
	local left = dict[a]
	local right = dict[b]
	return left[S_REQUIRED] < right[S_REQUIRED] and 1 or(left[S_DESCRIPTION] < right[S_DESCRIPTION])
end

function addon:dumpBoni()
	local keys = addon:getSortedKeys(addon.boni, SortBoni)
	for i = 1, #keys do
		local boni = addon.boni[keys[i]]
		d(boni[S_REQUIRED] .. ":" .. boni[S_DESCRIPTION])
	end
end

function addon:registerSetInfo(link, setName, numberOfBonuses, numEquipped, maxWearable)
	if (addon.sets == nil) then addon.sets = { } end
	if (addon.sets[setName] == nil) then addon.sets[setName] = { } end
	local set = addon.sets[setName]
	set.numberOfBonuses = numberOfBonuses
	set.boni = { }
	-- remove if necessary
	if (addon.boni == nil) then addon.boni = { } end
	for i = 1, numberOfBonuses do
		local numrequired, description = GetItemLinkSetBonusInfo(link, false, i)
		table.insert(set.boni, { numrequired, description })
		table.insert(addon.boni, { numrequired, description })
	end
	set.numEquipped = numEquipped
	set.maxWearable = maxWearable
	set.crafted = IsItemLinkCrafted(link)
	-- d("Register set " .. setName .. " for item " .. GetItemLinkName(link))
	if set.items == nil then set.items = { } end
	table.insert(set.items, link)
end

function addon:DoCompleteProcess()
	addon.ClearItems()
	addon.ClearBoni()
	addon:ProcessList(addon.account.sets)
	addon:ProcessList(addon.player.sets)
	addon:ProcessList(addon.player.crafting)
end

function addon:ProcessList(list)
	if (list ~= nil) then
		for i = 1, #list do
			-- boolean hasSet, string setName, integer numberOfBonuses, integer numEquipped, integer maxWearable
			local hasSet, setName, numberOfBonuses, numEquipped, maxWearable = GetItemLinkSetInfo(list[i])
			if (hasSet) then
				addon:registerSetInfo(list[i], setName, numberOfBonuses, numEquipped, maxWearable)
			else
				-- d(GetItemLinkName(list[i]) .. " is no set")
			end
		end
	end
end

function addon:ScanSets(maxItemId)
	maxItemId = maxItemId or 150000
	local isArmorList =
	{
		[EQUIP_TYPE_HEAD] = true,
		[EQUIP_TYPE_CHEST] = true,
		[EQUIP_TYPE_SHOULDERS] = true,
		[EQUIP_TYPE_WAIST] = true,
		[EQUIP_TYPE_LEGS] = true,
		[EQUIP_TYPE_FEET] = true,
		[EQUIP_TYPE_HAND] = true,
	}
	local isWeaponList = {
		[EQUIP_TYPE_MAIN_HAND] = true,
		[EQUIP_TYPE_ONE_HAND] = true,
		[EQUIP_TYPE_TWO_HAND] = true,
	}
	local isJevelryList = {
		[EQUIP_TYPE_NECK] = true,
		[EQUIP_TYPE_RING] = true,
	}

	local debugstart = GetGameTimeMilliseconds()
	local format, createLink = zo_strformat, string.format
	local GetItemLinkSetInfo, GetItemLinkTraitInfo, GetItemLinkSetBonusInfo = GetItemLinkSetInfo, GetItemLinkTraitInfo, GetItemLinkSetBonusInfo
	local list = { }

	local identifier = "SET_MANAGER_SCANSETS"
	local itemId = 29500
	local GetFrameTimeMilliseconds, GetFramerate, GetGameTimeMilliseconds = GetFrameTimeMilliseconds, GetFramerate, GetGameTimeMilliseconds
	local GetItemLinkEquipType = GetItemLinkEquipType
	local blacklist = {
		[ITEM_TRAIT_TYPE_NONE] = true,
		[ITEM_TRAIT_TYPE_ARMOR_INTRICATE] = true,
		[ITEM_TRAIT_TYPE_WEAPON_INTRICATE] = true,
		[ITEM_TRAIT_TYPE_ARMOR_ORNATE] = true,
		[ITEM_TRAIT_TYPE_JEWELRY_ORNATE] = true,
		[ITEM_TRAIT_TYPE_WEAPON_ORNATE] = true,
		[ITEM_TRAIT_TYPE_SPECIAL_STAT] = true,
	}
	local function Scan()
		local start = GetFrameTimeMilliseconds()
		local spendTime = 500 / GetFramerate()
		while (GetGameTimeMilliseconds() - start) < spendTime do
			if itemId <= maxItemId then
				local itemLink = createLink("|H1:item:%i:370:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", itemId)
				local hasSet, setName, numBonuses, _, maxWearable = GetItemLinkSetInfo(itemLink, false)
				if hasSet then
					local traitType = GetItemLinkTraitInfo(itemLink)
					if not blacklist[traitType] then
						local setInfo = list[setName]
						if setInfo == nil then
							setInfo = { items = { }, equipType = { }, maxWearable = maxWearable, bonus = { } }

							local equipType = GetItemLinkEquipType(itemLink)
							setInfo.equipType[equipType] = true
							for i = 1, numBonuses do
								local _, bonusDescription = GetItemLinkSetBonusInfo(itemLink, false, i)
								setInfo.bonus[i] = bonusDescription
							end

							list[setName] = setInfo
						end

						setInfo.items[#setInfo.items + 1] = itemId
					end
				end
				itemId = itemId + 1
			else
				local sets = { }
				for name, setInfo in pairs(list) do
					local items = setInfo.items
					local firstItem = items[1]
					local isArmor, isWeapon, isJevelry = false, false, false
					for equipType, available in pairs(setInfo.equipType) do
						isArmor = isArmor or isArmorList[equipType] == true
						isWeapon = isWeapon or isWeaponList[equipType] == true
						isJevelry = isJevelry or isJevelryList[equipType] == true
					end
					local isMonster = setInfo.maxWearable <= 2 and isArmor
					sets[firstItem] = { items = items, isCraftable = #items >= 315 and not isMonster, isMonster = isMonster, isJevelry = isJevelry and not isArmor, bonus = setInfo.bonus }
				end
				em:UnregisterForUpdate(identifier)
				d(zo_strformat("done: <<1>>ms: <<2>> sets", GetGameTimeMilliseconds() - debugstart, NonContiguousCount(sets)))
				addon.account.all = sets
				return
			end
		end
	end
	d("start set scan")
	em:RegisterForUpdate(identifier, 20, Scan)
end