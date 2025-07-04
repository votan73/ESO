-- Example Addon using LibHarvensAddonSettings
-- This demonstrates all the major features and patterns

local ADDON_NAME = "ExampleAddon"
local ADDON_VERSION = "1.0.0"

-- Create the addon namespace
local ExampleAddon = {}
ExampleAddon.name = ADDON_NAME
ExampleAddon.version = ADDON_VERSION

-- Saved variables with defaults
local savedVarsDefaults = {
    -- Basic settings
    enabled = true,
    debug = false,
    
    -- Display settings
    showInCombat = true,
    windowOpacity = 0.8,
    fontSize = 18,
    displayMode = "Normal",
    
    -- Advanced settings
    advancedMode = false,
    updateFrequency = 5,
    maxItems = 100,
    
    -- UI customization
    windowColor = {r = 0.2, g = 0.2, b = 0.2, a = 0.8},
    textColor = {r = 1, g = 1, b = 1, a = 1},
    theme = "Default",
    iconIndex = 1,
    
    -- Features
    autoSave = true,
    playSound = true,
    showTooltips = true,
    
    -- Performance
    cacheEnabled = true,
    backgroundUpdates = false
}

local savedVars

-- Initialize saved variables
local function InitializeSavedVars()
    savedVars = ZO_SavedVars:NewAccountWide(ADDON_NAME .. "SavedVars", 1, nil, savedVarsDefaults)
end

-- Example addon methods (these would be your actual addon functions)
function ExampleAddon:IsEnabled()
    return savedVars.enabled
end

function ExampleAddon:SetDebugMode(enabled)
    savedVars.debug = enabled
    if enabled then
        d(ADDON_NAME .. ": Debug mode enabled")
    end
end

function ExampleAddon:UpdateWindowOpacity(opacity)
    -- Your code to update window opacity
    d(ADDON_NAME .. ": Window opacity set to " .. tostring(opacity))
end

function ExampleAddon:LoadTheme(themeId)
    -- Your code to load a theme
    d(ADDON_NAME .. ": Loading theme: " .. tostring(themeId))
end

function ExampleAddon:UpdateDisplayMode(mode)
    -- Your code to update display mode
    d(ADDON_NAME .. ": Display mode changed to: " .. tostring(mode))
end

function ExampleAddon:ClearCache()
    -- Your code to clear cache
    d(ADDON_NAME .. ": Cache cleared")
end

function ExampleAddon:ResetToDefaults()
    -- Custom reset logic
    d(ADDON_NAME .. ": Reset to defaults complete")
end

function ExampleAddon:GetConnectionStatus()
    -- Mock connection status
    return math.random() > 0.5 and "Connected" or "Disconnected"
end

