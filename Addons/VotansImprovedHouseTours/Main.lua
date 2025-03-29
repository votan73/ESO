local addon = ZO_InitializingObject:Subclass()
addon.name = "VotansImprovedHouseTours"

local em = GetEventManager()

function addon:Initialize()
    self:RegisterForEvents()
    self:SetupContextMenu()
end

function addon:IsShowing()
    return self.fragment and self.fragment:IsShowing()
end

function addon:ShowLoading()
    self.loadingIcon:Show()
    self.emptyText:SetText(GetString(SI_HOUSE_TOURS_SEARCH_RESULTS_REFRESHING_RESULTS))
    self.emptyText:SetHidden(false)
    self.houseControl:SetHidden(true)
    self.totalHouses:SetHidden(true)
end

function addon:HideLoading()
    self.loadingIcon:Hide()
    self.emptyText:SetHidden(true)
end

function addon:CurrentHouseIdentifier()
    local houseId = GetCurrentZoneHouseId()
    local owner = GetCurrentHouseOwner()
    return string.format("%i%s", houseId, owner)
end

function addon:SetupContextMenu()
    local parent = ZO_MapPin.PIN_CLICK_HANDLERS[MOUSE_BUTTON_INDEX_LEFT][MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE][3]
    assert(parent, "out-dated")
    local orgFn = parent.GetDynamicHandlers
    parent.GetDynamicHandlers = function(...)
        if not self.account.showInContextMenu then
            return orgFn(...)
        end
        local pin = ...
        local handlers = orgFn(...)
        local handler = {
            name = GetString(SI_COLLECTIBLE_ACTION_TOUR_THIS_HOME),
            callback = function(pin)
                ZO_Dialogs_ReleaseDialog("FAST_TRAVEL_CONFIRM")
                ZO_Dialogs_ReleaseDialog("RECALL_CONFIRM")
                ZO_Dialogs_ReleaseDialog("TRAVEL_TO_HOUSE_CONFIRM")
                local nodeIndex = pin:GetFastTravelNodeIndex()
                local houseId = GetFastTravelNodeHouseId(nodeIndex)
                HOUSE_TOURS_SEARCH_RESULTS_KEYBOARD:BrowseToSpecificHouse(houseId)
                GROUP_MENU_KEYBOARD:ShowCategoryByData(HOUSE_TOURS_SEARCH_RESULTS_KEYBOARD:GetActivityFinderCategoryData(HOUSE_TOURS_LISTING_TYPE_BROWSE))
            end
        }
        handlers[#handlers + 1] = handler
        return handlers
    end
end

function addon:RegisterForEvents()
    HOUSE_TOURS_SEARCH_MANAGER:RegisterCallback(
        "OnSearchStateChanged",
        function(newState, listingType)
            if listingType == HOUSE_TOURS_LISTING_TYPE_BROWSE then
                self:HideLoading()
                if self:IsShowing() then
                    self:RefreshHouse()
                    return
                end
            end
            self.dirty = true
            self.lastHouse = nil
        end
    )

    local function recordHouse()
        local identifier = self:CurrentHouseIdentifier()
        local now = GetTimeStamp()
        if not self.visitedHouses[identifier] or (now - self.visitedHouses[identifier]) > 900 then
            self.visitedHouses[identifier] = now
        end
    end
    em:RegisterForEvent(addon.name, EVENT_PLAYER_ACTIVATED, recordHouse)

    local function OnAddOnLoaded(event, addonName)
        if addonName == addon.name then
            em:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)
            self:InitSavedVar()
            self:InitSettings()
        end
    end

    em:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
end

