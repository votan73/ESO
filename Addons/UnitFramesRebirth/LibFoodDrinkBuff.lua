LIB_IDENTIFIER = "LibFoodDrinkBuff"

-- Author: Scootworks & Baertram
--- Latest food & drink export: 100027 pts
local LATEST_DISPLAY_ID = 126112 -- abilityId from UespLog AddOn "/uespdump skills abilities" or the latest displayId from esolog.uesp.net - Mined Skills

----------------
-- BUFF TYPES --
----------------
local NONE = 0
local MAX_HEALTH = 1
local MAX_MAGICKA = 2
local MAX_STAMINA = 4
local REGEN_HEALTH = 8
local REGEN_MAGICKA = 16
local REGEN_STAMINA = 32
local SPECIAL_VAMPIRE = 64
local FIND_FISHES = 128
local MAX_ALL = MAX_HEALTH + MAX_MAGICKA + MAX_STAMINA
local MAX_HEALTH_MAGICKA = MAX_HEALTH + MAX_MAGICKA
local MAX_HEALTH_MAGICKA_FISH = MAX_HEALTH + MAX_MAGICKA + FIND_FISHES
local MAX_HEALTH_MAGICKA_REGEN_HEALTH_MAGICKA = MAX_HEALTH + REGEN_HEALTH + MAX_MAGICKA + REGEN_MAGICKA
local MAX_HEALTH_MAGICKA_REGEN_MAGICKA = MAX_HEALTH + MAX_MAGICKA + REGEN_MAGICKA
local MAX_HEALTH_MAGICKA_SPECIAL_VAMPIRE = MAX_HEALTH + MAX_MAGICKA + SPECIAL_VAMPIRE
local MAX_HEALTH_REGEN_ALL = MAX_HEALTH + REGEN_HEALTH + REGEN_MAGICKA + REGEN_STAMINA
local MAX_HEALTH_REGEN_HEALTH = MAX_HEALTH + REGEN_HEALTH
local MAX_HEALTH_REGEN_MAGICKA = MAX_HEALTH + REGEN_MAGICKA
local MAX_HEALTH_REGEN_STAMINA = MAX_HEALTH + REGEN_STAMINA
local MAX_HEALTH_REGEN_MAGICKA_STAMINA = MAX_HEALTH + REGEN_MAGICKA + REGEN_STAMINA
local MAX_HEALTH_STAMINA = MAX_HEALTH + MAX_STAMINA
local MAX_HEALTH_STAMINA_REGEN_HEALTH_STAMINA = MAX_HEALTH + REGEN_HEALTH + MAX_STAMINA + REGEN_STAMINA
local MAX_MAGICKA_REGEN_HEALTH = MAX_MAGICKA + REGEN_HEALTH
local MAX_MAGICKA_REGEN_MAGICKA = MAX_MAGICKA + REGEN_MAGICKA
local MAX_MAGICKA_REGEN_STAMINA = MAX_MAGICKA + REGEN_STAMINA
local MAX_MAGICKA_STAMINA = MAX_MAGICKA + MAX_STAMINA
local MAX_STAMINA_HEALTH_REGEN_STAMINA = MAX_HEALTH + MAX_STAMINA + REGEN_STAMINA
local MAX_STAMINA_REGEN_HEALTH = MAX_STAMINA + REGEN_HEALTH
local MAX_STAMINA_REGEN_MAGICKA = MAX_STAMINA + REGEN_MAGICKA
local MAX_STAMINA_REGEN_STAMINA = MAX_STAMINA + REGEN_STAMINA
local REGEN_ALL = REGEN_HEALTH + REGEN_MAGICKA + REGEN_STAMINA
local REGEN_HEALTH_MAGICKA = REGEN_HEALTH + REGEN_MAGICKA
local REGEN_HEALTH_STAMINA = REGEN_HEALTH + REGEN_STAMINA
local REGEN_MAGICKA_STAMINA = REGEN_MAGICKA + REGEN_STAMINA
local REGEN_MAGICKA_STAMINA_FISH = REGEN_MAGICKA + REGEN_STAMINA + FIND_FISHES

