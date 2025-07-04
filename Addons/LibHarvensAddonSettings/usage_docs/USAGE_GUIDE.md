# LibHarvensAddonSettings Usage Guide

LibHarvensAddonSettings is a library for Elder Scrolls Online addons that provides a unified settings interface supporting both PC/keyboard and console/gamepad inputs. It automatically integrates with the game's Settings menu.

## Quick Start

```lua
-- Make sure the library is available
if not LibHarvensAddonSettings then
    d("LibHarvensAddonSettings is required!")
    return
end

-- Your addon's saved variables
local savedVars = {}

-- Create addon settings panel
local panel = LibHarvensAddonSettings:AddAddon("My Awesome Addon", {
    allowDefaults = true,  -- Show "Reset to Defaults" button
    allowRefresh = true    -- Enable control refresh callbacks
})
```

## Basic Settings Examples

### Checkbox Settings

```lua
-- Simple checkbox
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_CHECKBOX,
    label = "Enable Feature",
    tooltip = "Check this to enable the awesome feature",
    getFunction = function() return savedVars.enableFeature end,
    setFunction = function(value) savedVars.enableFeature = value end,
    default = true  -- For reset functionality
})

-- Checkbox with dynamic label and complex disable logic
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_CHECKBOX,
    label = function() 
        return savedVars.advancedMode and "Advanced Feature" or "Basic Feature" 
    end,
    tooltip = "This feature behavior changes based on your mode",
    getFunction = function() return savedVars.dynamicFeature end,
    setFunction = function(value) savedVars.dynamicFeature = value end,
    disable = function() 
        return not savedVars.enableFeature -- Disabled if main feature is off
    end,
    default = false
})
```

### Slider Settings

```lua
-- Basic number slider
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_SLIDER,
    label = "Update Frequency",
    tooltip = "How often to update in seconds",
    min = 1,
    max = 60,
    step = 1,
    getFunction = function() return savedVars.updateFrequency end,
    setFunction = function(value) savedVars.updateFrequency = value end,
    default = 5
})

-- Slider with units and custom formatting
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_SLIDER,
    label = "Opacity",
    tooltip = "Window transparency level",
    min = 0,
    max = 1,
    step = 0.01,
    format = "%.2f",  -- Show 2 decimal places
    unit = "%",       -- Add % suffix
    getFunction = function() return savedVars.opacity end,
    setFunction = function(value) 
        savedVars.opacity = value
        MyAddon:UpdateWindowOpacity(value)  -- Update immediately
    end,
    default = 0.8
})

-- Slider with dynamic unit text
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_SLIDER,
    label = "Distance Threshold",
    min = 1,
    max = 100,
    step = 1,
    unit = function() 
        return savedVars.useMetric and " meters" or " feet"
    end,
    getFunction = function() return savedVars.distance end,
    setFunction = function(value) savedVars.distance = value end,
    default = 10
})
```

### Text Input Settings

```lua
-- Simple text input
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_EDIT,
    label = "Player Name",
    tooltip = "Enter your character name",
    getFunction = function() return savedVars.playerName end,
    setFunction = function(value) savedVars.playerName = value end,
    default = ""
})

-- Text input with restrictions
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_EDIT,
    label = "API Key",
    tooltip = "Enter your API key (numbers only)",
    textType = TEXT_TYPE_NUMERIC,  -- Only allow numbers
    maxChars = 20,  -- Limit input length
    getFunction = function() return savedVars.apiKey end,
    setFunction = function(value) 
        savedVars.apiKey = value
        MyAddon:ValidateApiKey(value)
    end,
    default = ""
})
```

### Dropdown Settings

```lua
-- Simple dropdown with static items
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_DROPDOWN,
    label = "Display Mode",
    tooltip = "Choose how information is displayed",
    items = {
        {name = "Compact", data = 1},
        {name = "Normal", data = 2},
        {name = "Detailed", data = 3}
    },
    getFunction = function() return savedVars.displayMode end,
    setFunction = function(control, itemName, itemData) 
        savedVars.displayMode = itemName
        savedVars.displayModeId = itemData
        MyAddon:UpdateDisplayMode(itemData)
    end,
    default = "Normal"
})

-- Dynamic dropdown that changes based on other settings
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_DROPDOWN,
    label = "Theme",
    tooltip = "Visual theme selection",
    items = function()
        local themes = {
            {name = "Default", data = "default"},
            {name = "Dark", data = "dark"}
        }
        
        -- Add premium themes if unlocked
        if savedVars.premiumUnlocked then
            table.insert(themes, {name = "Gold", data = "gold"})
            table.insert(themes, {name = "Royal", data = "royal"})
        end
        
        return themes
    end,
    getFunction = function() return savedVars.theme end,
    setFunction = function(control, itemName, itemData) 
        savedVars.theme = itemName
        MyAddon:LoadTheme(itemData)
    end,
    default = "Default"
})
```

