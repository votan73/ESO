local data = {
	name = "VotansFisherman",
	title = "Fisherman",
	lootTypes = {
		[0] = {
			-- Fishes
			-- Foul Water
			[42861] = {id = 1},
			[42862] = {id = 1},
			-- Lakes
			[42863] = {id = 3},
			[42864] = {id = 3},
			-- Rivers
			[42865] = {id = 2},
			[42866] = {id = 2},
			-- Oceans
			[42867] = {id = 4},
			[42868] = {id = 4},
			-- Baits
			[42873] = {id = 2},
			[42874] = {id = 3},
			[42875] = {id = 1},
			[42876] = {id = 4}
		},
		[980] = {
			[133561] = {id = 1},
			[133562] = {id = 1},
			[42875] = {id = 1}
		},
		[981] = {
			[133561] = {id = 1},
			[133562] = {id = 1},
			[42875] = {id = 1}
		}
	},
	ActionToLootType = {},
	InteractToLootType = {},
	TypeToSlotPreferSimple = {
		[1] = {3, 9, 1},
		[2] = {4, 6, 1},
		[3] = {2, 8, 1},
		[4] = {5, 7, 1}
	},
	TypeToSlotPreferBetter = {
		[1] = {9, 3, 1},
		[2] = {6, 4, 1},
		[3] = {8, 2, 1},
		[4] = {7, 5, 1}
	},
	LureColors = {true, true, true, true},
	LureColorDefaults = {true, true, true, true},
	iconNameToPath = {
		{
			["default"] = "esoui/art/treeicons/gamepad/achievement_categoryicon_fishing.dds",
			["bait"] = "esoui/art/inventory/gamepad/gp_inventory_icon_craftbag_fishing.dds",
			["builtin merringar"] = "esoui/art/icons/crafting_fishing_merringar.dds",
			["Rare Fish Tracker"] = "RareFishTracker/art/Foul.dds"
		},
		{
			["default"] = "esoui/art/treeicons/gamepad/achievement_categoryicon_fishing.dds",
			["bait"] = "esoui/art/inventory/gamepad/gp_inventory_icon_craftbag_fishing.dds",
			["builtin salmon"] = "esoui/art/icons/crafting_fishing_salmon.dds",
			["Rare Fish Tracker"] = "RareFishTracker/art/River.dds"
		},
		{
			["default"] = "esoui/art/treeicons/gamepad/achievement_categoryicon_fishing.dds",
			["bait"] = "esoui/art/inventory/gamepad/gp_inventory_icon_craftbag_fishing.dds",
			["builtin perch"] = "esoui/art/icons/crafting_fishing_perch.dds",
			["Rare Fish Tracker"] = "RareFishTracker/art/Lake.dds"
		},
		{
			["default"] = "esoui/art/treeicons/gamepad/achievement_categoryicon_fishing.dds",
			["bait"] = "esoui/art/inventory/gamepad/gp_inventory_icon_craftbag_fishing.dds",
			["builtin longfin"] = "esoui/art/icons/crafting_fishing_longfin.dds",
			["Rare Fish Tracker"] = "RareFishTracker/art/Ocean.dds"
		}
	},
	Caught = {},
	Zones = {},
	pinType = "VotansFishermanPinType",
	pinTypeId = 0,
	layout = 0,
	inDialog = false,
	fishing = false,
	reelInTimeout = "FishermanReelInTimeout",
	reelInColor = true,
	reelInColorDefault = true,
	DrawPinIdentifier1 = "VOTANFISHERMAN_DRAWPIN1",
	DrawPinIdentifier2 = "VOTANFISHERMAN_DRAWPIN2",
	mapZoneIndex_100011_100012 = {
		[10] = -1,
		[11] = 10,
		[12] = 11,
		[13] = 12,
		[14] = 13,
		[15] = 14,
		[16] = 15,
		[17] = 16,
		[18] = 17,
		[19] = 18,
		[20] = 19,
		[21] = 20,
		[22] = 21,
		[23] = 22,
		[24] = 23,
		[25] = 24,
		[26] = 25,
		[27] = 26,
		[28] = 27,
		[29] = 28,
		[30] = 29,
		[31] = 30,
		[32] = 31,
		[33] = 32,
		[34] = 33,
		[35] = 34,
		[36] = 35,
		[38] = 37,
		[39] = 38,
		[40] = 39,
		[41] = 40,
		[42] = 41,
		[43] = 42,
		[44] = 43,
		[45] = 44,
		[46] = 45,
		[47] = 46,
		[48] = 47,
		[49] = 48,
		[50] = 49,
		[52] = 51,
		[53] = 52,
		[54] = 53,
		[55] = 54,
		[56] = 55,
		[57] = 56,
		[58] = 57,
		[59] = 58,
		[60] = 59,
		[61] = 60,
		[62] = 61,
		[63] = 62,
		[64] = 63,
		[66] = 65,
		[67] = 66,
		[68] = 67,
		[69] = 68,
		[70] = 69,
		[71] = 70,
		[72] = 71,
		[73] = 72,
		[74] = 73,
		[75] = 74,
		[76] = 75,
		[77] = 76,
		[78] = 77,
		[79] = 78,
		[80] = 79,
		[81] = 80,
		[82] = 81,
		[83] = 82,
		[84] = 83,
		[85] = 84,
		[86] = 85,
		[87] = 86,
		[88] = 87,
		[89] = 88,
		[90] = 89,
		[91] = 90,
		[92] = 91,
		[93] = 92,
		[94] = 93,
		[95] = 94,
		[96] = 95,
		[97] = 96,
		[98] = 97,
		[99] = 98,
		[100] = 99,
		[101] = 100,
		[102] = 101,
		[103] = 102,
		[104] = 103,
		[105] = 104,
		[106] = 105,
		[107] = 106,
		[108] = 107,
		[109] = 108,
		[110] = 109,
		[111] = 110,
		[112] = 111,
		[113] = 112,
		[114] = 113,
		[115] = 114,
		[116] = 115,
		[117] = 116,
		[118] = 117,
		[119] = 118,
		[120] = 119,
		[121] = 120,
		[122] = 121,
		[123] = 122,
		[124] = 123,
		[125] = 124,
		[126] = 125,
		[127] = 126,
		[128] = 127,
		[129] = 128,
		[130] = 129,
		[131] = 130,
		[132] = 131,
		[133] = 132,
		[134] = 133,
		[135] = 134,
		[136] = 135,
		[137] = 136,
		[138] = 137,
		[139] = 138,
		[140] = 139,
		[141] = 140,
		[142] = 141,
		[143] = 142,
		[144] = 143,
		[145] = 144,
		[146] = 145,
		[147] = 146,
		[148] = 147,
		[149] = 148,
		[150] = 149,
		[151] = 150,
		[152] = 151,
		[153] = 152,
		[154] = 153,
		[155] = 154,
		[156] = 155,
		[157] = 156,
		[158] = 157,
		[159] = 158,
		[160] = 159,
		[161] = 160,
		[162] = 161,
		[163] = 162,
		[164] = 163,
		[165] = 164,
		[166] = 165,
		[167] = 166,
		[168] = 167,
		[169] = 168,
		[170] = 169,
		[171] = 170,
		[172] = 171,
		[173] = 172,
		[174] = 173,
		[175] = 174,
		[176] = 175,
		[177] = 176,
		[178] = 177,
		[179] = 178,
		[180] = 179,
		[181] = 180,
		[182] = 181,
		[183] = 182,
		[184] = 183,
		[185] = 184,
		[186] = 185,
		[187] = 186,
		[188] = 187,
		[189] = 188,
		[190] = 189,
		[191] = 190,
		[192] = 191,
		[193] = 192,
		[194] = 193,
		[195] = 194,
		[196] = 195,
		[197] = 196,
		[198] = 197,
		[199] = 198,
		[200] = 199,
		[201] = 200,
		[202] = 201,
		[203] = 202,
		[204] = 203,
		[205] = 204,
		[206] = 205,
		[209] = 208,
		[210] = 209,
		[211] = 210,
		[212] = 211,
		[213] = 212,
		[214] = 213,
		[215] = 214,
		[216] = 215,
		[217] = 216,
		[218] = 217,
		[219] = 218,
		[220] = 219,
		[221] = 220,
		[222] = 221,
		[223] = 222,
		[224] = 223,
		[225] = 224,
		[226] = 225,
		[227] = 226,
		[228] = 227,
		[229] = 228,
		[230] = 229,
		[231] = 230,
		[232] = 231,
		[233] = 232,
		[234] = 233,
		[235] = 234,
		[236] = 235,
		[237] = 236,
		[238] = 237,
		[239] = 238,
		[240] = 239,
		[241] = 240,
		[242] = 241,
		[243] = 242,
		[244] = 243,
		[245] = 244,
		[246] = 245,
		[247] = 246,
		[248] = 247,
		[249] = 248,
		[250] = 249,
		[251] = 250,
		[252] = 251,
		[253] = 252,
		[254] = 253,
		[255] = 254,
		[256] = 255,
		[257] = 256,
		[258] = 257,
		[259] = 258,
		[260] = 259,
		[261] = 260,
		[262] = 261,
		[263] = 262,
		[264] = 263,
		[265] = 264,
		[266] = 265,
		[267] = 266,
		[268] = 267,
		[269] = 268,
		[270] = 269,
		[271] = 270,
		[272] = 271,
		[273] = 272,
		[274] = 273,
		[275] = 274,
		[276] = 275,
		[277] = 276,
		[278] = 277,
		[279] = 278,
		[280] = 279,
		[281] = 280,
		[282] = 281,
		[283] = 282,
		[284] = 283,
		[285] = 284,
		[286] = 285,
		[287] = 286,
		[288] = 287,
		[289] = 288,
		[290] = 289,
		[291] = 290,
		[292] = 291,
		[293] = 292,
		[294] = 293,
		[295] = 294,
		[296] = 295,
		[297] = 296,
		[298] = 297,
		[299] = 298,
		[300] = 299,
		[301] = 300,
		[302] = 301,
		[303] = 302,
		[304] = 303,
		[305] = 304,
		[306] = 305,
		[307] = 306,
		[308] = 307,
		[309] = 308,
		[310] = 309,
		[311] = 310,
		[312] = 311,
		[313] = 312,
		[314] = 313,
		[315] = 314,
		[316] = 315,
		[317] = 316,
		[318] = 317,
		[319] = 318,
		[320] = 319,
		[321] = 320,
		[322] = 321,
		[323] = 322,
		[324] = 323,
		[325] = 324,
		[326] = 325,
		[327] = 326,
		[328] = 327,
		[329] = 328,
		[330] = 329,
		[331] = 330,
		[332] = 331,
		[333] = 332,
		[334] = 333,
		[335] = 334,
		[390] = 393,
		[391] = 394,
		[392] = 395,
		[393] = 396,
		[394] = 398,
		[395] = -1,
		[396] = 399,
		[397] = 400,
		[398] = 401,
		[399] = 402,
		[400] = 403,
		[401] = 404,
		[402] = 405,
		[403] = 406,
		[404] = 407,
		[405] = 408,
		[406] = 409,
		[407] = 410,
		[408] = 411,
		[409] = 412,
		[410] = 413,
		[411] = 414,
		[412] = 415,
		[413] = 416,
		[414] = 417,
		[415] = 418,
		[416] = 419,
		[417] = 420,
		[418] = 421,
		[419] = 422,
		[420] = 423,
		[421] = 424,
		[422] = 425,
		[423] = 426,
		[424] = 427,
		[425] = 428,
		[426] = 429,
		[427] = 430,
		[428] = 431,
		[429] = 432,
		[430] = 433,
		[431] = 434,
		[432] = 435,
		[433] = 436,
		[434] = 437,
		[435] = 438,
		[436] = 439,
		[437] = 440,
		[438] = 441,
		[439] = 442,
		[440] = 443,
		[441] = 444,
		[442] = 445,
		[443] = 446,
		[444] = 447,
		[445] = 448,
		[446] = 449,
		[447] = 450,
		[448] = 451,
		[449] = 452,
		[450] = -1,
		[451] = 453,
		[452] = 454,
		[453] = 455,
		[454] = 456,
		[455] = 457,
		[456] = 458,
		[457] = 459,
		[458] = 460,
		[459] = 461,
		[460] = 462,
		[461] = 463,
		[462] = 464,
		[463] = 465,
		[464] = 466,
		[465] = 467,
		[466] = 468,
		[467] = 469,
		[468] = 470,
		[469] = 471,
		[470] = 472,
		[471] = 473,
		[472] = 474,
		[473] = 475,
		[474] = 476,
		[475] = 477,
		[476] = 478,
		[477] = 479,
		[478] = 480,
		[479] = 481,
		[480] = 482,
		[481] = 483
	},
	["mapZoneIndex_100012_100013"] = {
		[392] = 393,
		[393] = 394,
		[394] = 396,
		[395] = 397,
		[396] = 398,
		[397] = 399,
		[398] = 422,
		[399] = 424,
		[400] = 425,
		[401] = 426,
		[402] = 427,
		[403] = 428,
		[404] = 429,
		[405] = 430,
		[406] = 431,
		[407] = 432,
		[408] = 433,
		[409] = 434,
		[410] = 435,
		[411] = 436,
		[412] = 437,
		[413] = 438,
		[414] = 439,
		[415] = 440,
		[416] = 441,
		[417] = 442,
		[418] = 443,
		[419] = 444,
		[420] = 445,
		[421] = 446,
		[422] = 447,
		[423] = 448,
		[424] = 449,
		[425] = 450,
		[426] = 451,
		[427] = 452,
		[428] = 453,
		[429] = 454,
		[430] = 455,
		[431] = 456,
		[432] = 457,
		[433] = 458,
		[434] = 459,
		[435] = 460,
		[436] = 461,
		[437] = 462,
		[438] = 463,
		[439] = 464,
		[440] = -1,
		[441] = 465,
		[442] = 466,
		[443] = 467,
		[444] = 468,
		[445] = 469,
		[446] = 470,
		[447] = 471,
		[448] = 472,
		[449] = 473,
		[450] = 474,
		[451] = 475,
		[452] = 476,
		[453] = 478,
		[454] = 479,
		[455] = 480,
		[456] = 481,
		[457] = 482,
		[458] = 483,
		[459] = 484,
		[460] = 485,
		[461] = 486,
		[462] = 487,
		[463] = 488,
		[464] = 489,
		[465] = 490,
		[466] = 491,
		[467] = 492,
		[468] = 493,
		[469] = 494,
		[470] = 495,
		[471] = 496,
		[472] = 497,
		[473] = 498,
		[474] = 499,
		[475] = 500,
		[476] = 501,
		[477] = 502,
		[478] = 503,
		[479] = 504,
		[480] = 505,
		[481] = 506,
		[482] = 507,
		[483] = 508,
		[484] = 509,
		[485] = 510,
		[486] = -1,
		[487] = -1,
		[488] = -1,
		[489] = -1,
		[490] = -1,
		[491] = -1
	},
	["mapZoneIndex_100013_100014"] = {
		[1] = 2,
		[2] = 3,
		[3] = 11,
		[4] = 19,
		[5] = 20,
		[6] = 22,
		[7] = 31,
		[8] = 38,
		[9] = 41,
		[10] = 57,
		[11] = 58,
		[12] = 63,
		[13] = 64,
		[14] = 92,
		[15] = 101,
		[16] = 103,
		[17] = 104,
		[18] = 108,
		[19] = 117,
		[20] = 124,
		[21] = 126,
		[22] = 130,
		[23] = 131,
		[24] = 134,
		[25] = 137,
		[26] = 138,
		[27] = 142,
		[28] = 144,
		[29] = 146,
		[30] = 148,
		[31] = 159,
		[32] = 162,
		[33] = 166,
		[34] = 168,
		[35] = 169,
		[37] = 181,
		[38] = 187,
		[39] = 188,
		[40] = 189,
		[41] = 190,
		[42] = 191,
		[43] = 192,
		[44] = 193,
		[45] = 199,
		[46] = 200,
		[47] = 201,
		[48] = 203,
		[49] = 207,
		[51] = 209,
		[52] = 212,
		[53] = 213,
		[54] = 214,
		[55] = 215,
		[56] = 216,
		[57] = 217,
		[58] = 218,
		[59] = 219,
		[60] = 222,
		[61] = 223,
		[62] = 224,
		[63] = 227,
		[65] = 229,
		[66] = 231,
		[67] = 232,
		[68] = 233,
		[69] = 234,
		[70] = 235,
		[71] = 236,
		[72] = 237,
		[73] = 238,
		[74] = 239,
		[75] = 241,
		[76] = 242,
		[77] = 243,
		[78] = 245,
		[79] = 246,
		[80] = 247,
		[81] = 248,
		[82] = 249,
		[83] = 250,
		[84] = 252,
		[85] = 253,
		[86] = 254,
		[87] = 255,
		[88] = 256,
		[89] = 257,
		[90] = 258,
		[91] = 259,
		[92] = 260,
		[93] = 261,
		[94] = 262,
		[95] = 263,
		[96] = 264,
		[97] = 265,
		[98] = 266,
		[99] = 267,
		[100] = 268,
		[101] = 269,
		[102] = 270,
		[103] = 271,
		[104] = 272,
		[105] = 273,
		[106] = 274,
		[107] = 275,
		[108] = 279,
		[109] = 280,
		[110] = 281,
		[111] = 283,
		[112] = 284,
		[113] = 287,
		[114] = 288,
		[115] = 289,
		[116] = 290,
		[117] = 291,
		[118] = 296,
		[119] = 306,
		[120] = 308,
		[121] = 309,
		[122] = 310,
		[123] = 311,
		[124] = 312,
		[125] = 313,
		[126] = 314,
		[127] = 315,
		[128] = 316,
		[129] = 317,
		[130] = 318,
		[131] = 319,
		[132] = 320,
		[133] = 321,
		[134] = 322,
		[135] = 323,
		[136] = 324,
		[137] = 325,
		[138] = 326,
		[139] = 327,
		[140] = 328,
		[141] = 329,
		[142] = 330,
		[143] = 331,
		[144] = 332,
		[145] = 333,
		[146] = 334,
		[147] = 335,
		[148] = 336,
		[149] = 337,
		[150] = 338,
		[151] = 339,
		[152] = 341,
		[153] = 346,
		[154] = 347,
		[155] = 353,
		[156] = 354,
		[157] = 359,
		[158] = 360,
		[159] = 361,
		[160] = 362,
		[161] = 363,
		[162] = 364,
		[163] = 365,
		[164] = 366,
		[165] = 367,
		[166] = 368,
		[167] = 369,
		[168] = 370,
		[169] = 371,
		[170] = 372,
		[171] = 374,
		[172] = 375,
		[173] = 376,
		[174] = 377,
		[175] = 378,
		[176] = 379,
		[177] = 380,
		[178] = 381,
		[179] = 382,
		[180] = 383,
		[181] = 385,
		[182] = 386,
		[183] = 387,
		[184] = 388,
		[185] = 389,
		[186] = 390,
		[187] = 392,
		[188] = 393,
		[189] = 394,
		[190] = 395,
		[191] = 396,
		[192] = 397,
		[193] = 398,
		[194] = 399,
		[195] = 400,
		[196] = 401,
		[197] = 402,
		[198] = 403,
		[199] = 404,
		[200] = 405,
		[201] = 406,
		[202] = 407,
		[203] = 408,
		[204] = 409,
		[205] = 410,
		[208] = 413,
		[209] = 414,
		[210] = 415,
		[211] = 416,
		[212] = 417,
		[213] = 418,
		[214] = 419,
		[215] = 420,
		[216] = 421,
		[217] = 422,
		[218] = 424,
		[219] = 425,
		[220] = 426,
		[221] = 429,
		[222] = 430,
		[223] = 431,
		[224] = 433,
		[225] = 434,
		[226] = 435,
		[227] = 436,
		[228] = 437,
		[229] = 438,
		[230] = 439,
		[231] = 440,
		[232] = 442,
		[233] = 444,
		[234] = 447,
		[235] = 449,
		[236] = 451,
		[237] = 452,
		[238] = 453,
		[239] = 454,
		[240] = 455,
		[241] = 456,
		[242] = 457,
		[243] = 458,
		[244] = 459,
		[245] = 460,
		[246] = 461,
		[247] = 462,
		[248] = 463,
		[249] = 464,
		[250] = 465,
		[251] = 466,
		[252] = 467,
		[253] = 468,
		[254] = 469,
		[255] = 470,
		[256] = 471,
		[257] = 472,
		[258] = 473,
		[259] = 475,
		[260] = 477,
		[261] = 478,
		[262] = 480,
		[263] = 481,
		[264] = 482,
		[265] = 484,
		[266] = 485,
		[267] = 486,
		[268] = 487,
		[269] = 492,
		[270] = 493,
		[271] = 494,
		[272] = 495,
		[273] = 496,
		[274] = 497,
		[275] = 498,
		[276] = 499,
		[277] = 500,
		[278] = 501,
		[279] = 502,
		[280] = 503,
		[281] = 504,
		[282] = 505,
		[283] = 506,
		[284] = 507,
		[285] = 526,
		[286] = 527,
		[287] = 529,
		[288] = 530,
		[289] = 531,
		[290] = 532,
		[291] = 533,
		[292] = 534,
		[293] = 535,
		[294] = 537,
		[295] = 539,
		[296] = 541,
		[297] = 542,
		[298] = 543,
		[299] = 544,
		[300] = 545,
		[301] = 546,
		[302] = 547,
		[303] = 548,
		[304] = 549,
		[305] = 551,
		[306] = 552,
		[307] = 553,
		[308] = 554,
		[309] = 555,
		[310] = 556,
		[311] = 557,
		[312] = 558,
		[313] = 559,
		[314] = 560,
		[315] = 561,
		[316] = 562,
		[317] = 565,
		[318] = 566,
		[319] = 567,
		[320] = 568,
		[321] = 569,
		[322] = 570,
		[323] = 571,
		[324] = 572,
		[325] = 573,
		[326] = 574,
		[327] = 575,
		[328] = 576,
		[329] = 577,
		[330] = 578,
		[331] = 579,
		[332] = 580,
		[334] = 582,
		[335] = 584,
		[336] = 585,
		[338] = 587,
		[340] = 589,
		[341] = 590,
		[342] = 591,
		[343] = 592,
		[344] = 593,
		[345] = 594,
		[346] = 595,
		[348] = 597,
		[349] = 598,
		[350] = 599,
		[351] = 600,
		[352] = 601,
		[353] = 603,
		[354] = 604,
		[355] = 605,
		[356] = 606,
		[357] = 607,
		[358] = 608,
		[359] = 609,
		[360] = 611,
		[361] = 612,
		[362] = 613,
		[363] = 614,
		[364] = 615,
		[365] = 616,
		[366] = 617,
		[367] = 618,
		[368] = 619,
		[369] = 620,
		[370] = 621,
		[371] = 622,
		[372] = 623,
		[373] = 624,
		[374] = 625,
		[375] = 626,
		[376] = 628,
		[377] = 629,
		[378] = 630,
		[379] = 631,
		[380] = 632,
		[381] = 634,
		[382] = 635,
		[383] = 636,
		[384] = 637,
		[385] = 638,
		[386] = 639,
		[387] = 640,
		[388] = 641,
		[389] = 642,
		[390] = 643,
		[391] = 649,
		[393] = 678,
		[394] = 681,
		[395] = 684,
		[396] = 685,
		[397] = 686,
		[398] = 687,
		[399] = 688,
		[400] = 689,
		[401] = 691,
		[402] = 692,
		[403] = 693,
		[404] = 694,
		[405] = 695,
		[406] = 697,
		[407] = 698,
		[408] = 699,
		[409] = 700,
		[410] = 701,
		[411] = 702,
		[412] = 703,
		[413] = 704,
		[414] = 705,
		[415] = 706,
		[416] = 707,
		[417] = 708,
		[418] = 710,
		[419] = 711,
		[420] = 712,
		[421] = 715,
		[422] = 723,
		[423] = 724,
		[424] = 726,
		[425] = 727,
		[426] = 728,
		[427] = 729,
		[428] = 730,
		[429] = 731,
		[430] = 732,
		[431] = 733,
		[432] = 734,
		[433] = 735,
		[434] = 736,
		[435] = 737,
		[436] = 738,
		[437] = 739,
		[438] = 740,
		[439] = 741,
		[440] = 742,
		[441] = 743,
		[442] = 744,
		[443] = 745,
		[444] = 746,
		[445] = 747,
		[446] = 748,
		[447] = 749,
		[448] = 750,
		[449] = 751,
		[450] = 752,
		[451] = 753,
		[452] = 754,
		[453] = 755,
		[454] = 756,
		[455] = 757,
		[456] = 758,
		[457] = 759,
		[458] = 760,
		[459] = 761,
		[460] = 762,
		[461] = -1,
		[462] = -1,
		[463] = 765,
		[464] = -1,
		[465] = 768,
		[466] = -1,
		[467] = -1,
		[468] = -1,
		[469] = -1,
		[470] = 773,
		[471] = 774,
		[472] = 775,
		[473] = 776,
		[474] = 777,
		[475] = 778,
		[476] = 779,
		[477] = 780,
		[478] = 781,
		[479] = 782,
		[480] = 783,
		[481] = 784,
		[482] = 785,
		[483] = 786,
		[484] = 787,
		[485] = 788,
		[486] = 789,
		[487] = 790,
		[488] = 791,
		[489] = 792,
		[490] = 793,
		[491] = 794,
		[492] = 795,
		[493] = 796,
		[494] = 797,
		[495] = 798,
		[496] = 799,
		[497] = 800,
		[498] = 801,
		[499] = 802,
		[500] = 803,
		[501] = 804,
		[502] = 805,
		[503] = 806,
		[504] = 807,
		[505] = 808,
		[506] = 809,
		[507] = 810,
		[508] = 811,
		[509] = 812,
		[510] = 813,
		[511] = 814,
		[512] = 815
	}
}

