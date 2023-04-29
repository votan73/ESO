if RFT == nil then
	RFT = {}
end

local RFT = RFT

function RFT.MakeOrders()
	RFT.orders = {
		[0] = {
			-- the "usual"
			RFT.window.column4,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column4,
			RFT.window.column4,
			RFT.window.column1,
			RFT.window.column1
		},
		[491] = {
			RFT.window.column1
		},
		[492] = {
			RFT.window.column1
		},
		[493] = {
			RFT.window.column1
		},
		[472] = {
			-- Stormhaven: just messed up
			RFT.window.column4,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column4,
			RFT.window.column4,
			RFT.window.column1,
			RFT.window.column1
		},
		[916] = {
			-- Craglorn: no foul, no ocean
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column4,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column4,
			RFT.window.column4
		},
		[483] = {
			-- Auridon: no foul
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column2,
			RFT.window.column1,
			RFT.window.column1
		},
		[473] = {
			-- Rivenspire: no foul
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column1,
			RFT.window.column1
		},
		[475] = {
			-- Bangkorai: no foul
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column1
		},
		[478] = {
			-- Deshaan: no foul
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column1,
			RFT.window.column3,
			RFT.window.column1,
			RFT.window.column1
		},
		[487] = {
			-- Reaper's March: no ocean
			RFT.window.column3,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column2,
			RFT.window.column3
		},
		[479] = {
			-- Shadowfen: no ocean
			RFT.window.column3,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column1,
			RFT.window.column2
		},
		[481] = {
			-- Rift: no ocean
			RFT.window.column3,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column1
		},
		[474] = {
			-- Alik'r: no river
			RFT.window.column3,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column1,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column1,
			RFT.window.column1
		},
		[1186] = {
			-- Imperial City: all foul
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column2,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column3
		},
		[1339] = {
			-- Wrothgar: rare
			RFT.window.column1
		},
		[1340] = {
			-- Wrothgar
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column3,
			RFT.window.column2,
			RFT.window.column4,
			RFT.window.column1,
			RFT.window.column4,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column4,
			RFT.window.column3,
			RFT.window.column2
		},
		[1351] = {
			-- Abah's Landing
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column4,
			RFT.window.column4,
			RFT.window.column4
		},
		[1431] = {
			-- Gold Coast
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column4,
			RFT.window.column4,
			RFT.window.column4
		},
		[1882] = {
			-- Vvardenfell
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column4,
			RFT.window.column4,
			RFT.window.column4
		},
		[2027] = {
			-- Clockwork City
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column3
		},
		[2191] = {
			-- Sommersend
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column4,
			RFT.window.column4,
			RFT.window.column4
		},
		[2240] = {
			-- Artaeum
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column1
		},
		[2295] = {
			-- Murkmire
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column4,
			RFT.window.column4,
			RFT.window.column4
		},
		[2566] = {
			-- Southern Elsweyr
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column1
		},
		[2655] = {
			-- Western Skyrim
			RFT.window.column4,
			RFT.window.column4,
			RFT.window.column4,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column3
		},
		[2861] = {
			-- The Reach
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column3
		},
		[2981] = {
			-- Blackwood
			RFT.window.column4,
			RFT.window.column4,
			RFT.window.column4,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column3
		},
		[3144] = {
			-- Deathlands
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column4,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column4,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column4
		},
		[3269] = {
			-- High Isle
			RFT.window.column4,
			RFT.window.column4,
			RFT.window.column4,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column3
		},
		[3500] = {
			-- Galen
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column3,
		},
		[3636] = {
			-- Telvani-Halbinsel
			RFT.window.column4,
			RFT.window.column4,
			RFT.window.column4,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column2,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column1,
			RFT.window.column3,
			RFT.window.column3,
			RFT.window.column3,
		}
	}
	RFT.quality = {
		[0] = {
			-- the "usual"
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC
		},
		[916] = {
			-- Craglorn: 1,2,7,8
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC
		},
		[1186] = {
			-- Imperial City: 1,3,5
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC
		},
		[1339] = {
			-- Wrothgar rare
			ITEM_QUALITY_ARTIFACT
		},
		[1340] = {
			-- Wrothgar
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC
		},
		[1351] = {
			-- Abah's Landing
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC
		},
		[1431] = {
			-- Gold Coast
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC
		},
		[1882] = {
			-- Vvardenfell
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC
		},
		[2027] = {
			-- Clockwork City
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC
		},
		[2191] = {
			-- Sommersend
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC
		},
		[2240] = {
			-- Sommersend
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC
		},
		[2295] = {
			-- Murkmire
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE
		},
		[2566] = {
			-- Southern Elsweyr
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE
		},
		[2655] = {
			-- Western Skyrim
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE
		},
		[2861] = {
			-- The Reach
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC
		},
		[2981] = {
			-- Blackwood
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE
		},
		[3144] = {
			-- Deathlands
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_ARCANE
		},
		[3269] = {
			-- High Isle
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
		},
		[3500] = {
			-- Galen
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
		},
		[3636] = {
			-- Telvani
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_MAGIC,
			ITEM_QUALITY_ARCANE,
		}
	}
	RFT.types = {
		[0] = {
			-- the "usual"
			SI_RARE_FISH_TRACKER_TYPE_OCEAN,
			SI_RARE_FISH_TRACKER_TYPE_LAKE,
			SI_RARE_FISH_TRACKER_TYPE_RIVER,
			SI_RARE_FISH_TRACKER_TYPE_FOUL
		},
		[280] = {
			-- Bleakrock: ocean only
			SI_RARE_FISH_TRACKER_TYPE_OCEAN
		},
		[534] = {
			-- Stros M'Kai: ocean only
			SI_RARE_FISH_TRACKER_TYPE_OCEAN
		},
		[537] = {
			-- Khenarthi's Roost: ocean only
			SI_RARE_FISH_TRACKER_TYPE_OCEAN
		},
		[888] = {
			-- Craglorn: no foul, no ocean
			SI_RARE_FISH_TRACKER_TYPE_LAKE,
			SI_RARE_FISH_TRACKER_TYPE_LAKE,
			SI_RARE_FISH_TRACKER_TYPE_RIVER,
			SI_RARE_FISH_TRACKER_TYPE_RIVER
		},
		[381] = {
			-- Auridon: no foul
			SI_RARE_FISH_TRACKER_TYPE_OCEAN,
			SI_RARE_FISH_TRACKER_TYPE_LAKE,
			SI_RARE_FISH_TRACKER_TYPE_RIVER
		},
		[20] = {
			-- Rivenspire: no foul
			SI_RARE_FISH_TRACKER_TYPE_OCEAN,
			SI_RARE_FISH_TRACKER_TYPE_LAKE,
			SI_RARE_FISH_TRACKER_TYPE_RIVER
		},
		[92] = {
			-- Bangkorai: no foul
			SI_RARE_FISH_TRACKER_TYPE_OCEAN,
			SI_RARE_FISH_TRACKER_TYPE_LAKE,
			SI_RARE_FISH_TRACKER_TYPE_RIVER
		},
		[57] = {
			-- Deshaan: no foul
			SI_RARE_FISH_TRACKER_TYPE_OCEAN,
			SI_RARE_FISH_TRACKER_TYPE_LAKE,
			SI_RARE_FISH_TRACKER_TYPE_RIVER
		},
		[382] = {
			-- Reaper's March: no ocean
			SI_RARE_FISH_TRACKER_TYPE_LAKE,
			SI_RARE_FISH_TRACKER_TYPE_RIVER,
			SI_RARE_FISH_TRACKER_TYPE_FOUL
		},
		[117] = {
			-- Shadowfen: no ocean
			SI_RARE_FISH_TRACKER_TYPE_LAKE,
			SI_RARE_FISH_TRACKER_TYPE_RIVER,
			SI_RARE_FISH_TRACKER_TYPE_FOUL
		},
		[103] = {
			-- Rift: no ocean
			SI_RARE_FISH_TRACKER_TYPE_LAKE,
			SI_RARE_FISH_TRACKER_TYPE_RIVER,
			SI_RARE_FISH_TRACKER_TYPE_FOUL
		},
		[104] = {
			-- Alik'r: no river
			SI_RARE_FISH_TRACKER_TYPE_OCEAN,
			SI_RARE_FISH_TRACKER_TYPE_LAKE,
			SI_RARE_FISH_TRACKER_TYPE_FOUL
		},
		[347] = {
			-- Coldharbour: all foul
			SI_RARE_FISH_TRACKER_TYPE_FOUL,
			SI_RARE_FISH_TRACKER_TYPE_FOUL,
			SI_RARE_FISH_TRACKER_TYPE_FOUL,
			SI_RARE_FISH_TRACKER_TYPE_FOUL
		},
		[584] = {
			-- Imperial City: all foul
			SI_RARE_FISH_TRACKER_TYPE_FOUL,
			SI_RARE_FISH_TRACKER_TYPE_FOUL,
			SI_RARE_FISH_TRACKER_TYPE_FOUL
		},
		[980] = {
			-- Clockwork City: all foul
			SI_RARE_FISH_TRACKER_TYPE_FOUL,
			SI_RARE_FISH_TRACKER_TYPE_FOUL,
			SI_RARE_FISH_TRACKER_TYPE_FOUL
		},
		[981] = {
			-- Clockwork City: all foul
			SI_RARE_FISH_TRACKER_TYPE_FOUL,
			SI_RARE_FISH_TRACKER_TYPE_FOUL,
			SI_RARE_FISH_TRACKER_TYPE_FOUL
		},
		[1027] = {
			-- Artaeum
			SI_RARE_FISH_TRACKER_TYPE_OCEAN,
			SI_RARE_FISH_TRACKER_TYPE_OCEAN,
			SI_RARE_FISH_TRACKER_TYPE_OCEAN
		},
		[1086] = {
			-- Elsweyr
			SI_RARE_FISH_TRACKER_TYPE_RIVER,
			SI_RARE_FISH_TRACKER_TYPE_RIVER,
			SI_RARE_FISH_TRACKER_TYPE_RIVER,
			SI_RARE_FISH_TRACKER_TYPE_RIVER
		},
		[1133] = {
			-- Elsweyr
			SI_RARE_FISH_TRACKER_TYPE_OCEAN,
			SI_RARE_FISH_TRACKER_TYPE_RIVER,
			SI_RARE_FISH_TRACKER_TYPE_FOUL
		},
		[1207] = {
			-- The Reach
			SI_RARE_FISH_TRACKER_TYPE_LAKE,
			SI_RARE_FISH_TRACKER_TYPE_RIVER,
			SI_RARE_FISH_TRACKER_TYPE_FOUL
		},
		[1286] = {
			-- The Deathlands
			SI_RARE_FISH_TRACKER_TYPE_FOUL,
			SI_RARE_FISH_TRACKER_TYPE_FOUL,
			SI_RARE_FISH_TRACKER_TYPE_FOUL,
			SI_RARE_FISH_TRACKER_TYPE_FOUL
		},
		[1383] = {
			-- Galen
			SI_RARE_FISH_TRACKER_TYPE_OCEAN,
			SI_RARE_FISH_TRACKER_TYPE_LAKE,
			SI_RARE_FISH_TRACKER_TYPE_FOUL
		}
	}
	RFT.typeSymbols = {
		[SI_RARE_FISH_TRACKER_TYPE_OCEAN] = zo_iconFormatInheritColor("RareFishTracker/art/ocean.dds", "110%", "110%"),
		[SI_RARE_FISH_TRACKER_TYPE_LAKE] = zo_iconFormatInheritColor("RareFishTracker/art/lake.dds", "110%", "110%"),
		[SI_RARE_FISH_TRACKER_TYPE_RIVER] = zo_iconFormatInheritColor("RareFishTracker/art/river.dds", "110%", "110%"),
		[SI_RARE_FISH_TRACKER_TYPE_FOUL] = zo_iconFormatInheritColor("RareFishTracker/art/foul.dds", "110%", "110%")
	}
end