--------------------
-- DRINKS'n'FOODS --
--------------------
local DRINK_BUFF_ABILITIES = {
	[61322] = REGEN_HEALTH, -- Health Recovery
	[61325] = REGEN_MAGICKA, -- Magicka Recovery
	[61328] = REGEN_STAMINA, -- Health & Magicka Recovery
	[61335] = REGEN_HEALTH_MAGICKA, -- Health & Magicka Recovery (Liqueurs)
	[61340] = REGEN_HEALTH_STAMINA, -- Health & Stamina Recovery
	[61345] = REGEN_MAGICKA_STAMINA, -- Magicka & Stamina Recovery
	[61350] = REGEN_ALL, -- All Primary Stat Recovery
	[66125] = MAX_HEALTH, -- Increase Max Health
	[66132] = REGEN_HEALTH, -- Health Recovery (Alcoholic Drinks)
	[66137] = REGEN_MAGICKA, -- Magicka Recovery (Tea)
	[66141] = REGEN_STAMINA, -- Stamina Recovery (Tonics)
	[66586] = REGEN_HEALTH, -- Health Recovery
	[66590] = REGEN_MAGICKA, -- Magicka Recovery
	[66594] = REGEN_STAMINA, -- Stamina Recovery
	[68416] = REGEN_ALL, -- All Primary Stat Recovery (Crown Refreshing Drink)
	[72816] = REGEN_HEALTH_MAGICKA, -- Red Frothgar
	[72965] = REGEN_HEALTH_STAMINA, -- Health and Stamina Recovery (Cyrodilic Field Brew)
	[72968] = REGEN_HEALTH_MAGICKA, -- Health and Magicka Recovery (Cyrodilic Field Tea)
	[72971] = REGEN_MAGICKA_STAMINA, -- Magicka and Stamina Recovery (Cyrodilic Field Tonic)
	[84700] = REGEN_HEALTH_MAGICKA, -- 2h Witches event: Eyeballs
	[84704] = REGEN_ALL, -- 2h Witches event: Witchmother's Party Punch
	[84720] = MAX_MAGICKA_REGEN_MAGICKA, -- 2h Witches event: Eye Scream
	[84731] = MAX_HEALTH_MAGICKA_REGEN_MAGICKA, -- 2h Witches event: Witchmother's Potent Brew
	[84732] = REGEN_HEALTH, -- Increase Health Regen
	[84733] = REGEN_HEALTH, -- Increase Health Regen
	[84735] = MAX_HEALTH_MAGICKA_SPECIAL_VAMPIRE, -- 2h Witches event: Double Bloody Mara
	[85497] = REGEN_ALL, -- All Primary Stat Recovery
	[86559] = REGEN_MAGICKA_STAMINA_FISH, -- Hissmir Fish Eye Rye
	[86560] = REGEN_STAMINA, -- Stamina Recovery
	[86673] = MAX_STAMINA_REGEN_STAMINA, -- Lava Foot Soup & Saltrice
	[86674] = REGEN_STAMINA, -- Stamina Recovery
	[86677] = MAX_STAMINA_REGEN_HEALTH, -- Warning Fire (Bergama Warning Fire)
	[86678] = REGEN_HEALTH, -- Health Recovery
	[86746] = REGEN_HEALTH_MAGICKA, -- Betnikh Spiked Ale (Betnikh Twice-Spiked Ale)
	[86747] = REGEN_HEALTH, -- Health Recovery
	[86791] = REGEN_STAMINA, -- Increase Stamina Recovery (Ice Bear Glow-Wine)
	[89957] = MAX_STAMINA_HEALTH_REGEN_STAMINA, -- Dubious Camoran Throne
	[92433] = REGEN_HEALTH_MAGICKA, -- Health & Magicka Recovery
	[92476] = REGEN_HEALTH_STAMINA, -- Health & Stamina Recovery
	[100502] = REGEN_HEALTH_MAGICKA, -- Deregulated Mushroom Stew (Health + magicka reg)
}

