local addon = {
	name = "VotansCraglornDungeonCodes"
}

-- Bingo Code to Fast Travel Node
local codes = {
	["AA"] = 231, --Trial: Aetherian Archive
	["AC"] = 192, --Dungeon: Arx Corinium
	["Arx"] = 192, --Dungeon: Arx Corinium
	["AS"] = 346, --Trial: Asylum Sanctorium
	["Banished"] = 194, --Dungeon: The Banished Cells I
	["Banished2"] = 194, --Dungeon: The Banished Cells I
	["Banished2"] = 262, --Dungeon: The Banished Cells II
	["BC"] = 194, --Dungeon: The Banished Cells I
	["BC1"] = 194, --Dungeon: The Banished Cells I
	["BC2"] = 262, --Dungeon: The Banished Cells II
	["BCR"] = 187, --Dungeon: Blessed Crucible
	["BDV"] = 437, --Dungeon: Black Drake Villa
	["BF"] = 326, --Dungeon: Bloodroot Forge
	["BH"] = 186, --Dungeon: Blackheart Haven
	["BHH"] = 186, --Dungeon: Blackheart Haven
	["Blackheart"] = 186, --Dungeon: Blackheart Haven
	["BRF"] = 326, --Dungeon: Bloodroot Forge
	["BRP"] = 378, --Blackrose Prison
	["CA"] = 497, --Dungeon: Coral Aerie
	["Cauldron"] = 454, --Dungeon: The Cauldron
	["CD"] = 454, --Dungeon: The Cauldron
	["CoA"] = 197, --Dungeon: City of Ash I
	["CoA1"] = 197, --Dungeon: City of Ash I
	["CoA2"] = 268, --Dungeon: City of Ash II
	["CoH"] = 190, --Dungeon: Crypt of Hearts I
	["CoH1"] = 190, --Dungeon: Crypt of Hearts I
	["CoH2"] = 269, --Dungeon: Crypt of Hearts II
	["CoS"] = 261, --Dungeon: Cradle of Shadows
	["CR"] = 364, --Trial: Cloudrest
	["Crucible"] = 187, --Dungeon: Blessed Crucible
	["Crypts"] = 190, --Dungeon: Crypt of Hearts I
	["Crypts1"] = 190, --Dungeon: Crypt of Hearts I
	["Crypts2"] = 269, --Dungeon: Crypt of Hearts II
	["CT"] = 436, --Dungeon: Castle Thorn
	["Darkshade2"] = 264, --Dungeon: Darkshade Caverns II
	["DC"] = 469, --Dungeon: The Dread Cellar
	["DFK"] = 195, --Dungeon: Direfrost Keep
	["Direfrost"] = 195, --Dungeon: Direfrost Keep
	["DK"] = 195, --Dungeon: Direfrost Keep
	["DoM"] = 390, --Dungeon: Depths of Malatar
	["DRC"] = 469, --Dungeon: The Dread Cellar
	["DSA"] = 270, --Dragonstar Arena
	["DSC"] = 198, --Dungeon: Darkshade Caverns I
	["DSC1"] = 198, --Dungeon: Darkshade Caverns I
	["DSC2"] = 264, --Dungeon: Darkshade Caverns II
	["DSR"] = 488, --Trial: Dreadsail Reef
	["EH"] = 191, --Dungeon: Elden Hollow I
	["EH1"] = 191, --Dungeon: Elden Hollow I
	["EH2"] = 265, --Dungeon: Elden Hollow II
	["Elden"] = 191, --Dungeon: Elden Hollow I
	["Elden1"] = 191, --Dungeon: Elden Hollow I
	["Elden2"] = 265, --Dungeon: Elden Hollow II
	["ERE"] = 520, --Dungeon: Earthen Root Enclave
	["FG"] = 98, --Dungeon: Fungal Grotto I
	["FG1"] = 98, --Dungeon: Fungal Grotto I
	["FG2"] = 266, --Dungeon: Fungal Grotto II
	["FH"] = 332, --Dungeon: Falkreath Hold
	["FL"] = 341, --Dungeon: Fang Lair
	["Frost"] = 389, --Dungeon: Frostvault
	["Fungal"] = 98, --Dungeon: Fungal Grotto I
	["Fungal1"] = 98, --Dungeon: Fungal Grotto I
	["Fungal2"] = 266, --Dungeon: Fungal Grotto II
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
	["Mazza"] = 260, --Dungeon: Ruins of Mazzatun
	["MF"] = 391, --Dungeon: Moongrave Fane
	["MGF"] = 391, --Dungeon: Moongrave Fane
	["MHK"] = 371, --Dungeon: Moon Hunter Keep
	["MoL"] = 258, --Trial: Maw of Lorkhaj
	["MoS"] = 370, --Dungeon: March of Sacrifices
	["MSA"] = 250, --"Maelstrom Arena",
	["Prison"] = 236, --Dungeon: Imperial City Prison
	["RG"] = 468, --Trial: Rockgrove
	["RoM"] = 260, --Dungeon: Ruins of Mazzatun
	["RPB"] = 470, --Dungeon: Red Petal Bastion
	["SC"] = 193, --Dungeon: Spindleclutch I
	["SC1"] = 193, --Dungeon: Spindleclutch I
	["SC2"] = 267, --Dungeon: Spindleclutch II
	["SCP"] = 363, --Dungeon: Scalecaller Peak
	["Selene"] = 185, --Dungeon: Selene's Web
	["SG"] = 435, --Dungeon: Stone Garden
	["SO"] = 232, --Trial: Sanctum Ophidia
	["SP"] = 363, --Dungeon: Scalecaller Peak
	["Spindle"] = 193, --Dungeon: Spindleclutch I
	["Spindle1"] = 193, --Dungeon: Spindleclutch I
	["Spindle2"] = 267, --Dungeon: Spindleclutch II
	["SS"] = 399, --Trial: Sunspire
	["SW"] = 185, --Dungeon: Selene's Web
	["SWR"] = 498, --Dungeon: Shipwright's Regret
	["TCA"] = 497, --Dungeon: Coral Aerie
	["TDC"] = 469, --Dungeon: The Dread Cellar
	["Tempest"] = 188, --Dungeon: Tempest Island
	["TI"] = 188, --Dungeon: Tempest Island
	["UG"] = 425, --Dungeon: Unhallowed Grave
	["Vaults"] = 184, --Dungeon: Vaults of Madness
	["VF"] = 196, --Dungeon: Volenfell
	["VoM"] = 184, --Dungeon: Vaults of Madness
	["Wayrest2"] = 263, --Dungeon: Wayrest Sewers II
	["WgT"] = 247, --Dungeon: White-Gold Tower
	["WGT"] = 247, --Dungeon: White-Gold Tower
	["WRS"] = 189, --Dungeon: Wayrest Sewers I
	["WRS1"] = 189, --Dungeon: Wayrest Sewers I
	["WS"] = 189, --Dungeon: Wayrest Sewers I
	["WS1"] = 189, --Dungeon: Wayrest Sewers I
	["WS2"] = 263, --Dungeon: Wayrest Sewers II
	["BS"] = 531, --Dungeon: Bal Sunnar
	["SH"] = 532 --Dungeon: Scrivener's Hall
}

