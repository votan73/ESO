-- Register with LibStub
local MAJOR, MINOR = "LibWorldMapInfoTab", 1.2

local lib, oldminor = LibStub and LibStub:NewLibrary(MAJOR, MINOR)

lib = lib or { }

if lib.Unload then
	lib:Unload()
end

local orgAddButton = WORLD_MAP_INFO.modeBar.menuBar.m_object.AddButton

function lib:Unload()
	WORLD_MAP_INFO.modeBar.menuBar.m_object.AddButton = orgAddButton
end

lib.numUnscaledButtons = lib.numUnscaledButtons or 6

local function ScaleButtons(self)
	local numButtons = #self.m_buttons + 1
	local numUnscaledButtons = lib.numUnscaledButtons
	if numButtons <= numUnscaledButtons then
		self.m_buttonPadding = 20
		self.m_downSize = 64
		self.m_normalSize = 51
	else
		self.m_downSize = 64 -(numButtons - numUnscaledButtons - 1) * 4
		self.m_normalSize = self.m_downSize * 0.8
		self.m_buttonPadding = 20 -(numButtons - numUnscaledButtons) * 4.4
	end

	local button, normalSize, downSize, size
	for _, data in ipairs(self.m_buttons) do
		button = data[1].m_object
		normalSize, downSize = button:GetAnimationData()
		size = button:GetState() == BSTATE_PRESSED and downSize or normalSize
		button.m_image:SetDimensions(size, size)
	end
end

function WORLD_MAP_INFO.modeBar.menuBar.m_object:AddButton(buttonData)
	ScaleButtons(self)

	return orgAddButton(self, buttonData)
end

function lib:GetNumUnscaledButtons()
	return lib.numUnscaledButtons
end
function lib:SetMinimumUnscaledButtons(value)
	value = math.max(lib.numUnscaledButtons, value)
	if lib.numUnscaledButtons ~= value then
		lib.numUnscaledButtons = value
		local function change(bg)
			bg:SetWidth(math.max(350, value * 51 + 42))
		end
		change(ZO_WorldMapInfoFootPrintBackground)
		change(ZO_WorldMapInfo)
		ZO_WorldMapInfoMenuBarDivider:ClearAnchors()

		local margin = 72 + math.max(0,(value - 6) * 18)
		ZO_WorldMapInfoMenuBarDivider:SetAnchor(TOPLEFT, nil, BOTTOMLEFT, - margin, 14)
		ZO_WorldMapInfoMenuBarDivider:SetAnchor(TOPRIGHT, ZO_WorldMapInfo, TOPRIGHT, margin - 36, ZO_WorldMapInfoMenuBarDivider:GetTop() - ZO_WorldMapInfoMenuBar:GetTop())

		ScaleButtons(WORLD_MAP_INFO.modeBar.menuBar.m_object)
	end
end

LibWorldMapInfoTab = lib
