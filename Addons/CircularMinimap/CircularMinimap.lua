local ADDON_NAME = "CircularMinimap"
CircularMinimap = {}

LibDAU:VerifyAddon(ADDON_NAME)

CircularMinimap.textures = {
	["(Circular) Moosetrax Normal Wheel"] = "CircularMinimap/Textures/MNormalWheel.dds",
	["(Circular) Moosetrax Normal Lense Wheel"] = "CircularMinimap/Textures/MNormalLense1Wheel.dds",
	["(Circular) Moosetrax Astro Wheel"] = "CircularMinimap/Textures/MAstroWheel.dds",
	["(Circular) Moosetrax Astro Lense Wheel"] = "CircularMinimap/Textures/MAstroLense1Wheel.dds"
}

-- circular border texture
CircularMinimap.background = WINDOW_MANAGER:CreateControl("CircularBackground", ZO_WorldMap, CT_TEXTURE)
CircularMinimap.background:SetDrawLayer(1)
CircularMinimap.background:SetDrawLevel(1)
CircularMinimap.background:SetAnchor(CENTER, ZO_WorldMapScroll, CENTER, 0, 0)
CircularMinimap.background:SetHidden(true)

-- on the 500 x 500 circular border image
-- the center scroll has its top left corner at (72, 72)
-- an the vertical scroll has its top left corner at (130,34)
local scale = (500 - 72 * 2)
local shortScale = (250 - 130) * 2 / scale
local longScale = (250 - 34) * 2 / scale
local borderScale = longScale * 500 / 410 -- ratio of the long side of the vertical scroll to the complete border image

local function applyClip()
	if CircularMinimap.circularMode then
		local width, height = ZO_WorldMapScroll:GetDimensions()
		CircularMinimap.background:SetDimensions(borderScale * width, borderScale * width)
		ZO_WorldMapScroll:SetAutoRectClipChildren(false)
		ZO_WorldMapScroll:SetCircularClip(ZO_WorldMapScroll:GetLeft() + width / 2, ZO_WorldMapScroll:GetTop() + height / 2, 1.25 * width / 2)
	else
		ZO_WorldMapScroll:ClearClips()
		ZO_WorldMapScroll:SetAutoRectClipChildren(true)
	end
end

for name, path in pairs(CircularMinimap.textures) do
	VOTANS_MINIMAP:AddBorderStyle(
		name,
		name,
		function(settings, background, frame)
			CircularMinimap.circularMode = true

			-- default ESO style from votan's minimap
			local alpha = settings.borderAlpha / 100 or 1
			background:SetCenterColor(0, 0, 0, alpha)
			background:SetEdgeColor(0, 0, 0, alpha)
			background:SetEdgeTexture("/esoui/art/chatwindow/chat_bg_edge.dds", 256, 128, 16)
			background:SetCenterTexture("/esoui/art/chatwindow/chat_bg_center.dds")
			background:SetInsets(16, 16, -16, -16)

			-- we have to hide the old border frame
			frame:SetHidden(true)

			ZO_WorldMapTitle:ClearAnchors()
			ZO_WorldMapTitle:SetAnchor(TOP, background, TOP, 0, 4)

			CircularMinimap.background:SetHidden(false)
			CircularMinimap.background:SetTexture(path)

			-- move the old background to the bottom of the minimap
			-- and adjust draw levels, so it isn't hidden behind the minimap
			background:ClearAnchors()
			background:SetAnchor(TOPLEFT, ZO_WorldMap, BOTTOMLEFT, -8, -64)
			background:SetAnchor(BOTTOMRIGHT, ZO_WorldMap, BOTTOMRIGHT, 6, 8)

			CircularMinimap.oldBackgroundDrawLevel = CircularMinimap.oldBackgroundDrawLevel or background:GetDrawLevel()
			CircularMinimap.oldBackgroundDrawLayer = CircularMinimap.oldBackgroundDrawLayer or background:GetDrawLayer()
			background:SetDrawLevel(2)
			background:SetDrawLayer(1)

			applyClip()
			ZO_WorldMapScroll:SetHandler("OnRectChanged", applyClip, "CircularMiniMap")
		end,
		function(settings, background, frame)
			CircularMinimap.circularMode = false
			frame:SetHidden(false)

			background:ClearAnchors()
			background:SetAnchor(TOPLEFT, nil, TOPLEFT, -8, -4)
			background:SetAnchor(BOTTOMRIGHT, nil, BOTTOMRIGHT, 6, 0)

			background:SetDrawLevel(CircularMinimap.oldBackgroundDrawLevel)
			background:SetDrawLayer(CircularMinimap.oldBackgroundDrawLayer)

			CircularMinimap.background:SetHidden(true)

			ZO_WorldMapScroll:SetHandler("OnRectChanged", nil, "CircularMiniMap")
			applyClip()
		end
	)
end
