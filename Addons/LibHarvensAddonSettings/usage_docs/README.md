# LibHarvensAddonSettings

A comprehensive settings library for Elder Scrolls Online addons that provides a unified interface supporting both PC/keyboard and console/gamepad inputs. The library automatically integrates with the game's Settings menu under the "Addons" section.

## Features

- **Cross-platform support**: Works seamlessly on PC and console
- **9 control types**: Checkbox, Slider, Text Input, Dropdown, Color Picker, Button, Label, Section Header, Icon Picker
- **Dynamic content**: Support for functions that update content in real-time
- **Conditional controls**: Enable/disable controls based on other settings
- **Reset to defaults**: Built-in support for resetting settings
- **Localization friendly**: Support for string IDs and dynamic text
- **Tooltips**: Rich tooltip support with custom functions
- **Automatic UI refresh**: Controls can update each other automatically

## Quick Start

```lua
-- Ensure library is loaded
if not LibHarvensAddonSettings then
    d("LibHarvensAddonSettings is required!")
    return
end

-- Create your addon settings panel
local panel = LibHarvensAddonSettings:AddAddon("My Awesome Addon", {
    allowDefaults = true,  -- Show "Reset to Defaults" button
    allowRefresh = true    -- Enable automatic control updates
})

-- Add a simple checkbox
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_CHECKBOX,
    label = "Enable Feature",
    tooltip = "Toggle this awesome feature on/off",
    getFunction = function() return MyAddon.savedVars.enabled end,
    setFunction = function(value) MyAddon.savedVars.enabled = value end,
    default = true
})
```

## Control Types

### Available Control Types

| Constant | Type | Description |
|----------|------|-------------|
| `ST_CHECKBOX` | Checkbox | Boolean on/off toggle |
| `ST_SLIDER` | Slider | Numeric value with min/max range |
| `ST_EDIT` | Text Input | Single-line text entry |
| `ST_DROPDOWN` | Dropdown | Selection from a list of options |
| `ST_COLOR` | Color Picker | RGBA color selection |
| `ST_BUTTON` | Button | Clickable action button |
| `ST_LABEL` | Label | Display-only text |
| `ST_SECTION` | Section Header | Organizational header with divider |
| `ST_ICONPICKER` | Icon Picker | Selection from a grid of icons |

## Common Parameters

All control types support these base parameters:

- `type` **(required)**: Control type constant (ST_*)
- `label` **(required)**: Display text (string or function)
- `tooltip` *(optional)*: Tooltip text (string, number, or function)
- `default` *(optional)*: Default value for reset functionality
- `disable` *(optional)*: Boolean or function to disable control

## Detailed Examples

### Checkbox Settings

```lua
-- Basic checkbox
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_CHECKBOX,
    label = "Enable Feature",
    tooltip = "Check this to enable the awesome feature",
    getFunction = function() return savedVars.enableFeature end,
    setFunction = function(value) savedVars.enableFeature = value end,
    default = true
})

-- Conditional checkbox (disabled based on other settings)
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_CHECKBOX,
    label = "Advanced Mode",
    tooltip = "Enable advanced features",
    getFunction = function() return savedVars.advancedMode end,
    setFunction = function(value) savedVars.advancedMode = value end,
    disable = function() return not savedVars.enableFeature end, -- Disabled if main feature is off
    default = false
})
```

### Slider Settings

```lua
-- Numeric slider with units
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_SLIDER,
    label = "Update Frequency",
    tooltip = "How often to update in seconds",
    min = 1,
    max = 60,
    step = 1,
    format = "%.0f",  -- No decimal places
    unit = " seconds",
    getFunction = function() return savedVars.updateFrequency end,
    setFunction = function(value) 
        savedVars.updateFrequency = value
        MyAddon:RestartTimer(value)  -- Apply immediately
    end,
    default = 5
})

-- Percentage slider
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_SLIDER,
    label = "Window Opacity",
    min = 0,
    max = 1,
    step = 0.01,
    format = "%.2f",
    unit = "%",
    getFunction = function() return savedVars.opacity end,
    setFunction = function(value) 
        savedVars.opacity = value
        MyAddon:UpdateOpacity(value)
    end,
    default = 0.8
})
```

