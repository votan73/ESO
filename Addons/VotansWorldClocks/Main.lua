local addon = {
	name = "VotansWorldClocks"
}
local em = GetEventManager()

local function getUseDst()
	local now = os.time()
	local t1 = os.date("*t", now)
	local t2 = os.date("*t", now + 6 * 31 * 24 * 60 * 60)
	return t1.isdst ~= t2.isdst

	-- local year = os.date("%Y", now)
	-- -- A day in summer time
	-- local t1 = {year = year, month = 6, day = 30}
	-- -- A day in standard time
	-- local t2 = {year = year, month = 12, day = 30}
	-- d(os.time(t1))
	-- d(os.time(t2))
	-- local t1 = os.date("*t", os.time(t1))
	-- local t2 = os.date("*t", os.time(t2))
	-- d(t1.isdst ~= t2.isdst)
end

local isdstNA
do
	-- The days and hours the clock is changed.
	-- Last sunday of May and last sunday of October. Between these days is summer-time.
	local secondSundayOfMarch
	local firstSundayOfNovember

	local function getSummerTimeRange()
		local year = os.date("%Y", os.time())

		local t_firstDayOfMonth = {year = year, month = 3, day = 1}
		local firstDayOfMonth = os.time(t_firstDayOfMonth)
		t_firstDayOfMonth.day = 1 + (7 - os.date("%u", firstDayOfMonth)) + 7
		t_firstDayOfMonth.hour = 2
		t_firstDayOfMonth.minute = 0
		t_firstDayOfMonth.second = 0
		t_firstDayOfMonth.isdst = false

		secondSundayOfMarch = os.time(t_firstDayOfMonth)

		t_firstDayOfMonth.month = 11
		t_firstDayOfMonth.day = 1
		t_firstDayOfMonth.hour = nil
		t_firstDayOfMonth.minute = nil
		t_firstDayOfMonth.second = nil
		t_firstDayOfMonth.isdst = nil
		firstDayOfMonth = os.time(t_firstDayOfMonth)

		t_firstDayOfMonth.day = 1 + (7 - os.date("%u", firstDayOfMonth))
		t_firstDayOfMonth.hour = 3
		t_firstDayOfMonth.minute = 0
		t_firstDayOfMonth.second = 0
		t_firstDayOfMonth.isdst = false

		firstSundayOfNovember = os.time(t_firstDayOfMonth)
	end
	getSummerTimeRange()

	function isdstNA(now)
		return now >= secondSundayOfMarch and now < firstSundayOfNovember
	end
end

local isdstEU
do
	-- The days and hours the clock is changed.
	-- Last sunday of May and last sunday of October. Between these days is summer-time.
	local lastSundayOfMay
	local lastSundayOfOctober

	local function getSummerTimeRange()
		local year = os.date("%Y", os.time())

		-- Trick: Day zero of a month is the last day of the previous month
		local t_lastDayOfMonth = {year = year, month = 4, day = 0}
		local lastDayOfMonth = os.time(t_lastDayOfMonth)
		t_lastDayOfMonth.day = -(os.date("%u", lastDayOfMonth) % 7)
		t_lastDayOfMonth.hour = 2
		t_lastDayOfMonth.minute = 0
		t_lastDayOfMonth.second = 0
		t_lastDayOfMonth.isdst = false

		lastSundayOfMay = os.time(t_lastDayOfMonth)

		t_lastDayOfMonth.month = 11
		t_lastDayOfMonth.day = 0
		t_lastDayOfMonth.hour = nil
		t_lastDayOfMonth.minute = nil
		t_lastDayOfMonth.second = nil
		t_lastDayOfMonth.isdst = nil
		lastDayOfMonth = os.time(t_lastDayOfMonth)

		t_lastDayOfMonth.day = -(os.date("%u", lastDayOfMonth) % 7)
		t_lastDayOfMonth.hour = 3
		t_lastDayOfMonth.minute = 0
		t_lastDayOfMonth.second = 0
		t_lastDayOfMonth.isdst = false

		lastSundayOfOctober = os.time(t_lastDayOfMonth)
	end
	getSummerTimeRange()

	function isdstEU(now)
		return now >= lastSundayOfMay and now < lastSundayOfOctober
	end
end

addon.timezones = {
	{
		name = "CST/CDT",
		isdst = isdstNA,
		offset = -6 * 3600,
		standard = "%s CST",
		summer = "%s CDT",
		tooltip = "NA Megaserver location"
	},
	{
		name = "EST/EDT",
		isdst = isdstNA,
		offset = -5 * 3600,
		standard = "%s EST",
		summer = "%s EDT",
		tooltip = "ZOS Headquarter location"
	},
	{
		name = "CET/CEST",
		isdst = isdstEU,
		offset = 1 * 3600,
		standard = "%s CET",
		summer = "%s CEST",
		tooltip = "EU Megaserver location"
	}
}