### Color Settings

```lua
-- Color picker
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_COLOR,
    label = "Window Color",
    tooltip = "Choose the window background color",
    getFunction = function() 
        return savedVars.windowColor.r, savedVars.windowColor.g, 
               savedVars.windowColor.b, savedVars.windowColor.a 
    end,
    setFunction = function(r, g, b, a) 
        savedVars.windowColor = {r = r, g = g, b = b, a = a}
        MyAddon:UpdateWindowColor(r, g, b, a)
    end,
    default = {0.2, 0.2, 0.2, 0.8}  -- Dark gray with transparency
})
```

### Button Settings

```lua
-- Simple action button
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_BUTTON,
    label = "Configuration",
    buttonText = "Reset All Data",
    tooltip = "WARNING: This will delete all saved data!",
    clickHandler = function(control)
        -- Show confirmation dialog
        ZO_Dialogs_ShowDialog("MY_ADDON_CONFIRM_RESET")
    end
})

-- Button with dynamic text
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_BUTTON,
    label = "Database",
    buttonText = function()
        return MyAddon:HasDatabase() and "Update Database" or "Download Database"
    end,
    tooltip = "Manage the addon database",
    clickHandler = function(control)
        if MyAddon:HasDatabase() then
            MyAddon:UpdateDatabase()
        else
            MyAddon:DownloadDatabase()
        end
    end
})
```

### Label and Section Settings

```lua
-- Section header to organize settings
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_SECTION,
    label = "Display Options",
    tooltip = "Settings that affect how information is displayed"
})

-- Informational label
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_LABEL,
    label = "Version: " .. MyAddon.version,
    tooltip = "Current addon version information"
})

-- Dynamic status label
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_LABEL,
    label = function()
        local status = MyAddon:GetConnectionStatus()
        local color = status == "connected" and "|c00ff00" or "|cff0000"
        return color .. "Status: " .. status .. "|r"
    end,
    tooltip = "Real-time connection status"
})
```

### Icon Picker Settings

```lua
-- Icon selection
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_ICONPICKER,
    label = "Window Icon",
    tooltip = "Choose an icon for your window",
    items = {
        "/esoui/art/icons/icon_alliance_ad.dds",
        "/esoui/art/icons/icon_alliance_dc.dds", 
        "/esoui/art/icons/icon_alliance_ep.dds",
        "/esoui/art/icons/achievements_indexicon_summary_up.dds"
    },
    getFunction = function() return savedVars.iconIndex end,
    setFunction = function(control, iconIndex, iconPath)
        savedVars.iconIndex = iconIndex
        savedVars.iconPath = iconPath
        MyAddon:UpdateWindowIcon(iconPath)
    end,
    default = 1
})
```

## Advanced Usage Patterns

### Conditional Settings with Dependencies

```lua
-- Create multiple settings that depend on each other
local enabledCheckbox = panel:AddSetting({
    type = LibHarvensAddonSettings.ST_CHECKBOX,
    label = "Enable Advanced Features",
    getFunction = function() return savedVars.advancedEnabled end,
    setFunction = function(value) savedVars.advancedEnabled = value end,
    default = false
})

-- These settings are only enabled when the checkbox above is checked
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_SLIDER,
    label = "Advanced Setting 1",
    min = 1, max = 10, step = 1,
    getFunction = function() return savedVars.advancedSetting1 end,
    setFunction = function(value) savedVars.advancedSetting1 = value end,
    disable = function() return not savedVars.advancedEnabled end,
    default = 5
})

panel:AddSetting({
    type = LibHarvensAddonSettings.ST_DROPDOWN,
    label = "Advanced Setting 2", 
    items = {{name = "Option A"}, {name = "Option B"}},
    getFunction = function() return savedVars.advancedSetting2 end,
    setFunction = function(control, name) savedVars.advancedSetting2 = name end,
    disable = function() return not savedVars.advancedEnabled end,
    default = "Option A"
})
```

### Complex Settings with Multiple Functions

```lua
-- Settings that affect multiple systems
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_DROPDOWN,
    label = "UI Scale",
    tooltip = "Affects all window sizes and positions",
    items = {
        {name = "Small", data = 0.8},
        {name = "Normal", data = 1.0}, 
        {name = "Large", data = 1.2},
        {name = "Extra Large", data = 1.5}
    },
    getFunction = function() return savedVars.uiScaleName end,
    setFunction = function(control, itemName, itemData)
        savedVars.uiScaleName = itemName
        savedVars.uiScale = itemData
        
        -- Update all windows immediately
        MyAddon:ScaleAllWindows(itemData)
        MyAddon:RepositionWindows()
        MyAddon:UpdateFontSizes(itemData)
        
        -- Show restart notice for some changes
        if itemData ~= 1.0 then
            d("Some changes require /reloadui to take full effect")
        end
    end,
    default = "Normal"
})
```

