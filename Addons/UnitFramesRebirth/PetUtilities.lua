MAX_PLAYER_PET = 7
PET_GROUP_SIZE_THRESHOLD = 2

UNIT_FRAMES_REBIRTH_PET_FAMILIAR = 1
UNIT_FRAMES_REBIRTH_PET_TWILIGHT = 2
UNIT_FRAMES_REBIRTH_PET_GUARDIAN = 3

local PETINDEX_NONE = 4294967296

local function GetPetNameLower(abilityId)
	return ZO_CachedStrFormat("<<z:1>>", GetAbilityName(abilityId))
end

local PET_NAMES =
{
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
		local unitTag = petIndices[i]
		if DoesUnitExist(unitTag) and IsTrackedPet(unitTag) then
			index = index + 1
		end
		if index == petIndex then
			return unitTag
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

	local function ActiveUnitsUpTo(maxIndex)
		local index = 0
		for i = 1, maxIndex do
			local unitTag = petIndices[i]
			if DoesUnitExist(unitTag) and IsTrackedPet(unitTag) then
				index = index + 1
			end
		end
		return index > 0 and index or PETINDEX_NONE
	end

	function GetPetIndexFromUnitTag(unitTag)
		return DoesUnitExist(unitTag) and ActiveUnitsUpTo(petUnitTags[unitTag]) or PETINDEX_NONE
	end
end

-- keybind functions
local ABILITIES_SUMMONED_PETS =
{
	[UNIT_FRAMES_REBIRTH_PET_FAMILIAR] =
	{
		[23304] = true, -- Summon Unstable Familiar I
		[30631] = true, -- Summon Unstable Familiar II
		[30636] = true, -- Summon Unstable Familiar III
		[30641] = true, -- Summon Unstable Familiar IV
		[23319] = true, -- Summon Unstable Clannfear I
		[30647] = true, -- Summon Unstable Clannfear II
		[30652] = true, -- Summon Unstable Clannfear III
		[30657] = true, -- Summon Unstable Clannfear IV
		[23316] = true, -- Summon Volatile Familiar I
		[30664] = true, -- Summon Volatile Familiar II
		[30669] = true, -- Summon Volatile Familiar III
		[30674] = true, -- Summon Volatile Familiar IV
	},
	[UNIT_FRAMES_REBIRTH_PET_TWILIGHT] =
	{
		[24613] = true, -- Summon Winged Twilight I
		[30581] = true, -- Summon Winged Twilight II
		[30584] = true, -- Summon Winged Twilight III
		[30587] = true, -- Summon Winged Twilight IV
		[24636] = true, -- Summon Twilight Tormentor I
		[30592] = true, -- Summon Twilight Tormentor II
		[30595] = true, -- Summon Twilight Tormentor III
		[30598] = true, -- Summon Twilight Tormentor IV
		[24639] = true, -- Summon Twilight Matriarch I
		[30618] = true, -- Summon Twilight Matriarch II
		[30622] = true, -- Summon Twilight Matriarch III
		[30626] = true, -- Summon Twilight Matriarch IV
	},
	[UNIT_FRAMES_REBIRTH_PET_GUARDIAN] =
	{
		[85982] = true, -- Feral Guardian I
		[85983] = true, -- Feral Guardian II
		[85984] = true, -- Feral Guardian III
		[85985] = true, -- Feral Guardian IV
		[85986] = true, -- Eternal Guardian I
		[85987] = true, -- Eternal Guardian II
		[85988] = true, -- Eternal Guardian III
		[85989] = true, -- Eternal Guardian IV
		[85990] = true, -- Wild Guardian I
		[85991] = true, -- Wild Guardian II
		[85992] = true, -- Wild Guardian III
		[85993] = true, -- Wild Guardian IV
	},
}

local function GetPetAbilityIds(lookup)
	if lookup then
		if lookup == UNIT_FRAMES_REBIRTH_PET_FAMILIAR then
			return ABILITIES_SUMMONED_PETS.UNIT_FRAMES_REBIRTH_PET_FAMILIAR
		elseif lookup == UNIT_FRAMES_REBIRTH_PET_TWILIGHT then
			return ABILITIES_SUMMONED_PETS.UNIT_FRAMES_REBIRTH_PET_TWILIGHT
		elseif lookup == UNIT_FRAMES_REBIRTH_PET_GUARDIAN then
			return ABILITIES_SUMMONED_PETS.UNIT_FRAMES_REBIRTH_PET_GUARDIAN
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
			if petAbilities[abilityId] then
				return CancelBuff(buffSlot)
			end
		end
	end
end

function DismissAllPlayerPets()
	DismissPlayerPet(UNIT_FRAMES_REBIRTH_PET_FAMILIAR)
	DismissPlayerPet(UNIT_FRAMES_REBIRTH_PET_TWILIGHT)
	DismissPlayerPet(UNIT_FRAMES_REBIRTH_PET_GUARDIAN)
end