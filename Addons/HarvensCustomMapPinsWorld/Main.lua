local pi = math.pi
local atan2 = math.atan2
local async = LibAsync
local gps = LibGPS3

local pinInfo

local function Hook(HarvensCustomMapPins)
    local fov = pi * 0.4

    local task = async:Create("HARVENS_CUSTOMPINS_WORLDPINS")

    local measurementControl = CreateControl("HarvensCustomMapPinsCamera", GuiRoot, CT_CONTROL)
    measurementControl:Create3DRenderSpace()

    local function GetCamera3DPosition()
        Set3DRenderSpaceToCurrentCamera(measurementControl:GetName())
        local worldX, worldZ, worldY = measurementControl:Get3DRenderSpaceOrigin()
        worldX, worldZ, worldY = GuiRender3DPositionToWorldPosition(worldX, worldZ, worldY)
        return worldX / 100, worldY / 100, worldZ / 100
    end

    local function GetPlayer3DPosition()
        local _, worldX, worldZ, worldY = GetUnitRawWorldPosition("player")
        return worldX, worldY, worldZ
    end

    function HarvensCustomMapPins:Update3dPins(timeMs)
        self.timeInMs = timeInMs
        task:Cancel()

        local currentPins, tileName, currentFloor = self:GetCurrentMapPins()
        if not currentPins or not next(currentPins) then
            self.worldPinPool:ReleaseAllObjects()
            ZO_ClearTable(self.worldKeys)
            return
        end

        local heading = GetPlayerCameraHeading()
        if heading > pi then --normalize heading to [-pi,pi]
            heading = heading - 2 * pi
        end

        local x, y = GetCamera3DPosition()
        local ox, oz, oy = HarvensCustomMapPinsWorld:Get3DRenderSpaceOrigin()
        local rx, ry, rz = GetPlayer3DPosition()
        local pins = HarvensCustomMapPins:GetCurrentMapPins()

        local function SyncPin(pinTag, cpin)
            local px, pz, py = gps:LocalToWorld(cpin.normalizedX, cpin.normalizedY)
            local dx, dy = px / 100, py / 100
            dx, dy = x - dx, y - dy
            local angle = -atan2(dx, dy)
            angle = angle + heading
            if angle > pi then
                angle = angle - 2 * pi
            elseif angle < -pi then
                angle = angle + 2 * pi
            end
            local key = self.worldKeys[pinTag]
            if angle >= -fov and angle <= fov then
                local normalizedDistance = (dx * dx + dy * dy) / 25000
                if normalizedDistance <= 1 then
                    local control
                    if key then
                        control = self.worldPinPool:GetActiveObject(key)
                    else
                        control, key = self:GetNewWorldPin(cpin)
                        self.worldKeys[pinTag] = key
                        control.pin = pinInfo[pinTag] or {}
                        pinInfo[pinTag] = control.pin
                    end

                    local pin = control.pin
                    if pin then
                        pz = pin.worldZ or pz

                        --- Get z-axis
                        dx, dy = px - rx, py - ry
                        local prevDistance = pin.worldDist or 1000000000000
                        normalizedDistance = dx * dx + dy * dy
                        if normalizedDistance < prevDistance then
                            pin.worldDist = normalizedDistance
                            pz = rz
                            pin.worldZ = pz
                        end
                        ---

                        px, pz, py = WorldPositionToGuiRender3DPosition(px, pz, py)
                        px, pz, py = px - ox, pz - oz, py - oy
                        control:Set3DRenderSpaceOrigin(px, pz, py)
                        control:Set3DRenderSpaceOrientation(0, GetGameTimeSeconds(), 0)
                        control.timeMs = timeMs
                        key = nil
                    end
                end
            end
            if key then
                self.worldPinPool:ReleaseObject(key)
                self.worldKeys[pinTag] = nil
            end
        end
        for _, cpin in pairs(self.pinManager:GetActiveObjects()) do
            local pinId, pinTag = cpin:GetPinTypeAndTag()
            if pinId == self.pinTypeId then
                task:Then(
                    function()
                        SyncPin(pinTag, cpin)
                    end
                )
            end
        end

        task:For(pairs(self.worldPinPool:GetActiveObjects())):Do(
            function(key, control)
                if control.timeMs < timeMs then
                    d("weg")
                    self.worldPinPool:ReleaseObject(key)
                end
            end
        )
    end

    function HarvensCustomMapPins:Initialize3D()
        self.worldPinPool = ZO_ControlPool:New("HarvensCustomMapPinsWorldPin", HarvensCustomMapPinsWorld, "Pin")
        local orgFactory = self.worldPinPool.m_Factory
        self.worldPinPool.m_Factory = function(...)
            local pin, key = orgFactory(...)
            local icon = pin.icon or pin:GetNamedChild("Texture")
            pin.icon = icon

            pin:Create3DRenderSpace()
            icon:Create3DRenderSpace()

            pin:Set3DRenderSpaceUsesDepthBuffer(false)
            icon:Set3DRenderSpaceUsesDepthBuffer(false)
            icon:Set3DRenderSpaceOrigin(0, 1, 0)

            return pin, key
        end

        HarvensCustomMapPinsWorld:Create3DRenderSpace()
        self.worldKeys = {}
        self.fragment = ZO_SimpleSceneFragment:New(HarvensCustomMapPinsWorld)
        HUD_UI_SCENE:AddFragment(self.fragment)
        HUD_SCENE:AddFragment(self.fragment)
        --LOOT_SCENE:AddFragment(self.fragment)

        local function UpdatePins(timeMs)
            if self.fragment:IsHidden() then
                return
            end
            self:Update3dPins(timeMs)
        end
        local function updateOrigin()
            self.worldPinPool:ReleaseAllObjects()
            ZO_ClearTable(self.worldKeys)
            local worldX, worldZ, worldY = WorldPositionToGuiRender3DPosition(0, 0, 0)
            HarvensCustomMapPinsWorld:Set3DRenderSpaceOrigin(worldX, worldZ, worldY)

            EVENT_MANAGER:UnregisterForUpdate("HarvensCustomMapPinsWorldPins")
            EVENT_MANAGER:RegisterForUpdate("HarvensCustomMapPinsWorldPins", 30, UpdatePins)
        end

        EVENT_MANAGER:RegisterForEvent("HarvensCustomMapPinsWorldPins", EVENT_PLAYER_ACTIVATED, updateOrigin)
        CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", updateOrigin)

        SecurePostHook(
            ESO_Dialogs["HARVENS_CUSTOM_MAP_PINS_EDIT"].buttons[1],
            "callback",
            function(dialog)
                HarvensCustomMapPins:RemoveWorldPin(dialog.data.key)
            end
        )
    end

    function HarvensCustomMapPins:GetNewWorldPin(cpin)
        local pin, pinKey = self.worldPinPool:AcquireObject()

        local size = self.sv.pinSize * 0.25
        pin.icon:Set3DLocalDimensions(0.25 * size + 0.5, 0.25 * size + 0.5)
        pin.icon:SetTexture(cpin.backgroundControl:GetTextureFileName())
        pin.icon:SetColor(cpin.backgroundControl:GetColor())

        return pin, pinKey
    end
    function HarvensCustomMapPins:RemoveWorldPin(pinTag)
        local key = self.worldKeys[pinTag]
        if key then
            self.worldPinPool:ReleaseObject(key)
            self.worldKeys[pinTag] = nil
        end
    end
    local orgDeletePin = HarvensCustomMapPins.DeletePin
    function HarvensCustomMapPins:DeletePin(pinTag)
        pinInfo[pinTag] = nil
        return orgDeletePin(self, pinTag)
    end
end

local function AddonLoaded(eventCode, addOnName)
    if addOnName ~= "HarvensCustomMapPinsWorld" then
        return
    end

    EVENT_MANAGER:UnregisterForEvent("HarvensCustomMapPinsWorld", EVENT_ADD_ON_LOADED)

    pinInfo = HarvensCustomMapPinsWorld_Data or {}
    HarvensCustomMapPinsWorld_Data = pinInfo

    Hook(HarvensCustomMapPins)

    HarvensCustomMapPins:Initialize3D()
end

EVENT_MANAGER:RegisterForEvent("HarvensCustomMapPinsWorld", EVENT_ADD_ON_LOADED, AddonLoaded)
