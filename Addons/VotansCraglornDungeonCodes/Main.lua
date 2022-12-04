local addon = {
	name = "VotansCraglornDungeonCodes"
}
local em = GetEventManager()

-- Bingo Code to Fast Travel Node
local codes = {
	["AA"] = 231, --Trial: Aetherian Archive
	["AC"] = 192, --Dungeon: Arx Corinium
	["Arx"] = 192, --Dungeon: Arx Corinium
	["AS"] = 346, --Trial: Asylum Sanctorium
	["BC"] = 194, --Dungeon: The Banished Cells I
	["BC1"] = 194, --Dungeon: The Banished Cells I
	["BC2"] = 262, --Dungeon: The Banished Cells II
	["BCR"] = 187, --Dungeon: Blessed Crucible
	["BDV"] = 437, --Dungeon: Black Drake Villa
	["BF"] = 326, --Dungeon: Bloodroot Forge
	["BH"] = 186, --Dungeon: Blackheart Haven
	["BrP"] = 378, --Blackrose Prison
	["CA"] = 497, --Dungeon: Coral Aerie
	["CD"] = 454, --Dungeon: The Cauldron
	["CD"] = 454, --Dungeon: The Cauldron
	["CoA"] = 197, --Dungeon: City of Ash I
	["CoA1"] = 197, --Dungeon: City of Ash I
	["CoA2"] = 268, --Dungeon: City of Ash II
	["CoH"] = 190, --Dungeon: Crypt of Hearts I
	["CoH1"] = 190, --Dungeon: Crypt of Hearts I
	["CoH2"] = 269, --Dungeon: Crypt of Hearts II
	["CoS"] = 261, --Dungeon: Cradle of Shadows
	["CR"] = 364, --Trial: Cloudrest
	["Cru"] = 187, --Dungeon: Blessed Crucible
	["CT"] = 436, --Dungeon: Castle Thorn
	["DC"] = 198, --Dungeon: Darkshade Caverns I
	["DC1"] = 198, --Dungeon: Darkshade Caverns I
	["DC2"] = 264, --Dungeon: Darkshade Caverns II
	["DK"] = 195, --Dungeon: Direfrost Keep
	["DoM"] = 390, --Dungeon: Depths of Malatar
	["DRC"] = 469, --Dungeon: The Dread Cellar
	["DSA"] = 270, --Dragonstar Arena
	["DSR"] = 488, --Trial: Dreadsail Reef
	["EH"] = 191, --Dungeon: Elden Hollow I
	["EH1"] = 191, --Dungeon: Elden Hollow I
	["EH2"] = 265, --Dungeon: Elden Hollow II
	["ERE"] = 520, --Dungeon: Earthen Root Enclave
	["FG"] = 98, --Dungeon: Fungal Grotto I
	["FG1"] = 98, --Dungeon: Fungal Grotto I
	["FG2"] = 266, --Dungeon: Fungal Grotto II
	["FH"] = 332, --Dungeon: Falkreath Hold
	["FL"] = 341, --Dungeon: Fang Lair
	["FV"] = 389, --Dungeon: Frostvault
	["GD"] = 521, --Dungeon: Graven Deep
	["HoF"] = 331, --Trial: Halls of Fabrication
	["HR"] = 230, --Trial: Hel Ra Citadel
	["HrC"] = 230, --Trial: Hel Ra Citadel
	["ICP"] = 236, --Dungeon: Imperial City Prison
	["IR"] = 424, --Dungeon: Icereach
	["KA"] = 434, --Trial: Kyne's Aegis
	["LoM"] = 398, --Dungeon: Lair of Maarselok
	["MA"] = 250, --"Maelstrom Arena",
	["MGF"] = 391, --Dungeon: Moongrave Fane
	["MHK"] = 371, --Dungeon: Moon Hunter Keep
	["MoL"] = 258, --Trial: Maw of Lorkhaj
	["MoS"] = 370, --Dungeon: March of Sacrifices
	["MSA"] = 250, --"Maelstrom Arena",
	["RG"] = 468, --Trial: Rockgrove
	["RoM"] = 260, --Dungeon: Ruins of Mazzatun
	["RPB"] = 470, --Dungeon: Red Petal Bastion
	["SC"] = 193, --Dungeon: Spindleclutch I
	["SC1"] = 193, --Dungeon: Spindleclutch I
	["SC2"] = 267, --Dungeon: Spindleclutch II
	["SCP"] = 363, --Dungeon: Scalecaller Peak
	["Sel"] = 185, --Dungeon: Selene's Web
	["SG"] = 435, --Dungeon: Stone Garden
	["SO"] = 232, --Trial: Sanctum Ophidia
	["SS"] = 399, --Trial: Sunspire
	["SW"] = 185, --Dungeon: Selene's Web
	["SWR"] = 498, --Dungeon: Shipwright's Regret
	["TI"] = 188, --Dungeon: Tempest Island
	["UG"] = 425, --Dungeon: Unhallowed Grave
	["VF"] = 196, --Dungeon: Volenfell
	["VoM"] = 184, --Dungeon: Vaults of Madness
	["WgT"] = 247, --Dungeon: White-Gold Tower
	["WS"] = 189, --Dungeon: Wayrest Sewers I
	["WS1"] = 189, --Dungeon: Wayrest Sewers I
	["WS2"] = 263 --Dungeon: Wayrest Sewers II
}
local trigger = {
	["lf "] = true,
	["lfm "] = true,
	["lfg "] = true,
	["LF "] = true,
	["LFM "] = true,
	["LFG "] = true
}
local tooltipCodes = {}
for keyword, nodeIndex in pairs(codes) do
	if not tooltipCodes[nodeIndex] or string.len(tooltipCodes[nodeIndex]) < string.len(keyword) then
		tooltipCodes[nodeIndex] = keyword
	end