local FOOD_BUFF_ABILITIES = {
	[17407] = MAX_HEALTH, -- Increase Max Health
	[17577] = MAX_MAGICKA_STAMINA, -- Increase Max Magicka & Stamina
	[17581] = MAX_ALL, -- Increase All Primary Stats
	[17608] = REGEN_MAGICKA_STAMINA, -- Magicka & Stamina Recovery
	[17614] = REGEN_ALL, -- All Primary Stat Recovery
	[61218] = MAX_ALL, -- Increase All Primary Stats
	[61255] = MAX_HEALTH_STAMINA, -- Increase Max Health & Stamina
	[61257] = MAX_HEALTH_MAGICKA, -- Increase Max Health & Magicka
	[61259] = MAX_HEALTH, -- Increase Max Health
	[61260] = MAX_MAGICKA, -- Increase Max Magicka
	[61261] = MAX_STAMINA, -- Increase Max Stamina
	[61294] = MAX_MAGICKA_STAMINA, -- Increase Max Magicka & Stamina
	[66128] = MAX_MAGICKA, -- Increase Max Magicka (Fruit Dishes)
	[66130] = MAX_STAMINA, -- Increase Max Stamina (Vegetable Dishes)
	[66551] = MAX_HEALTH, -- Garlic and Pepper Venison Steak
	[66568] = MAX_MAGICKA, -- Increase Max Magicka
	[66576] = MAX_STAMINA, -- Increase Max Stamina
	[68411] = MAX_ALL, -- Crown store
	[72819] = MAX_HEALTH_REGEN_STAMINA, -- Tripe Trifle Pocket
	[72822] = MAX_HEALTH_REGEN_HEALTH, -- Blood Price Pie
	[72824] = MAX_HEALTH_REGEN_ALL, -- Smoked Bear Haunch
	[72956] = MAX_HEALTH_STAMINA, -- Max Health and Stamina (Cyrodilic Field Tack)
	[72959] = MAX_HEALTH_MAGICKA, -- Max Health and Magicka (Cyrodilic Field Treat)
	[72961] = MAX_MAGICKA_STAMINA, -- Max Stamina and Magicka (Cyrodilic Field Bar)
	[84678] = MAX_MAGICKA, -- Increase Max Magicka
	[84681] = MAX_MAGICKA_STAMINA, -- Pumpkin Snack Skewer
	[84709] = MAX_MAGICKA_REGEN_STAMINA, -- Crunchy Spider Skewer
	[84725] = MAX_MAGICKA_REGEN_HEALTH, -- The Brains!
	[84736] = MAX_HEALTH, -- Increase Max Health
	[85484] = MAX_ALL, -- Increase All Primary Stats
	[86749] = MAX_MAGICKA_STAMINA, -- Mud Ball
	[86787] = MAX_STAMINA, -- Rajhin's Sugar Claws
	[86789] = MAX_HEALTH, -- Alcaire Festival Sword-Pie
	[89955] = MAX_STAMINA_REGEN_MAGICKA, -- Candied Jester's Coins
	[89971] = MAX_HEALTH_REGEN_MAGICKA_STAMINA, -- Jewels of Misrule
	[92435] = MAX_HEALTH_MAGICKA, -- Increase Health & Magicka
	[92437] = MAX_HEALTH, -- Increase Health
	[92474] = MAX_HEALTH_STAMINA, -- Increase Health & Stamina
	[92477] = MAX_HEALTH, -- Increase Health
	[100488] = MAX_ALL, -- Spring-Loaded Infusion (Increase all primary stats)
	[100498] = MAX_HEALTH_MAGICKA_REGEN_HEALTH_MAGICKA, -- Clockwork Citrus Filet (Increase health + health Recovery, and magicka + magicka Recovery)
	[107748] = MAX_HEALTH_MAGICKA_FISH, -- Lure Allure (Increase Health & Magicka)
	[107789] = MAX_HEALTH_STAMINA_REGEN_HEALTH_STAMINA, -- Artaeum Takeaway Broth (Increase Health & Stamina & Health Recovery & Stamina Recovery)
}

local function GetBuffTypeInfos(abilityId)
-- Returns 2: number buffTypeFoodDrink, bool isDrink
	local isDrinkBuff = DRINK_BUFF_ABILITIES[abilityId]
	return isDrinkBuff or FOOD_BUFF_ABILITIES[abilityId] or nil, isDrinkBuff ~= nil and true or false
end

local LibFoodDrinkBuff = ZO_Object:Subclass()

function LibFoodDrinkBuff:New(...)
	local object = ZO_Object.New(self)
	object:Initialize(...)
	return object
end

function LibFoodDrinkBuff:Initialize()
	local function OnAddOnLoaded(_, addOnName)
		if addOnName == LIB_IDENTIFIER then
			EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_ADD_ON_LOADED)
			self.version = self:GetAddonVersionFromManifest(LIB_IDENTIFIER)
		end
	end

	EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
end