### Panel with Reset Functionality

```lua
-- Create panel with custom reset behavior
local panel = LibHarvensAddonSettings:AddAddon("My Addon", {
    allowDefaults = true,
    defaultsFunction = function()
        -- Custom logic when reset button is pressed
        d("Resetting My Addon to defaults...")
        
        -- Reset some values that aren't handled by individual controls
        savedVars.firstTimeUser = true
        savedVars.tutorialComplete = false
        
        -- Trigger UI updates
        MyAddon:ResetToDefaults()
        MyAddon:ShowWelcomeMessage()
    end,
    allowRefresh = true  -- Enables controls to update each other
})
```

### Adding Multiple Settings at Once

```lua
-- Define all settings in a table and add them together
local allSettings = {
    {
        type = LibHarvensAddonSettings.ST_SECTION,
        label = "Basic Settings"
    },
    {
        type = LibHarvensAddonSettings.ST_CHECKBOX,
        label = "Enable Addon",
        getFunction = function() return savedVars.enabled end,
        setFunction = function(value) savedVars.enabled = value end,
        default = true
    },
    {
        type = LibHarvensAddonSettings.ST_SLIDER,
        label = "Update Rate",
        min = 1, max = 30, step = 1,
        getFunction = function() return savedVars.updateRate end,
        setFunction = function(value) savedVars.updateRate = value end,
        default = 5
    },
    {
        type = LibHarvensAddonSettings.ST_SECTION,
        label = "Display Settings"  
    },
    {
        type = LibHarvensAddonSettings.ST_COLOR,
        label = "Text Color",
        getFunction = function() return unpack(savedVars.textColor) end,
        setFunction = function(r, g, b, a) savedVars.textColor = {r, g, b, a} end,
        default = {1, 1, 1, 1}
    }
}

-- Add all settings at once
local controls = panel:AddSettings(allSettings)

-- You can still access individual controls if needed
local enableControl = controls[2]  -- The checkbox
```

## Integration Tips

### Saved Variables Integration

```lua
-- Typical saved variables setup for settings
local defaults = {
    enabled = true,
    updateFrequency = 5,
    windowColor = {r = 0.2, g = 0.2, b = 0.2, a = 0.8},
    theme = "Default",
    displayMode = "Normal"
}

local function InitializeSavedVars()
    savedVars = ZO_SavedVars:NewAccountWide("MyAddonSavedVars", 1, nil, defaults)
end

-- Call this in your addon initialization
EVENT_MANAGER:RegisterForEvent("MyAddon", EVENT_ADD_ON_LOADED, function(eventCode, addonName)
    if addonName == "MyAddon" then
        InitializeSavedVars()
        CreateSettingsPanel()  -- Your function that creates the settings
    end
end)
```

### Localization Support

```lua
-- Use string IDs for localization
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_CHECKBOX,
    label = function() return GetString(SI_MYADDON_ENABLE_FEATURE) end,
    tooltip = function() return GetString(SI_MYADDON_ENABLE_FEATURE_TOOLTIP) end,
    -- ... other settings
})

-- Or define a helper function
local function L(stringId)
    return function() return GetString(stringId) end
end

panel:AddSetting({
    type = LibHarvensAddonSettings.ST_CHECKBOX,
    label = L(SI_MYADDON_ENABLE_FEATURE),
    tooltip = L(SI_MYADDON_ENABLE_FEATURE_TOOLTIP),
    -- ... other settings
})
```

### Performance Considerations

- Use functions for dynamic values that change frequently
- Keep getFunction and setFunction lightweight
- Avoid heavy computations in disable functions
- Cache expensive lookups outside of the settings functions

```lua
-- Good: Cache expensive data
local availableThemes = MyAddon:GetAvailableThemes()  -- Expensive call

panel:AddSetting({
    type = LibHarvensAddonSettings.ST_DROPDOWN,
    items = availableThemes,  -- Use cached data
    -- ...
})

-- Avoid: Expensive call every time dropdown opens
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_DROPDOWN,
    items = function() return MyAddon:GetAvailableThemes() end,  -- Bad!
    -- ...
})
```

This library provides a powerful and flexible way to create addon settings that work seamlessly across all ESO interfaces. The key is understanding how the different control types work and leveraging the callback system effectively for dynamic UIs. 