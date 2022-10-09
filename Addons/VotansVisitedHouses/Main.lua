local addon = {
	name = "VotansVisitedHouses",
}
local em = GetEventManager()

function addon:VisitHouse()
	if IsOwnerOfCurrentHouse() then
		local id = GetCurrentZoneHouseId()
		self.current[id] = true
	end
end

local newHouse = "VotansVisitedHouses/NewHouse.dds"
function addon:HookPinData()
	local data = ZO_MapPin.PIN_DATA[MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE]
	local orgTexture = data.texture
	data.texture = function(pin)
		local nodeIndex = pin:GetFastTravelNodeIndex()
		local houseId = nodeIndex and GetFastTravelNodeHouseId(nodeIndex)
		if houseId and houseId > 0 and not self.current[houseId] then
			local collectibleId = GetCollectibleIdForHouse(houseId)
			local collectible = collectibleId and collectibleId > 0 and ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
			if collectible then
				if collectible:IsUnlocked() then
					-- orgTexture is call to execute other (hooking) code, only.
					orgTexture(pin)
					return newHouse
				end
			end
		end
		return orgTexture(pin)
	end
end

function addon:Initialize()
	VotansVisitedHouses_List = VotansVisitedHouses_List or { }
	self.sv = VotansVisitedHouses_List
	local id = GetCurrentCharacterId()
	self.sv[id] = self.sv[id] or { }
	self.current = self.sv[id]

	em:RegisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED, function() self:VisitHouse() end)

	self:HookPinData()
end

local function OnAddonLoaded(_, name)
	if name ~= addon.name then return end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)
	addon:Initialize()
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

VOTANS_VISITED_HOUSES = addon