local tooltipCodes = {}
for keyword, nodeIndex in pairs(codes) do
	if string.len(keyword) <= 3 then
		tooltipCodes[nodeIndex] = keyword
	end
end
for keyword, nodeIndex in pairs(codes) do
	if not tooltipCodes[nodeIndex] or string.len(keyword) == 3 then
		tooltipCodes[nodeIndex] = keyword
	end
end
for keyword, nodeIndex in pairs(codes) do
	local locationName = select(2, GetFastTravelNodeInfo(nodeIndex))
	codes[keyword] = locationName
end
local replacement = {}
local normalText = GetString(SI_DUNGEONDIFFICULTY1)
local vetText = GetString(SI_DUNGEONDIFFICULTY2)
for keyword, name in pairs(codes) do
	local name = zo_strformat("<<!AT:1>>", name)
	local default = string.format("%s %s", keyword, name)
	local normal = string.format("n%s %s |c00ef00%s|r", keyword, name, normalText)
	local vet = string.format("v%s %s |cED8200%s|r", keyword, name, vetText)
	replacement["n" .. keyword] = normal
	replacement["v" .. keyword] = vet
	local alter = keyword:lower()
	replacement["n" .. alter] = normal
	replacement["v" .. alter] = vet
	alter = keyword:upper()
	replacement[alter] = default
	replacement["n" .. alter] = normal
	replacement["v" .. alter] = vet
	replacement["N" .. alter] = normal
	replacement["V" .. alter] = vet
end
do
	local prefixes = {
		[" "] = true,
		[","] = true,
		["/"] = true,
		[":"] = true
	}
	local function replaceCode(prefix, keyword)
		local name = prefixes[prefix] and replacement[keyword]
		if name then
			return string.format("%s|o%s", prefix, name)
		end
	end
	local FormatAndAddChatMessage = CHAT_ROUTER.FormatAndAddChatMessage
	function CHAT_ROUTER:FormatAndAddChatMessage(eventCode, ...)
		if eventCode == EVENT_CHAT_MESSAGE_CHANNEL then
			local count
			local msg = select(3, ...)

			msg, count = msg:gsub("(%A)(%a%w+)", replaceCode)
			if count > 0 then
				local result = {...}
				result[3] = msg
				return FormatAndAddChatMessage(self, eventCode, unpack(result))
			end
		end
		return FormatAndAddChatMessage(self, eventCode, ...)
	end
end

do
	local function showCode(pin)
		local nodeIndex = pin:GetFastTravelNodeIndex()
		local code = nodeIndex and tooltipCodes[nodeIndex]
		if code then
			local text = zo_strformat("Code: |cFFFFFFn<<1>>, v<<1>>|r", code)
			if IsInGamepadPreferredMode() then
				ZO_MapLocationTooltip_Gamepad.tooltip:AddLine(text)
			else
				InformationTooltip:AddLine(text, "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
			end
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
