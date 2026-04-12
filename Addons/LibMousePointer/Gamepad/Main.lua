local lib = {}

lib.name = "LibMousePointer"

function lib:Initialize()
    self.control = LibMousePointerTopLevel
    local fragment = ZO_SimpleSceneFragment:New(self.control)

    lib.keybindButton = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        order = -1000,
        name = GetString(SI_GAMEPAD_SELECT_OPTION),
        keybind = "UI_SHORTCUT_PRIMARY",
        callback = function(keyUp)
            self:InvokeClick()
        end
    }

    local buttonApplied = false
    fragment:RegisterCallback(
        "StateChange",
        function(oldState, newState)
            if newState == SCENE_FRAGMENT_SHOWN then
                if not self.gamepadCursor then
                    self.gamepadCursor = self.Cursor_Gamepad:New(self.control:GetNamedChild("GamepadCursor"))
                end
                self.control:BringWindowToTop()
                self.gamepadCursor:UpdateVisibility(true)
                DIRECTIONAL_INPUT:Activate(self, self.control)
                if not KEYBIND_STRIP:HasKeybindButton(self.keybindButton) then
                    KEYBIND_STRIP:AddKeybindButton(self.keybindButton)
                    buttonApplied = true
                end
            elseif newState == SCENE_FRAGMENT_HIDING then
                if buttonApplied then
                    KEYBIND_STRIP:RemoveKeybindButton(self.keybindButton)
                    buttonApplied = false
                end
                DIRECTIONAL_INPUT:Deactivate(self)
                self.gamepadCursor:UpdateVisibility(false)
            end
        end
    )

    MOUSE_POINTER_FRAGMENT = fragment
end

function lib:UpdateDirectionalInput()
    self.gamepadCursor:UpdateDirectionalInput()
end

function lib:ResetPosition()
    self.gamepadCursor:ResetPosition()
end

function lib:GetCursorPosition()
    if not self.gamepadCursor then
        return -1, -1
    end
    return self.gamepadCursor:GetCursorPosition()
end

function lib:GetControlAtCursor(desiredHandlers)
    if not self.gamepadCursor then
        return nil
    end
    return self.gamepadCursor:GetControlAtCursor(desiredHandlers)
end

function lib:InvokeClick(button, desiredHandlers)
    if not self.gamepadCursor then
        return
    end
    local control = self:GetControlAtCursor(desiredHandlers)
    if not control then
        return
    end
    button = button or MOUSE_BUTTON_INDEX_LEFT
    local handler = control:GetHandler("OnClicked")
    if handler then
        handler(control, button)
        return
    end
    handler = control:GetHandler("OnMouseDown")
    if handler then
        handler(control, button)
    end
    handler = control:GetHandler("OnMouseUp")
    if handler then
        zo_callLater(
            function()
                handler(control, button)
            end,
            100
        )
    end
end

local function AddonLoaded(eventType, addonName)
    if addonName ~= lib.name then
        return
    end
    EVENT_MANAGER:UnregisterForEvent(lib.name, EVENT_ADD_ON_LOADED)
    lib:Initialize()
end

EVENT_MANAGER:RegisterForEvent(lib.name, EVENT_ADD_ON_LOADED, AddonLoaded)

LibMousePointer = lib
