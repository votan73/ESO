---@meta LibHarvensAddonSettings

---@class LibHarvensAddonSettings
---@field version number Library version number
---@field addons LibHarvensAddonSettings.AddonSettings[] Array of registered addon settings
---@field ST_CHECKBOX number Checkbox control type (1)
---@field ST_SLIDER number Slider control type (2)
---@field ST_EDIT number Edit/text input control type (3)
---@field ST_DROPDOWN number Dropdown/combobox control type (4)
---@field ST_COLOR number Color picker control type (5)
---@field ST_BUTTON number Button control type (6)
---@field ST_LABEL number Label/text control type (7)
---@field ST_SECTION number Section header control type (8)
---@field ST_ICONPICKER number Icon picker control type (9)
LibHarvensAddonSettings = {}

---@class LibHarvensAddonSettings.AddonSettings
---@field name string Addon name
---@field selected boolean Whether this addon panel is currently selected
---@field mouseOver boolean Whether mouse is over this addon panel
---@field settings LibHarvensAddonSettings.AddonSettingsControl[] Array of setting controls
---@field allowDefaults boolean Whether to show defaults button
---@field defaultsFunction function? Optional function called when resetting to defaults
---@field callbackManager table? Callback manager for refresh functionality
local AddonSettings = {}

---@class LibHarvensAddonSettings.AddonSettingsControl
---@field type number Control type (ST_* constant)
---@field callbackManager table? Callback manager reference
---@field control userdata? The actual UI control
---@field labelText string|function Label text or function returning text
---@field tooltipText string|number|function? Tooltip text, string ID, or function
---@field getFunction function Function to get current value
---@field setFunction function? Function to set new value
---@field clickHandler function? Click handler for buttons
---@field default any? Default value for this control
---@field disable boolean|function? Whether control is disabled
local AddonSettingsControl = {}

---Options table for AddAddon
---@class LibHarvensAddonSettings.AddonOptions
---@field allowDefaults boolean? Whether to show a "Reset to Defaults" button (default: false)
---@field defaultsFunction function? Function called when "Reset to Defaults" is clicked
---@field allowRefresh boolean? Whether to enable refresh callbacks between controls (default: false)

---Base parameters for all setting types
---@class LibHarvensAddonSettings.BaseSettingParams
---@field type number Control type (use ST_* constants)
---@field label string|function Display label text or function returning text
---@field tooltip string|number|function? Tooltip text, string ID, or function returning text
---@field default any? Default value for reset functionality
---@field disable boolean|function? Whether control is disabled, or function returning boolean

---Checkbox setting parameters
---@class LibHarvensAddonSettings.CheckboxParams : LibHarvensAddonSettings.BaseSettingParams
---@field getFunction function Function returning current boolean value
---@field setFunction function Function accepting boolean value to set

---Slider setting parameters  
---@class LibHarvensAddonSettings.SliderParams : LibHarvensAddonSettings.BaseSettingParams
---@field min number Minimum value
---@field max number Maximum value
---@field step number? Step size (default: 1)
---@field format string? Number format string (default: "%f")
---@field unit string|function? Unit text or function returning unit text
---@field getFunction function Function returning current number value
---@field setFunction function Function accepting number value to set

---Edit/text input setting parameters
---@class LibHarvensAddonSettings.EditParams : LibHarvensAddonSettings.BaseSettingParams
---@field textType number? Text input type (TEXT_TYPE_* constant)
---@field maxChars number? Maximum input characters
---@field getFunction function Function returning current string value
---@field setFunction function Function accepting string value to set

---Dropdown item definition
---@class LibHarvensAddonSettings.DropdownItem
---@field name string Display name for this item
---@field data any? Associated data for this item

---Dropdown setting parameters
---@class LibHarvensAddonSettings.DropdownParams : LibHarvensAddonSettings.BaseSettingParams
---@field items LibHarvensAddonSettings.DropdownItem[]|function Array of dropdown items or function returning array
---@field getFunction function Function returning currently selected item name
---@field setFunction function Function accepting (control, itemName, itemData) to set selection

