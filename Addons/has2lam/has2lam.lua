local LibHarvensAddonSettings = LibHarvensAddonSettings

local function HookLibHarvensAddonSettings()
	local lam = LibAddonMenu2
	if lam == nil then return end
	local currentSettings

	local AddonSettings = LibHarvensAddonSettings.AddonSettings
	local AddonSettingsControl = LibHarvensAddonSettings.AddonSettingsControl

	-----
	-- AddonSettingsControl class - represents single option control
	-----
	local orgCreateControl = AddonSettingsControl.CreateControl
	function AddonSettingsControl:CreateControl(lastControl)
		local control = orgCreateControl(self, lastControl)
		control:SetWidth(587)
		return control
	end
	-----

	-----
	-- AddonSettings class - represents addon settings panel
	-----
	function AddonSettings:Select()
		if self.selected then return end
		LibHarvensAddonSettings:DetachContainer()
		CALLBACK_MANAGER:FireCallbacks("LibHarvensAddonSettings_AddonSelected", self.name, self)
		LibHarvensAddonSettings:AttachContainerToControl(self.control)

		self.selected = true
		self:UpdateHighlight()
	end

	function AddonSettings:InitHandlers()
		CALLBACK_MANAGER:RegisterCallback("LibHarvensAddonSettings_AddonSelected", function(name)
			if self.selected then
				self:CleanUp()
				self.selected = false
				self:UpdateHighlight()
			end
		end )
	end

	function AddonSettings:UpdateHighlight()
		-- Hook placeholder
	end

	function AddonSettings:AddToOptionsPanel(panelID)
	end


	-----
	-- LibHarvensAddonSettings singleton
	-----
	function LibHarvensAddonSettings:AttachContainerToControl(control)
		self.container:ClearAnchors()
		self.container:SetParent(control.scroll)
		self.container:SetAnchor(TOPLEFT, control.scroll, TOPLEFT, 0, 0)
		self.container:SetHeight(0)
		self.container:SetResizeToFitDescendents(true)
		self.container:SetResizeToFitPadding(48, 10)
		self.container:SetHidden(false)
		self.container.currentHeight = 0
	end

	function LibHarvensAddonSettings:SetContainerHeightPercentage(progress)
	end

	function LibHarvensAddonSettings:SelectFirstAddon()
	end

	function LibHarvensAddonSettings:CreateAddonSettingsPanel()
		self.container = WINDOW_MANAGER:CreateControl("LibHarvensAddonSettingsContainer", GuiRoot, CT_SCROLL)
		self.container:SetHidden(true)
		self.container.currentHeight = 0
		self.container.endHeight = 0

		self.openTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TreeOpenAnimation")
		local anim = self.openTimeline:GetFirstAnimation()
		anim:SetUpdateFunction( function(animation, progress) self:SetContainerHeightPercentage(progress) end)
		anim:SetEasingFunction(ZO_EaseOutQuadratic)

		CALLBACK_MANAGER:RegisterCallback("LibHarvensAddonSettings_AddonSelected", function(_, addonSettings)
			currentSettings = addonSettings
			addonSettings:CreateControls()
			self.container.endHeight = addonSettings:GetOverallHeight() + 8
		end )
	end

	local function RefreshPanel(panel)
		local addonSettings = panel and panel.addonSettings
		if addonSettings and addonSettings.Select then
			if not addonSettings.selected then
				addonSettings:Select()
			end
			LibHarvensAddonSettings:RefreshAddonSettings()
		end
	end

	function LibHarvensAddonSettings:CreateAddonList()
		local prev = nil
		local function CreateSingleAddon(i)
			local addon = LibHarvensAddonSettings.addons[i]
			local addonName = addon.name
			local author, name = addonName:match("^(.+)'s%s(.+)")
			if name == nil then name = addonName end
			if addon.author then author = addon.author end
			local panelData = {
				type = "panel",
				name = name,
				displayName = name,
				author = author,
				version = addon.version,
				registerForRefresh = true,
				registerForDefaults = addon.allowDefaults,
				resetFunc = function()
					if addon == currentSettings then
						addon:ResetToDefaults()
					end
				end,
				website = addon.website,
			}
			local control = lam:RegisterAddonPanel(addonName, panelData)

			addon.control = control
			control.addonSettings = addon
			addon:InitHandlers()

			prev = addon
		end
		local function Finalize()
			if prev ~= nil then
				CALLBACK_MANAGER:RegisterCallback("LAM-RefreshPanel", RefreshPanel)
			end
		end
		for i = 1, #LibHarvensAddonSettings.addons do CreateSingleAddon(i) end
		Finalize()
	end
end

-- Hook newest version, even if newer than the included version
local function PlayerActivated()
	EVENT_MANAGER:UnregisterForEvent("has2lam", EVENT_PLAYER_ACTIVATED)
	HookLibHarvensAddonSettings()
	--LibHarvensAddonSettings:Initialize()
end

EVENT_MANAGER:RegisterForEvent("has2lam", EVENT_PLAYER_ACTIVATED, PlayerActivated)
