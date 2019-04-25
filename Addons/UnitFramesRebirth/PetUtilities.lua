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

-- keybind functions
local FAMILIAR = 1
local TWILIGHT = 2
local GUARDIAN = 3

local FAMILIAR_ABILITIES = {
	23304, -- Summon Unstable Familiar I
	30631, -- Summon Unstable Familiar II
	30636, -- Summon Unstable Familiar III
	30641, -- Summon Unstable Familiar IV
	23319, -- Summon Unstable Clannfear I
	30647, -- Summon Unstable Clannfear II
	30652, -- Summon Unstable Clannfear III
	30657, -- Summon Unstable Clannfear IV
	23316, -- Summon Volatile Familiar I
	30664, -- Summon Volatile Familiar II
	30669, -- Summon Volatile Familiar III
	30674, -- Summon Volatile Familiar IV
}

local TWILIGHT_ABILITIES = {
	24613, -- Summon Winged Twilight I
	30581, -- Summon Winged Twilight II
	30584, -- Summon Winged Twilight III
	30587, -- Summon Winged Twilight IV
	24636, -- Summon Twilight Tormentor I
	30592, -- Summon Twilight Tormentor II
	30595, -- Summon Twilight Tormentor III
	30598, -- Summon Twilight Tormentor IV
	24639, -- Summon Twilight Matriarch I
	30618, -- Summon Twilight Matriarch II
	30622, -- Summon Twilight Matriarch III
	30626, -- Summon Twilight Matriarch IV
}

local GUARDIAN_ABILITIES = {
	85982, -- Feral Guardian I
	85983, -- Feral Guardian II
	85984, -- Feral Guardian III
	85985, -- Feral Guardian IV
	85986, -- Eternal Guardian I
	85987, -- Eternal Guardian II
	85988, -- Eternal Guardian III
	85989, -- Eternal Guardian IV
	85990, -- Wild Guardian I
	85991, -- Wild Guardian II
	85992, -- Wild Guardian III
	85993, -- Wild Guardian IV
}

local function GetPetAbilityIds(lookup)
	if lookup then
		if lookup == FAMILIAR then
			return FAMILIAR_ABILITIES
		elseif lookup == TWILIGHT then
			return TWILIGHT_ABILITIES
		elseif lookup == GUARDIAN then
			return GUARDIAN_ABILITIES
		end
	end
	return nil
end

function DismissPlayerPet(lookup)
	local petAbilities = GetPetAbilityIds(lookup)
	if petAbilities then
		local buffSlot, abilityId, _
		local numBuffs = GetNumBuffs("player")
		for i = 1, numBuffs do
			buffSlot, _, _, _, _, _, _, abilityId = select(4, GetUnitBuffInfo("player", i))
			for _, value in pairs(petAbilities) do
				if value == abilityId then
					return CancelBuff(buffSlot)
				end
			end
		end
	end
end

function DismissAllPlayerPets()
	DismissPlayerPet(FAMILIAR)
	DismissPlayerPet(TWILIGHT)
	DismissPlayerPet(GUARDIAN)
end