-- Read the addon version from the addon's txt manifest file tag ##AddOnVersion
function LibFoodDrinkBuff:GetAddonVersionFromManifest(addOnNameString)
-- Returns 1: number addOnVersion
	if addOnNameString then
		local ADDON_MANAGER = GetAddOnManager()
		for i = 1, ADDON_MANAGER:GetNumAddOns() do
			addOnName = ADDON_MANAGER:GetAddOnInfo(i)
			if addOnName == addOnNameString then
				return ADDON_MANAGER:GetAddOnVersion(i)
			end
		end
	end
	return nil
end

-- Calculate time left of a food/drink buff
function LibFoodDrinkBuff:GetTimeLeftInSeconds(timeInMilliseconds)
-- Returns 1: number seconds
	return math.max(zo_roundToNearest(timeInMilliseconds-(GetGameTimeMilliseconds()/1000), 1), 0)
end

function LibFoodDrinkBuff:GetFoodBuffInfos(unitTag)
-- Returns 7: number buffTypeFoodDrink, bool isDrink, number abilityId, string buffName, number timeStarted, number timeEnds, string iconTexture, number timeLeftInSeconds
	local numBuffs = GetNumBuffs(unitTag)
	if numBuffs > 0 then
		local buffName, timeStarted, timeEnding, iconTexture, abilityId, buffTypeDrink, buffTypeFood, buffTypeFoodDrink, isDrink
		for i = 1, numBuffs do
			-- Returns 13: string buffName, number timeStarted, number timeEnding, number buffSlot, number stackCount, string iconFilename, string buffType, number effectType, number abilityType, number statusEffectType, number abilityId, bool canClickOff, bool castByPlayer
			buffName, timeStarted, timeEnding, _, _, iconTexture, _, _, _, _, abilityId = GetUnitBuffInfo(unitTag, i)
			buffTypeFoodDrink, isDrink = GetBuffTypeInfos(abilityId)
			if buffTypeFoodDrink then
				return buffTypeFoodDrink, isDrink, abilityId, ZO_CachedStrFormat(SI_UNIT_NAME, buffName), timeStarted, timeEnding, iconTexture, self:GetTimeLeftInSeconds(timeEnding)
			end
		end
	end
	return NONE, nil, nil, nil, nil, nil, nil, nil
end

function LibFoodDrinkBuff:IsFoodBuffActive(unitTag)
-- Returns 1: bool isBuffActive
	local numBuffs = GetNumBuffs(unitTag)
	if numBuffs > 0 then
		local abilityId
		for i = 1, numBuffs do
			abilityId = select(11, GetUnitBuffInfo(unitTag, i))
			if GetBuffTypeInfos(abilityId) then
				return true
			end
		end
	end
	return false
end

function LibFoodDrinkBuff:IsFoodBuffActiveAndGetTimeLeft(unitTag)
-- Returns 3: bool isBuffActive, number timeLeftInSeconds, number abilityId
	local numBuffs = GetNumBuffs(unitTag)
	if numBuffs > 0 then
		local timeEnding, abilityId
		for i = 1, numBuffs do
			_, _, timeEnding, _, _, _, _, _, _, _, abilityId = GetUnitBuffInfo(unitTag, i)
			if GetBuffTypeInfos(abilityId) then
				return true, self:GetTimeLeftInSeconds(timeEnding), abilityId
			end
		end
	end
	return false, 0, nil
end

function LibFoodDrinkBuff:IsAbilityADrinkBuff(abilityId)
-- Returns 1: nilable:bool isAbilityADrinkBuff(true) or isAbilityAFoodBuff(false), or nil if not a food or drink buff
	local buffTypeFoodDrink, isDrink = GetBuffTypeInfos(abilityId)
	if buffTypeFoodDrink then
		return isDrink
	end
	return nil
end

