local addon = {
	name = "VotansImprovedOutfit"
}
local em = GetEventManager()

function addon:InitVariables()
	VotansImprovedOutfit_Fashion = VotansImprovedOutfit_Fashion or {}
	VotansImprovedOutfit_Data = VotansImprovedOutfit_Data or {}
	self.masterList = VotansImprovedOutfit_Fashion
	self.settings = VotansImprovedOutfit_Data

	local collectible
	collectible = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(2948)
	self.categoryIndexArmor = collectible:GetCategoryData():GetCategoryIndicies()
	collectible = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(2896)
	self.categoryIndexWeapon = collectible:GetCategoryData():GetCategoryIndicies()
end

local function OnAddonLoaded(event, name)
	if name ~= addon.name then
		return
	end
	em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)

	addon:InitVariables()
	addon:AddUndoButtons()
	addon:InitializeFashion()
	addon:InitializeNavigation()
	addon:InitializeRandomize()
end

em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

VOTANS_IMPROVED_OUTFIT = addon
