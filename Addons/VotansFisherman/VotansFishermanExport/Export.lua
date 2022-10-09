local addon = {
	name = "VotansFishermanExport",
	version = "1.0.0",
	typeNames = { "foul", "river", "lake", "saltwater" }
}
local em = GetEventManager()
local gps

SLASH_COMMANDS["/vfexport"] = function(what)

	if not what or what == "" or what == "zones" then
		addon:ExportZones()
	elseif what == "zone" then
		addon:ExportCurrentZone()
	elseif what == "pins" then
		addon:ExportCurrentMapPins()
	end
end

SLASH_COMMANDS["/vfimport"] = function(what)
	if not VotansFisherman_Export_Data then
		d("nothing to do")
		return
	end

	if VotansFisherman_Export_Data.zoneData then
		addon:ImportZones()
		VotansFisherman_Export_Data.zoneData = nil
	else
		d("nothing to import")
	end
	VotansFisherman_Export_Data = { }
end

local function CreateSavedVar()
	local sv = VotansFisherman_Export_Data or { }
	VotansFisherman_Export_Data = sv
	sv.version = addon.version
	return sv
end

function addon:ExportCurrentMapPins()
	local mapZone = GetZoneId(GetCurrentMapZoneIndex())
	if mapZone < 1 or mapZone >= 2147483647 then return end

	local measurements = gps:GetCurrentMapMeasurement()
	if not measurements then return end

	local sv = CreateSavedVar()
	local export = sv.mapPins or { }
	sv.mapPins = export
	ZO_ClearNumericallyIndexedTable(export)

	local offsetX, scaleX, offsetY, scaleY = measurements.offsetX, 1 / measurements.scaleX, measurements.offsetY, 1 / measurements.scaleY

	local x, y, type
	local pins = VOTANS_FISHERMAN:GetZoneToLure()[mapZone]
	if pins then
		for timestamp, lure in pairs(pins) do
			x, y =(lure.x - offsetX) * scaleX,(lure.y - offsetY) * scaleY
			if x > 0 and x < 1 and y > 0 and y < 1 then
				type = next(lure.lureType)
				type = type and addon.typeNames[type] or "unknown"
				export[#export + 1] = string.format("%s;%.4f;%.4f", type, x, y)
			end
		end
		table.sort(export)
	end
	df("%i pins exported. Now logout or execute /reloadui to save.", #export)
end


function addon:ExportZones()
	CreateSavedVar().zoneData = VOTANS_FISHERMAN:GetZoneToLure()
	d("All zones marked for export. Now logout or execute /reloadui to save.")
end

function addon:ExportCurrentZone()
	local mapZone = GetZoneId(GetCurrentMapZoneIndex())
	if mapZone < 1 or mapZone >= 2147483647 then return end

	local sv = CreateSavedVar()
	sv.zoneData = sv.zoneData or { }
	sv.zoneData[mapZone] = VOTANS_FISHERMAN:GetZoneToLure()[mapZone]
	df("Zone \"%s\" marked for export. Now logout or execute /reloadui to save.", zo_strformat(SI_WORLD_MAP_LOCATION_NAME, GetZoneNameByIndex(GetCurrentMapZoneIndex())))
end

local function MergePins(newPin, existing)
	newPin.count = newPin.count or 0
	existing.count = existing.count or 0
	if newPin.lureType then
		for type in pairs(newPin.lureType) do existing.lureType[type] = true end
	end
	if newPin.caught then
		for caught in pairs(newPin.caught) do existing.caught[caught] = true end
	end
	if newPin.count > existing.count then
		existing.px = newPin.px
		existing.py = newPin.py
		existing.x = newPin.x
		existing.y = newPin.y
		existing.my = newPin.my
		existing.mx = newPin.mx
		existing.count = newPin.count
	end
end

function addon:ImportZones()
	local import = VotansFisherman_Export_Data.zoneData
	local target = VOTANS_FISHERMAN:GetZoneToLure()
	local zone
	local distance = zo_distance3D
	local found
	local new, merged, newZone = 0, 0, 0
	for mapZone, sourceList in pairs(import) do
		zone = target[mapZone]
		if zone then
			for timestamp, newPin in pairs(sourceList) do
				found = false
				for _, existing in pairs(zone) do
					if distance(newPin.x, newPin.y, 0, existing.x, existing.y, 0) <= 0.0000001 then
						found = true
						MergePins(newPin, existing)
						merged = merged + 1
						break
					end
				end
				if not found then
					zone[timestamp] = newPin
					new = new + 1
				end
			end
		else
			target[mapZone] = sourceList
			newZone = newZone + 1
		end
	end
	df("%i new zone(s)", newZone)
	df("%i new pin(s)", new)
	df("%i merged pin(s)", merged)
	if (newZone + new + merged) > 0 then
		VOTANS_FISHERMAN:RefreshPins()
	end
end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then return end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	gps = LibGPS3
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)
