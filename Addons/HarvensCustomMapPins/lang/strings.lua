local strings = {
    SI_HARVEN_CMP_EDIT_PIN = "Edit",
    SI_HARVEN_CMP_SHOW_IN_POPUP = "Show in Popup",
    SI_HARVEN_CMP_SHARE_PIN = "Share",
    SI_HARVEN_CMP_DELETE_PIN = "Delete",
    SI_HARVEN_CMP_PLACE_CUSTOM_PIN = "Place custom pin",
    SI_HARVEN_CMP_NO_IMPORT_SECTION = "No import section in the SavedVariable file. Logout and make sure that the section is present.",
    SI_HARVEN_CMP_PIN_MALFORMED = "Pin '<<1>>' seems to be malformed, ignoring.",
    SI_HARVEN_CMP_IMPORTED_PIN = "Imported pin '<<1>>' on map '<<2>>' location <<3>>, <<4>>",
    SI_HARVEN_CMP_PIN_ALREADY_PRESENT = "A pin is already present at that location: <<1>>, <<2>> <<3>>",
    SI_HARVEN_CMP_IMPORT_COMPLETED = "Import completed!",
    SI_HARVEN_CMP_PIN_SIZE = "Pin Size",
    SI_HARVEN_CMP_PIN_DRAW_LEVEL = "Pin Draw Level",
    SI_HARVEN_CMP_PIN_DRAW_LEVEL_TOOLTIP = "The greater the number then more top level a pin would be.",
    SI_HARVEN_CMP_SPREAD_PIN_RENDERING = "Spread Pin Rendering",
    SI_HARVEN_CMP_SPREAD_PIN_RENDERING_TOOLTIP = "Spread pin rendering over time to reduce CPU load per frame.",
    SI_HARVEN_CMP_ALLOW_PIN_SUB_FILTER = "Allow pin sub-filter",
    SI_HARVEN_CMP_ALLOW_PIN_SUB_FILTER_TOOLTIP = "Allow to show/hide predefines (map filter tab). Reloads UI!",
    SI_HARVEN_CMP_TITLE_REPLACE = "CUSTOM MAP PIN (replace)",
    SI_HARVEN_CMP_TITLE_EDIT = "CUSTOM MAP PIN (edit)",
    SI_HARVEN_CMP_TITLE_NEW = "CUSTOM MAP PIN (new)",
    SI_HARVEN_CMP_ENTER_PIN_DESCRIPTION = "Enter Pin Description:",
    SI_HARVEN_CMP_ADVANCED_OPTIONS = "Advanced Options",
    SI_HARVEN_CMP_SELECT_ICON = "Select Icon:",
    SI_HARVEN_CMP_SELECT_COLOR = "Select Color:",
    SI_HARVEN_CMP_APPLY_PREDEFINED = "Apply Predefined:",
    SI_HARVEN_CMP_PREDEFINED_NAME = "Predefined Name:"
}

for stringId, stringValue in pairs(strings) do
    ZO_CreateStringId(stringId, stringValue)
    SafeAddVersion(stringId, 1)
end
