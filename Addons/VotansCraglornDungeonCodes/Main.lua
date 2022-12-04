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
	["CoA"] = 197, --Dungeon: City of Ash I
	["CoA1"] = 197, --Dungeon: City of Ash I
	["CoA2"] = 268, --Dungeon: City of Ash II
	["CoH"] = 190, --Dungeon: Crypt of Hearts I
	["CoH1"] = 190, --Dungeon: Crypt of Hearts I
	["CoH2"] = 269, --Dungeon: Crypt of Hearts II
	["CoS"] = 261, --Dungeon: Cradle of Shadows
	["CR"] = 364, --Trial: Cloudrest
	["Crucible"] = 187, --Dungeon: Blessed Crucible
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
	["KA"] = 434, --Trial: Kyne's Aegis
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
	["Selene"] = 185, --Dungeon: Selene's Web
	["SO"] = 232, --Trial: Sanctum Ophidia
	["SP"] = 363, --Dungeon: Scalecaller Peak
	["SS"] = 399, --Trial: Sunspire
	["SW"] = 185, --Dungeon: Selene's Web
	["TI"] = 188, --Dungeon: Tempest Island
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
for keyword, nodeIndex in pairs(codes) do
	if tonumber(nodeIndex) then
		local locationName = select(2, GetFastTravelNodeInfo(nodeIndex))
		codes[keyword] = locationName
	end
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
	local default = zo_strformat(" <<!AT:1>>", name)
	local normal = default .. normalText
	local vet = default .. vetText
	replacement["%s" .. keyword] = default
	replacement["%sn" .. keyword] = normal
	replacement["%sv" .. keyword] = vet
	local alter = keyword:lower()
	replacement["%s" .. alter] = default
	replacement["%sn" .. alter] = normal
	replacement["%sv" .. alter] = vet
	alter = keyword:upper()
	replacement["%s" .. alter] = default
	replacement["%sn" .. alter] = normal
	replacement["%sv" .. alter] = vet
end
do
	local FormatAndAddChatMessage = CHAT_ROUTER.FormatAndAddChatMessage
	function CHAT_ROUTER:FormatAndAddChatMessage(eventCode, ...)
		if eventCode == EVENT_CHAT_MESSAGE_CHANNEL then
			local result = {...}
			local msg = result[3]
			local triggered = false
			for keyword in pairs(trigger) do
				if zo_plainstrfind(msg, keyword) then
					triggered = true
					break
				end
			end
			if triggered then
				for keyword, name in pairs(replacement3) do
					msg = msg:gsub(keyword, name)
				end
				for keyword, name in pairs(replacement2) do
					msg = msg:gsub(keyword, name)
				end
				result[3] = msg
				return FormatAndAddChatMessage(self, eventCode, unpack(result))
			end
		end
		return FormatAndAddChatMessage(self, eventCode, ...)
	end
end

SLASH_COMMANDS["/bingo"] = function()
	for nodeIndex = 1, 600 do
		local name, _, _, texture = select(2, GetFastTravelNodeInfo(nodeIndex))
		if texture:find("instance_") or texture:find("raiddungeon_") or texture:find("arena_") then
			df("%i, --%s %s", nodeIndex, name, texture)
		end
	end
end