local clockFormat = (GetCVar("Language.2") == "en") and TIME_FORMAT_PRECISION_TWELVE_HOUR or TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR
local oppositeClockFormat = (GetCVar("Language.2") ~= "en") and TIME_FORMAT_PRECISION_TWELVE_HOUR or TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR

local orgZO_FormatClockTime
local function NewTimeFormat(...)
	local result = {orgZO_FormatClockTime(...)}
	local now = os.time()

	local clocks = {}
	if addon.account.showOppositeTimeFormat then
		local localTimeOppositeFormat = ZO_FormatTime(GetSecondsSinceMidnight(), TIME_FORMAT_STYLE_CLOCK_TIME, oppositeClockFormat)
		clocks[#clocks + 1] = string.format("%s (%s)", result[1], localTimeOppositeFormat)
	else
		clocks[#clocks + 1] = result[1]
	end

	if addon.account.showUTC then
		clocks[#clocks + 1] = string.format("%s UTC", ZO_FormatTime(now % 86400, TIME_FORMAT_STYLE_CLOCK_TIME, clockFormat))
	end

	for _, timezone in ipairs(addon.timezones) do
		if addon.account[timezone.name] then
			local summerTime = timezone.isdst and timezone.isdst(now)
			local time
			if summerTime then
				time = (now + timezone.offset + 3600) % 86400
				clocks[#clocks + 1] = string.format(timezone.summer, ZO_FormatTime(time, TIME_FORMAT_STYLE_CLOCK_TIME, clockFormat))
			else
				time = (now + timezone.offset) % 86400
				clocks[#clocks + 1] = string.format(timezone.standard, ZO_FormatTime(time, TIME_FORMAT_STYLE_CLOCK_TIME, clockFormat))
			end
			if addon.account.showOppositeTimeFormat then
				local localTimeOppositeFormat = ZO_FormatTime(time, TIME_FORMAT_STYLE_CLOCK_TIME, oppositeClockFormat)
				clocks[#clocks] = string.format("%s (%s)", clocks[#clocks], localTimeOppositeFormat)
			end
		end
	end
	if addon.account.showInGameTime then
		local igSecondsPerDay = 20955
		clocks[#clocks + 1] = string.format("%s IGT", ZO_FormatTime((now % igSecondsPerDay) * 86400 / igSecondsPerDay, TIME_FORMAT_STYLE_CLOCK_TIME, clockFormat))
	end

	result[1] = table.concat(clocks, " \226\128\162 ")
	return unpack(result)
end
local function Init()
	local orgZO_WorldMapCorner_OnUpdate = ZO_WorldMapCorner_OnUpdate
	function ZO_WorldMapCorner_OnUpdate(...)
		orgZO_FormatClockTime = ZO_FormatClockTime
		ZO_FormatClockTime = NewTimeFormat
		orgZO_WorldMapCorner_OnUpdate(...)
		ZO_FormatClockTime = orgZO_FormatClockTime
	end
end

local function CreateSettings()
	local LibHarvensAddonSettings = LibHarvensAddonSettings or LibStub("LibHarvensAddonSettings-1.0")
	local settings = LibHarvensAddonSettings:AddAddon("Votan's World Clocks")

	local DEFAULT_SETTINGS = {
		showOppositeTimeFormat = false,
		showUTC = true,
		showInGameTime = false
	}
	addon.account = ZO_SavedVars:NewAccountWide("VotansWorldClocks_Data", 1, nil, DEFAULT_SETTINGS)

	local function update()
		if orgZO_FormatClockTime then
			ZO_WorldMapCorner:GetNamedChild("Time"):SetText(NewTimeFormat())
		end
	end
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Show Opposite Time Format",
		tooltip = "Additional show the opposite time format.",
		default = DEFAULT_SETTINGS.showOppositeTimeFormat,
		getFunction = function()
			return addon.account.showOppositeTimeFormat
		end,
		setFunction = function(bool)
			addon.account.showOppositeTimeFormat = bool
			update()
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Show Coordinated Universal Time",
		tooltip = "Show the Coordinated Universal Time.",
		default = DEFAULT_SETTINGS.showOppositeTimeFormat,
		getFunction = function()
			return addon.account.showUTC
		end,
		setFunction = function(bool)
			addon.account.showUTC = bool
			update()
		end
	}
	for _, timezone in ipairs(addon.timezones) do
		settings:AddSetting {
			type = LibHarvensAddonSettings.ST_CHECKBOX,
			label = "Show " .. timezone.name,
			default = false,
			getFunction = function()
				return addon.account[timezone.name]
			end,
			setFunction = function(bool)
				addon.account[timezone.name] = bool
				update()
			end,
			tooltip = timezone.tooltip
		}
	end
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Show In-Game Time",
		tooltip = "Show the time of Tamriel (IGT).",
		default = DEFAULT_SETTINGS.showInGameTime,
		getFunction = function()
			return addon.account.showInGameTime
		end,
		setFunction = function(bool)
			addon.account.showInGameTime = bool
			update()
		end
	}
end

local function OnAddOnLoaded(event, name)
	if name ~= addon.name then
		return
	end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	Init()
	CreateSettings()
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
