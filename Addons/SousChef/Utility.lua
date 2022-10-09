local SousChef = SousChef
local u = SousChef.Utility
-- local colors = {
-- ["green"] = "|c00ff00",
-- ["blue"] = "|c0066ff",
-- ["purple"] = "|c782ee6",
-- ["gold"] = "|cE6B800",
-- ["white"] = "|cFFFFFF",
-- ["ending"] = "|r",
-- }

function u.GetItemID(link)
	if not link or link == "" then return -1 end
	return GetItemLinkItemId(link)
end

function u.GetColoredLinkName(link)
	if link == nil or link == "" then return "" end
	local plainName = GetItemLinkName(link)
	local color = GetItemLinkQuality(link)
	local coloredName
	if color == ITEM_QUALITY_NORMAL then
		-- white
		return zo_strformat("|cFFFFFF<<t:1>>|r", plainName)
	elseif color == ITEM_QUALITY_MAGIC then
		-- green
		return zo_strformat("|c00ff00<<t:1>>|r", plainName)
	elseif color == ITEM_QUALITY_ARCANE then
		-- blue
		return zo_strformat("|c0066ff<<t:1>>|r", plainName)
	elseif color == ITEM_QUALITY_ARTIFACT then
		-- purple
		return zo_strformat("|c782ee6<<t:1>>|r", plainName)
	elseif color == ITEM_QUALITY_LEGENDARY then
		-- gold
		return zo_strformat("|cE6B800<<t:1>>|r", plainName)
	else
		return zo_strformat("<<t:1>>", plainName)
	end
	return coloredName
end

function u.EndsWith(String, End)
	return End == '' or string.sub(String, - string.len(End)) == End
end

function u.StartsWith(String, Start)
	return Start == '' or string.sub(String, 1, string.len(Start)) == Start
end

local separators = { "%^[%a:]+", "-", " " }

function u.Compress(entry)
	if not entry or entry == "" then return "" end
	for _, v in pairs(separators) do
		entry = entry:gsub(v, "")
	end
	return entry
end

do
	local LocalizeString = LocalizeString
	function u.CleanString(entry)
		-- if not entry or entry == "" then return "" end
		return LocalizeString("<<Z:1>>", entry or "")
		-- u.Compress(entry):lower()
	end
end

function u.TableKeyConcat(t)
	local tt = { }
	for k in pairs(t) do tt[#tt + 1] = k end
	return table.concat(tt, ", ")
end

function u.MatchInIgnoreList(name)
	name = u.CleanString(name)
	for recipe in pairs(SousChef.settings.ignoredRecipes) do
		if u.CleanString(recipe) == name then return true end
	end
	return false
end
