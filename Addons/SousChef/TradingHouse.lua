local SousChef = SousChef
local u = SousChef.Utility
local m = SousChef.Media

local linkData = { GetTradingHouseSearchResultItemLink, "slotIndex", nil }
function SousChef.HookTrading(...)
	if SousChef.hookedDataFunction then return end
	local searchResult = TRADING_HOUSE.m_searchResultsList or TRADING_HOUSE.searchResultsList
	SousChef.hookedDataFunction = searchResult.dataTypes[1].setupCallback
	if SousChef.hookedDataFunction then
		searchResult.dataTypes[1].setupCallback = function(...)
			local row, data = ...
			SousChef.hookedDataFunction(...)
			SousChef.AddRankToSlot(row, linkData)
		end
	else
		d("SousChef could not hook into the Trading House")
	end
end