-- Filter the event EVENT_EFFECT_CHANGED to the local player and only the abilityIds of the food/drink buffs
-- Possible additional filterTypes are: REGISTER_FILTER_UNIT_TAG, REGISTER_FILTER_UNIT_TAG_PREFIX
--> Performance gain as you check if a food/drink buff got active (gained, refreshed), or was removed (faded, refreshed)
function LibFoodDrinkBuff:RegisterAbilityIdsFilterOnEventEffectChanged(addonEventNameSpace, callbackFunc, filterType, filterParameter)
	if type(addonEventNameSpace) == "string" and addonEventNameSpace ~= "" and type(callbackFunc) == "function" then
		local eventCounter = 0
		local eventName
		for abilityId, _ in pairs(FOOD_BUFF_ABILITIES) do
			eventCounter = eventCounter + 1
			eventName = addonEventNameSpace..eventCounter
			EVENT_MANAGER:RegisterForEvent(eventName, EVENT_EFFECT_CHANGED, callbackFunc)
			EVENT_MANAGER:AddFilterForEvent(eventName, EVENT_EFFECT_CHANGED, REGISTER_FILTER_ABILITY_ID, abilityId, filterType, filterParameter)
		end
		for abilityId, _ in pairs(DRINK_BUFF_ABILITIES) do
			eventCounter = eventCounter + 1
			eventName = addonEventNameSpace..eventCounter
			EVENT_MANAGER:RegisterForEvent(eventName, EVENT_EFFECT_CHANGED, callbackFunc)
			EVENT_MANAGER:AddFilterForEvent(eventName, EVENT_EFFECT_CHANGED, REGISTER_FILTER_ABILITY_ID, abilityId, filterType, filterParameter)
		end
		return true
	end
	return nil
end

-- Unregister the register function above
function LibFoodDrinkBuff:UnRegisterAbilityIdsFilterOnEventEffectChanged(addonEventNameSpace)
	if type(addonEventNameSpace) == "string" and addonEventNameSpace ~= "" then
		local eventCounter = 0
		local eventName
		if addonEventNameSpace == nil or addonEventNameSpace == "" then return nil end
		for abilityId, _ in pairs(FOOD_BUFF_ABILITIES) do
			eventCounter = eventCounter + 1
			eventName = addonEventNameSpace..eventCounter
			EVENT_MANAGER:UnregisterForEvent(eventName, EVENT_EFFECT_CHANGED)
		end
		for abilityId, _ in pairs(DRINK_BUFF_ABILITIES) do
			eventCounter = eventCounter + 1
			eventName = addonEventNameSpace..eventCounter
			EVENT_MANAGER:UnregisterForEvent(eventName, EVENT_EFFECT_CHANGED)
		end
		return true
	end
	return nil
end


-------------
-- MANAGER --
-------------
local LibFoodDrinkBuffManager = ZO_Object:Subclass()

local USE_PREFIX = true
local SAVE_ALL = 1
local SAVE_NEW = 2

function LibFoodDrinkBuffManager:New(...)
	local object = ZO_Object.New(self)
	object:Initialize(...)
	return object
end

function LibFoodDrinkBuffManager:Initialize()
	self.async = LibAsync
	if self.async then
		local function OnAddOnLoaded(_, addOnName)
			if addOnName == LIB_IDENTIFIER then
				EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER.."LibFoodDrinkBuffManager", EVENT_ADD_ON_LOADED)
				
				self.sv = ZO_SavedVars:NewAccountWide("LibFoodDrinkBuff_Save")
				self.sv.list = {}
				
				self.TaskScan = self.async:Create("FoodDrinkBuffCheck")
				self.TaskMessage = self.async:Create("FoodDrinkBuffMessage")

				self:InitializeSlashCommands()
			end
		end

		EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER.."LibFoodDrinkBuffManager", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
	end
end

function LibFoodDrinkBuffManager:Message(message, prefix)
	if prefix then
		df("|cFF0000[%s]|r %s", LIB_IDENTIFIER, message)
	else
		d(message)
	end
end

function LibFoodDrinkBuffManager:NotificationAfterCreatingFoodDrinkTable()
	local countEntries = #self.sv.list
	self:Message(ZO_CachedStrFormat(SI_LIB_FOOD_DRINK_EXPORT_FINISH, countEntries), USE_PREFIX)
	if countEntries > 0 then
		self:Message(GetString(SI_LIB_FOOD_DRINK_RELOAD), USE_PREFIX)
		self.TaskMessage:Delay(5000, function() ReloadUI("ingame") end)
	end
end