---Color setting parameters
---@class LibHarvensAddonSettings.ColorParams : LibHarvensAddonSettings.BaseSettingParams
---@field getFunction function Function returning r, g, b, a color values (0-1 range)
---@field setFunction function Function accepting r, g, b, a color values to set

---Button setting parameters
---@class LibHarvensAddonSettings.ButtonParams : LibHarvensAddonSettings.BaseSettingParams
---@field buttonText string|function? Button text or function returning text (falls back to label if not provided)
---@field clickHandler function Function called when button is clicked, receives control as parameter

---Label setting parameters
---@class LibHarvensAddonSettings.LabelParams : LibHarvensAddonSettings.BaseSettingParams
---@field canSelect boolean? Whether label can be selected (default: based on tooltip presence)

---Section header parameters
---@class LibHarvensAddonSettings.SectionParams : LibHarvensAddonSettings.BaseSettingParams

---Icon picker setting parameters
---@class LibHarvensAddonSettings.IconPickerParams : LibHarvensAddonSettings.BaseSettingParams
---@field items string[]|function Array of icon texture paths or function returning array
---@field getFunction function Function returning currently selected icon index (1-based)
---@field setFunction function Function accepting (control, iconIndex, iconPath) to set selection

---Union type for all setting parameter types
---@alias LibHarvensAddonSettings.SettingParams 
---| LibHarvensAddonSettings.CheckboxParams
---| LibHarvensAddonSettings.SliderParams  
---| LibHarvensAddonSettings.EditParams
---| LibHarvensAddonSettings.DropdownParams
---| LibHarvensAddonSettings.ColorParams
---| LibHarvensAddonSettings.ButtonParams
---| LibHarvensAddonSettings.LabelParams
---| LibHarvensAddonSettings.SectionParams
---| LibHarvensAddonSettings.IconPickerParams

---Create a new addon settings panel
---@param name string Addon name (color markup will be removed)
---@param options LibHarvensAddonSettings.AddonOptions? Optional configuration
---@return LibHarvensAddonSettings.AddonSettings addonSettings The created addon settings object
function LibHarvensAddonSettings:AddAddon(name, options) end

---Add a single setting control to this addon panel
---@param params LibHarvensAddonSettings.SettingParams Setting configuration parameters
---@return LibHarvensAddonSettings.AddonSettingsControl control The created setting control
function AddonSettings:AddSetting(params) end

---Add multiple setting controls to this addon panel
---@param params LibHarvensAddonSettings.SettingParams[] Array of setting configurations
---@return LibHarvensAddonSettings.AddonSettingsControl[] controls Array of created setting controls
function AddonSettings:AddSettings(params) end

---Select this addon panel (show its settings)
function AddonSettings:Select() end

---Reset all settings to their default values
function AddonSettings:ResetToDefaults() end

---Clear all settings from this addon panel
function AddonSettings:Clear() end

---Update all setting controls (refresh their display)
function AddonSettings:UpdateControls() end

---Clean up resources when deselecting
function AddonSettings:CleanUp() end

---Check if this setting control is currently disabled
---@return boolean disabled True if disabled
function AddonSettingsControl:IsDisabled() end

---Set the enabled/disabled state of this control
---@param enabled boolean Whether control should be enabled
function AddonSettingsControl:SetEnabled(enabled) end

---Set the value of this control (if supported)
---@param ... any Values to set (type depends on control type)
function AddonSettingsControl:SetValue(...) end

---Reset this control to its default value
function AddonSettingsControl:ResetToDefaults() end

---Get the height of this control in pixels
---@return number height Control height including padding
function AddonSettingsControl:GetHeight() end

---Trigger value changed callback and update dependent controls
---@param ... any New values (passed to setFunction or clickHandler)
function AddonSettingsControl:ValueChanged(...) end

---Get a value that might be a function or direct value
---@param arg any|function Value or function returning value
---@return any value The resolved value
function AddonSettingsControl:GetValueOrCallback(arg) end

---Convert string ID to localized string if needed
---@param strOrId string|number String or string ID
---@return string text The localized string
function AddonSettingsControl:GetString(strOrId) end

---Initialize the library (called automatically)
function LibHarvensAddonSettings:Initialize() end

---Refresh addon settings display (for external use)
function LibHarvensAddonSettings:RefreshAddonSettings() end 