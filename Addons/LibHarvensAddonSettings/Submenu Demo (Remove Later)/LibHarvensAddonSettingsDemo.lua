Demo = { name = "LibHarvensAddonSettingsDemo" }

Demo.defaults = {
	
}

function Demo.Initialize()
	Demo.savedVariables = ZO_SavedVars:NewAccountWide("DemoSavedVariables", 1, nil, Demo.defaults, GetWorldName())
	
	settings = LibHarvensAddonSettings:AddAddon("Example")

	--Initialize everything here since there's a lot of cross-referencing below.
	local section1 = {type = LibHarvensAddonSettings.ST_SECTION,label = "Section 1",}
	local section2 = {type = LibHarvensAddonSettings.ST_SECTION,label = "Section 2",}
	local expandButton = {nil}
	local collapse = nil
	local textinput = nil
	local add1 = nil
	local remove1 = nil
	local menu1, menu2 = nil, nil
	local back = nil
	
	collapse = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "COLLAPSE",
		buttonText = "Collapse this section",
		tooltip = "",
		clickHandler = function(control)
			local currentIndex = settings:GetIndexOf(collapse) - 10
			
			settings:RemoveSettings(currentIndex, 11)

			settings:AddSetting(expandButton, currentIndex)
			
			if IsConsoleUI() then
				LibHarvensAddonSettings.list:SetSelectedIndexWithoutAnimation(2)
			end
			
		end
	}

	textinput = {
		type = LibHarvensAddonSettings.ST_EDIT,
		label = "Example input",
		tooltip = "",
		getFunction = function() return ""  end,
		setFunction = function(value)  end,
		default = ""
	}

	expandButton = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "EXPAND",
		buttonText = "Expand this section",
		tooltip = "",
		clickHandler = function(control)
			local currentIndex = settings:GetIndexOf(expandButton)
				
			settings:RemoveSettings(currentIndex)

			for i = 1, 10 do
				settings:AddSetting(textinput, currentIndex)
			end

			settings:AddSetting(collapse, currentIndex + 10)
			if IsConsoleUI() then
				LibHarvensAddonSettings.list:SetSelectedIndexWithoutAnimation(currentIndex)
			end
		end
	}

	add1 = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "ADD ONE",
		buttonText = "ADD ONE",
		tooltip = "",
		clickHandler = function(control)
			settings:AddSetting(textinput, settings:GetIndexOf(add1) + 1)
		end
	}

	remove1 = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "REMOVE ONE",
		buttonText = "REMOVE ONE",
		tooltip = "",
		clickHandler = function(control)
			local removeIndex = settings:GetIndexOf(remove1)
			local addIndex = settings:GetIndexOf(add1)
			if removeIndex - 1 ~= addIndex then
				settings:RemoveSettings(removeIndex - 1, 1)
			end
		end
	}


	back = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "BACK",
		buttonText = "BACK",
		tooltip = "",
		clickHandler = function(control)
			settings:RemoveAllSettings()
			settings:AddSettings({menu1, menu2})
			if IsConsoleUI() then
				LibHarvensAddonSettings.list:SetSelectedIndexWithoutAnimation(1)
			end
		end
	}

	--Initialize submenu groups after initializing their respective settings and before initializing the menus.
	local sect1 = {section1, expandButton, back}
	local sect2 = {section2, add1, remove1, back}

	menu1 = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "MENU ONE",
		buttonText = "MENU ONE",
		tooltip = "",
		clickHandler = function(control)
			settings:RemoveAllSettings()
			settings:AddSettings(sect1)
			if IsConsoleUI() then
				LibHarvensAddonSettings.list:SetSelectedIndexWithoutAnimation(2)
			end
		end
	}
	
	menu2 = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "MENU TWO",
		buttonText = "MENU TWO",
		tooltip = "",
		clickHandler = function(control)
			settings:RemoveAllSettings()
			settings:AddSettings(sect2)
			if IsConsoleUI() then
				LibHarvensAddonSettings.list:SetSelectedIndexWithoutAnimation(2)
			end
		end
	}

	settings:AddSettings({menu1, menu2})
end

function Demo.OnAddOnLoaded(event, addonName)
	if addonName == Demo.name then
		Demo.Initialize()
		EVENT_MANAGER:UnregisterForEvent(Demo.name, EVENT_ADD_ON_LOADED)
	end
end

EVENT_MANAGER:RegisterForEvent(Demo.name, EVENT_ADD_ON_LOADED, Demo.OnAddOnLoaded)