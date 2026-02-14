-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - New Transmogs Tab UI
-- Shows unpublished transmog items for review and publishing
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")

-- Get Options module reference
local Options = TSM:GetModule("Options")

-- Pagination
local ITEMS_PER_PAGE = 25

local function GetPagedItems(filteredItems)
    local currentPage = Options.newTmogCurrentPage or 1
    local startIdx = (currentPage - 1) * ITEMS_PER_PAGE + 1
    local endIdx = math.min(startIdx + ITEMS_PER_PAGE - 1, #filteredItems)
    local paged = {}
    for i = startIdx, endIdx do
        tinsert(paged, filteredItems[i])
    end
    return paged
end

-- ===================================================================================== --
-- Type/SubType Definitions (duplicated from TransmogsTab - file-local there)
-- ===================================================================================== --

local TMOG_TYPE_LIST = {
    "weapon", "mount", "pet", "armor set", "shield", "tabard", "misc", "illusions", "altars",
}

local TMOG_TYPE_DISPLAY = {
    ["weapon"] = "Weapon",
    ["mount"] = "Mount",
    ["pet"] = "Pet",
    ["armor set"] = "Armor Set",
    ["shield"] = "Shield",
    ["tabard"] = "Tabard",
    ["misc"] = "Misc",
    ["illusions"] = "Illusions",
    ["altars"] = "Altars",
}

local TMOG_SUBTYPE_LIST = {
    "none",
    "sword", "axe", "mace", "dagger", "staff", "polearm", "fist",
    "bow", "gun", "crossbow", "wand", "thrown",
    "head", "shoulders", "chest", "wrist", "gloves", "waist", "legs", "feet", "back",
}

local TMOG_SUBTYPE_DISPLAY = {
    ["none"] = "None",
    ["sword"] = "Sword",
    ["axe"] = "Axe",
    ["mace"] = "Mace",
    ["dagger"] = "Dagger",
    ["staff"] = "Staff",
    ["polearm"] = "Polearm",
    ["fist"] = "Fist",
    ["bow"] = "Bow",
    ["gun"] = "Gun",
    ["crossbow"] = "Crossbow",
    ["wand"] = "Wand",
    ["thrown"] = "Thrown",
    ["head"] = "Head",
    ["shoulders"] = "Shoulders",
    ["chest"] = "Chest",
    ["wrist"] = "Wrist",
    ["gloves"] = "Gloves",
    ["waist"] = "Waist",
    ["legs"] = "Legs",
    ["feet"] = "Feet",
    ["back"] = "Back",
}

-- ===================================================================================== --
-- Dropdown Helpers
-- ===================================================================================== --

local function GetTypeDropdownList()
    local list = {}
    for _, typeKey in ipairs(TMOG_TYPE_LIST) do
        list[typeKey] = TMOG_TYPE_DISPLAY[typeKey] or typeKey
    end
    return list
end

local function GetTypeDropdownOrder()
    local order = {}
    for _, typeKey in ipairs(TMOG_TYPE_LIST) do
        tinsert(order, typeKey)
    end
    return order
end

local function GetSubTypeDropdownList()
    local list = {}
    for _, subKey in ipairs(TMOG_SUBTYPE_LIST) do
        list[subKey] = TMOG_SUBTYPE_DISPLAY[subKey] or subKey
    end
    return list
end

local function GetSubTypeDropdownOrder()
    local order = {}
    for _, subKey in ipairs(TMOG_SUBTYPE_LIST) do
        tinsert(order, subKey)
    end
    return order
end

-- Filter dropdown: "all" + each type
local FILTER_LIST = { "all", "weapon", "mount", "pet", "armor set", "shield", "tabard", "misc", "illusions", "altars", "new" }
local FILTER_DISPLAY = {
    ["all"] = L["All"],
    ["weapon"] = "Weapon",
    ["mount"] = "Mount",
    ["pet"] = "Pet",
    ["armor set"] = "Armor Set",
    ["shield"] = "Shield",
    ["tabard"] = "Tabard",
    ["misc"] = "Misc",
    ["illusions"] = "Illusions",
    ["altars"] = "Altars",
    ["new"] = L["New"],
}

-- 3 days in seconds
local NEW_ITEM_DURATION = 3 * 24 * 3600

local function GetFilterDropdownList()
    local list = {}
    for _, key in ipairs(FILTER_LIST) do
        list[key] = FILTER_DISPLAY[key] or key
    end
    return list
end

local function GetFilterDropdownOrder()
    local order = {}
    for _, key in ipairs(FILTER_LIST) do
        tinsert(order, key)
    end
    return order
end

-- SubType filter
local FILTER_SUBTYPE_LIST = { "all" }
for _, subKey in ipairs(TMOG_SUBTYPE_LIST) do
    if subKey ~= "none" then
        tinsert(FILTER_SUBTYPE_LIST, subKey)
    end
end

local function GetFilterSubTypeDropdownList()
    local list = { ["all"] = L["All"] }
    for _, subKey in ipairs(TMOG_SUBTYPE_LIST) do
        if subKey ~= "none" then
            list[subKey] = TMOG_SUBTYPE_DISPLAY[subKey] or subKey
        end
    end
    return list
end

local function GetFilterSubTypeDropdownOrder()
    local order = {}
    for _, subKey in ipairs(FILTER_SUBTYPE_LIST) do
        tinsert(order, subKey)
    end
    return order
end

-- ===================================================================================== --
-- New Transmogs Tab
-- ===================================================================================== --

function Options:LoadNewTransmogsTab(container)
    Options.newTransmogsContainer = container

    -- Initialize filter state
    if not Options.newTmogFilterTab then Options.newTmogFilterTab = "all" end
    if not Options.newTmogFilterSubType then Options.newTmogFilterSubType = "all" end
    if not Options.newTmogFilterHand then Options.newTmogFilterHand = "all" end
    if not Options.newTmogCurrentPage then Options.newTmogCurrentPage = 1 end

    -- Get filtered unpublished items
    local filteredItems = Options:GetFilteredUnpublishedItems()
    local totalPages = math.max(1, math.ceil(#filteredItems / ITEMS_PER_PAGE))
    if Options.newTmogCurrentPage > totalPages then
        Options.newTmogCurrentPage = totalPages
    end

    local page = {
        {
            type = "ScrollFrame",
            layout = "Flow",
            children = {
                -- Publish All button
                {
                    type = "Button",
                    text = L["Publish All"],
                    relativeWidth = 0.15,
                    callback = function()
                        Options:PublishAllItems()
                    end,
                },
                {
                    type = "HeadingLine",
                },
                -- Filter Dropdowns
                {
                    type = "Dropdown",
                    label = L["Filter"],
                    relativeWidth = 0.25,
                    list = GetFilterDropdownList(),
                    order = GetFilterDropdownOrder(),
                    value = Options.newTmogFilterTab,
                    callback = function(widget, _, value)
                        Options.newTmogFilterTab = value
                        Options.newTmogFilterSubType = "all"
                        Options.newTmogFilterHand = "all"
                        Options.newTmogCurrentPage = 1
                        Options:RefreshNewTransmogsTab()
                    end,
                },
                {
                    type = "Dropdown",
                    label = L["SubType"],
                    relativeWidth = 0.20,
                    list = GetFilterSubTypeDropdownList(),
                    order = GetFilterSubTypeDropdownOrder(),
                    value = Options.newTmogFilterSubType,
                    callback = function(widget, _, value)
                        Options.newTmogFilterSubType = value
                        Options.newTmogCurrentPage = 1
                        Options:RefreshNewTransmogsTab()
                    end,
                },
                {
                    type = "Dropdown",
                    label = L["Hand"],
                    relativeWidth = 0.15,
                    list = { ["all"] = L["All"], ["1h"] = "1H", ["2h"] = "2H" },
                    order = { "all", "1h", "2h" },
                    value = Options.newTmogFilterHand,
                    callback = function(widget, _, value)
                        Options.newTmogFilterHand = value
                        Options.newTmogCurrentPage = 1
                        Options:RefreshNewTransmogsTab()
                    end,
                },
                -- Item List
                {
                    type = "InlineGroup",
                    title = L["New Transmogs List"] .. " (" .. #filteredItems .. " " .. L["items"] .. ")",
                    layout = "Flow",
                    fullWidth = true,
                    children = Options:GetNewTransmogListWidgets(filteredItems, totalPages),
                },
            },
        },
    }

    TSMAPI:BuildPage(container, page)
end

-- ===================================================================================== --
-- Unpublished Item Filtering
-- ===================================================================================== --

function Options:GetFilteredUnpublishedItems()
    local filterValue = Options.newTmogFilterTab or "all"
    local filterSubType = Options.newTmogFilterSubType or "all"
    local filterHand = Options.newTmogFilterHand or "all"
    local allItems = TSM.db.profile.transmogs.itemList
    local filtered = {}
    for i, item in ipairs(allItems) do
        -- Only show unpublished items
        if item.published == false then
            local show = false
            if filterValue == "all" then
                show = true
            elseif filterValue == "new" then
                show = (item.availableSince and (time() - item.availableSince) < NEW_ITEM_DURATION)
            else
                show = (item.tmogType == filterValue)
            end
            -- Apply subtype filter
            if show and filterSubType ~= "all" then
                show = (item.tmogSubType == filterSubType)
            end
            -- Apply hand filter
            if show and filterHand ~= "all" then
                show = (item.tmogHand == filterHand)
            end
            if show then
                tinsert(filtered, { index = i, item = item })
            end
        end
    end
    return filtered
end

-- ===================================================================================== --
-- Item List Widgets
-- ===================================================================================== --

function Options:GetNewTransmogListWidgets(filteredItems, totalPages)
    local children = {}
    local currentPage = Options.newTmogCurrentPage or 1
    local totalItems = #filteredItems

    if totalItems == 0 then
        tinsert(children, {
            type = "Label",
            text = L["No unpublished transmog items."],
            fullWidth = true,
        })
        return children
    end

    -- Header row
    tinsert(children, { type = "Label", text = "|cffffd100S|r", relativeWidth = 0.05 })
    tinsert(children, { type = "Label", text = "|cffffd100" .. L["Item"] .. "|r", relativeWidth = 0.26 })
    tinsert(children, { type = "Label", text = "|cffffd100" .. L["Price"] .. "|r", relativeWidth = 0.10 })
    tinsert(children, { type = "Label", text = "|cffffd100" .. L["Type"] .. "|r", relativeWidth = 0.16 })
    tinsert(children, { type = "Label", text = "|cffffd100" .. L["SubType"] .. "|r", relativeWidth = 0.16 })
    tinsert(children, { type = "Label", text = "", relativeWidth = 0.26 })

    -- Get only the items for the current page
    local pagedItems = GetPagedItems(filteredItems)

    -- Item rows
    for _, entry in ipairs(pagedItems) do
        local item = entry.item
        local originalIndex = entry.index
        local priceGold = (item.price and item.price > 0) and tostring(math.floor(item.price / 10000)) or ""
        local currentType = item.tmogType or "misc"
        local currentSubType = item.tmogSubType or "none"

        -- Stock checkbox
        local itemRef = item
        tinsert(children, {
            type = "CheckBox",
            label = "",
            relativeWidth = 0.05,
            value = (item.inStock == true),
            callback = function(widget, _, value)
                itemRef.inStock = value
                Options:RefreshNewTransmogsTab()
            end,
        })
        tinsert(children, {
            type = "InteractiveLabel",
            text = item.link or item.name or "Unknown",
            relativeWidth = 0.26,
            tooltip = item.link,
            callback = function()
                if IsControlKeyDown() and item.link then
                    DressUpItemLink(item.link)
                end
            end,
        })
        tinsert(children, {
            type = "EditBox",
            label = "",
            relativeWidth = 0.10,
            value = priceGold,
            callback = function(widget, _, value)
                local goldAmount = tonumber(value)
                local newPrice = goldAmount and goldAmount > 0 and (goldAmount * 10000) or nil
                item.price = newPrice
                -- Update history
                if item.name then
                    if not TSM.db.profile.transmogs.itemHistory[item.name] then
                        TSM.db.profile.transmogs.itemHistory[item.name] = {}
                    end
                    TSM.db.profile.transmogs.itemHistory[item.name].price = newPrice
                end
            end,
        })
        tinsert(children, {
            type = "Dropdown",
            label = "",
            relativeWidth = 0.16,
            list = GetTypeDropdownList(),
            order = GetTypeDropdownOrder(),
            value = currentType,
            callback = function(widget, _, value)
                item.tmogType = value
                -- Update history
                if item.name then
                    if not TSM.db.profile.transmogs.itemHistory[item.name] then
                        TSM.db.profile.transmogs.itemHistory[item.name] = {}
                    end
                    TSM.db.profile.transmogs.itemHistory[item.name].tmogType = value
                end
            end,
        })
        tinsert(children, {
            type = "Dropdown",
            label = "",
            relativeWidth = 0.16,
            list = GetSubTypeDropdownList(),
            order = GetSubTypeDropdownOrder(),
            value = currentSubType,
            callback = function(widget, _, value)
                local subType = value ~= "none" and value or nil
                item.tmogSubType = subType
                -- Update history
                if item.name then
                    if not TSM.db.profile.transmogs.itemHistory[item.name] then
                        TSM.db.profile.transmogs.itemHistory[item.name] = {}
                    end
                    TSM.db.profile.transmogs.itemHistory[item.name].tmogSubType = subType
                end
            end,
        })
        tinsert(children, {
            type = "Button",
            text = L["Publish"],
            relativeWidth = 0.13,
            callback = function()
                item.published = true
                -- Save to history
                if item.name then
                    local history = TSM.db.profile.transmogs.itemHistory
                    if not history[item.name] then
                        history[item.name] = {}
                    end
                    history[item.name].price = item.price
                    history[item.name].tmogType = item.tmogType
                    history[item.name].tmogSubType = item.tmogSubType
                    history[item.name].tmogHand = item.tmogHand
                end
                Options:RefreshNewTransmogsTab()
            end,
        })
        tinsert(children, {
            type = "Button",
            text = L["Delete"],
            relativeWidth = 0.13,
            callback = function()
                tremove(TSM.db.profile.transmogs.itemList, originalIndex)
                Options:RefreshNewTransmogsTab()
            end,
        })
    end

    -- Pagination controls
    if totalPages > 1 then
        tinsert(children, { type = "HeadingLine" })
        tinsert(children, {
            type = "Button",
            text = "< " .. L["Prev"],
            relativeWidth = 0.15,
            disabled = (currentPage <= 1),
            callback = function()
                Options.newTmogCurrentPage = math.max(1, currentPage - 1)
                Options:RefreshNewTransmogsTab()
            end,
        })
        tinsert(children, {
            type = "Label",
            text = format("Page %d / %d  (%d %s)", currentPage, totalPages, totalItems, L["items"]),
            relativeWidth = 0.56,
        })
        tinsert(children, {
            type = "Button",
            text = L["Next"] .. " >",
            relativeWidth = 0.15,
            disabled = (currentPage >= totalPages),
            callback = function()
                Options.newTmogCurrentPage = math.min(totalPages, currentPage + 1)
                Options:RefreshNewTransmogsTab()
            end,
        })
    end

    return children
end

-- ===================================================================================== --
-- Actions
-- ===================================================================================== --

function Options:PublishAllItems()
    local items = TSM.db.profile.transmogs.itemList
    local count = 0
    for _, item in ipairs(items) do
        if item.published == false then
            item.published = true
            count = count + 1
        end
    end
    TSM:Print(format(L["Published %d items."], count))
    Options:RefreshNewTransmogsTab()
end

function Options:RefreshNewTransmogsTab()
    if Options.newTransmogsContainer then
        Options.newTransmogsContainer:ReleaseChildren()
        Options:LoadNewTransmogsTab(Options.newTransmogsContainer)
    end
end
