-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Transmogs Tab UI
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")

-- Get Options module reference
local Options = TSM:GetModule("Options")

-- Pagination
local ITEMS_PER_PAGE = 25

local function GetPagedItems(filteredItems)
    local currentPage = Options.tmogCurrentPage or 1
    local startIdx = (currentPage - 1) * ITEMS_PER_PAGE + 1
    local endIdx = math.min(startIdx + ITEMS_PER_PAGE - 1, #filteredItems)
    local paged = {}
    for i = startIdx, endIdx do
        tinsert(paged, filteredItems[i])
    end
    return paged
end

-- ===================================================================================== --
-- Transmog Type/SubType Definitions (for dropdowns)
-- ===================================================================================== --

-- Base types for dropdown
local TMOG_TYPE_LIST = {
    "weapon", "mount", "pet", "whistle", "demon", "incarnation", "armor set", "shield", "tabard", "misc", "illusions", "altars",
}

-- Display names for types
local TMOG_TYPE_DISPLAY = {
    ["weapon"] = "Weapon",
    ["mount"] = "Mount",
    ["pet"] = "Pet",
    ["whistle"] = "Whistle",
    ["demon"] = "Demon",
    ["incarnation"] = "Incarnation",
    ["armor set"] = "Armor Set",
    ["shield"] = "Shield",
    ["tabard"] = "Tabard",
    ["misc"] = "Misc",
    ["illusions"] = "Illusions",
    ["altars"] = "Altars",
}

-- Subtypes for dropdown (None + weapon types + armor slots)
local TMOG_SUBTYPE_LIST = {
    "none",
    -- Weapon subtypes
    "sword", "axe", "mace", "dagger", "staff", "polearm", "fist",
    "bow", "gun", "crossbow", "wand", "thrown",
    -- Armor subtypes
    "head", "shoulders", "chest", "wrist", "gloves", "waist", "legs", "feet", "back",
}

-- Display names for subtypes
local TMOG_SUBTYPE_DISPLAY = {
    ["none"] = "None",
    -- Weapons
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
    -- Armor
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
-- Auto-detection Mapping Tables (GetItemInfo → tmog type/subtype)
-- ===================================================================================== --

-- Maps WoW itemSubClass string → our transmog subtype key
local ITEM_SUBCLASS_TO_TMOG_SUBTYPE = {
    ["One-Handed Swords"] = "sword",
    ["Two-Handed Swords"] = "sword",
    ["One-Handed Axes"] = "axe",
    ["Two-Handed Axes"] = "axe",
    ["One-Handed Maces"] = "mace",
    ["Two-Handed Maces"] = "mace",
    ["Daggers"] = "dagger",
    ["Staves"] = "staff",
    ["Polearms"] = "polearm",
    ["Fist Weapons"] = "fist",
    ["Bows"] = "bow",
    ["Guns"] = "gun",
    ["Crossbows"] = "crossbow",
    ["Wands"] = "wand",
    ["Thrown"] = "thrown",
}

-- Maps WoW itemSubClass string → hand type (1h or 2h)
local ITEM_SUBCLASS_TO_HAND = {
    ["One-Handed Swords"] = "1h",
    ["Two-Handed Swords"] = "2h",
    ["One-Handed Axes"] = "1h",
    ["Two-Handed Axes"] = "2h",
    ["One-Handed Maces"] = "1h",
    ["Two-Handed Maces"] = "2h",
    ["Daggers"] = "1h",
    ["Staves"] = "2h",
    ["Polearms"] = "2h",
    ["Fist Weapons"] = "1h",
    ["Bows"] = "2h",
    ["Guns"] = "2h",
    ["Crossbows"] = "2h",
    ["Wands"] = "1h",
    ["Thrown"] = "1h",
}

-- Maps WoW equipLoc → our transmog subtype key
local EQUIP_LOC_TO_TMOG_SUBTYPE = {
    ["INVTYPE_HEAD"] = "head",
    ["INVTYPE_SHOULDER"] = "shoulders",
    ["INVTYPE_CHEST"] = "chest",
    ["INVTYPE_ROBE"] = "chest",
    ["INVTYPE_WRIST"] = "wrist",
    ["INVTYPE_HAND"] = "gloves",
    ["INVTYPE_WAIST"] = "waist",
    ["INVTYPE_LEGS"] = "legs",
    ["INVTYPE_FEET"] = "feet",
    ["INVTYPE_CLOAK"] = "back",
}

-- Detect tmogType, tmogSubType, and tmogHand from GetItemInfo data
-- Returns tmogType, tmogSubType, tmogHand (or nil, nil, nil if unrecognized)
function TSM:DetectTmogTypeAndSubType(itemSubClass, equipLoc)
    -- Check weapon subclass first
    local weaponSubType = ITEM_SUBCLASS_TO_TMOG_SUBTYPE[itemSubClass]
    if weaponSubType then
        local hand = ITEM_SUBCLASS_TO_HAND[itemSubClass]
        return "weapon", weaponSubType, hand
    end

    -- Check shield (special type, not "armor set")
    if equipLoc == "INVTYPE_SHIELD" then
        return "shield", "none", nil
    end

    -- Check tabard
    if equipLoc == "INVTYPE_BODY" then
        return "tabard", "none", nil
    end

    -- Check armor slots
    local armorSubType = EQUIP_LOC_TO_TMOG_SUBTYPE[equipLoc]
    if armorSubType then
        return "armor set", armorSubType, nil
    end

    -- Unrecognized - return nil to keep current dropdown values
    return nil, nil, nil
end

-- Build dropdown list tables for TSMAPI:BuildPage
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

-- ===================================================================================== --
-- Filter Dropdown for Item List
-- ===================================================================================== --

-- Filter options: "all" + each type + "free"
local FILTER_LIST = { "all", "weapon", "mount", "pet", "whistle", "demon", "incarnation", "armor set", "shield", "tabard", "misc", "illusions", "altars", "free", "out of stock", "new" }
local FILTER_DISPLAY = {
    ["all"] = L["All"],
    ["weapon"] = "Weapon",
    ["mount"] = "Mount",
    ["pet"] = "Pet",
    ["whistle"] = "Whistle",
    ["demon"] = "Demon",
    ["incarnation"] = "Incarnation",
    ["armor set"] = "Armor Set",
    ["shield"] = "Shield",
    ["tabard"] = "Tabard",
    ["misc"] = "Misc",
    ["illusions"] = "Illusions",
    ["altars"] = "Altars",
    ["free"] = L["Free"],
    ["out of stock"] = L["Out of Stock"],
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

-- SubType filter: "all" + all subtypes (reuses TMOG_SUBTYPE_LIST but excludes "none")
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
-- Transmogs Tab
-- ===================================================================================== --

function Options:LoadTransmogsTab(container)
    Options.transmogsContainer = container
    local prefix = TSM.db.profile.commandPrefix or ""
    local cmdPrefix = (prefix ~= "") and (prefix .. " ") or ""

    -- Initialize dropdown selections if not set
    if not Options.pendingTmogType then
        Options.pendingTmogType = "misc"
    end
    if not Options.pendingTmogSubType then
        Options.pendingTmogSubType = "none"
    end
    if not Options.tmogFilterTab then
        Options.tmogFilterTab = "mount"
    end
    if not Options.tmogFilterSubType then
        Options.tmogFilterSubType = "all"
    end
    if not Options.tmogFilterHand then
        Options.tmogFilterHand = "all"
    end
    if not Options.tmogCurrentPage then
        Options.tmogCurrentPage = 1
    end

    -- Get filtered items and validate current page
    local filteredItems = Options:GetFilteredTransmogItems()
    local totalPages = math.max(1, math.ceil(#filteredItems / ITEMS_PER_PAGE))
    if Options.tmogCurrentPage > totalPages then
        Options.tmogCurrentPage = totalPages
    end

    local page = {
        {
            type = "ScrollFrame",
            layout = "Flow",
            children = {
                -- Enable/Disable Section
                {
                    type = "InlineGroup",
                    title = L["Transmog Lookup"],
                    layout = "Flow",
                    fullWidth = true,
                    children = {
                        {
                            type = "CheckBox",
                            label = L["Enable Transmog Lookup"],
                            settingInfo = { TSM.db.profile.transmogs, "enabled" },
                            tooltip = L["Allow users to whisper you for transmog listings."],
                        },
                        {
                            type = "HeadingLine",
                        },
                        {
                            type = "Label",
                            text = L["When enabled, other players can whisper you with:"],
                            fullWidth = true,
                        },
                        {
                            type = "Label",
                            text = "  " .. cmdPrefix .. "tmog [type] [subtype] [name]",
                            fullWidth = true,
                        },
                        {
                            type = "Label",
                            text = L["Types: weapon, mount, pet, whistle, demon, incarnation, set, shield, tabard, misc, illusions, altars"],
                            fullWidth = true,
                        },
                        {
                            type = "Label",
                            text = L["Subtypes: sword, axe, mace, dagger, staff, polearm, bow, gun, crossbow, wand, thrown"],
                            fullWidth = true,
                        },
                        {
                            type = "Label",
                            text = L["Armor subtypes: head, shoulders, chest, wrist, gloves, waist, legs, feet, back"],
                            fullWidth = true,
                        },
                    },
                },
                {
                    type = "HeadingLine",
                },
                -- Add Item Section
                {
                    type = "InlineGroup",
                    title = L["Add Transmog Item"],
                    layout = "Flow",
                    fullWidth = true,
                    children = {
                        {
                            type = "EditBox",
                            label = L["Item link (Shift+Click item)"],
                            relativeWidth = 0.35,
                            value = Options.pendingTmogLink or "",
                            callback = function(widget, _, value)
                                Options.pendingTmogLink = value
                                -- Auto-detect type/subtype and price on Enter
                                if value and value ~= "" then
                                    local name, itemLink, _, _, _, _, itemSubClass, _, equipLoc = GetItemInfo(value)
                                    if name then
                                        local history = TSM.db.profile.transmogs.itemHistory
                                        local historyEntry = history and history[name]

                                        if historyEntry then
                                            -- History found: use saved type/subtype/price/hand
                                            if historyEntry.tmogType then
                                                Options.pendingTmogType = historyEntry.tmogType
                                            end
                                            if historyEntry.tmogSubType then
                                                Options.pendingTmogSubType = historyEntry.tmogSubType
                                            end
                                            if historyEntry.price then
                                                Options.pendingTmogPrice = tostring(math.floor(historyEntry.price / 10000))
                                            end
                                            Options.pendingTmogHand = historyEntry.tmogHand
                                        else
                                            -- No history: try to detect from item data
                                            local detectedType, detectedSubType, detectedHand = TSM:DetectTmogTypeAndSubType(itemSubClass, equipLoc)
                                            if detectedType then
                                                Options.pendingTmogType = detectedType
                                            end
                                            if detectedSubType then
                                                Options.pendingTmogSubType = detectedSubType
                                            end
                                            Options.pendingTmogHand = detectedHand
                                        end

                                        -- Refresh to show updated dropdowns and price
                                        Options:RefreshTransmogsTab()
                                    end
                                end
                            end,
                        },
                        {
                            type = "EditBox",
                            label = L["Price (gold)"],
                            relativeWidth = 0.15,
                            value = Options.pendingTmogPrice or "",
                            callback = function(widget, _, value)
                                Options.pendingTmogPrice = value
                            end,
                        },
                        {
                            type = "Dropdown",
                            label = L["Type"],
                            relativeWidth = 0.20,
                            list = GetTypeDropdownList(),
                            order = GetTypeDropdownOrder(),
                            value = Options.pendingTmogType,
                            callback = function(widget, _, value)
                                Options.pendingTmogType = value
                            end,
                        },
                        {
                            type = "Dropdown",
                            label = L["SubType"],
                            relativeWidth = 0.20,
                            list = GetSubTypeDropdownList(),
                            order = GetSubTypeDropdownOrder(),
                            value = Options.pendingTmogSubType,
                            callback = function(widget, _, value)
                                Options.pendingTmogSubType = value
                            end,
                        },
                        {
                            type = "Button",
                            text = L["Add"],
                            relativeWidth = 0.10,
                            callback = function()
                                Options:AddTransmogItemFromInput()
                            end,
                        },
                        {
                            type = "Button",
                            text = L["Clear All"],
                            relativeWidth = 0.10,
                            callback = function()
                                wipe(TSM.db.profile.transmogs.itemList)
                                Options.tmogCurrentPage = 1
                                Options:RefreshTransmogsTab()
                            end,
                        },
                        {
                            type = "Button",
                            text = L["Refresh Stock"],
                            relativeWidth = 0.12,
                            callback = function()
                                Options:RefreshTransmogStock()
                            end,
                        },
                        {
                            type = "Button",
                            text = L["Detect Hand"],
                            relativeWidth = 0.12,
                            callback = function()
                                Options:BackfillTmogHand()
                            end,
                        },
                    },
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
                    value = Options.tmogFilterTab,
                    callback = function(widget, _, value)
                        Options.tmogFilterTab = value
                        Options.tmogFilterSubType = "all"
                        Options.tmogFilterHand = "all"
                        Options.tmogCurrentPage = 1
                        Options:RefreshTransmogsTab()
                    end,
                },
                {
                    type = "Dropdown",
                    label = L["SubType"],
                    relativeWidth = 0.20,
                    list = GetFilterSubTypeDropdownList(),
                    order = GetFilterSubTypeDropdownOrder(),
                    value = Options.tmogFilterSubType,
                    callback = function(widget, _, value)
                        Options.tmogFilterSubType = value
                        Options.tmogCurrentPage = 1
                        Options:RefreshTransmogsTab()
                    end,
                },
                {
                    type = "Dropdown",
                    label = L["Hand"],
                    relativeWidth = 0.15,
                    list = { ["all"] = L["All"], ["1h"] = "1H", ["2h"] = "2H" },
                    order = { "all", "1h", "2h" },
                    value = Options.tmogFilterHand,
                    callback = function(widget, _, value)
                        Options.tmogFilterHand = value
                        Options.tmogCurrentPage = 1
                        Options:RefreshTransmogsTab()
                    end,
                },
                -- Item List Section
                {
                    type = "InlineGroup",
                    title = L["Transmog List"] .. " (" .. #filteredItems .. " " .. L["items"] .. ")",
                    layout = "Flow",
                    fullWidth = true,
                    children = Options:GetTransmogListWidgets(filteredItems, totalPages),
                },
            },
        },
    }

    TSMAPI:BuildPage(container, page)
end

-- ===================================================================================== --
-- Transmog List Management
-- ===================================================================================== --

-- Get filtered items based on current filter tab selection
-- Returns array of { index = originalIndex, item = itemRef }
function Options:GetFilteredTransmogItems()
    local filterValue = Options.tmogFilterTab or "all"
    local filterSubType = Options.tmogFilterSubType or "all"
    local filterHand = Options.tmogFilterHand or "all"
    local allItems = TSM.db.profile.transmogs.itemList
    local filtered = {}
    for i, item in ipairs(allItems) do
        local show = false
        if filterValue == "all" then
            show = true
        elseif filterValue == "free" then
            show = (not item.price or item.price == 0)
        elseif filterValue == "out of stock" then
            show = (item.inStock == false)
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
    return filtered
end

-- Get widgets for the transmog item list (paginated)
function Options:GetTransmogListWidgets(filteredItems, totalPages)
    local children = {}
    local currentPage = Options.tmogCurrentPage or 1
    local totalItems = #filteredItems

    if totalItems == 0 then
        tinsert(children, {
            type = "Label",
            text = L["No transmog items. Add items above."],
            fullWidth = true,
        })
        return children
    end

    -- Header row
    tinsert(children, { type = "Label", text = "|cffffd100S|r", relativeWidth = 0.05 })
    tinsert(children, { type = "Label", text = "|cffffd100" .. L["Item"] .. "|r", relativeWidth = 0.35 })
    tinsert(children, { type = "Label", text = "|cffffd100" .. L["Price"] .. "|r", relativeWidth = 0.10 })
    tinsert(children, { type = "Label", text = "|cffffd100" .. L["Type"] .. "|r", relativeWidth = 0.18 })
    tinsert(children, { type = "Label", text = "|cffffd100" .. L["SubType"] .. "|r", relativeWidth = 0.18 })
    tinsert(children, { type = "Label", text = "", relativeWidth = 0.12 })

    -- Get only the items for the current page
    local pagedItems = GetPagedItems(filteredItems)

    -- Item rows (only current page)
    for _, entry in ipairs(pagedItems) do
        local originalIndex = entry.index
        local item = entry.item
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
                Options:RefreshTransmogsTab()
            end,
        })
        tinsert(children, {
            type = "InteractiveLabel",
            text = item.link or item.name or "Unknown",
            relativeWidth = 0.36,
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
                if TSM.db.profile.transmogs.itemHistory[item.name] then
                    TSM.db.profile.transmogs.itemHistory[item.name].price = newPrice
                end
            end,
        })
        tinsert(children, {
            type = "Dropdown",
            label = "",
            relativeWidth = 0.18,
            list = GetTypeDropdownList(),
            order = GetTypeDropdownOrder(),
            value = currentType,
            callback = function(widget, _, value)
                item.tmogType = value
                -- Update history
                if TSM.db.profile.transmogs.itemHistory[item.name] then
                    TSM.db.profile.transmogs.itemHistory[item.name].tmogType = value
                end
            end,
        })
        tinsert(children, {
            type = "Dropdown",
            label = "",
            relativeWidth = 0.18,
            list = GetSubTypeDropdownList(),
            order = GetSubTypeDropdownOrder(),
            value = currentSubType,
            callback = function(widget, _, value)
                local subType = value ~= "none" and value or nil
                item.tmogSubType = subType
                -- Update history
                if TSM.db.profile.transmogs.itemHistory[item.name] then
                    TSM.db.profile.transmogs.itemHistory[item.name].tmogSubType = subType
                end
            end,
        })
        tinsert(children, {
            type = "Button",
            text = L["Delete"],
            relativeWidth = 0.12,
            callback = function()
                tremove(TSM.db.profile.transmogs.itemList, originalIndex)
                Options:RefreshTransmogsTab()
            end,
        })
    end

    -- Pagination controls (only show if more than one page)
    if totalPages > 1 then
        tinsert(children, { type = "HeadingLine" })
        tinsert(children, {
            type = "Button",
            text = "< " .. L["Prev"],
            relativeWidth = 0.15,
            disabled = (currentPage <= 1),
            callback = function()
                Options.tmogCurrentPage = math.max(1, currentPage - 1)
                Options:RefreshTransmogsTab()
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
                Options.tmogCurrentPage = math.min(totalPages, currentPage + 1)
                Options:RefreshTransmogsTab()
            end,
        })
    end

    return children
end

-- Refresh stock status for all transmog items using ItemTracker
function Options:RefreshTransmogStock()
    local ItemTracker = LibStub("AceAddon-3.0"):GetAddon("TSM_ItemTracker", true)
    if not ItemTracker then
        TSM:Print(L["ItemTracker not loaded."])
        return
    end

    local items = TSM.db.profile.transmogs.itemList
    local inStockCount, outOfStockCount = 0, 0

    for _, item in ipairs(items) do
        local itemString = item.link and TSMAPI:GetItemString(item.link)
        if itemString then
            local playerTotal, altTotal = ItemTracker:GetPlayerTotal(itemString)
            local guildTotal = ItemTracker:GetGuildTotal(itemString) or 0
            local personalBanksTotal = ItemTracker:GetPersonalBanksTotal(itemString) or 0
            local realmBankTotal = ItemTracker:GetRealmBankTotal(itemString) or 0
            local auctionsTotal = ItemTracker:GetAuctionsTotal(itemString) or 0
            local total = (playerTotal or 0) + (altTotal or 0) + guildTotal + personalBanksTotal + realmBankTotal + auctionsTotal
            local wasOutOfStock = (item.inStock == false)
            item.inStock = (total > 0)
            -- If item just came back in stock, update availableSince
            if wasOutOfStock and item.inStock then
                item.availableSince = time()
            end
        else
            item.inStock = false
        end

        if item.inStock then
            inStockCount = inStockCount + 1
        else
            outOfStockCount = outOfStockCount + 1
        end
    end

    TSM:Print(format(L["Stock refreshed: %d in stock, %d out of stock."], inStockCount, outOfStockCount))
    Options:RefreshTransmogsTab()
end

-- Backfill tmogHand for existing items that don't have it
function Options:BackfillTmogHand()
    local items = TSM.db.profile.transmogs.itemList
    local history = TSM.db.profile.transmogs.itemHistory
    local updated = 0

    for _, item in ipairs(items) do
        if not item.tmogHand and item.link then
            local _, _, _, _, _, _, itemSubClass, _, equipLoc = GetItemInfo(item.link)
            if itemSubClass then
                local _, _, hand = TSM:DetectTmogTypeAndSubType(itemSubClass, equipLoc)
                if hand then
                    item.tmogHand = hand
                    -- Also update history
                    if item.name and history[item.name] then
                        history[item.name].tmogHand = hand
                    end
                    updated = updated + 1
                end
            end
        end
    end

    TSM:Print(format(L["Hand detection: updated %d items."], updated))
    Options:RefreshTransmogsTab()
end

-- Refresh the transmogs tab
function Options:RefreshTransmogsTab()
    if Options.transmogsContainer then
        Options.transmogsContainer:ReleaseChildren()
        Options:LoadTransmogsTab(Options.transmogsContainer)
    end
end

-- Add a transmog item from input fields
function Options:AddTransmogItemFromInput()
    local link = Options.pendingTmogLink
    local priceStr = Options.pendingTmogPrice
    local tmogType = Options.pendingTmogType or "misc"
    local tmogSubType = Options.pendingTmogSubType or "none"

    if not link or link == "" then
        TSM:Print(L["Please enter an item link."])
        return
    end

    -- Get item info (name, link, and subclass/equiploc for hand detection)
    local name, itemLink, _, _, _, _, itemSubClass, _, equipLoc = GetItemInfo(link)

    if not name then
        TSM:Print(L["Invalid item link or item not cached."])
        return
    end

    -- Parse price (input in gold, store in copper)
    local price = nil
    if priceStr and priceStr ~= "" then
        local goldAmount = tonumber(priceStr)
        if goldAmount then
            price = goldAmount * 10000  -- Convert gold to copper
        end
    end

    -- Normalize subtype
    if tmogSubType == "none" then
        tmogSubType = nil
    end

    -- Detect hand type from item data
    local tmogHand = Options.pendingTmogHand
    if not tmogHand and itemSubClass then
        local _, _, detectedHand = TSM:DetectTmogTypeAndSubType(itemSubClass, equipLoc)
        tmogHand = detectedHand
    end

    -- Check for duplicates - update existing item instead of rejecting
    local existingIndex = nil
    for i, existing in ipairs(TSM.db.profile.transmogs.itemList) do
        if existing.name == name then
            existingIndex = i
            break
        end
    end

    if existingIndex then
        -- Update existing item
        local existing = TSM.db.profile.transmogs.itemList[existingIndex]
        existing.price = price
        existing.link = itemLink  -- refresh link in case it changed
        existing.tmogType = tmogType
        existing.tmogSubType = tmogSubType
        existing.tmogHand = tmogHand
        existing.published = true
        TSM:Print(format(L["Updated %s in transmog list."], itemLink))
    else
        -- Add new item
        tinsert(TSM.db.profile.transmogs.itemList, {
            link = itemLink,
            price = price,
            name = name,
            tmogType = tmogType,
            tmogSubType = tmogSubType,
            tmogHand = tmogHand,
            source = "Manual",
            published = true,
            availableSince = time(),
        })
        TSM:Print(format(L["Added %s to transmog list."], itemLink))
    end

    -- Save to item history (regardless of add or update)
    TSM.db.profile.transmogs.itemHistory[name] = {
        price = price,
        tmogType = tmogType,
        tmogSubType = tmogSubType,
        tmogHand = tmogHand,
    }

    -- Clear input fields (keep dropdown selections for convenience)
    Options.pendingTmogLink = nil
    Options.pendingTmogPrice = nil
    Options.pendingTmogHand = nil

    -- Refresh the tab
    Options:RefreshTransmogsTab()
end
