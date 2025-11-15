Demo = { name = "LibHarvensAddonSettingsDemo" }

Demo.defaults = {
	
}

function Demo.Initialize()
	Demo.savedVariables = ZO_SavedVars:NewAccountWide("DemoSavedVariables", 1, nil, Demo.defaults, GetWorldName())
	
	settings = LibHarvensAddonSettings:AddAddon("Example")

	--Initialize some stuff here since there's a lot of cross-referencing below.
	 expandButton = nil
	 collapse = nil
	local add1 = nil
	local remove1 = nil
	local menu1, menu2 = nil, nil

	--Static indexes. We can save them on creation instead of recalculating them on button click.
	local expandButton_index = nil
	local add1_index = nil
	

	local menuLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Main Menu",}

	--Blank dummy setting
	local textinput = {
		type = LibHarvensAddonSettings.ST_EDIT,
		label = "Example input",
		tooltip = "",
		getFunction = function() return ""  end,
		setFunction = function(value)  end,
		default = ""
	}

	local back = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "BACK",
		buttonText = "BACK",
		tooltip = "",
		clickHandler = function(control)
			settings:RemoveAllSettings()
			settings:AddSettings({menuLabel, menu1, menu2}, nil, true)
			if IsConsoleUI() then
				LibHarvensAddonSettings.list:SetSelectedIndexWithoutAnimation(2)
			end
		end
	}

	---------------------------------------
	---				Menu 1				---
	---------------------------------------

	local section1 = {type = LibHarvensAddonSettings.ST_SECTION,label = "Section 1",}

	collapse = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "COLLAPSE",
		buttonText = "Collapse this section",
		tooltip = "",
		clickHandler = function(control)
			local currentIndex = settings:GetIndexOf(collapse, true) - 10
			
			settings:RemoveSettings(currentIndex, 11)

			settings:AddSetting(expandButton, currentIndex)
			
			if IsConsoleUI() then
				LibHarvensAddonSettings.list:SetSelectedIndexWithoutAnimation(2)
			end
			
		end
	}


	expandButton = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "EXPAND",
		buttonText = "Expand this section",
		tooltip = "",
		clickHandler = function(control)
			local currentIndex = settings:GetIndexOf(expandButton, true)
				
			settings:RemoveSettings(currentIndex, 1)

			for i = 1, 10 do
				settings:AddSetting(textinput, currentIndex)
			end

			settings:AddSetting(collapse, currentIndex + 10)
			if IsConsoleUI() then
				LibHarvensAddonSettings.list:SetSelectedIndexWithoutAnimation(currentIndex)
			end
		end
	}

	--Initialize submenu groups after initializing their respective settings and before initializing the menus.
	local sect1 = {section1, expandButton, back}

	menu1 = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "MENU ONE",
		buttonText = "MENU ONE",
		tooltip = "",
		clickHandler = function(control)
			settings:RemoveAllSettings()
			local _, indexes = settings:AddSettings(sect1, nil, true)
			expandButton_index = indexes[2]
			if IsConsoleUI() then
				LibHarvensAddonSettings.list:SetSelectedIndexWithoutAnimation(2)
			end
		end
	}

	---------------------------------------
	---				Menu 2				---
	---------------------------------------

	local section2 = {type = LibHarvensAddonSettings.ST_SECTION,label = "Section 2",}

	add1 = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "ADD ONE",
		buttonText = "ADD ONE",
		tooltip = "",
		clickHandler = function(control)
			settings:AddSetting(textinput, settings:GetIndexOf(add1, true) + 1)
		end
	}

	remove1 = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "REMOVE ONE",
		buttonText = "REMOVE ONE",
		tooltip = "",
		clickHandler = function(control)
			local removeIndex = settings:GetIndexOf(remove1, true)
			local addIndex = settings:GetIndexOf(add1, true)
			if removeIndex - 1 ~= addIndex then
				settings:RemoveSettings(removeIndex - 1, 1)
			end
		end
	}

	--Initialize submenu groups after initializing their respective settings and before initializing the menus.
	local sect2 = {section2, add1, remove1, back}

	menu2 = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "MENU TWO",
		buttonText = "MENU TWO",
		tooltip = "",
		clickHandler = function(control)
			settings:RemoveAllSettings()
			local _, indexes = settings:AddSettings(sect2, nil, true)
			add1_index = indexes[2]
			if IsConsoleUI() then
				LibHarvensAddonSettings.list:SetSelectedIndexWithoutAnimation(2)
			end
		end
	}


	---------------------------------------
	---				Menu 3				---
	---------------------------------------
	
	settings:AddSettings({menuLabel, menu1, menu2})
end

function Demo.OnAddOnLoaded(event, addonName)
	if addonName == Demo.name then
		Demo.Initialize()
		EVENT_MANAGER:UnregisterForEvent(Demo.name, EVENT_ADD_ON_LOADED)
	end
end

EVENT_MANAGER:RegisterForEvent(Demo.name, EVENT_ADD_ON_LOADED, Demo.OnAddOnLoaded)