local INDEX_BUTTON = 1

local function UpdateButtons(self, forceSelection)
end

local TWO_PI = math.pi * 2
local function PerformLayout(menu)
	local self = menu.m_object
	local width, height = menu:GetDimensions()
	local halfWidth, halfHeight = width / 2 / menu:GetScale(), height / 2 / menu:GetScale()
	local numEntries = #self.m_buttons
	local halfSliceSize = TWO_PI / numEntries / 2

	self.m_barPool:ReleaseAllObjects()

	local initialRotation = numEntries == 2 and math.pi / 2 or 0

	local setupFunction = self.setupFunction
	for i, button in ipairs(self.m_buttons) do
		local entryControl = button[INDEX_BUTTON]
		local centerAngle = initialRotation + i / numEntries * TWO_PI
		local x = math.sin(centerAngle)
		local y = math.cos(centerAngle)

		--- math.sin is returning very small numbers instead of 0 for PI and TWO_PI
		if math.abs(x) < 0.01 then
			x = 0
		end

		if entryControl.icon then
			entryControl.icon:SetTexture(entryControl.inactiveIcon)

			if entryControl.label then
				entryControl.label:ClearAnchors()
				if x > 0 then
					entryControl.label:SetAnchor(LEFT, entryControl.icon, RIGHT, 15, 0)
				elseif x < 0 then
					entryControl.label:SetAnchor(RIGHT, entryControl.icon, LEFT, -15, 0)
				elseif y > 0 then
					entryControl.label:SetAnchor(TOP, entryControl.icon, BOTTOM, 0, 0)
				else
					entryControl.label:SetAnchor(BOTTOM, entryControl.icon, TOP, 0, -5)
				end
			end
		end

		if setupFunction then
			local buttonData = entryControl.m_object.m_buttonData
			setupFunction(entryControl, buttonData)
		end

		entryControl:SetAnchor(CENTER, nil, CENTER, x * halfWidth, y * halfHeight)
		entryControl:SetHidden(false)

		entryControl.startX = math.sin(centerAngle - halfSliceSize)
		entryControl.startY = math.cos(centerAngle - halfSliceSize)

		entryControl.endX = math.sin(centerAngle + halfSliceSize)
		entryControl.endY = math.cos(centerAngle + halfSliceSize)

		entryControl.m_object:RefreshStatus()
	end
end

function EnchantMakerRadialMenuBar_OnInitialized(self)
	ZO_MenuBar_OnInitialized(self)
	local barData =
	{
		normalSize = 47,
		downSize = 69,
		animationDuration = DEFAULT_SCENE_TRANSITION_TIME,
		buttonTemplate = "ZO_MenuBarButtonTemplate1",
	}
	ZO_MenuBar_SetData(self, barData)
	self.m_object.UpdateButtons = UpdateButtons
	self.PerformLayout = PerformLayout
	function self:SetSetupFunction(func) self.m_object.setupFunction = func end
end