-- Create the settings panel
local function CreateSettingsPanel()
    if not LibHarvensAddonSettings then
        d(ADDON_NAME .. ": LibHarvensAddonSettings is required!")
        return
    end

    -- Create the main settings panel
    local panel = LibHarvensAddonSettings:AddAddon(ADDON_NAME, {
        allowDefaults = true,
        defaultsFunction = function()
            d(ADDON_NAME .. ": Resetting all settings to defaults...")
            ExampleAddon:ResetToDefaults()
        end,
        allowRefresh = true  -- Enable control refresh functionality
    })

    -- SECTION: Basic Settings
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_SECTION,
        label = "Basic Settings",
        tooltip = "Core addon functionality settings"
    })

    -- Enable addon checkbox
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_CHECKBOX,
        label = "Enable " .. ADDON_NAME,
        tooltip = "Toggle the addon on/off",
        getFunction = function() return savedVars.enabled end,
        setFunction = function(value) 
            savedVars.enabled = value
            if value then
                d(ADDON_NAME .. " enabled")
            else
                d(ADDON_NAME .. " disabled")
            end
        end,
        default = true
    })

    -- Debug mode checkbox (disabled when addon is off)
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_CHECKBOX,
        label = "Debug Mode",
        tooltip = "Enable debug output to chat",
        getFunction = function() return savedVars.debug end,
        setFunction = function(value) 
            savedVars.debug = value
            ExampleAddon:SetDebugMode(value)
        end,
        disable = function() return not savedVars.enabled end,
        default = false
    })

    -- Combat visibility
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_CHECKBOX,
        label = "Show in Combat",
        tooltip = "Whether to show the addon during combat",
        getFunction = function() return savedVars.showInCombat end,
        setFunction = function(value) savedVars.showInCombat = value end,
        disable = function() return not savedVars.enabled end,
        default = true
    })

    -- SECTION: Display Settings
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_SECTION,
        label = "Display Settings",
        tooltip = "Visual appearance and layout options"
    })

    -- Window opacity slider
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_SLIDER,
        label = "Window Opacity",
        tooltip = "Adjust window transparency",
        min = 0.1,
        max = 1.0,
        step = 0.01,
        format = "%.2f",
        unit = "%",
        getFunction = function() return savedVars.windowOpacity end,
        setFunction = function(value) 
            savedVars.windowOpacity = value
            ExampleAddon:UpdateWindowOpacity(value)
        end,
        disable = function() return not savedVars.enabled end,
        default = 0.8
    })

    -- Font size slider
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_SLIDER,
        label = "Font Size",
        tooltip = "Adjust text size",
        min = 12,
        max = 32,
        step = 1,
        format = "%.0f",
        unit = " px",
        getFunction = function() return savedVars.fontSize end,
        setFunction = function(value) savedVars.fontSize = value end,
        disable = function() return not savedVars.enabled end,
        default = 18
    })

    -- Display mode dropdown
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_DROPDOWN,
        label = "Display Mode",
        tooltip = "Choose how information is displayed",
        items = {
            {name = "Compact", data = "compact"},
            {name = "Normal", data = "normal"},
            {name = "Detailed", data = "detailed"},
            {name = "Full", data = "full"}
        },
        getFunction = function() return savedVars.displayMode end,
        setFunction = function(control, itemName, itemData) 
            savedVars.displayMode = itemName
            ExampleAddon:UpdateDisplayMode(itemData)
        end,
        disable = function() return not savedVars.enabled end,
        default = "Normal"
    })

    -- Theme selection with dynamic options
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_DROPDOWN,
        label = "Theme",
        tooltip = "Visual theme selection",
        items = function()
            local themes = {
                {name = "Default", data = "default"},
                {name = "Dark", data = "dark"},
                {name = "Light", data = "light"}
            }
            
            -- Add premium themes if advanced mode is enabled
            if savedVars.advancedMode then
                table.insert(themes, {name = "Custom Blue", data = "blue"})
                table.insert(themes, {name = "Custom Red", data = "red"})
            end
            
            return themes
        end,
        getFunction = function() return savedVars.theme end,
        setFunction = function(control, itemName, itemData) 
            savedVars.theme = itemName
            ExampleAddon:LoadTheme(itemData)
        end,
        disable = function() return not savedVars.enabled end,
        default = "Default"
    })

    -- SECTION: Color Settings
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_SECTION,
        label = "Color Settings",
        tooltip = "Customize colors and appearance"
    })

    -- Window background color
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_COLOR,
        label = "Window Background",
        tooltip = "Choose the window background color",
        getFunction = function() 
            return savedVars.windowColor.r, savedVars.windowColor.g, 
                   savedVars.windowColor.b, savedVars.windowColor.a 
        end,
        setFunction = function(r, g, b, a) 
            savedVars.windowColor = {r = r, g = g, b = b, a = a}
            d(ADDON_NAME .. ": Window color updated")
        end,
        disable = function() return not savedVars.enabled end,
        default = {0.2, 0.2, 0.2, 0.8}
    })

    -- Text color
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_COLOR,
        label = "Text Color",
        tooltip = "Choose the text color",
        getFunction = function() 
            return savedVars.textColor.r, savedVars.textColor.g, 
                   savedVars.textColor.b, savedVars.textColor.a 
        end,
        setFunction = function(r, g, b, a) 
            savedVars.textColor = {r = r, g = g, b = b, a = a}
        end,
        disable = function() return not savedVars.enabled end,
        default = {1, 1, 1, 1}
    })

    -- Icon picker
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_ICONPICKER,
        label = "Window Icon",
        tooltip = "Choose an icon for the window",
        items = {
            "/esoui/art/icons/achievements_indexicon_summary_up.dds",
            "/esoui/art/icons/achievements_indexicon_pvp_up.dds",
            "/esoui/art/icons/achievements_indexicon_dungeons_up.dds",
            "/esoui/art/icons/achievements_indexicon_quests_up.dds",
            "/esoui/art/icons/icon_alliance_ad.dds",
            "/esoui/art/icons/icon_alliance_dc.dds",
            "/esoui/art/icons/icon_alliance_ep.dds"
        },
        getFunction = function() return savedVars.iconIndex end,
        setFunction = function(control, iconIndex, iconPath)
            savedVars.iconIndex = iconIndex
            d(ADDON_NAME .. ": Icon changed to index " .. iconIndex)
        end,
        disable = function() return not savedVars.enabled end,
        default = 1
    })

    -- SECTION: Advanced Settings
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_SECTION,
        label = "Advanced Settings",
        tooltip = "Advanced configuration options"
    })

    -- Advanced mode toggle
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_CHECKBOX,
        label = "Advanced Mode",
        tooltip = "Enable advanced features and options",
        getFunction = function() return savedVars.advancedMode end,
        setFunction = function(value) 
            savedVars.advancedMode = value
            if value then
                d(ADDON_NAME .. ": Advanced mode enabled - more options available!")
            end
        end,
        disable = function() return not savedVars.enabled end,
        default = false
    })

    -- Update frequency (only when advanced mode is on)
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_SLIDER,
        label = "Update Frequency",
        tooltip = "How often to update data (in seconds)",
        min = 1,
        max = 30,
        step = 1,
        format = "%.0f",
        unit = " sec",
        getFunction = function() return savedVars.updateFrequency end,
        setFunction = function(value) savedVars.updateFrequency = value end,
        disable = function() return not savedVars.enabled or not savedVars.advancedMode end,
        default = 5
    })

    -- Max items (only when advanced mode is on)
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_SLIDER,
        label = "Maximum Items",
        tooltip = "Maximum number of items to display",
        min = 10,
        max = 500,
        step = 10,
        format = "%.0f",
        getFunction = function() return savedVars.maxItems end,
        setFunction = function(value) savedVars.maxItems = value end,
        disable = function() return not savedVars.enabled or not savedVars.advancedMode end,
        default = 100
    })

    -- SECTION: Feature Toggles
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_SECTION,
        label = "Features",
        tooltip = "Toggle specific addon features"
    })

    -- Auto-save feature
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_CHECKBOX,
        label = "Auto Save",
        tooltip = "Automatically save settings",
        getFunction = function() return savedVars.autoSave end,
        setFunction = function(value) savedVars.autoSave = value end,
        disable = function() return not savedVars.enabled end,
        default = true
    })

    -- Sound effects
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_CHECKBOX,
        label = "Play Sounds",
        tooltip = "Enable sound effects",
        getFunction = function() return savedVars.playSound end,
        setFunction = function(value) savedVars.playSound = value end,
        disable = function() return not savedVars.enabled end,
        default = true
    })

    -- Tooltips
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_CHECKBOX,
        label = "Show Tooltips",
        tooltip = "Display helpful tooltips",
        getFunction = function() return savedVars.showTooltips end,
        setFunction = function(value) savedVars.showTooltips = value end,
        disable = function() return not savedVars.enabled end,
        default = true
    })

    -- SECTION: Performance
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_SECTION,
        label = "Performance",
        tooltip = "Performance and optimization settings"
    })

    -- Cache enabled
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_CHECKBOX,
        label = "Enable Caching",
        tooltip = "Cache data for better performance",
        getFunction = function() return savedVars.cacheEnabled end,
        setFunction = function(value) savedVars.cacheEnabled = value end,
        disable = function() return not savedVars.enabled end,
        default = true
    })

    -- Background updates
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_CHECKBOX,
        label = "Background Updates",
        tooltip = "Update data even when window is hidden",
        getFunction = function() return savedVars.backgroundUpdates end,
        setFunction = function(value) savedVars.backgroundUpdates = value end,
        disable = function() return not savedVars.enabled or not savedVars.cacheEnabled end,
        default = false
    })

    -- SECTION: Actions
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_SECTION,
        label = "Actions",
        tooltip = "Utility actions and tools"
    })

    -- Clear cache button
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_BUTTON,
        label = "Cache Management",
        buttonText = "Clear Cache",
        tooltip = "Clear all cached data",
        clickHandler = function(control)
            ExampleAddon:ClearCache()
            d(ADDON_NAME .. ": Cache cleared successfully!")
        end
    })

    -- Status display
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_LABEL,
        label = function()
            local status = ExampleAddon:GetConnectionStatus()
            local color = status == "Connected" and "|c00ff00" or "|cff0000"
            return "Status: " .. color .. status .. "|r"
        end,
        tooltip = "Current connection status"
    })

    -- Version info
    panel:AddSetting({
        type = LibHarvensAddonSettings.ST_LABEL,
        label = "Version: " .. ADDON_VERSION,
        tooltip = "Current addon version"
    })

    d(ADDON_NAME .. ": Settings panel created successfully!")
end

-- Addon initialization
local function OnAddonLoaded(eventCode, addonName)
    if addonName ~= ADDON_NAME then
        return
    end

    -- Unregister the event
    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

    -- Initialize saved variables
    InitializeSavedVars()

    -- Create settings panel
    CreateSettingsPanel()

    -- Initialize your addon here
    d(ADDON_NAME .. " " .. ADDON_VERSION .. " loaded!")
end

-- Register for addon loaded event
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)

-- Example of how to access settings from other parts of your addon:
-- if savedVars.enabled then
--     -- Do something when addon is enabled
-- end
--
-- if savedVars.debug then
--     d("Debug: some debug message")
-- end 