local addon = VOTANS_IMPROVED_OUTFIT

local function OneTimeHook(method, hook)
    local org = _G[method]
    _G[method] = function(...)
        _G[method] = org
        hook()
        return org(...)
    end
end

local currentSlotOnly

local function GetHoveredSlot()
    local slotType = ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:GetCurrentSheet():GetMouseOverData()
    return slotType and slotType:GetRestyleSlotType()
end

local orgRandomizeStyleData = ZO_OutfitManipulator.RandomizeStyleData
function ZO_OutfitManipulator.RandomizeStyleData(...)
    if currentSlotOnly then
        local self = ...
        local slotType = GetHoveredSlot() or ZO_RESTYLE_STATION_KEYBOARD.categoryTree:GetSelectedData().referenceData.restyleSlotType
        local backup = self.outfitSlotManipulators
        local newManipulators = {}
        for k, m in pairs(backup) do
            if m:GetRestyleSlotData():GetRestyleSlotType() == slotType then
                newManipulators[k] = m
            end
        end
        self.outfitSlotManipulators = newManipulators
        OneTimeHook(
            "PlaySound",
            function()
                self.outfitSlotManipulators = backup
            end
        )
    end
    return orgRandomizeStyleData(...)
end

local orgZO_Dyeing_GetSlotsForRestyleSet = ZO_Dyeing_GetSlotsForRestyleSet
function ZO_Dyeing_GetSlotsForRestyleSet(...)
    if currentSlotOnly then
        local slots = orgZO_Dyeing_GetSlotsForRestyleSet(...)
        local slotType = GetHoveredSlot()
        local newSlots = {}
        for k, m in pairs(slots) do
            if m:GetRestyleSlotType() == slotType then
                newSlots[#newSlots + 1] = m
            end
        end
        return newSlots
    else
        return orgZO_Dyeing_GetSlotsForRestyleSet(...)
    end
end

function addon:InitializeRandomize()
    local layerName = GetString(SI_KEYBINDINGS_LAYER_OUTFIT_STATION)

    self.keybindButtonGroupRandomize = {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = function()
                return GetString(currentSlotOnly and SI_BINDING_NAME_VOTANS_IMPROVED_OUTFIT_RANDOMIZE_CURRENT or SI_BINDING_NAME_VOTANS_IMPROVED_OUTFIT_RANDOMIZE_ALL)
            end,
            keybind = "VOTANS_IMPROVED_OUTFIT_RANDOMIZE",
            callback = function()
                currentSlotOnly = not currentSlotOnly
                KEYBIND_STRIP:UpdateKeybindButtonGroup(addon.keybindButtonGroupRandomize)
                ZO_RESTYLE_STATION_KEYBOARD:UpdateKeybind()
                PlaySound(SOUNDS.DEFAULT_CLICK)
            end
        }
    }

    local function stateChanged(oldState, newState)
        if newState == SCENE_SHOWN then
            PushActionLayerByName(layerName)
            KEYBIND_STRIP:AddKeybindButtonGroup(addon.keybindButtonGroupRandomize)
        elseif newState == SCENE_HIDING then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(addon.keybindButtonGroupRandomize)
            RemoveActionLayerByName(layerName)
        end
    end
    KEYBOARD_DYEING_FRAGMENT:RegisterCallback("StateChange", stateChanged)
    KEYBOARD_OUTFIT_STYLES_PANEL_FRAGMENT:RegisterCallback("StateChange", stateChanged)

    local function enabled()
        if not KEYBOARD_DYEING_FRAGMENT:IsShowing() then
            return true
        else
            return not currentSlotOnly or (GetHoveredSlot() ~= nil)
        end
    end

    local function initRandomize()
        local descriptor = ZO_RESTYLE_STATION_KEYBOARD.keybindStripDescriptor
        for i = 1, #descriptor do
            if descriptor[i].keybind == "UI_SHORTCUT_TERTIARY" then
                descriptor[i].enabled = enabled
                break
            end
        end
    end
    if ZO_RESTYLE_STATION_KEYBOARD.keybindStripDescriptor then
        initRandomize()
    else
        SecurePostHook(ZO_RESTYLE_STATION_KEYBOARD, "InitializeKeybindStripDescriptors", initRandomize)
    end
end