### Text Input Settings

```lua
-- Basic text input
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_EDIT,
    label = "Character Name",
    tooltip = "Enter your main character name",
    getFunction = function() return savedVars.characterName end,
    setFunction = function(value) savedVars.characterName = value end,
    default = ""
})

-- Restricted input (numbers only)
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_EDIT,
    label = "Guild ID",
    tooltip = "Enter guild ID (numbers only)",
    textType = TEXT_TYPE_NUMERIC,
    maxChars = 10,
    getFunction = function() return savedVars.guildId end,
    setFunction = function(value) savedVars.guildId = value end,
    default = ""
})
```

### Dropdown Settings

```lua
-- Static dropdown options
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
        MyAddon:UpdateDisplay(itemData)
    end,
    default = "Normal"
})

-- Dynamic dropdown (options change based on conditions)
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_DROPDOWN,
    label = "Available Themes",
    items = function()
        local themes = {
            {name = "Default", data = "default"},
            {name = "Dark", data = "dark"}
        }
        
        -- Add premium themes if player has access
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
    label = "Window Background",
    tooltip = "Choose the window background color",
    getFunction = function() 
        return savedVars.backgroundColor.r, savedVars.backgroundColor.g, 
               savedVars.backgroundColor.b, savedVars.backgroundColor.a 
    end,
    setFunction = function(r, g, b, a) 
        savedVars.backgroundColor = {r = r, g = g, b = b, a = a}
        MyAddon:UpdateWindowColor(r, g, b, a)
    end,
    default = {0.2, 0.2, 0.2, 0.8}
})
```

### Button Settings

```lua
-- Action button
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_BUTTON,
    label = "Database Management",
    buttonText = "Clear Cache",
    tooltip = "Clear all cached data (requires reload)",
    clickHandler = function(control)
        MyAddon:ClearCache()
        d("Cache cleared! Type /reloadui to complete.")
    end
})

-- Button with dynamic text
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_BUTTON,
    label = "Backup",
    buttonText = function()
        return MyAddon:HasBackup() and "Update Backup" or "Create Backup"
    end,
    tooltip = "Manage your settings backup",
    clickHandler = function(control)
        if MyAddon:HasBackup() then
            MyAddon:UpdateBackup()
        else
            MyAddon:CreateBackup()
        end
    end
})
```

### Labels and Sections

```lua
-- Section header for organization
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_SECTION,
    label = "Display Options",
    tooltip = "Settings that control the visual appearance"
})

-- Status label with dynamic content
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_LABEL,
    label = function()
        local status = MyAddon:GetStatus()
        local color = status == "OK" and "|c00ff00" or "|cff0000"
        return color .. "Status: " .. status .. "|r"
    end,
    tooltip = "Current addon status"
})

-- Version information
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_LABEL,
    label = "Version: " .. MyAddon.version,
    tooltip = "Current addon version"
})
```

### Icon Picker Settings

```lua
-- Icon selection
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_ICONPICKER,
    label = "Window Icon",
    tooltip = "Choose an icon for your window header",
    items = {
        "/esoui/art/icons/achievements_indexicon_summary_up.dds",
        "/esoui/art/icons/achievements_indexicon_pvp_up.dds",
        "/esoui/art/icons/achievements_indexicon_dungeons_up.dds",
        "/esoui/art/icons/achievements_indexicon_quests_up.dds"
    },
    getFunction = function() return savedVars.iconIndex end,
    setFunction = function(control, iconIndex, iconPath)
        savedVars.iconIndex = iconIndex
        savedVars.iconPath = iconPath
        MyAddon:UpdateIcon(iconPath)
    end,
    default = 1
})
```