function addon:RefreshHouse()
    local searchResults = HOUSE_TOURS_SEARCH_MANAGER:GetSortedSearchResults(HOUSE_TOURS_LISTING_TYPE_BROWSE)
    if #searchResults == 0 then
        return
    end

    self.dirty = false

    local interval = self.account.rotationInterval * 60 - 1 -- Not exactly 15min for a slight drift over day time
    local timeSlot = math.floor(GetTimeStamp() / interval)
    local houseListingData
    if self.lastTimeSlot ~= timeSlot or not self.lastHouse then
        if not self.lastHouse then
            local currentIndex = (timeSlot % #searchResults) + 1 -- take timeSlot as a random start index
            houseListingData = searchResults[currentIndex]
        else
            houseListingData = searchResults[self.lastIndex + 1] or searchResults[1]
        end
        local count = #searchResults
        while houseListingData and count > 0 and not houseListingData:IsListed() or houseListingData:GetListingType() == HOUSE_TOURS_LISTING_TYPE_RECOMMENDED do
            houseListingData = searchResults[houseListingData:GetListingIndex() + 1] or searchResults[1]
            count = count - 1
        end
        self.lastIndex = houseListingData and houseListingData:GetListingIndex() or 0
        self.lastTimeSlot = timeSlot
        self.lastHouse = houseListingData
    else
        houseListingData = self.lastHouse
    end
    if not houseListingData then
        self.emptyText:SetText(GetString(SI_HOUSE_TOURS_SEARCH_RESULTS_EMPTY_TEXT))
        self.emptyText:SetHidden(false)
        self.houseControl:SetHidden(true)
        return
    end
    self:HideLoading()
    self.houseControl:SetHidden(false)
    self.house:Layout(houseListingData)
    self.totalHouses:SetText(zo_strformat(SI_VOTANS_IMPROVED_HOUSE_TOURS_TOTAL_HOUSES, #searchResults))
    self.totalHouses:SetHidden(false)
end

function addon:LayoutTooltip(tile)
    if tile.listingData and tile:IsMousedOver() then
        local identifier = string.format("%i%s", tile.listingData:GetHouseId(), tile.listingData:GetOwnerDisplayName())
        local DEFAULT_FONT = ""
        local lastVisitedTimeStamp = self.visitedHouses[identifier]
        if lastVisitedTimeStamp then
            local time = ZO_FormatTime(GetTimeStamp() - lastVisitedTimeStamp, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_ASCENDING)
            InformationTooltip:AddLine(zo_strformat(GetString(SI_VOTANS_IMPROVED_HOUSE_TOURS_LAST_VISITED), time), DEFAULT_FONT, ZO_NORMAL_TEXT:UnpackRGBA())
        else
            InformationTooltip:AddLine(zo_strformat(GetString(SI_VOTANS_IMPROVED_HOUSE_TOURS_NOT_VISITED)), DEFAULT_FONT, ZO_NORMAL_TEXT:UnpackRGBA())
        end
    end
end

function addon:OnStateChange(oldState, newState)
    if newState == SCENE_FRAGMENT_SHOWN then
        if self.dirty then
            local currentSearchState = HOUSE_TOURS_SEARCH_MANAGER:GetSearchState(HOUSE_TOURS_LISTING_TYPE_BROWSE)
            if currentSearchState ~= ZO_HOUSE_TOURS_SEARCH_STATES.COMPLETE then
                self:ShowLoading()
                if currentSearchState ~= ZO_HOUSE_TOURS_SEARCH_STATES.WAITING and currentSearchState ~= ZO_HOUSE_TOURS_SEARCH_STATES.QUEUED then
                    HOUSE_TOURS_SEARCH_MANAGER:ExecuteSearch(HOUSE_TOURS_LISTING_TYPE_BROWSE)
                end
            else
                self:RefreshHouse()
            end
        end
    end
end

function addon:OnControlInitialized(control)
    self.control = control
    self.fragment = ZO_FadeSceneFragment:New(control)
    self.fragment:RegisterCallback(
        "StateChange",
        function(...)
            self:OnStateChange(...)
        end
    )

    local container = control:GetNamedChild("Container")
    self.emptyText = container:GetNamedChild("EmptyText")
    self.loadingIcon = container:GetNamedChild("LoadingIcon")
    self.houseControl = container:GetNamedChild("House")
    self.house = self.houseControl.object
    self.totalHouses = container:GetNamedChild("TotalHouses")

    local houseToursCategoryData = {
        priority = ZO_ACTIVITY_FINDER_SORT_PRIORITY.HOUSE_TOURS,
        name = GetString(SI_VOTANS_IMPROVED_HOUSE_TOURS_TITLE),
        onTreeEntrySelected = function()
            self.dirty = true
        end,
        normalIcon = "/esoui/art/guild/tabicon_home_up.dds",
        pressedIcon = "/esoui/art/guild/tabicon_home_down.dds",
        mouseoverIcon = "/esoui/art/guild/tabicon_home_over.dds",
        disabledIcon = "/esoui/art/guild/tabicon_home_disabled.dds",
        isHouseTours = true,
        categoryFragment = self.fragment
    }
    GROUP_MENU_KEYBOARD:AddCategory(houseToursCategoryData)

    local function nextHouse()
        if self:IsShowing() then
            self:RefreshHouse()
        else
            self.dirty = true
        end
    end
    em:RegisterForUpdate(addon.name, 60000, nextHouse)

    SecurePostHook(
        ZO_HouseToursSearchResultsTile_Keyboard,
        "RefreshMouseoverVisuals",
        function(tile)
            self:LayoutTooltip(tile)
        end
    )
end

function addon:InitSavedVar()
    if not VotansImprovedHouseTours_Data then
        VotansImprovedHouseTours_Data = {}
    end
    local settings = VotansImprovedHouseTours_Data
    local currentServer = GetWorldName()
    if not settings[currentServer] then
        settings[currentServer] = {}
    end
    self.visitedHouses = settings[currentServer]

    -- keep data clean
    local expireDate = GetTimeStamp() - 7776000 -- 90 days
    for world, houses in pairs(VotansImprovedHouseTours_Data) do
        if world ~= "account" then
            for identifier, time in pairs(houses) do
                if time < expireDate then
                    houses[identifier] = nil
                end
            end
        end
    end

    self.account = settings.account or {}
    settings.account = self.account
end

function addon:InitSettings()
    local settings = LibHarvensAddonSettings:AddAddon("Votan's Improved House Tours")
    if not settings then
        return
    end
    settings.version = "1.0.1"

    local accountDefaults = {
        showInContextMenu = true,
        rotationInterval = 15
    }
    for setting, value in pairs(accountDefaults) do
        if self.account[setting] == nil then
            self.account[setting] = accountDefaults[setting]
        end
    end

    settings:AddSetting {
        type = LibHarvensAddonSettings.ST_CHECKBOX,
        label = GetString(SI_VOTANS_IMPROVED_HOUSE_TOURS_SHOW_IN_CONTEXTMENU),
        default = accountDefaults.showInContextMenu,
        getFunction = function()
            return self.account.showInContextMenu
        end,
        setFunction = function(value)
            self.account.showInContextMenu = value
        end
    }
    local items = {}
    local dataToItem = {}
    for _, min in ipairs({5, 10, 15, 20, 30}) do
        local item = {name = zo_strformat("<<1>>mins", min), data = min}
        dataToItem[min] = item
        items[#items + 1] = item
    end
    settings:AddSetting {
        type = LibHarvensAddonSettings.ST_DROPDOWN,
        label = GetString(SI_VOTANS_IMPROVED_HOUSE_TOURS_ROTATION_INTERVAL),
        default = accountDefaults.rotationInterval,
        items = items,
        getFunction = function()
            return (dataToItem[self.account.rotationInterval] or dataToItem[15]).name
        end,
        setFunction = function(combobox, name, item)
            self.account.rotationInterval = item.data
        end
    }
end

VOTANS_IMPROVED_HOUSE_TOURS = addon:New()
