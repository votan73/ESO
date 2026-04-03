local lib = LibMousePointer
local Cursor_Gamepad = ZO_InitializingObject:Subclass()
lib.Cursor_Gamepad = Cursor_Gamepad
local CURSOR_SPEED = 5

function Cursor_Gamepad:Initialize(control)
    self.control = control
    self.control:SetHidden(true)
    self.initialX, self.initialY = GuiRoot:GetCenter()
    self:ResetPosition()
end

function Cursor_Gamepad:UpdateDirectionalInput()
    if not DIRECTIONAL_INPUT:IsAvailable(ZO_DI_LEFT_STICK) then
        --d("Directional input not available, cannot update cursor position.")
        return
    end

    local dx, dy = DIRECTIONAL_INPUT:GetXY(ZO_DI_LEFT_STICK)
    dx, dy = zo_clampLength2D(dx, dy, 1.6) -- clamp dpad output
    local frameDelta = GetFrameDeltaNormalizedForTargetFramerate()
    local magnitude = frameDelta * CURSOR_SPEED
    dx = dx * magnitude
    dy = -dy * magnitude

    self.control:SetAnchor(CENTER, GuiRoot, TOPLEFT, self.x + dx, self.y + dy)
    local clampedX, clampedY = self.control:GetCenter()
    if clampedX ~= self.x or clampedY ~= self.y then
        self.x, self.y = clampedX, clampedY
        self.directionalX = self.x + dx
        self.directionalY = self.y + dy
    end

    self:UpdateCursorInfo()
end

function Cursor_Gamepad:UpdateVirtualMousePosition()
    if self.cursorId ~= nil then
        local deltaX, deltaY = GetUIMouseDeltas()
        if deltaX ~= 0 or deltaY ~= 0 then
            -- This code allows the player to use the mouse on the gamepad UI on a PC build.
            -- If movement is coming from directional input (ei. arrows, joystick) then the
            -- mouse should jump to the crosshairs when used again. When mouse is the primary
            -- mode of movement then the gamepad crosshairs (self.control) will follow.
            local mouseX, mouseY = self.directionalX, self.directionalY
            if mouseX == nil or mouseY == nil then
                mouseX, mouseY = GetUIMousePosition()
            else
                WINDOW_MANAGER:SetMouseFocusByName(self.control:GetName())
                self.directionalX = nil
                self.directionalY = nil
            end

            self.control:SetAnchor(CENTER, GuiRoot, TOPLEFT, mouseX, mouseY)
            local clampedX, clampedY = self.control:GetCenter()
            if clampedX ~= self.x or clampedY ~= self.y then
                self.x, self.y = clampedX, clampedY
                return true
            end
        end
    end
    return false
end

function Cursor_Gamepad:OnUpdate()
    if self:UpdateVirtualMousePosition() then
        self:UpdateCursorInfo()
    end
end

function Cursor_Gamepad:UpdateCursorInfo()
    local counterScrollX = (self.x - self.initialX) * ZO_CHAMPION_COUNTERSCROLL_FACTOR_X
    local counterScrollY = (self.y - self.initialY) * -ZO_CHAMPION_COUNTERSCROLL_FACTOR_Y

    WINDOW_MANAGER:UpdateCursorPosition(self.cursorId, self.x, self.y)
    local mouseOverControl = WINDOW_MANAGER:GetControlAtCursor(self.cursorId)
    self.mouseOverControl = mouseOverControl
end

function Cursor_Gamepad:UpdateVisibility(show)
    self.control:SetHidden(not show)

    if show then
        if not self.cursorId then
            self.cursorId = WINDOW_MANAGER:CreateCursor(self.x, self.y)
        end
    else
        if self.cursorId then
            WINDOW_MANAGER:DestroyCursor(self.cursorId)
            self.cursorId = nil
        end
    end

    if not show then
        self.mouseOverControl = nil
    end
end

function Cursor_Gamepad:ResetPosition()
    self.x, self.y = self.initialX, self.initialY
    self.control:SetAnchor(CENTER, GuiRoot, TOPLEFT, self.x, self.y)
    self:UpdateCursorInfo()
end

function Cursor_Gamepad:GetCursorPosition()
    return WINDOW_MANAGER:GetCursorPosition(self.cursorId)
end

function Cursor_Gamepad:GetControlAtCursor(desiredHandlers)
    return desiredHandlers and WINDOW_MANAGER:GetControlAtCursor(self.cursorId, desiredHandlers) or self.mouseOverControl
end
