-- Bait Counter, an Elder Scrolls Online add-on by katkat42
-- Bait Counter shows in the reticle frame how much of a bait you have left when you hover
-- over a fishing hole with that bait selected.

local GetGameCameraInteractableActionInfo = GetGameCameraInteractableActionInfo

local orgGetFishingLureInfo
local function newGetFishingLureInfo(...)
	GetFishingLureInfo = orgGetFishingLureInfo
	local result = {GetFishingLureInfo(...)}
	result[1] = string.format("%i %s", result[3], result[1])
	return unpack(result)
end

local function HookInteraction(self, interactionPossible, currentFrameTimeSeconds)
	if not interactionPossible then return end
	local adtlInfo = select(5, GetGameCameraInteractableActionInfo())
	if adtlInfo ~= ADDITIONAL_INTERACT_INFO_FISHING_NODE then return end
	if GetFishingLureInfo ~= newGetFishingLureInfo then
		orgGetFishingLureInfo = GetFishingLureInfo
	end
	GetFishingLureInfo = newGetFishingLureInfo
end

local function InitBaitCounter()
	EVENT_MANAGER:UnregisterForUpdate("BaitCountInit")
	local orgTryHandlingInteraction = RETICLE.TryHandlingInteraction
	function RETICLE.TryHandlingInteraction(...)
		HookInteraction(...)
		return orgTryHandlingInteraction(...)
	end
end

local function BC_Init()
	EVENT_MANAGER:UnregisterForEvent("BaitCountInit", EVENT_PLAYER_ACTIVATED)

	--Hook as late as possible
	EVENT_MANAGER:RegisterForUpdate("BaitCountInit", 0, InitBaitCounter)
end

EVENT_MANAGER:RegisterForEvent("BaitCountInit", EVENT_PLAYER_ACTIVATED, BC_Init)
