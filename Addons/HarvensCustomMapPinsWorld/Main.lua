local pi = math.pi
local atan2 = math.atan2
local async = LibAsync
local gps = LibGPS3

local pinInfo
local fov = pi * 0.4

local sv

local function Hook(HarvensCustomMapPins)
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

	local function getPinId(pinTag)
		local _, pwx1, _, pwy1 = GetUnitRawWorldPosition("player")
		local _, pwx2, _, pwy2 = GetUnitWorldPosition("player")
		local mapId = GetCurrentMapId()
		return string.format("%i:%i:%i:%s", mapId, math.floor((pwx1 - pwx2) / 10000 + 0.5), math.floor((pwy1 - pwy2) / 10000 + 0.5), pinTag)
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
		local rx, ry, rz = GetPlayer3DPosition()
		local pins = HarvensCustomMapPins:GetCurrentMapPins()

		local orientation = sv.useRotation and GetGameTimeSeconds() or heading
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
				local normalizedDistance = (dx * dx + dy * dy) / 25000 / sv.distance
				if normalizedDistance <= 1 then
					local control
					if key then
						control = self.worldPinPool:GetActiveObject(key)
					else
						control, key = self:GetNewWorldPin(cpin)
						local pinId = getPinId(pinTag)
						self.worldKeys[pinTag] = key
						control.pin = pinInfo[pinId] or {}
						pinInfo[pinId] = control.pin
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
						control:Set3DRenderSpaceOrigin(px, pz, py)
						control:Set3DRenderSpaceOrientation(0, orientation, 0)
						control.timeMs = timeMs
						key = nil -- pin is visible
					end
				end
			end
			if key then -- control belongs to a pin which is not in field of view or distance
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
				if control.timeMs < timeMs then -- control does not belong to a pin anymore
					control.pin = nil
					self.worldPinPool:ReleaseObject(key)
				end
			end
		)
	end

	function HarvensCustomMapPins:Initialize3D()
		local defaults = {
			pinSize = 32,
			distance = 0.4,
			useDepth = true,
			useRotation = false
		}
		sv = ZO_SavedVars:NewAccountWide("HarvensCustomMapPinsWorld_Data", 1, nil, defaults)

		self.worldPinPool = ZO_ControlPool:New("HarvensCustomMapPinsWorldPin", HarvensCustomMapPinsWorld, "Pin")
		local orgFactory = self.worldPinPool.m_Factory
		self.worldPinPool.m_Factory = function(...)
			local pin, key = orgFactory(...)
			local icon = pin.icon or pin:GetNamedChild("Texture")
			pin.icon = icon

			pin:Create3DRenderSpace()
			icon:Create3DRenderSpace()

			pin:Set3DRenderSpaceUsesDepthBuffer(sv.useDepth)
			icon:Set3DRenderSpaceUsesDepthBuffer(sv.useDepth)

			return pin, key
		end

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

	local function Get3dSize()
		return sv.pinSize * 0.0625 + 0.5
	end
	local function ApplySize(pin, size)
		pin.icon:Set3DLocalDimensions(size, size)
		pin.icon:Set3DRenderSpaceOrigin(0, size * 0.5, 0)
	end
	function HarvensCustomMapPins:GetNewWorldPin(cpin)
		local pin, pinKey = self.worldPinPool:AcquireObject()

		ApplySize(pin, Get3dSize())
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
		local tag = string.format(":%s$", pinTag)
		for key in pairs(pinInfo) do
			if key:match(tag) then
				pinInfo[key] = nil
			end
		end
		return orgDeletePin(self, pinTag)
	end

	local LibHarvensAddonSettings = LibHarvensAddonSettings
	local settings = LibHarvensAddonSettings:AddAddon("Harven's Custom Map Pins")

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SECTION,
		label = "World Pins"
	}

	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "World pin size",
		min = 1,
		max = 200,
		step = 1,
		format = "%d",
		getFunction = function()
			return sv.pinSize
		end,
		setFunction = function(value)
			sv.pinSize = value
			local size = Get3dSize()
			for key, pin in HarvensCustomMapPins.worldPinPool:ActiveAndFreeObjectIterator() do
				ApplySize(pin, size)
			end
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Distance",
		tooltip = "If you have performance issues reducing the distance may helps. High distance with depth-buffer on is sometimes a bit exaggerated.",
		min = 1,
		max = 200,
		step = 1,
		format = "%d",
		getFunction = function()
			return sv.distance * 100
		end,
		setFunction = function(value)
			sv.distance = value / 100
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Use depth-buffer",
		tooltip = "Turn it off to see through walls and floors. You will see tricks and tweaks of level design as well.",
		getFunction = function()
			return sv.useDepth
		end,
		setFunction = function(value)
			sv.useDepth = value
			for key, pin in HarvensCustomMapPins.worldPinPool:ActiveAndFreeObjectIterator() do
				pin:Set3DRenderSpaceUsesDepthBuffer(value)
				pin.icon:Set3DRenderSpaceUsesDepthBuffer(value)
			end
		end
	}
	settings:AddSetting {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Rotate pins",
		tooltip = "Turn it on to animate the pins for better visibility.",
		getFunction = function()
			return sv.useRotation
		end,
		setFunction = function(value)
			sv.useRotation = value
		end
	}
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
