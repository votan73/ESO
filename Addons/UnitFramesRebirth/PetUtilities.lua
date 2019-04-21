MAX_PLAYER_PET = 7
PET_GROUP_SIZE_THRESHOLD = 2

local function GetPetNameLower(abilityId)
	return zo_strformat("<<z:1>>", GetAbilityName(abilityId))
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

function IsValidPetUnitTag(unitTag)
	if unitTag then
		local unitName = zo_strformat("<<z:1>>", GetUnitName(unitTag))
		return PET_NAMES[unitName]
	end
	return false
end


function IsPetActive()
	for i = 1, MAX_PLAYER_PET do
		local unitTag = GetPetUnitTagByIndex(i)
		if DoesUnitExist(unitTag) and IsValidPetUnitTag(unitTag) then
			return true
		end
	end
	return false
end

function GetPetGroupSize()
	local count = 0
	for i = 1, MAX_PLAYER_PET do
		local unitTag = GetPetUnitTagByIndex(i)
		if DoesUnitExist(unitTag) and IsValidPetUnitTag(unitTag) then
			count = count + 1
		end
	end
	return count
end

do
	local petUnitTags = setmetatable({}, {__index = function(self, key)
		local petIndex = tonumber(key:match("^playerpet(%d+)$"))
		if petIndex and petIndex >= 1 and petIndex <= MAX_PLAYER_PET then
			self[key] = petIndex
		else
			self[key] = false
		end

		return self[key]
	end, })

	function IsPetUnitTag(unitTag)
		return petUnitTags[unitTag] ~= false
	end

	function GetPetIndexFromUnitTag(unitTag)
		return petUnitTags[unitTag] or nil
	end

	local petIndices = {}

	for i = 1, MAX_PLAYER_PET do
		petIndices[i] = "playerpet" .. i
	end
	
	function GetPetUnitTagByIndex(petIndex)
		return petIndices[petIndex]
	end


end