local em = GetEventManager()
local math = math
local table = table
local gps

local lastAction = ""
local zoneToLure
local zoneStats
local lure
local lureLast
local interactionReady = false

local measureReady = false
local focusRadius = 10.5 / 10000
local measureCount = 3

local lureToPin = {}

local function GetZone()
	return GetZoneId(GetUnitZoneIndex("player"))
end

function data:GetLootTypes(zoneId)
	return self.lootTypes[zoneId or GetZone()] or self.lootTypes[0]
end

function data:GetZoneToLure()
	return zoneToLure
end

---- Reel In ----
local disabledColor = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED))

local currentBaitName
local currentBaitCount
local function CountCurrentBait()
	local lure = GetFishingLure()
	if lure then
		return select(3, GetFishingLureInfo(lure))
	end
	return 0
end

local function StopReelIn()
	data.reelInAnim:Stop()
	em:UnregisterForUpdate(data.reelInTimeout)
	em:UnregisterForEvent(data.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
end

local AddStats

-- Use OnLootReceived then we don't have to worry about
-- other types of single slot updates
local function OnLootReceived(eventCode, receivedBy, itemLink)
	if receivedBy ~= data.unitName then
		return
	end

	StopReelIn()
	local itemType = GetItemLinkItemType(itemLink)
	if itemType == ITEMTYPE_LURE or itemType == ITEMTYPE_CONTAINER or itemType == ITEMTYPE_COLLECTIBLE or itemType == ITEMTYPE_FISH then
		local itemId = GetItemLinkItemId(itemLink)
		local lootType = data:GetLootTypes()[itemId]
		if lootType then
			local needUpdate = next(lure.lureType) == nil
			lure.lureType[lootType.id] = true
			if needUpdate then
				local pin = lureToPin[lure]
				if pin then
					pin:SetData(data.pinTypeId, pin.m_PinTag)
				else
					data:RefreshPins()
				end
			end
		end
		if itemType ~= ITEMTYPE_LURE or lootType then
			data.Caught[itemId] = itemLink
			lure.caught[itemId] = true
			AddStats(itemId)
		end
		lastAction = ""
	end
end

local function Notify()
	em:UnregisterForUpdate(data.reelInTimeout, Notify)
	if data.settings.showReelIn then
		data.reelIn:SetAlpha(1)
		data.reelIn:SetHidden(false)
		data.reelIn:SetColor(data.reelInColor:UnpackRGB())
		data.reelInAnim:PlayFromStart()
		em:RegisterForUpdate(data.reelInTimeout, 3000, StopReelIn)
	end
	PlaySound(SOUNDS[data.settings.notificationSound])
end

local function SlotUpdate(event, bagId, slotIndex, isNew)
	if lure == nil then
		return
	end
	if bagId ~= BAG_BACKPACK and bagId ~= BAG_VIRTUAL then
		return
	end

	local count = CountCurrentBait()

	if not isNew and (currentBaitCount - count) == 1 then
		-- Loosing one of the current selected baits
		if data.settings.autoReturnInteraction then
			if SCENE_MANAGER:IsInUIMode() and not SCENE_MANAGER:IsLockedInUIMode() and not IsUserAdjustingClientWindow() then
				SCENE_MANAGER:SetInUIMode(false)
			end
			if data.inDialog then
				SCENE_MANAGER:ShowBaseScene()
				data.inDialog = false
			end
		end

		if not data.inDialog then
			em:RegisterForUpdate(data.reelInTimeout, 250, Notify)
		end
	end
	currentBaitCount = count
end
---- End Reel In ----

local function ActionLayerChanged(event, layerIndex, activeLayerIndex)
	data.inDialog = not HUD_SCENE:IsShowing()
end

local function CleanUp()
	for zoneIndex, map in pairs(zoneToLure) do
		if next(map) == nil then
			zoneToLure[zoneIndex] = nil
		end
	end
end

do
	local id = GetCurrentCharacterId()
	AddStats = function(itemId)
		local mapZone = GetZone()
		local map = zoneStats[mapZone]
		if not map then
			map = {}
			zoneStats[mapZone] = map
		end
		local stats = map.stats or {}
		local char = stats[id]
		if not char then
			char = {}
			stats[id] = char
		end
		local count = char[itemId] or 0
		count = count + 1
		char[itemId] = count
		map.stats = stats
	end
end

local GetFocusRange
do
	local LMP = LibMapPing
	local x0, y0 = -1500000, -1500000
	local x1, y1 = 1500000, 1500000
	local state

	local function OnBeforeMapPing(pinType)
		if pinType == MAP_PIN_TYPE_PLAYER_WAYPOINT then
			if state > 0 then
				LMP:UnsuppressPing(MAP_PIN_TYPE_PLAYER_WAYPOINT)
			end
		end
	end

	local function OnAfterMapPing(pinType)
		if pinType == MAP_PIN_TYPE_PLAYER_WAYPOINT then
			if state > 0 then
				LMP:UnmutePing(MAP_PIN_TYPE_PLAYER_WAYPOINT)
			end
			state = state - 1
			if state <= 0 then
				LMP:UnregisterCallback("BeforePingAdded", OnBeforeMapPing)
				LMP:UnregisterCallback("AfterPingAdded", OnAfterMapPing)
				LMP:UnregisterCallback("AfterPingRemoved", OnAfterMapPing)
			end
		end
	end

	function GetFocusRange()
		local zone = GetZone()
		local measuredFocus = gps:GetGlobalWorldRatio()
		measuredFocus = measuredFocus * focusRadius

		local focusRadius = measuredFocus or focusRadius
		local searchRadius = focusRadius * 1.10
		local updateRadiusMin = focusRadius * 0.10
		return focusRadius, searchRadius, updateRadiusMin
	end
end

local function RestartMeasurementNearby()
	local mapZone = GetZone()
	local map = zoneToLure[mapZone]
	if map == nil then
		return
	end

	local playerX, playerY = gps:LocalToGlobal(GetMapPlayerPosition("player"))
	local sqrt = math.sqrt
	local radius = GetFocusRange() * 1.25
	for _, lure in pairs(map) do
		local dx = lure.x - playerX
		local dy = lure.y - playerY
		local distance = sqrt(dx * dx + dy * dy)
		if distance <= radius then
			lure.count = 0
			lure.px = nil
			lure.py = nil
		end
	end
	lastAction = ""
end

local function ClearNearbyCaughtLists()
	local mapZone = GetZone()
	local map = zoneToLure[mapZone]
	if map == nil then
		return
	end

	local playerX, playerY = gps:LocalToGlobal(GetMapPlayerPosition("player"))
	local sqrt = math.sqrt
	local radius = GetFocusRange() * 1.25
	for _, lure in pairs(map) do
		local dx = lure.x - playerX
		local dy = lure.y - playerY
		local distance = sqrt(dx * dx + dy * dy)
		if distance <= radius then
			lure.caught = {}
		end
	end
	lastAction = ""
end

local function EraseNearbyFishingHoles()
	local mapZone = GetZone()
	local map = zoneToLure[mapZone]
	if map == nil then
		return
	end

	local playerX, playerY = gps:LocalToGlobal(GetMapPlayerPosition("player"))
	local sqrt = math.sqrt
	local radius = GetFocusRange() * 1.25
	for timeStamp, lure in pairs(map) do
		local dx = lure.x - playerX
		local dy = lure.y - playerY
		local distance = sqrt(dx * dx + dy * dy)
		if distance <= radius then
			map[timeStamp] = nil
		end
	end
	lastAction = ""
	data:RefreshPins()
end

local function MergeFishingHolesAtPosition(playerX, playerY, range)
	local mapZone = GetZone()
	local map = zoneToLure[mapZone]
	if map == nil then
		return
	end
	local sqrt, round = math.sqrt, math.floor

	local dx, dy, distance
	local radius = GetFocusRange() * range
	for _, lure in pairs(map) do
		dx, dy = lure.x - playerX, lure.y - playerY
		distance = sqrt(dx * dx + dy * dy)
		if distance <= radius then
			for timeStamp, lure2 in pairs(map) do
				if lure2 ~= lure then
					dx, dy = lure2.x - lure.x, lure2.y - lure.y
					distance = sqrt(dx * dx + dy * dy)
					if distance <= radius then
						for type in pairs(lure2.lureType) do
							lure.lureType[type] = true
						end
						for type in pairs(lure2.caught) do
							lure.caught[type] = true
						end
						map[timeStamp] = nil
						lure.count = 0
						lure.x = (lure.x + lure2.x) / 2
						lure.y = (lure.y + lure2.y) / 2
					end
				end
			end
		end
	end
	data:RefreshPins()
end

local function MergeFishingHoles(range)
	local playerX, playerY = gps:LocalToGlobal(GetMapPlayerPosition("player"))
	MergeFishingHolesAtPosition(playerX, playerY, range)
	lastAction = ""
end

local mapZone = nil
local lastHeading = -1
local currentFilter = ""

local function WaitForLibGPS(measuring)
	if measuring then
		ZO_WorldMap_SetCustomPinEnabled(data.pinTypeId, false)
	else
		measureReady = true
		ZO_WorldMap_SetCustomPinEnabled(data.pinTypeId, data.player.showPins[currentFilter] ~= false)
		data:RefreshPins()
	end
end

local function AddFilter()
	local panelToFilter = {}

	local orgGetPinFilter = ZO_WorldMapFilterPanel_Shared.GetPinFilter
	function ZO_WorldMapFilterPanel_Shared.GetPinFilter(...)
		local current, mapPinGroup = ...
		if mapPinGroup == data.pinTypeId then
			return data.player.showPins[panelToFilter[current]]
		else
			return orgGetPinFilter(...)
		end
	end
	local orgSetPinFilter = ZO_WorldMapFilterPanel_Shared.SetPinFilter
	function ZO_WorldMapFilterPanel_Shared.SetPinFilter(...)
		local current, mapPinGroup, shown = ...
		if mapPinGroup == data.pinTypeId then
			data.player.showPins[panelToFilter[current]] = shown
			if not gps:IsMeasuring() and panelToFilter[current] == currentFilter then
				ZO_WorldMap_SetCustomPinEnabled(data.pinTypeId, shown)
				data:RefreshPins()
			end
		else
			return orgSetPinFilter(...)
		end
	end

	local function FilterCallback()
	end
	local function AddCheckBox(panel, filter)
		panelToFilter[panel] = filter
		panel:AddPinFilterCheckBox(data.pinTypeId, FilterCallback, GetString(SI_FISHERMAN))
	end
	local self = WORLD_MAP_FILTERS
	AddCheckBox(self.pvePanel, "pve")
	AddCheckBox(self.pvpPanel, "pvp")
	AddCheckBox(self.imperialPvPPanel, "imperialPvP")
	AddCheckBox(self.battlegroundPanel, "battleground")
	local self = GAMEPAD_WORLD_MAP_FILTERS
	AddCheckBox(self.pvePanel, "pve")
	AddCheckBox(self.pvpPanel, "pvp")
	AddCheckBox(self.imperialPvPPanel, "imperialPvP")
	AddCheckBox(self.battlegroundPanel, "battleground")

	local function OnMapChanged()
		local filters = (IsInGamepadPreferredMode() and GAMEPAD_WORLD_MAP_FILTERS or WORLD_MAP_FILTERS).currentPanel
		currentFilter = panelToFilter[filters]
		WORLD_MAP_FILTERS.currentPanel:SetPinFilter(data.pinTypeId, data.player.showPins[currentFilter] ~= false)
		GAMEPAD_WORLD_MAP_FILTERS.currentPanel:SetPinFilter(data.pinTypeId, data.player.showPins[currentFilter] ~= false)
	end
	OnMapChanged()
	CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", OnMapChanged)
end

local function PlayerActivated()
	lastAction = ""
	lure = nil
end

local function OnFyrMiniNewMapEntered()
	data:RefreshPins()
end

local function PlayerActivatedFirstTime()
	em:UnregisterForEvent(data.name, EVENT_PLAYER_ACTIVATED)

	CleanUp()
	data.unitName = GetRawUnitName("player")

	CALLBACK_MANAGER:RegisterCallback(gps.LIB_EVENT_STATE_CHANGED, WaitForLibGPS)
	em:RegisterForEvent(data.name, EVENT_PLAYER_ACTIVATED, PlayerActivated)

	AddFilter()

	CALLBACK_MANAGER:RegisterCallback("OnFyrMiniNewMapEntered", OnFyrMiniNewMapEntered)

	if gps:GetCurrentMapMeasurement() ~= nil then
		WaitForLibGPS(false)
	end
	PlayerActivated()
	zo_callLater(
		function()
			interactionReady = true
		end,
		1000
	)
end

do
	local createLink = string.format
	function data:CreateRareCaughtLink(id)
		local itemLink = self.Caught[id]
		if not itemLink then
			itemLink = createLink("|H0:item:%i:25:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", id)
			self.Caught[id] = itemLink
		end
		assert(itemLink ~= nil)
		return itemLink
	end
	function data:CreateDefaultCaughtLink(id)
		local itemLink = self.Caught[id]
		if not itemLink then
			itemLink = createLink("|H0:item:%i:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", id)
			self.Caught[id] = itemLink
		end
		assert(itemLink ~= nil)
		return itemLink
	end
end
local function ShowCaught(lure, showLoot, showDebug)
	local caught = {}
	local format, createLink = ZO_CachedStrFormat, string.format
	if showLoot then
		local itemLink
		local GetItemLinkName, SI_TOOLTIP_ITEM_NAME = GetItemLinkName, SI_TOOLTIP_ITEM_NAME
		for id in pairs(lure.caught) do
			itemLink = data:CreateRareCaughtLink(id)
			caught[#caught + 1] = createLink("|H0:item:%i:25:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h%s|h", id, format(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(itemLink)))
		end
		if data.settings.showDefaultLoot then
			local zoneId = GetZoneId(GetCurrentMapZoneIndex())
			if zoneId then
				for id, info in pairs(data:GetLootTypes(zoneId)) do
					if not lure.caught[id] and lure.lureType[info.id] then
						itemLink = data:CreateDefaultCaughtLink(id)
						caught[#caught + 1] = disabledColor:Colorize(format(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(itemLink)))
					end
				end
			end
		end
		table.sort(caught)
	end
	if showDebug and lure then
		local x, y = gps:GlobalToLocal(lure.x, lure.y)
		caught[#caught + 1] = createLink("gps: %.2fx%.2f map: %.2fx%.2f (%.0f%%)", lure.x * 100, lure.y * 100, x * 100, y * 100, math.min(lure.count or 0, measureCount) * 100 / measureCount)
	end
	return table.concat(caught, "\n")
end

local function Intersection(x1, y1, x2, y2, x3, y3, x4, y4)
	local t
	local dx, dy = x4 - x3, y4 - y3
	if dy ~= 0 and math.abs(dx) < math.abs(dy) then
		t = (y1 - y3) / dy
	elseif dx ~= 0 then
		t = (x1 - x3) / dx
	else
		return
	end
	if t < -0.0125 or t > 0.98 then
		return
	end

	local q = (dy * (x2 - x1)) - ((y2 - y1) * dx)
	if q > 1e-9 or q < -1e-9 then
		return ((dx * (x2 * y1 - x1 * y2)) - ((x2 - x1) * (x4 * y3 - x3 * y4))) / q, (((y1 - y2) * (x4 * y3 - x3 * y4)) - ((y3 - y4) * (x2 * y1 - x1 * y2))) / q
	end
	return nil
end

function data:RefreshPinOfLure(lure, x, y)
	local pin = lureToPin[lure]
	if pin then
		x, y = gps:GlobalToLocal(x, y)
		if x then
			pin.normalizedX, pin.normalizedY = x, y
			local _, tag = pin:GetPinTypeAndTag()
			if tag then
				tag.x, tag.y = x, y
				pin:UpdateLocation()
				return
			end
			self:RefreshPins()
		end
	end
end

local function UpdatePosition()
	if not IsPlayerMoving() then
		return
	end

	local count = lure.count or 0
	if count >= measureCount then
		return
	end
	if not lure.px then
		return
	end

	local playerX, playerY = gps:LocalToGlobal(GetMapPlayerPosition("player"))

	local heading = GetPlayerCameraHeading()
	local dx, dy = lure.x - playerX, lure.y - playerY
	local distance = math.sqrt(dx * dx + dy * dy)
	local focusRadius, searchRadius, updateRadiusMin = GetFocusRange()
	if distance > updateRadiusMin and (heading ~= lastHeading or distance > focusRadius) then
		dx, dy = lure.px - playerX, lure.py - playerY
		distance = math.sqrt(dx * dx + dy * dy)
		if distance < (updateRadiusMin * 4) then
			return
		end

		local headX, headY = -math.sin(heading) * focusRadius, -math.cos(heading) * focusRadius
		-- distance point in heading direction
		local mapX, mapY = playerX + headX, playerY + headY
		local xs, ys = Intersection(lure.px, lure.py, lure.mx, lure.my, playerX, playerY, mapX, mapY)
		if xs then
			dx, dy = xs - playerX, ys - playerY
			distance = math.sqrt(dx * dx + dy * dy)
			if distance < focusRadius then
				lastHeading = heading
				lure.x = xs
				lure.y = ys

				lure.count = count + 1
				if count >= measureCount then
					lure.px = nil
					lure.py = nil
					lure.mx = nil
					lure.my = nil
				else
					lure.px = playerX
					lure.py = playerY
					lure.mx = (xs + mapX) / 2
					lure.my = (ys + mapY) / 2
				end
				data:RefreshPinOfLure(lure, xs, ys)
			end
		end
		data.caughtInfo:SetText(ShowCaught(lure, data.settings.showLootOnHUD, data.settings.showDebug))
	end
end

local function GetZoneLures(mapZone)
	local map = zoneToLure[mapZone]
	if map == nil then
		map = {}
		zoneToLure[mapZone] = map
	end
	return map
end

local fishingInteractableName
local function FishingNode()
	mapZone = GetZone()
	if GetZoneId(GetCurrentMapZoneIndex()) ~= mapZone then
		if SetMapToPlayerLocation() == SET_MAP_RESULT_MAP_CHANGED then
			CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
		end
	end

	lure = nil

	local map = GetZoneLures(mapZone)
	local playerX, playerY = gps:LocalToGlobal(GetMapPlayerPosition("player"))

	local heading = GetPlayerCameraHeading()
	local focusRadius, searchRadius, updateRadiusMin = GetFocusRange()

	local headX, headY = math.sin(heading) * focusRadius, math.cos(heading) * focusRadius
	-- max focus point in heading direction
	local mapX, mapY = playerX - headX, playerY - headY

	focusRadius, searchRadius, updateRadiusMin = focusRadius * focusRadius, searchRadius * searchRadius, updateRadiusMin * updateRadiusMin
	local bestMatch = nil
	local bestMatchDistance = 64 * focusRadius
	local createNew = true
	local focusRadius4 = focusRadius / 4
	local pi, abs, atan2 = math.pi, math.abs, math.atan2

	local dx, dy, distance
	for _, other in pairs(map) do
		dx, dy = other.x - mapX, other.y - mapY
		distance = dx * dx + dy * dy

		if distance <= searchRadius then
			dx, dy = playerX - other.x, playerY - other.y
			distance = dx * dx + dy * dy
			if distance <= searchRadius then
				local alpha = atan2(dx, dy)
				if alpha < 0 then
					alpha = alpha + 2 * pi
				end
				alpha = abs(alpha - heading)
				if alpha > pi then
					alpha = 2 * pi - alpha
				end
				alpha = 1 - alpha / pi
				alpha = alpha * alpha
				alpha = alpha * alpha
				distance = distance * (32 - 31 * alpha)
				if distance < bestMatchDistance then
					bestMatch = other
					bestMatchDistance = distance
				end
			end
		end

		if other.px then
			dx, dy = other.px - mapX, other.py - mapY
			distance = dx * dx + dy * dy

			if distance <= focusRadius then
				dx = playerX - other.x
				dy = playerY - other.y
				distance = dx * dx + dy * dy
				if distance <= focusRadius4 then
					-- better than nothing. Choice Prio 2
					distance = distance * 31
					if distance < bestMatchDistance then
						bestMatch = other
						bestMatchDistance = distance
					end
				end
			end
		end
		dx, dy = other.x - playerX, other.y - playerY
		distance = dx * dx + dy * dy

		if distance <= focusRadius4 then
			-- better than nothing. Choice Prio 3
			distance = distance * 32
			if distance <= bestMatchDistance then
				bestMatch = other
				bestMatchDistance = distance
			end
		end

		-- 	dx, dy = other.x - playerX, other.y - playerY
		-- 	distance = dx * dx + dy * dy

		-- 	if distance <= updateRadiusMin then
		-- 		d("better do nothing")
		-- 		createNew = false
		-- 	end
	end

	if bestMatch ~= nil then
		lure = bestMatch
		local count = lure.count or 0
		if count < measureCount then
			if lure.px then
				-- ensure new position is good enough for triangulation
				dx, dy = lure.px - playerX, lure.py - playerY
				distance = dx * dx + dy * dy
				if distance > 4 * updateRadiusMin then
					dx, dy = lure.mx - playerX, lure.my - playerY
					distance = dx * dx + dy * dy
					if distance > focusRadius then
						local xs, ys = Intersection(lure.px, lure.py, lure.mx, lure.my, playerX, playerY, mapX, mapY)
						if xs then
							dx, dy = playerX - xs, playerY - ys
							distance = dx * dx + dy * dy
							if distance > updateRadiusMin and distance <= focusRadius then
								lure.x = xs
								lure.y = ys
								lure.px = playerX
								lure.py = playerY
								lure.mx = (xs + mapX) / 2
								lure.my = (ys + mapY) / 2
								count = count + 1
								data:RefreshPinOfLure(lure, xs, ys)
							end
						end
					end
				end
			else
				lure.px = playerX
				lure.py = playerY
				lure.mx = mapX
				lure.my = mapY
			end
			lure.count = count
		end
	else
		lure = nil
	end

	if lure == nil then
		if not createNew then
			return
		end
		lure = {lureType = {}, caught = {}, x = playerX - headX, y = playerY - headY, count = 0, px = playerX, py = playerY, mx = playerX - headX * 2, my = playerY - headY * 2}
		local timestamp = GetTimeStamp()
		map[timestamp] = lure
		data:RefreshPins()
	end

	if lure.lureType == nil then
		lure.lureType = {}
	end

	if not data.ActionToLootType[fishingInteractableName] then
		local typeText = ZO_CachedStrFormat("<<z:1>>", fishingInteractableName)
		for text, type in pairs(data.InteractToLootType) do
			if zo_plainstrfind(typeText, text) then
				data.ActionToLootType[fishingInteractableName] = type
				break
			end
		end
	end

	if next(lure.lureType) == nil and data.ActionToLootType[fishingInteractableName] then
		lure.lureType[data.ActionToLootType[fishingInteractableName]] = true
		data:RefreshPins()
	end
	local types = {}
	for type in pairs(lure.lureType) do
		types[#types + 1] = GetString("SI_FISHERMAN_INTERACT", type)
	end
	if #types > 0 then
		if #types == 1 and data.settings.autoSwitchBait then
			local stack = select(3, GetFishingLureInfo(GetFishingLure()))
			if lure ~= lureLast or stack <= 0 then
				local slots
				for type in pairs(lure.lureType) do
					lureLast = lure
					slots = data.TypeToSlot[type]
					for i = 1, #slots do
						stack = select(3, GetFishingLureInfo(slots[i]))
						if stack > 0 then
							SetFishingLure(slots[i])
							break
						end
					end
				end
			end
		end
	else
		if data.settings.autoSwitchBait then
			local stack = select(3, GetFishingLureInfo(GetFishingLure()))
			if lure ~= lureLast or stack <= 0 then
				local selected, max, lureLast = 0, 0, nil
				local typeText = RETICLE.interactContext:GetText()
				local type = data.ActionToLootType[typeText]
				if type then
					local slots, lureLast = data.TypeToSlot[type], lure
					for i = 1, #slots do
						stack = select(3, GetFishingLureInfo(slots[i]))
						if stack > 0 then
							selected = slots[i]
							break
						end
					end
				end
				SetFishingLure(selected)
			end
		end
	end
	data.caughtInfo:SetText(ShowCaught(lure, data.settings.showLootOnHUD, data.settings.showDebug))
	data.base:SetHidden(false)
end

local function StopFishing()
	if data.fishing then
		data.fishing = false
		em:UnregisterForEvent(data.name, EVENT_LOOT_RECEIVED)
		em:UnregisterForEvent(data.name, EVENT_LOOT_CLOSED)
		em:UnregisterForEvent(data.name, EVENT_ACTION_LAYER_POPPED)
		em:UnregisterForEvent(data.name, EVENT_ACTION_LAYER_PUSHED)
		StopReelIn()
	end
end

-- On loot window closed
local function OnLootClosed(eventCode)
	StopFishing()
end

local function StartFishing()
	local lureIndex = GetFishingLure()
	if lureIndex then
		StopReelIn()
		currentBaitName = GetFishingLureInfo(lureIndex)
		currentBaitCount = CountCurrentBait()
		em:RegisterForEvent(data.name, EVENT_LOOT_RECEIVED, OnLootReceived)
		em:RegisterForEvent(data.name, EVENT_LOOT_CLOSED, OnLootClosed)
		em:RegisterForEvent(data.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, SlotUpdate)
		em:RegisterForEvent(data.name, EVENT_ACTION_LAYER_POPPED, ActionLayerChanged)
		em:RegisterForEvent(data.name, EVENT_ACTION_LAYER_PUSHED, ActionLayerChanged)
		data.inDialog = false
		data.fishing = true
	end
end

---- Handle interaction ----
-- This is called on every frame, but if interaction HUD is visible, only!
local function NewInteraction()
	if not interactionReady then
		return
	end
	local action, interactableName, _, _, additionalInfo = GetGameCameraInteractableActionInfo()
	if action then
		if not measureReady then
			local mapZone = GetCurrentMapZoneIndex()
			measureReady = mapZone > 1 and mapZone < 2147483648
			if not measureReady then
				if SetMapToPlayerLocation() == SET_MAP_RESULT_MAP_CHANGED then
					CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
				end
			end
		end
		if lastAction == action then
			if lure and interactableName == fishingInteractableName then
				UpdatePosition()
			end
			return false
		end
		lastAction = action
		if additionalInfo == ADDITIONAL_INTERACT_INFO_FISHING_NODE then
			fishingInteractableName = interactableName
			FishingNode()
			if lure == nil then
				StopFishing()
			else
				local RFT = RFT
				if data.settings.autoHideRFT and RFT and RFT.window then
					if RFT.SetIsFishing then
						RFT:SetIsFishing(true)
					else
						RFT.window:SetHidden(false)
					end
				end
			end
		else
			local isNotFishing = not (interactableName == fishingInteractableName)
			if isNotFishing then
				StopFishing()
			else
				StartFishing()
			end
			data.base:SetHidden(isNotFishing)
		end
	else
		if lastAction == action then
			return false
		end
		lastAction = action
		data.base:SetHidden(true)
		if data.settings.autoHideRFT and RFT and RFT.window then
			if RFT.SetIsFishing then
				RFT:SetIsFishing(false)
			else
				RFT.window:SetHidden(not RFT.settings.shown)
			end
		end
		lastHeading = -1
	end
	return false
end

---- ReelIn Animation ----
do
	local am = GetAnimationManager()
	local function HideReelIn()
		data.reelIn:SetAlpha(0)
	end
	local function SetStopHandler(reelInAnim)
		reelInAnim:SetHandler("OnStop", HideReelIn)
	end
	local function GetPulseTimeline()
		if not data.notificationPulseTimeline then
			data.notificationPulseTimeline = am:CreateTimelineFromVirtual("NotificationPulse", data.reelIn)
			SetStopHandler(data.notificationPulseTimeline)
		end
		return data.notificationPulseTimeline
	end
	local function GetFadeTimeline()
		if not data.notificationFadeTimeline then
			data.notificationFadeTimeline = am:CreateTimelineFromVirtual("SmithingImprovementBoosterFade", data.reelIn)
			SetStopHandler(data.notificationFadeTimeline)
		end
		return data.notificationFadeTimeline
	end

	data.reelInAnims = {
		["Pulse1"] = {
			setup = function()
				data.reelInAnim = GetPulseTimeline()
				local anim = data.reelInAnim:GetFirstAnimation()
				anim:SetDuration(1000)
				anim:SetEndScale(3 * data.settings.reelInSize)
				data.reelInAnim:SetPlaybackType(ANIMATION_PLAYBACK_LOOP, 3)
				data.reelIn:SetScale(1)
			end
		},
		["Pulse2"] = {
			setup = function()
				data.reelInAnim = GetPulseTimeline()
				local anim = data.reelInAnim:GetFirstAnimation()
				anim:SetDuration(1500)
				anim:SetEndScale(3 * data.settings.reelInSize)
				data.reelInAnim:SetPlaybackType(ANIMATION_PLAYBACK_PING_PONG, 2)
				data.reelIn:SetScale(1)
			end
		},
		["OneShot1"] = {
			setup = function()
				data.reelInAnim = GetPulseTimeline()
				local anim = data.reelInAnim:GetFirstAnimation()
				anim:SetDuration(1000)
				anim:SetEndScale(3 * data.settings.reelInSize)
				data.reelInAnim:SetPlaybackType(ANIMATION_PLAYBACK_ONE_SHOT, 0)
				data.reelIn:SetScale(1)
			end
		},
		["OneShot2"] = {
			setup = function()
				data.reelInAnim = GetPulseTimeline()
				local anim = data.reelInAnim:GetFirstAnimation()
				anim:SetDuration(1500)
				anim:SetEndScale(3 * data.settings.reelInSize)
				data.reelInAnim:SetPlaybackType(ANIMATION_PLAYBACK_ONE_SHOT, 2)
				data.reelIn:SetScale(1)
			end
		},
		["Fade1"] = {
			setup = function()
				data.reelInAnim = GetFadeTimeline()
				local anim = data.reelInAnim:GetFirstAnimation()
				anim:SetDuration(600)
				anim:SetAlphaValues(0.2, 1)
				data.reelInAnim:SetPlaybackType(ANIMATION_PLAYBACK_PING_PONG, 5)
				data.reelIn:SetScale(2 * data.settings.reelInSize)
			end
		},
		["Fade2"] = {
			setup = function()
				data.reelInAnim = GetFadeTimeline()
				local anim = data.reelInAnim:GetFirstAnimation()
				anim:SetDuration(3000)
				anim:SetAlphaValues(0, 1)
				data.reelInAnim:SetPlaybackType(ANIMATION_PLAYBACK_ONE_SHOT, 1)
				data.reelIn:SetScale(2 * data.settings.reelInSize)
			end
		}
	}

	function data:SetReelInAnim(name)
		(self.reelInAnims[name] or self.reelInAnims["Pulse1"]).setup()
	end
end

---- Hook interact controls ----
local function HookInteraction()
	local wm = GetWindowManager()

	data.base = wm:CreateControl("$(parent)Fisherman", RETICLE.interact)
	data.base:SetDimensions(0, 0)
	data.base:SetAnchor(BOTTOMLEFT, RETICLE.interactContext, BOTTOMRIGHT)
	data.base:SetResizeToFitDescendents(true)

	local ApplyPlatformStyle
	function ApplyPlatformStyle()
		if IsInGamepadPreferredMode() then
			data.caughtInfo:SetFont("ZoFontGamepad25")
			data.caughtInfo:SetAnchor(BOTTOMLEFT, RETICLE.interactContext, BOTTOMRIGHT, 48, -8)
		else
			data.caughtInfo:SetFont("ZoFontWinH4")
			data.caughtInfo:SetAnchor(BOTTOMLEFT, RETICLE.interactContext, BOTTOMRIGHT, 48, -2)
		end
	end

	data.caughtInfo = wm:CreateControl("$(parent)LureCaught", data.base, CT_LABEL)

	data.reelIn = wm:CreateControl("$(parent)LureReelIn", RETICLE.interact, CT_TEXTURE)
	data.reelIn:SetBlendMode(TEX_BLEND_MODE_ALPHA)
	data.reelIn:SetTexture("VotansFisherman/fishing_node.dds")
	data.reelIn:SetDrawLevel(2)
	data.reelIn:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
	data.reelIn:SetDimensions(256, 256)
	data.reelIn:SetHidden(true)

	data.base:SetHidden(true)

	-- Call ZO_PreHookHandler and not SetHandler to prevent overwriting another handler
	ZO_PreHookHandler(RETICLE.interact, "OnEffectivelyShown", NewInteraction)
	ZO_PreHookHandler(RETICLE.interact, "OnHide", NewInteraction)

	ZO_PlatformStyle:New(ApplyPlatformStyle, nil, nil)
end

---- FishingHole class ----
local FishingHole = {}

function FishingHole:new(o)
	setmetatable(o, self)
	self.__index = self
	return o
end
function FishingHole:GetTooltipText()
	local lines = {}
	local types = {}
	local lure = self.lure
	for type in pairs(lure.lureType) do
		types[#types + 1] = GetString("SI_FISHERMAN_INTERACT", type)
	end
	if next(types) ~= nil then
		table.sort(types)
		lines[#lines + 1] = table.concat(types, ", ")
	else
		lines[#lines + 1] = GetString(SI_GAMECAMERAACTIONTYPE16)
	end
	local text = ShowCaught(lure, data.settings.showLootOnMap, data.settings.showDebug)
	if text ~= "" then
		lines[#lines + 1] = ":\n"
		lines[#lines + 1] = text
	end
	return table.concat(lines)
end
function FishingHole:GetText()
	for type in pairs(self.lure.lureType) do
		return string.format("%s |c808080gps: %.2fx%.2f|r", GetString("SI_FISHERMAN_INTERACT", type), self.lure.x * 100, self.lure.y * 100)
	end
	return string.format("%s |c808080gps: %.2fx%.2f|r", GetString(SI_GAMECAMERAACTIONTYPE16), self.lure.x * 100, self.lure.y * 100)
end
function FishingHole:GetColor()
	local lureType = next(self.lure.lureType)
	local color = lureType and data.LureColors[lureType] or ZO_TOOLTIP_DEFAULT_COLOR
	return color
end
function FishingHole:GetTexture()
	for type in pairs(self.lure.lureType) do
		return data.iconNameToPath[type][data.settings.pinIcon[type]] or data.iconNameToPath[type]["default"]
	end
	return "esoui/art/treeicons/gamepad/achievement_categoryicon_fishing.dds"
end
function FishingHole:GetPositionInCurrentMap()
	return self.x, self.y
end
function FishingHole:ClearCaught()
	self.lure.caught = {}
end

---- POIs ----

function data:RefreshPins()
	local refreshPinsTimeout = "FishermanRefreshPinsTimeout"
	local function DoRefreshPins()
		em:UnregisterForUpdate(refreshPinsTimeout)
		ZO_WorldMap_RefreshCustomPinsOfType(self.pinTypeId)
	end
	em:UnregisterForUpdate(refreshPinsTimeout)
	em:RegisterForUpdate(refreshPinsTimeout, 300, DoRefreshPins)
end

local function LayoutPinsWithMiniMap(pinManager)
	em:UnregisterForUpdate(data.DrawPinIdentifier1)
	em:UnregisterForUpdate(data.DrawPinIdentifier2)
	pinManager:RemovePins(data.pinType)
	local mapZone = GetZoneId(GetCurrentMapZoneIndex())
	if gps:IsMeasuring() or mapZone < 1 or mapZone >= 2147483647 then
		return
	end

	local measurements = gps:GetCurrentMapMeasurement()
	if not measurements then
		return
	end
	local offsetX, scaleX, offsetY, scaleY = measurements.offsetX, 1 / measurements.scaleX, measurements.offsetY, 1 / measurements.scaleY
	local pinTypeId, GetGameTimeMilliseconds, FyrMM = data.pinTypeId, GetGameTimeMilliseconds, FyrMM

	lureToPin = {}

	if FyrMM.CustomPinList[pinTypeId] == nil then
		FyrMM.CustomPinList[pinTypeId] = {}
	else
		ZO_ClearNumericallyIndexedTable(FyrMM.CustomPinList[pinTypeId])
	end

	local mapId = GetMapTileTexture():lower()

	local function DrawPins(map, identifier)
		if map == nil then
			return
		end
		local k, k1, lure
		k1, lure = next(map)
		k = k1

		local function DrawPin()
			if FyrMM.LoadingCustomPins and FyrMM.LoadingCustomPins[pinTypeId] then
				return
			end

			local FyrCustomPinList = FyrMM.CustomPinList[pinTypeId]
			local addPins = not WORLD_MAP_SCENE:IsShowing()
			if addPins and (not FyrCustomPinList or mapId ~= FyrMM.currentMap.tileTexture) then
				return
			end

			local start, x, y, pin = GetFrameTimeMilliseconds()
			local spendTime = math.min(32, math.max(14, 500 / GetFramerate()))
			while lure and (GetGameTimeMilliseconds() - start) <= spendTime do
				x, y = (lure.x - offsetX) * scaleX, (lure.y - offsetY) * scaleY
				if x > 0 and x < 1 and y > 0 and y < 1 then
					pin = pinManager:CreatePin(pinTypeId, FishingHole:new({x = x, y = y, lure = lure}), x, y)
					if (lure.count or 0) < measureCount or (lure.lureType ~= nil and next(lure.lureType) == nil) then
						lureToPin[lure] = pin
					end

					if addPins then
						FyrCustomPinList[#FyrCustomPinList + 1] = {m_PinType = pinTypeId, m_PinTag = pin.m_PinTag, normalizedX = x, normalizedY = y}
					end
					pin:ResetAnimation(3)
				end
				k, lure = next(map, k)
				if k == k1 then
					em:UnregisterForUpdate(identifier)
					return
				end
			end
			if not lure then
				em:UnregisterForUpdate(identifier)
			end
		end
		if lure then
			em:RegisterForUpdate(identifier, 0, DrawPin)
		end
	end
	DrawPins(GetZoneLures(mapZone), data.DrawPinIdentifier1)

	if GetMapContentType() ~= MAP_CONTENT_DUNGEON then
		return
	end

	local playerZone = GetZone()
	if mapZone ~= playerZone then
		DrawPins(GetZoneLures(playerZone), data.DrawPinIdentifier2)
	end
end

local pinTask = LibAsync:Create(data.DrawPinIdentifier1)

local function LayoutPins(pinManager)
	pinTask:Cancel()
	pinManager:RemovePins(data.pinType)
	local mapZone = GetZoneId(GetCurrentMapZoneIndex())
	if gps:IsMeasuring() or mapZone < 1 or mapZone >= 2147483647 then
		return
	end

	local measurements = gps:GetCurrentMapMeasurement()
	if not measurements then
		return
	end
	local offsetX, scaleX, offsetY, scaleY = measurements.offsetX, 1 / measurements.scaleX, measurements.offsetY, 1 / measurements.scaleY
	local pinTypeId = data.pinTypeId

	lureToPin = {}

	local function DrawPins(map)
		if map == nil then
			return
		end
		pinTask:For(pairs(map)):Do(
			function(k, lure)
				local x, y = (lure.x - offsetX) * scaleX, (lure.y - offsetY) * scaleY
				if x > 0 and x < 1 and y > 0 and y < 1 then
					local pin = pinManager:CreatePin(pinTypeId, FishingHole:new({x = x, y = y, lure = lure}), x, y)
					if (lure.count or 0) < measureCount or (lure.lureType ~= nil and next(lure.lureType) == nil) then
						lureToPin[lure] = pin
					end
				end
			end
		)
	end
	DrawPins(GetZoneLures(mapZone))

	if GetMapContentType() ~= MAP_CONTENT_DUNGEON then
		return
	end

	local playerZone = GetZone()
	if mapZone ~= playerZone then
		DrawPins(GetZoneLures(playerZone))
	end
end

function data:PinClicked(pin)
	local identifier = "VOTANS_FISHERMAN_CONTEXTMENU"
	local function Erase()
		local mapZone = GetZone()
		local map = zoneToLure[mapZone]
		if map == nil then
			return
		end
		local _, tag = pin:GetPinTypeAndTag()
		local currentLure = tag.lure
		self.pinManager:RemovePins(self.pinType, self.pinTypeId, tag)
		for timeStamp, lure in pairs(map) do
			if lure == currentLure then
				map[timeStamp] = nil
				break
			end
		end
	end
	local function Merge(range)
		local _, tag = pin:GetPinTypeAndTag()
		local lure = tag.lure
		MergeFishingHolesAtPosition(lure.x, lure.y, range)
		lastAction = ""
	end

	local function ShowContextMenu()
		em:UnregisterForUpdate(identifier)
		ClearMenu()
		AddCustomMenuItem(
			GetString(SI_WORLD_MAP_ACTION_SET_PLAYER_WAYPOINT),
			function()
				PingMap(MAP_PIN_TYPE_PLAYER_WAYPOINT, MAP_TYPE_LOCATION_CENTERED, pin.normalizedX, pin.normalizedY)
			end
		)
		AddCustomMenuItem("-")
		AddCustomMenuItem(
			GetString(SI_FISHERMAN_SETTING_DATA_TO_PLAYER_POS),
			function()
				local _, tag = pin:GetPinTypeAndTag()
				local lure = tag.lure
				lure.count = measureCount
				local x, y = GetMapPlayerPosition("player")
				local _, radius = GetFocusRange()
				local gx, gy = gps:LocalToGlobal(x, y)
				local dx, dy = gx - lure.x, gy - lure.y
				if math.sqrt(dx * dx + dy * dy) < radius then
					lure.x, lure.y = gx, gy
					pin.normalizedX, pin.normalizedY = x, y
					pin:UpdateLocation()
				else
					ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, GetString(SI_FISHERMAN_SETTING_DATA_PLAYER_TOO_FAR))
				end
			end
		)
		AddCustomMenuItem(
			GetString(SI_FISHERMAN_SETTING_DATA_RESTART),
			function()
				local _, tag = pin:GetPinTypeAndTag()
				local lure = tag.lure
				lure.count = 0
				lure.px = nil
				lure.py = nil
			end
		)
		AddCustomMenuItem(
			GetString(SI_FISHERMAN_SETTING_DATA_CAUGHT_LIST),
			function()
				local _, tag = pin:GetPinTypeAndTag()
				tag:ClearCaught()
				pin:UpdateLocation()
			end
		)
		AddCustomSubMenuItem(
			GetString(SI_FISHERMAN_SETTING_DATA_MERGE),
			{
				{
					label = GetString(SI_FISHERMAN_SETTING_DATA_MERGE_BUTTON_VERY_CLOSE),
					callback = function()
						Merge(0.25)
					end
				},
				{
					label = GetString(SI_FISHERMAN_SETTING_DATA_MERGE_BUTTON_CLOSE),
					callback = function()
						Merge(0.5)
					end
				},
				{
					label = GetString(SI_FISHERMAN_SETTING_DATA_MERGE_BUTTON_NEAR),
					callback = function()
						Merge(1)
					end
				},
				{
					label = GetString(SI_FISHERMAN_SETTING_DATA_MERGE_BUTTON_RANGE),
					callback = function()
						Merge(1.25)
					end
				}
			}
		)
		AddCustomMenuItem("-")
		AddCustomSubMenuItem(
			GetString(SI_FISHERMAN_SETTING_DATA_ERASE),
			{
				{
					label = GetString(SI_FISHERMAN_SETTING_DATA_ERASE_TOOLTIP),
					callback = Erase
				}
			}
		)
		ShowMenu(pin:GetControl())
	end
	em:RegisterForUpdate(identifier, 50, ShowContextMenu)
end

function data:AddPinType()
	local mystyle = {fontSize = 34, fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1}
	self.tooltip = {
		creator = function(pin)
			local _, tag = pin:GetPinTypeAndTag()
			if IsInGamepadPreferredMode() then
				local tooltip = ZO_MapLocationTooltip_Gamepad.tooltip
				tooltip:AddLine(tag:GetTooltipText(), mystyle, tooltip:GetStyle("bodySection"))
			else
				local r, g, b = ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB()
				InformationTooltip:AddLine(tag:GetTooltipText(), "", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER)
			end
		end,
		tooltip = self.settings.showTooltip and 1 or 0
	}

	self.layout = {
		level = data.settings.pinLevel or 30,
		size = data.settings.pinSize or 32,
		insetX = 4,
		insetY = 4,
		texture = function(pin)
			local _, tag = pin:GetPinTypeAndTag()
			return tag:GetTexture()
		end,
		tint = function(pin)
			local _, tag = pin:GetPinTypeAndTag()
			if tag then
				return tag:GetColor()
			end
		end
	}

	ZO_WorldMap_AddCustomPin(self.pinType, FyrMM and LayoutPinsWithMiniMap or LayoutPins, nil, self.layout, self.tooltip)
	data.pinTypeId = _G[self.pinType]
	ZO_WorldMap_SetCustomPinEnabled(self.pinTypeId, false)

	ZO_CreateStringId("SI_MAPFILTER" .. self.pinTypeId, data.title)

	local contextmenu = {
		{
			name = function(pin)
				local _, tag = pin:GetPinTypeAndTag()
				return tag:GetText()
			end,
			show = function(pin)
				return self.settings.showContextMenu
			end,
			callback = function(pin)
				self:PinClicked(pin)
			end,
			duplicates = function(pin1, pin2)
				return pin1 == pin2
			end,
			gamepadName = function(pinDatas)
				for i = 1, #pinDatas do
					local pin = pinDatas[i].pin
					local pinType, tag = pin:GetPinTypeAndTag()
					if pinType == data.pinTypeId then
						return tag:GetText()
					end
				end
			end
		}
	}
	ZO_MapPin.PIN_CLICK_HANDLERS[1][data.pinTypeId] = contextmenu
end

local function ApplyTypeToSlot()
	data.TypeToSlot = data.settings.preferBetterBait and data.TypeToSlotPreferBetter or data.TypeToSlotPreferSimple
	lureLast = nil
end

function data:InitSettings()
	local LAM2 = LibAddonMenu2

	local panelData = {
		type = "panel",
		name = data.title,
		displayName = data.title,
		author = "votan",
		version = "1.16.0",
		-- slashCommand = "",
		-- registerForRefresh = true,
		registerForDefaults = true,
		website = "http://www.esoui.com/downloads/info918-VotansFisherman.html"
	}
	LAM2:RegisterAddonPanel(data.name, panelData)

	local optionsTable = {
		{
			type = "slider",
			name = GetString(SI_FISHERMAN_SETTING_PIN_LEVEL),
			min = 3,
			max = 100,
			step = 1,
			getFunc = function()
				return data.settings.pinLevel
			end,
			setFunc = function(value)
				data.settings.pinLevel = value
				self.layout.level = value
				data:RefreshPins()
			end,
			default = 30
		},
		{
			type = "slider",
			name = GetString(SI_FISHERMAN_SETTING_PIN_SIZE),
			min = 8,
			max = 128,
			step = 1,
			getFunc = function()
				return data.settings.pinSize
			end,
			setFunc = function(value)
				self.settings.pinSize = value
				self.layout.size = value
				data:RefreshPins()
			end,
			default = 32
		}
	}

	for i = 1, #data.LureColors do
		optionsTable[#optionsTable + 1] = {
			type = "colorpicker",
			name = GetString("SI_FISHERMAN_INTERACT", i),
			width = "half",
			getFunc = function()
				return data.LureColors[i]:UnpackRGB()
			end,
			setFunc = function(newR, newG, newB, newA)
				self.LureColors[i] = ZO_ColorDef:New(newR, newG, newB, 1)
				self.settings.lureColors[i] = self.LureColors[i]:ToHex()
				self:RefreshPins()
			end,
			default = data.LureColorDefaults[i]
		}
		local choices = {}
		local tooltips = {}
		local choicesToName = {}
		local nameToChoices = self.iconNameToPath[i]
		if not RFT then
			nameToChoices["Rare Fish Tracker"] = nil
		end
		for name, path in pairs(nameToChoices) do
			tooltips[#tooltips + 1] = name
			choicesToName[path] = name
		end
		table.sort(tooltips)
		for i, name in ipairs(tooltips) do
			choices[i] = nameToChoices[name]
		end
		optionsTable[#optionsTable + 1] = {
			type = "iconpicker",
			name = "",
			choices = choices,
			getFunc = function()
				return nameToChoices[self.settings.pinIcon[i]] or nameToChoices["default"]
			end,
			setFunc = function(value)
				local name = choicesToName[value]
				if self.settings.pinIcon[i] ~= name then
					self.settings.pinIcon[i] = name
					self:RefreshPins()
				end
			end,
			choicesTooltips = tooltips,
			width = "half",
			default = "default"
		}
	end

	optionsTable[#optionsTable + 1] = {
		type = "checkbox",
		name = GetString(SI_FISHERMAN_SETTING_SHOW_LOOT_HUD),
		tooltip = "",
		getFunc = function()
			return data.settings.showLootOnHUD
		end,
		setFunc = function(value)
			self.settings.showLootOnHUD = value
			lastAction = ""
		end,
		default = true
	}

	optionsTable[#optionsTable + 1] = {
		type = "checkbox",
		name = GetString(SI_FISHERMAN_SETTING_SHOW_LOOT_MAP),
		tooltip = "",
		getFunc = function()
			return data.settings.showLootOnMap
		end,
		setFunc = function(value)
			self.settings.showLootOnMap = value
			lastAction = ""
		end,
		default = true
	}

	optionsTable[#optionsTable + 1] = {
		type = "checkbox",
		name = GetString(SI_FISHERMAN_SETTING_SHOW_DEFAULT_LOOT),
		tooltip = "",
		getFunc = function()
			return data.settings.showDefaultLoot
		end,
		setFunc = function(value)
			self.settings.showDefaultLoot = value
			lastAction = ""
		end,
		default = true
	}

	optionsTable[#optionsTable + 1] = {
		type = "header",
		name = GetString(SI_FISHERMAN_SETTING_REEL_IN)
	}

	optionsTable[#optionsTable + 1] = {
		type = "checkbox",
		name = GetString(SI_FISHERMAN_SETTING_SHOW_REEL_IN),
		getFunc = function()
			return data.settings.showReelIn
		end,
		setFunc = function(value)
			self.settings.showReelIn = value
		end,
		default = true
	}

	do
		local choices = {}
		for name in pairs(data.reelInAnims) do
			choices[#choices + 1] = name
		end
		table.sort(choices)
		optionsTable[#optionsTable + 1] = {
			type = "dropdown",
			name = GetString(SI_FISHERMAN_SETTING_REEL_IN_ANIM),
			choices = choices,
			getFunc = function()
				return data.settings.notificationAnim
			end,
			setFunc = function(value)
				data.settings.notificationAnim = value
				data:SetReelInAnim(value)
			end,
			width = "full",
			-- or "half" (optional)
			default = choices[1]
		}
	end
	do
		local sounds = {
			"",
			"NEW_NOTIFICATION",
			"GROUP_REQUEST_DECLINED",
			"DEFER_NOTIFICATION",
			"NEW_MAIL",
			"MAIL_SENT",
			"ACHIEVEMENT_AWARDED",
			"QUEST_ACCEPTED",
			"QUEST_ABANDONED",
			"QUEST_COMPLETED",
			"QUEST_STEP_FAILED",
			"QUEST_FOCUSED",
			"OBJECTIVE_ACCEPTED",
			"OBJECTIVE_COMPLETED",
			"OBJECTIVE_DISCOVERED",
			"INVENTORY_ITEM_JUNKED",
			"INVENTORY_ITEM_UNJUNKED",
			"COLLECTIBLE_UNLOCKED",
			"JUSTICE_STATE_CHANGED",
			"JUSTICE_NOW_KOS",
			"JUSTICE_NO_LONGER_KOS",
			"JUSTICE_GOLD_REMOVED",
			"JUSTICE_ITEM_REMOVED",
			"JUSTICE_PICKPOCKET_BONUS",
			"JUSTICE_PICKPOCKET_FAILED",
			"GROUP_JOIN",
			"GROUP_LEAVE",
			"GROUP_DISBAND",
			"TELVAR_GAINED",
			"TELVAR_LOST",
			"RAID_TRIAL_COMPLETED",
			"RAID_TRIAL_FAILED"
		}
		local choices = {
			GetString(SI_FISHERMAN_SETTING_REEL_IN_NO_SOUND),
			"New",
			"Group Request Declined",
			"Defer",
			"New Mail",
			"Mail Sent",
			"Achievement Awarded",
			"Quest Accepted",
			"Quest Abandoned",
			"Quest Completed",
			"Quest Step Failed",
			"Quest Focused",
			"Objective Accepted",
			"Objective Completed",
			"Objective Discovered",
			"Inventory Item Junked",
			"Inventory Item Unjunked",
			"Collectible Unlocked",
			"Justice State Changed",
			"Justice Now KOS",
			"Justice No Longer KOS",
			"Justice Gold Removed",
			"Justice Item Removed",
			"Justice Pickpocket Bonus",
			"Justice Pickpocket Failed",
			"Group Join",
			"Group Leave",
			"Group Disband",
			"Telvar Gained",
			"Telvar Lost",
			"Raid Trial Completed",
			"Raid Trial Failed"
		}
		optionsTable[#optionsTable + 1] = {
			type = "dropdown",
			name = GetString(SI_FISHERMAN_SETTING_REEL_IN_SOUND),
			choices = choices,
			getFunc = function()
				local sound = data.settings.notificationSound
				for i = 1, #sounds do
					if sounds[i] == sound then
						return choices[i]
					end
				end
				return choices[1]
			end,
			setFunc = function(value)
				for i = 2, #choices do
					if choices[i] == value then
						data.settings.notificationSound = sounds[i]
						PlaySound(SOUNDS[data.settings.notificationSound])
						return
					end
				end
				data.settings.notificationSound = nil
			end,
			width = "full",
			-- or "half" (optional)
			default = choices[1]
		}
	end

	optionsTable[#optionsTable + 1] = {
		type = "colorpicker",
		name = GetString(SI_FISHERMAN_SETTING_REEL_IN_COLOR),
		getFunc = function()
			return data.reelInColor:UnpackRGB()
		end,
		setFunc = function(newR, newG, newB, newA)
			data.reelInColor = ZO_ColorDef:New(newR, newG, newB, 1)
			data.settings.reelInColor = data.reelInColor:ToHex()
		end,
		default = data.reelInColorDefault
	}

	optionsTable[#optionsTable + 1] = {
		type = "slider",
		name = GetString(SI_FISHERMAN_SETTING_REEL_IN_SIZE),
		min = 25,
		max = 400,
		step = 5,
		getFunc = function()
			return math.floor(data.settings.reelInSize * 100)
		end,
		setFunc = function(value)
			data.settings.reelInSize = value / 100
			data:SetReelInAnim(data.settings.notificationAnim)
		end,
		default = 1
	}

	optionsTable[#optionsTable + 1] = {
		type = "checkbox",
		name = GetString(SI_FISHERMAN_SETTING_REEL_IN_RETURN),
		tooltip = GetString(SI_FISHERMAN_SETTING_REEL_IN_RETURN_TOOLTIP),
		getFunc = function()
			return self.settings.autoReturnInteraction
		end,
		setFunc = function(value)
			self.settings.autoReturnInteraction = value
		end,
		default = false
	}
	optionsTable[#optionsTable + 1] = {
		type = "checkbox",
		name = GetString(SI_FISHERMAN_SETTING_AUTO_SWITCH_BAIT),
		tooltip = GetString(SI_FISHERMAN_SETTING_AUTO_SWITCH_BAIT_TOOLTIP),
		getFunc = function()
			return self.settings.autoSwitchBait
		end,
		setFunc = function(value)
			self.settings.autoSwitchBait = value
		end,
		default = false
	}
	optionsTable[#optionsTable + 1] = {
		type = "checkbox",
		name = " |u12:0::|u" .. GetString(SI_FISHERMAN_SETTING_PREFER_BETTER_BAIT),
		tooltip = GetString(SI_FISHERMAN_SETTING_PREFER_BETTER_BAIT_TOOLTIP),
		getFunc = function()
			return self.settings.preferBetterBait
		end,
		setFunc = function(value)
			self.settings.preferBetterBait = value
			ApplyTypeToSlot()
		end,
		default = false
	}

	optionsTable[#optionsTable + 1] = {
		type = "header",
		name = GetString(SI_FISHERMAN_SETTING_EXTRAS)
	}

	optionsTable[#optionsTable + 1] = {
		type = "checkbox",
		name = GetString(SI_FISHERMAN_SETTING_SHOW_HIDE_RFT),
		tooltip = "",
		getFunc = function()
			return self.settings.autoHideRFT
		end,
		setFunc = function(value)
			self.settings.autoHideRFT = value
			if value and RFT and RFT.window then
				RFT.window:SetHidden(true)
			end
		end,
		default = true,
		disabled = function()
			return not (RFT and RFT.window)
		end
	}
	optionsTable[#optionsTable + 1] = {
		type = "checkbox",
		name = GetString(SI_FISHERMAN_SETTING_PIN_SHOW_CONTEXTMENU),
		tooltip = "",
		getFunc = function()
			return self.settings.showContextMenu
		end,
		setFunc = function(value)
			self.settings.showContextMenu = value
		end,
		default = false
	}
	optionsTable[#optionsTable + 1] = {
		type = "checkbox",
		name = GetString(SI_FISHERMAN_SETTING_PIN_SHOW_TOOLTIP),
		tooltip = "",
		getFunc = function()
			return self.settings.showTooltip
		end,
		setFunc = function(value)
			self.settings.showTooltip = value
			self.tooltip.tooltip = value and 1 or 0
		end,
		default = false
	}
	optionsTable[#optionsTable + 1] = {
		type = "checkbox",
		name = GetString(SI_FISHERMAN_SETTING_PIN_SHOW_DEBUG),
		tooltip = "",
		getFunc = function()
			return data.settings.showDebug or false
		end,
		setFunc = function(value)
			self.settings.showDebug = value
			lastAction = ""
		end,
		default = false
	}

	optionsTable[#optionsTable + 1] = {
		type = "submenu",
		name = GetString(SI_FISHERMAN_SETTING_DATA_RESTART),
		controls = {
			{
				type = "description",
				text = GetString(SI_FISHERMAN_SETTING_DATA_RESTART_HINT),
				width = "full"
			},
			{
				type = "description",
				text = GetString(SI_FISHERMAN_SETTING_DATA_RESTART_HINT2),
				width = "full"
			},
			{
				type = "button",
				name = GetString(SI_FISHERMAN_SETTING_DATA_RESTART_BUTTON),
				tooltip = GetString(SI_FISHERMAN_SETTING_DATA_RESTART_TOOLTIP),
				func = RestartMeasurementNearby,
				width = "half"
			}
		}
	}
	optionsTable[#optionsTable + 1] = {
		type = "submenu",
		name = GetString(SI_FISHERMAN_SETTING_DATA_CAUGHT_LIST),
		controls = {
			{
				type = "description",
				text = GetString(SI_FISHERMAN_SETTING_DATA_CAUGHT_LIST_HINT),
				width = "full"
			},
			{
				type = "button",
				name = GetString(SI_FISHERMAN_SETTING_DATA_CAUGHT_LIST_BUTTON),
				tooltip = GetString(SI_FISHERMAN_SETTING_DATA_CAUGHT_LIST_TOOLTIP),
				func = ClearNearbyCaughtLists,
				width = "half"
			}
		}
	}
	optionsTable[#optionsTable + 1] = {
		type = "submenu",
		name = GetString(SI_FISHERMAN_SETTING_DATA_MERGE),
		controls = {
			{
				type = "description",
				text = GetString(SI_FISHERMAN_SETTING_DATA_MERGE_HINT),
				width = "full"
			},
			{
				type = "button",
				name = GetString(SI_FISHERMAN_SETTING_DATA_MERGE_BUTTON_VERY_CLOSE),
				tooltip = GetString(SI_FISHERMAN_SETTING_DATA_MERGE_VERY_CLOSE),
				func = function()
					MergeFishingHoles(0.25)
				end,
				width = "half"
			},
			{
				type = "button",
				name = GetString(SI_FISHERMAN_SETTING_DATA_MERGE_BUTTON_CLOSE),
				tooltip = GetString(SI_FISHERMAN_SETTING_DATA_MERGE_CLOSE),
				func = function()
					MergeFishingHoles(0.5)
				end,
				width = "half"
			},
			{
				type = "button",
				name = GetString(SI_FISHERMAN_SETTING_DATA_MERGE_BUTTON_NEAR),
				tooltip = GetString(SI_FISHERMAN_SETTING_DATA_MERGE_NEAR),
				func = function()
					MergeFishingHoles(1)
				end,
				width = "half"
			},
			{
				type = "button",
				name = GetString(SI_FISHERMAN_SETTING_DATA_MERGE_BUTTON_RANGE),
				tooltip = GetString(SI_FISHERMAN_SETTING_DATA_MERGE_RANGE),
				func = function()
					MergeFishingHoles(1.25)
				end,
				width = "half"
			}
		}
	}
	optionsTable[#optionsTable + 1] = {
		type = "submenu",
		name = ZO_ERROR_COLOR:Colorize(GetString(SI_FISHERMAN_SETTING_DATA_ERASE)),
		controls = {
			{
				type = "description",
				text = GetString(SI_FISHERMAN_SETTING_DATA_ERASE_HINT),
				width = "full"
			},
			{
				type = "button",
				name = GetString(SI_FISHERMAN_SETTING_DATA_ERASE_BUTTON),
				func = EraseNearbyFishingHoles,
				width = "half",
				isDangerous = true,
				warning = GetString(SI_FISHERMAN_SETTING_DATA_ERASE_TOOLTIP)
			}
		}
	}
	LAM2:RegisterOptionControls(data.name, optionsTable)
end

local function Initialize()
	gps = LibGPS3

	local varGlobalDefaults = {
		zoneStats = {},
		pinSize = 32,
		pinLevel = 30,
		showLootOnHUD = true,
		showLootOnMap = true,
		showDefaultLoot = false,
		showDebug = false,
		showReelIn = true,
		showContextMenu = true,
		showTooltip = true,
		notificationAnim = "Pulse1",
		lureColors = {"C2C444", "7CAECC", "2ECCBE", "345FE2"},
		reelInColor = "FFFFFF",
		reelInSize = 1,
		autoHideRFT = false,
		autoReturnInteraction = false,
		autoSwitchBait = false,
		pinIcon = {"default", "default", "default", "default"},
		preferBetterBait = false
	}

	for i = 1, 4 do
		data.LureColorDefaults[i] = ZO_ColorDef:New(varGlobalDefaults.lureColors[i])
		data.LureColorDefaults[i]:SetAlpha(1)
	end
	data.reelInColorDefault = ZO_ColorDef:New(varGlobalDefaults.reelInColor)

	local settings = ZO_SavedVars:NewAccountWide("VotansFisherman_Data", 1, nil, varGlobalDefaults)
	if not VotansFisherman_Data.zoneToLure5 then
		if not settings.zoneToLure4 then
			local function MoveZoneIndex(from, transform)
				local temp = {}
				local newIndex
				for zoneIndex, lure in pairs(from) do
					newIndex = transform[zoneIndex]
					if newIndex ~= nil and newIndex ~= -1 then
						temp[newIndex] = lure
					elseif newIndex ~= -1 then
						temp[zoneIndex] = lure
					end
				end
				return temp
			end
			if settings.zoneToLure then
				settings.zoneToLure2 = MoveZoneIndex(settings.zoneToLure, data.mapZoneIndex_100011_100012)
				settings.zoneToLure = nil
			end
			if settings.zoneToLure2 then
				settings.zoneToLure3 = MoveZoneIndex(settings.zoneToLure2, data.mapZoneIndex_100012_100013)
				settings.zoneToLure2 = nil
			end
			if settings.zoneToLure3 then
				settings.zoneToLure4 = MoveZoneIndex(settings.zoneToLure3, data.mapZoneIndex_100013_100014)
				settings.zoneToLure3 = nil
			end
		end
		if settings.zoneToLure4 then
			VotansFisherman_Data.zoneToLure5 = settings.zoneToLure4
			for zoneIndex, lureList in pairs(VotansFisherman_Data.zoneToLure5) do
				for timestamp, lure in pairs(lureList) do
					if lure.catched then
						lure.caught = lure.catched
						lure.catched = nil
					end
				end
			end
			settings.zoneToLure4 = nil
		end
	end

	data.settings = settings

	ApplyTypeToSlot()

	zoneToLure = VotansFisherman_Data.zoneToLure5
	if zoneToLure == nil then
		zoneToLure = {}
		VotansFisherman_Data.zoneToLure5 = zoneToLure
	end

	zoneStats = settings.zoneStats

	local varDefaults = {
		showPins = settings.showPins
	}
	local player = ZO_SavedVars:NewCharacterIdSettings("VotansFisherman_Data", 1, nil, varDefaults)
	data.player = player
	if type(player.showPins) ~= "table" then
		player.showPins = {}
	end

	for i = 1, 4 do
		data.LureColors[i] = ZO_ColorDef:New(settings.lureColors[i])
		data.LureColors[i]:SetAlpha(1)
	end
	data.reelInColor = ZO_ColorDef:New(settings.reelInColor)
	data.reelInColor:SetAlpha(1)
	for i = 1, 4 do
		data.ActionToLootType[GetString("SI_FISHERMAN_ACTIONNAME", i)] = i
	end

	local function addAction(identifier, type)
		data.InteractToLootType[zo_strformat("<<z:1>>", GetString(identifier))] = type
	end
	addAction(SI_FISHERMAN_INTERACT1, 1)
	addAction(SI_FISHERMAN_INTERACT1B, 1)
	addAction(SI_FISHERMAN_INTERACT2, 2)
	addAction(SI_FISHERMAN_INTERACT3, 3)
	addAction(SI_FISHERMAN_INTERACT4, 4)
	addAction(SI_FISHERMAN_INTERACT4B, 4)

	data.common = ZO_SavedVars:New("VotansFisherman_Data", GetAPIVersion(), nil, {focusRanges = {}}, "Default", "$Machine", "$UserProfileWide")
	data.focusRanges = data.common.focusRanges

	local success, msg = pcall(HookInteraction)
	if not success then
		zo_callLater(
			function()
				d(data.title .. ": HookInteraction failed.", msg)
			end,
			2000
		)
	else
		data:InitSettings()
		data:SetReelInAnim(data.settings.notificationAnim)
		data:AddPinType()
		em:RegisterForEvent(data.name, EVENT_PLAYER_ACTIVATED, PlayerActivatedFirstTime)
	end
end

-- Get the pinManager
data.pinManager = ZO_WorldMap_GetPinManager()

local function OnAddOnLoaded(event, addonName)
	if addonName == data.name then
		em:UnregisterForEvent(data.name, EVENT_ADD_ON_LOADED)
		Initialize()
	end
end

VOTANS_FISHERMAN = data

em:RegisterForEvent(data.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
