-- Feel free to use this library --
-- but do not modify without sending a pm to me (votan at www.esoui.com) to avoid version conflicts --

-- Register with LibStub
local MAJOR, MINOR = "LibAlchemyStation", 9999
local lib, oldminor = LibStub and LibStub:NewLibrary(MAJOR, MINOR)
if LibStub and lib then
	assert(MAJOR .. " still loaded via LibStub.")
end
lib = lib or {}

local function HideOtherTabs(descriptor)
	for otherDescriptor, tabData in pairs(lib.tabs) do
		local child = tabData.control
		child:SetHidden(otherDescriptor ~= descriptor)
	end
end

local function InitStationButton()
	local oldmode = ALCHEMY.mode
	local function postSetMode(self, mode)
		HideOtherTabs(mode)
		local tabData = lib.tabs[mode]
		if tabData then
			self.control:GetNamedChild("SlotContainer"):SetHidden(false)
			if oldmode ~= mode then
				if tabData.callback then
					tabData.callback(tabData)
				end
				oldmode = mode
			end
		end
	end
	SecurePostHook(ALCHEMY, "SetMode", postSetMode)
end

function lib:Init()
	if not lib.content then
		lib.tabs = {}
		local content = WINDOW_MANAGER:CreateControl("$(parent)Content", ZO_AlchemyTopLevel, CT_CONTROL)
		content:SetExcludeFromResizeToFitExtents(true)
		content:SetWidth(568)
		content:SetAnchor(TOPLEFT, ZO_SharedRightPanelBackground, TOPLEFT, 0, 67)
		content:SetAnchor(BOTTOMLEFT, ZO_SharedRightPanelBackground, BOTTOMLEFT, 0, -30)
		lib.content = content

		InitStationButton()
	end
end

function lib:AddTab(tabData)
	local name = tabData.name
	local control = WINDOW_MANAGER:CreateControl("$(grandparent)" .. tabData.descriptor, lib.content, CT_CONTROL)
	control:SetAnchorFill()
	tabData.control = control

	local creationData = {
		activeTabText = name,
		categoryName = name,
		descriptor = tabData.descriptor,
		normal = tabData.normal,
		pressed = tabData.pressed,
		highlight = tabData.highlight,
		disabled = tabData.disabled,
		callback = function(creationData)
			lib:SetText(GetString(name))
			ALCHEMY:SetMode(creationData.descriptor)
		end
	}
	ZO_MenuBar_AddButton(ALCHEMY.modeBar, creationData)
	lib.tabs[tabData.descriptor] = tabData
	return control
end

function lib:SelectTab(descriptor)
	return ZO_MenuBar_SelectDescriptor(ALCHEMY.modeBar, descriptor, false)
end

function lib:GetSelectedTab()
	return ZO_MenuBar_GetSelectedDescriptor(ALCHEMY.modeBar)
end

function lib:SetText(text)
	ALCHEMY.modeBarLabel:SetText(text)
end

LibAlchemyStation = lib
