local addon = {
	name = "LoadingScreenDetector"
}
local em = GetEventManager()

LoadingScreenEvent = LoadingScreenEvent or {}
local events = LoadingScreenEvent
local gps = LibGPS3

local function round(x)
	return math.floor(x * 20000 + 0.5) / 20000
end

local lastSubZone, lastX, lastY
local event
em:RegisterForEvent(
	"CheckLoadingScreen",
	EVENT_PLAYER_DEACTIVATED,
	function()
		if IsPlayerMoving() then
			-- Did not expect to be deactivated. Not standing at a door or wayshrine or NPC
			local now = GetTimeStamp()
			local pHeading
			lastX, lastY, pHeading = GetMapPlayerPosition("player")
			lastX, lastY = round(lastX), round(lastY)
			local x, y = gps:LocalToGlobal(lastX, lastY)
			local cHeading = GetPlayerCameraHeading()
			local fps = GetFramerate()
			local viewDistance = GetSetting(SETTING_TYPE_GRAPHICS, GRAPHICS_SETTING_VIEW_DISTANCE)
			local pfxDistance = GetSetting(SETTING_TYPE_GRAPHICS, GRAPHICS_SETTING_PFX_SUPPRESS_DISTANCE)
			lastSubZone = GetPlayerActiveSubzoneName()
			event = string.format("%i,%.6f,%.6f,%.6f,%.6f,%i,%.1f,%.1f", now, x * 100, y * 100, pHeading, cHeading, fps, (viewDistance - 0.4) * 62.5, pfxDistance)
			d("Unexpected LoadingScreen")
		end
	end
)

em:RegisterForEvent(
	"CheckLoadingScreen",
	EVENT_PLAYER_ACTIVATED,
	function()
		if lastSubZone then
			if lastSubZone == GetPlayerActiveSubzoneName() then
				local x, y = GetMapPlayerPosition("player")
				x, y = round(x), round(y)
				if x == lastX and y == lastY then
					LoadingScreenEvent[#LoadingScreenEvent + 1] = event
					d("confirmed")
				else
					d("not right")
				end
				lastSubZone, event = nil, nil
			end
		end
	end
)

do
	local pinTypeId = nil
	local pinType = "LoadingScreenPinType"

	local pi2 = math.pi * 2
	local toImage = -24 / pi2 -- image rotation correction

	local images = {
		"LoadingScreenDetector/arrow1.dds",
		"LoadingScreenDetector/arrow2.dds",
		"LoadingScreenDetector/arrow3.dds",
		"LoadingScreenDetector/arrow4.dds",
		"LoadingScreenDetector/arrow5.dds",
		"LoadingScreenDetector/arrow6.dds",
		"LoadingScreenDetector/arrow7.dds",
		"LoadingScreenDetector/arrow8.dds",
		"LoadingScreenDetector/arrow9.dds",
		"LoadingScreenDetector/arrow10.dds",
		"LoadingScreenDetector/arrow11.dds",
		"LoadingScreenDetector/arrow12.dds",
		"LoadingScreenDetector/arrow13.dds",
		"LoadingScreenDetector/arrow14.dds",
		"LoadingScreenDetector/arrow15.dds",
		"LoadingScreenDetector/arrow16.dds",
		"LoadingScreenDetector/arrow17.dds",
		"LoadingScreenDetector/arrow18.dds",
		"LoadingScreenDetector/arrow19.dds",
		"LoadingScreenDetector/arrow20.dds",
		"LoadingScreenDetector/arrow21.dds",
		"LoadingScreenDetector/arrow22.dds",
		"LoadingScreenDetector/arrow23.dds",
		"LoadingScreenDetector/arrow24.dds"
	}
	local layout = {
		level = 40,
		size = 16,
		insetX = 0,
		insetY = 0,
		texture = function(pin)
			local data = select(2, pin:GetPinTypeAndTag())
			local h = data[2]
			if h < 0 then
				h = h + pi2
			end
			h = h * toImage
			if h < 0 then
				h = h + 24
			end
			h = math.floor(h + 0.5) % 24 + 1
			return images[h] -- "esoui/art/buttons/pointsplus_highlight.dds"
		end
		-- 	tint = function(pin)
		-- 		local _, tag = pin:GetPinTypeAndTag()
		-- 		if tag then
		-- 			return tag:GetColor()
		-- 		end
		-- 	end,
	}
	local pins = {}
	local function Convert(i, str)
		local x, y, h = str:match("^[^,]+,([^,]+),([^,]+),([^,]+),")
		local pin = {tonumber(x) / 100, tonumber(y) / 100, tonumber(h)}
		pins[i] = pin
		return pin
	end
	local function LayoutPins(pinManager)
		pinManager:RemovePins(pinType)
		local mapZone = GetZoneId(GetCurrentMapZoneIndex())
		if gps:IsMeasuring() or mapZone < 1 or mapZone >= 2147483647 then
			return
		end
		local x, y, h
		for i = 1, #LoadingScreenEvent do
			x, y, h = unpack(pins[i] or Convert(i, LoadingScreenEvent[i]))
			x, y = gps:GlobalToLocal(x, y)
			if x > 0 and x < 1 and y > 0 and y < 1 then
				pinManager:CreatePin(pinTypeId, {i, h}, x, y)
			end
		end
	end
	SLASH_COMMANDS["/loadingscreen"] = function()
		if not pinTypeId then
			ZO_WorldMap_AddCustomPin(pinType, LayoutPins, nil, layout, nil)
			pinTypeId = _G[pinType]
			ZO_WorldMap_SetCustomPinEnabled(pinTypeId, false)
		end
		ZO_WorldMap_SetCustomPinEnabled(pinTypeId, true)
		ZO_WorldMap_RefreshCustomPinsOfType(pinTypeId)
	end
	SLASH_COMMANDS["/setloadingscreen"] = function()
		-- Did not expect to be deactivated. Not standing at a door or wayshrine or NPC
		local now = GetTimeStamp()
		local pHeading
		lastX, lastY, pHeading = GetMapPlayerPosition("player")
		lastX, lastY = round(lastX), round(lastY)
		local x, y = gps:LocalToGlobal(lastX, lastY)
		local cHeading = GetPlayerCameraHeading()
		local fps = GetFramerate()
		local viewDistance = GetSetting(SETTING_TYPE_GRAPHICS, GRAPHICS_SETTING_VIEW_DISTANCE)
		local pfxDistance = GetSetting(SETTING_TYPE_GRAPHICS, GRAPHICS_SETTING_PFX_SUPPRESS_DISTANCE)
		lastSubZone = GetPlayerActiveSubzoneName()
		event = string.format("%i,%.6f,%.6f,%.6f,%.6f,%i,%.1f,%.1f", now, x * 100, y * 100, pHeading, cHeading, fps, (viewDistance - 0.4) * 62.5, pfxDistance)
		LoadingScreenEvent[#LoadingScreenEvent + 1] = event
		d("confirmed")
		lastSubZone, event = nil, nil
	end
end