do
	local ARGUMENT_ALL = "all"
	local ARGUMENT_NEW = "new"

	local BLACKLIST_NO_FOOD_DRINK_BUFFS =
	{
		[43752] = true, -- Seelenbeschwörung
		[63570] = true, -- erhöhter Erfahrungsgewinn
		[66776] = true, -- erhöhter Erfahrungsgewinn
		[77123] = true, -- Jubiläums-Erfahrungsbonus
		[85501] = true, -- erhöhter Erfahrungsgewinn
		[85502] = true, -- erhöhter Erfahrungsgewinn
		[85503] = true, -- erhöhter Erfahrungsgewinn
		[86755] = true, -- Feiertags-Erfahrungsbonus
		[91369] = true, -- erhöhter Erfahrungsgewinn der Narrenpastete
		[92232] = true, -- Pelinals Wildheit
		[99462] = true, -- erhöhter Erfahrungsgewinn
		[99463] = true, -- erhöhter Erfahrungsgewinn
		[118985] = true, -- Jubiläums-Erfahrungsbonus
		[116467] = true, -- MillionHealth
	}

	function LibFoodDrinkBuffManager:AddToFoodDrinkTable(abilityId, saveType)
		if not BLACKLIST_NO_FOOD_DRINK_BUFFS[abilityId] then
			if DoesAbilityExist(abilityId) then
				local cost, mechanic = GetAbilityCost(abilityId)
				local channeled, castTime = GetAbilityCastInfo(abilityId)
				local minRangeCM, maxRangeCM = GetAbilityRange(abilityId)
				if cost == 0 and mechanic == 0 and GetAbilityTargetDescription(abilityId) == GetString(SI_TARGETTYPE2) and GetAbilityDescription(abilityId) ~= "" and GetAbilityEffectDescription(abilityId) == "" and not channeled and castTime == 0 and minRangeCM == 0 and maxRangeCM == 0 and GetAbilityRadius(abilityId) == 0 and GetAbilityAngleDistance(abilityId) == 0 and GetAbilityDuration(abilityId) > 2000000 then

					local ability = {}
					ability.id = abilityId
					ability.name = ZO_CachedStrFormat(SI_ABILITY_NAME, GetAbilityName(abilityId))
					ability.excel = ZO_CachedStrFormat(SI_LIB_FOOD_DRINK_EXCEL, abilityId, ability.name)

					if saveType == ARGUMENT_ALL then
						self.sv.list[#self.sv.list+1] = ability
					else
						if GetBuffTypeInfos(abilityId) == NONE then
							self.sv.list[#self.sv.list+1] = ability
						end
					end
				end
			end
		end
	end

	function LibFoodDrinkBuffManager:InitializeSlashCommands()
		SLASH_COMMANDS["/dumpfdb"] = function(saveType)
			if saveType == ARGUMENT_ALL or saveType == ARGUMENT_NEW then
				ZO_ClearNumericallyIndexedTable(self.sv.list)
				self:Message(GetString(SI_LIB_FOOD_DRINK_EXPORT_START), USE_PREFIX)

				self.TaskScan:For(0, LATEST_DISPLAY_ID):Do(function(abilityId)
					self:AddToFoodDrinkTable(abilityId, saveType)
				end):Then(function()
					self:NotificationAfterCreatingFoodDrinkTable()
				end)
			else
				self:Message(ZO_CachedStrFormat(SI_LIB_FOOD_DRINK_ARGUMENT_MISSING, GetString(SI_ERROR_INVALID_COMMAND)), USE_PREFIX)
			end
		end
	end
end


-------------
-- GLOBALS --
-------------
do
	local DIVIDER = ZO_ERROR_COLOR:Colorize("____________________________________")

	function DEBUG_ACTIVE_BUFFS(unitTag)
		unitTag = unitTag or "player"

		LibFoodDrinkBuffManager:Message(DIVIDER)
		LibFoodDrinkBuffManager:Message(zo_strformat("Debug \"<<1>>\" Buffs:", unitTag), USE_PREFIX)

		local abilityId, buffName
		local numBuffs = GetNumBuffs(unitTag)
		for i = 1, numBuffs do
			buffName, _, _, _, _, _, _, _, _, _, abilityId = GetUnitBuffInfo(unitTag, i)
			LibFoodDrinkBuffManager:Message(zo_strformat("<<1>>. [<<2>>] <<C:3>>", i, abilityId, ZO_SELECTED_TEXT:Colorize(buffName)))
		end

		LibFoodDrinkBuffManager:Message(DIVIDER)
	end
end

LIB_FOOD_DRINK_BUFF = LibFoodDrinkBuff:New()
LIB_FOOD_DRINK_MANAGER = LibFoodDrinkBuffManager:New()