## Advanced Usage

### Creating Complex Dependencies

```lua
-- Main feature toggle
local enableControl = panel:AddSetting({
    type = LibHarvensAddonSettings.ST_CHECKBOX,
    label = "Enable Advanced Features",
    getFunction = function() return savedVars.advancedEnabled end,
    setFunction = function(value) savedVars.advancedEnabled = value end,
    default = false
})

-- Sub-features that depend on the main toggle
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
    items = {{name = "Mode A"}, {name = "Mode B"}, {name = "Mode C"}},
    getFunction = function() return savedVars.advancedSetting2 end,
    setFunction = function(control, name) savedVars.advancedSetting2 = name end,
    disable = function() return not savedVars.advancedEnabled end,
    default = "Mode A"
})
```

### Adding Multiple Settings at Once

```lua
local settingsTable = {
    {
        type = LibHarvensAddonSettings.ST_SECTION,
        label = "Basic Configuration"
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
        label = "Refresh Rate",
        min = 1, max = 30, step = 1,
        getFunction = function() return savedVars.refreshRate end,
        setFunction = function(value) savedVars.refreshRate = value end,
        default = 5
    }
}

-- Add all settings at once
local controls = panel:AddSettings(settingsTable)
```

### Panel with Custom Reset Behavior

```lua
local panel = LibHarvensAddonSettings:AddAddon("My Addon", {
    allowDefaults = true,
    defaultsFunction = function()
        -- Custom logic when "Reset to Defaults" is pressed
        d("Resetting to defaults...")
        
        -- Perform additional reset operations
        MyAddon:ResetWindowPositions()
        MyAddon:ClearCache()
        
        -- Show completion message
        d("Reset complete! Some changes require /reloadui")
    end,
    allowRefresh = true  -- Enable automatic control updates
})
```

## Integration with Saved Variables

```lua
-- Typical saved variables setup
local defaults = {
    enabled = true,
    updateFrequency = 5,
    windowOpacity = 0.8,
    theme = "Default",
    displayMode = "Normal",
    backgroundColor = {r = 0.2, g = 0.2, b = 0.2, a = 0.8}
}

local function InitializeSettings()
    -- Load saved variables
    savedVars = ZO_SavedVars:NewAccountWide("MyAddonSavedVars", 1, nil, defaults)
    
    -- Create settings panel
    CreateSettingsPanel()
end

-- Initialize when addon loads
EVENT_MANAGER:RegisterForEvent("MyAddon", EVENT_ADD_ON_LOADED, function(eventCode, addonName)
    if addonName == "MyAddon" then
        InitializeSettings()
    end
end)
```

## Localization Support

```lua
-- Using string IDs for multi-language support
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_CHECKBOX,
    label = GetString(SI_MYADDON_ENABLE_FEATURE),
    tooltip = GetString(SI_MYADDON_ENABLE_FEATURE_TT),
    -- ... other parameters
})

-- Or use functions for dynamic localization
panel:AddSetting({
    type = LibHarvensAddonSettings.ST_CHECKBOX,
    label = function() return GetString(SI_MYADDON_ENABLE_FEATURE) end,
    tooltip = function() return GetString(SI_MYADDON_ENABLE_FEATURE_TT) end,
    -- ... other parameters
})
```

## Performance Tips

1. **Cache expensive operations**: Don't put heavy computations in functions that run frequently
2. **Use static data when possible**: Only use functions for truly dynamic content
3. **Minimize disable function complexity**: Keep conditional logic simple
4. **Batch UI updates**: Apply multiple changes together when possible

## API Reference

For complete LuaLS type annotations and detailed API documentation, see `LibHarvensAddonSettings.lua`.

## License

This library is not created by, affiliated with or sponsored by ZeniMax Media Inc. or its affiliates. The Elder Scrolls® and related logos are registered trademarks or trademarks of ZeniMax Media Inc. in the United States and/or other countries. 