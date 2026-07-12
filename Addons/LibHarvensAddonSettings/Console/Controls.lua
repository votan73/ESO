local function GetAtlasCoordinatesFor(n, atlasSizeX, atlasSizeY)
	if n > atlasSizeX * atlasSizeY then
		error(('Index is too big! Max atlas index must be less than %d x %d (%d), requested %d'):format(atlasSizeX, atlasSizeY, atlasSizeX * atlasSizeY, n))
	end

	n = n - 1
	local X, Y = n % atlasSizeX, math.floor(n / atlasSizeX)
	local xStep, yStep = 1 / atlasSizeX, 1 / atlasSizeY

    return xStep * X, xStep * (X + 1), yStep * Y, yStep * (Y + 1)
end

function LHAS_GamepadHorizontalListRow_Initialize(self)
    self.GetHeight = function(control)
        return control.label:GetTextHeight() + control.horizontalListControl:GetHeight()
    end
    self.label = self:GetNamedChild("Name")
    self.horizontalListControl = self:GetNamedChild("HorizontalList")

    local function setupFunction(control, data, selected, reselectingDuringRebuild, enabled, selectedFromParent)
        local icon = control:GetNamedChild('Icon')
        icon:SetTexture(data.data.texture)
        icon:SetTextureCoords(GetAtlasCoordinatesFor(data.index, data.data.atlasSizeX, data.data.atlasSizeY))
    end

    self.horizontalListObject = ZO_HorizontalScrollList_Gamepad:New(self.horizontalListControl, "LHAS_GamepadHorizontalListEntry", 1, setupFunction)
    self.horizontalListObject:SetAllowWrapping(true)
end
