MAX_PLAYER_PET = 7
PET_GROUP_SIZE_THRESHOLD = 2

local function GetPetNameLower(abilityId)
	return ZO_CachedStrFormat("<<z:1>>", GetAbilityName(abilityId))
end

local PET_NAMES = {
	-- Familiar
	[GetPetNameLower(18602)] = true,

	-- Clannfear
	["clannfear"] = true, -- en
	["clannbann"] = true, -- de
	["faucheclan"] = true, -- fr

	-- Volatile Familiar
	[GetPetNameLower(30678)] = true, -- en/de
	["familier explosif"] = true, -- fr

	-- Winged Twilight
	[GetPetNameLower(30589)] = true,

	-- Twilight Tormentor
	[GetPetNameLower(30594)] = true, -- en
	["zwielichtpeinigerin"] = true, -- de
	["tourmenteur crépusculaire"] = true, -- fr

	-- Twilight Matriarch
	[GetPetNameLower(30629)] = true,

	-- Feral Guardian
	[GetPetNameLower(94376)] = true,

	-- Eternal Guardian
	[GetPetNameLower(94394)] = true,

	-- Wild Guardian
	[GetPetNameLower(94408)] = true,
}

function IsTrackedPet(unitTag)
	if unitTag then
		local unitName = ZO_CachedStrFormat("<<z:1>>", GetUnitName(unitTag))
		return PET_NAMES[unitName] == true
	end
	return false
end

local petIndices = { }

for i = 1, MAX_PLAYER_PET do
	petIndices[i] = "playerpet" .. i
end


function IsPetActive()
	for i = 1, MAX_PLAYER_PET do
		local unitTag = petIndices[i]
		if DoesUnitExist(unitTag) and IsTrackedPet(unitTag) then
			return true
		end
	end
	return false
end

function IsPetUnitDead(unitTag)
	if DoesUnitExist(unitTag) and IsPetUnitTag(unitTag) then
		return GetUnitPower(unitTag, POWERTYPE_HEALTH) <= 0
	end
	return true
end

function GetPetUnitTagByIndex(petIndex)
	local index = 0
	for i = 1, MAX_PLAYER_PET do
		if DoesUnitExist(petIndices[i]) then
			index = index + 1
		end
		if index == petIndex then
			return petIndices[i]
		end
	end
end

function GetPetGroupSize()
	local count = 0
	for i = 1, MAX_PLAYER_PET do
		local unitTag = petIndices[i]
		if DoesUnitExist(unitTag) and IsTrackedPet(unitTag) then
			count = count + 1
		end
	end
	return count
end

do
	local petUnitTags = setmetatable( { }, {
		__index = function(self, key)
			local petIndex = tonumber(key:match("^playerpet(%d+)$"))
			if petIndex and petIndex >= 1 and petIndex <= MAX_PLAYER_PET then
				self[key] = petIndex
			else
				self[key] = false
			end

			return self[key]
		end,
	} )

	function IsPetUnitTag(unitTag)
		return petUnitTags[unitTag] ~= false
	end

	local function activeUnitsUpTo(maxIndex)
		local index = 0
		for i = 1, maxIndex do
			if DoesUnitExist(petIndices[i]) then
				index = index + 1
			end
		end
		return index > 0 and index or 4294967296
	end

	function GetPetIndexFromUnitTag(unitTag)
		return DoesUnitExist(unitTag) and activeUnitsUpTo(petUnitTags[unitTag]) or 4294967296
	end
end