end
for keyword, nodeIndex in pairs(codes) do
	local locationName = select(2, GetFastTravelNodeInfo(nodeIndex))
	codes[keyword] = locationName
end
local replacement2 = {}
local replacement3 = {}
local normalText = string.format(" (%s)", GetString(SI_DUNGEONDIFFICULTY1))
local vetText = string.format(" (%s)", GetString(SI_DUNGEONDIFFICULTY2))
for keyword, name in pairs(codes) do
	local replacement
	if string.len(keyword) == 2 then
		replacement = replacement2
	else
		replacement = replacement3
	end
	local default = zo_strformat("<<!AT:1>>", name)
	local normal = default .. normalText
	local vet = default .. vetText
	replacement[keyword] = default
	replacement["n" .. keyword] = normal
	replacement["v" .. keyword] = vet
	local alter = keyword:lower()
	replacement[alter] = default
	replacement["n" .. alter] = normal
	replacement["v" .. alter] = vet
	alter = keyword:upper()
	replacement[alter] = default
	replacement["n" .. alter] = normal
	replacement["v" .. alter] = vet
end
do
	local function replaceCode(replacement, prefix, keyword, suffix)
		local name = replacement[keyword]
		if name then
			return string.format("%s%s%s", prefix or "", name, suffix or "")
		end
	end
	local function replace2Code(prefix, keyword, suffix)
		return replaceCode(replacement2, prefix, keyword, suffix)
	end
	local function replace3Code(prefix, keyword, suffix)
		return replaceCode(replacement3, prefix, keyword, suffix)
	end
	local FormatAndAddChatMessage = CHAT_ROUTER.FormatAndAddChatMessage
	function CHAT_ROUTER:FormatAndAddChatMessage(eventCode, ...)
		if eventCode == EVENT_CHAT_MESSAGE_CHANNEL then
			local msg = select(3, ...)
			local triggered = false
			for keyword in pairs(trigger) do
				if zo_plainstrfind(msg, keyword) then
					triggered = true
					break
				end
			end
			if triggered then
				--Do longer codes first
				msg = msg:gsub("(%A)(%a%a%w+)(%W)", replace3Code):gsub("(%A)(%a%a%w+)$", replace3Code)
				msg = msg:gsub("(%A)(%a%w+)(%W)", replace2Code):gsub("(%A)(%a%w+)$", replace2Code)
				local result = {...}
				result[3] = msg
				return FormatAndAddChatMessage(self, eventCode, unpack(result))
			end
		end
		return FormatAndAddChatMessage(self, eventCode, ...)
	end
end

do
	local function GetInformationTooltip(isGamepadMode)
		if isGamepadMode then
			return ZO_MapLocationTooltip_Gamepad
		else
			return InformationTooltip
		end
	end

	local function GetPlatformInformationTooltip()
		return GetInformationTooltip(IsInGamepadPreferredMode())
	end

	local function showCode(pin)
		local nodeIndex = pin:GetFastTravelNodeIndex()
		local code = tooltipCodes[nodeIndex]
		if code then
			local informationTooltip = GetPlatformInformationTooltip()
			informationTooltip:AddLine(zo_strformat("Code: |cFFFFFFn<<1>>, v<<1>>|r", code), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
		end
	end
	SecurePostHook(ZO_MapPin.TOOLTIP_CREATORS[MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE], "creator", showCode)
end

-- SLASH_COMMANDS["/bingo"] = function()
-- 	for nodeIndex = 1, 600 do
-- 		local name, _, _, texture = select(2, GetFastTravelNodeInfo(nodeIndex))
-- 		if texture:find("instance_") or texture:find("raiddungeon_") or texture:find("arena_") then
-- 			df("%i, --%s", nodeIndex, name)
-- 		end
-- 	end
-- end
