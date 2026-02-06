-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Transmogs Tab UI
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")

-- Get Options module reference
local Options = TSM:GetModule("Options")

-- ===================================================================================== --
-- Transmog Type/SubType Definitions (for dropdowns)
-- ===================================================================================== --

-- Base types for dropdown
local TMOG_TYPE_LIST = {
    "weapon", "mount", "pet", "armor set", "shield", "tabard", "misc", "illusions", "altars",
}

-- Display names for types
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

-- Detect tmogType and tmogSubType from GetItemInfo data
-- Returns tmogType, tmogSubType (or nil, nil if unrecognized)
function TSM:DetectTmogTypeAndSubType(itemSubClass, equipLoc)
    -- Check weapon subclass first
    local weaponSubType = ITEM_SUBCLASS_TO_TMOG_SUBTYPE[itemSubClass]
    if weaponSubType then
        return "weapon", weaponSubType
    end

    -- Check shield (special type, not "armor set")
    if equipLoc == "INVTYPE_SHIELD" then
        return "shield", "none"
    end

    -- Check tabard
    if equipLoc == "INVTYPE_BODY" then
        return "tabard", "none"
    end

    -- Check armor slots
    local armorSubType = EQUIP_LOC_TO_TMOG_SUBTYPE[equipLoc]
    if armorSubType then
        return "armor set", armorSubType
    end

    -- Unrecognized - return nil to keep current dropdown values
    return nil, nil
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
local FILTER_LIST = { "all", "weapon", "mount", "pet", "armor set", "shield", "tabard", "misc", "illusions", "altars", "free", "out of stock" }
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
    ["free"] = L["Free"],
    ["out of stock"] = L["Out of Stock"],
}

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

    -- Get filtered items for the title count
    local filteredItems = Options:GetFilteredTransmogItems()

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
                            text = L["Types: weapon, mount, pet, set, shield, tabard, misc, illusions, altars"],
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
                                            -- History found: use saved type/subtype/price
                                            if historyEntry.tmogType then
                                                Options.pendingTmogType = historyEntry.tmogType
                                            end
                                            if historyEntry.tmogSubType then
                                                Options.pendingTmogSubType = historyEntry.tmogSubType
                                            end
                                            if historyEntry.price then
                                                Options.pendingTmogPrice = tostring(math.floor(historyEntry.price / 10000))
                                            end
                                        else
                                            -- No history: try to detect from item data
                                            local detectedType, detectedSubType = TSM:DetectTmogTypeAndSubType(itemSubClass, equipLoc)
                                            if detectedType then
                                                Options.pendingTmogType = detectedType
                                            end
                                            if detectedSubType then
                                                Options.pendingTmogSubType = detectedSubType
                                            end
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
                            relativeWidth = 0.12,
                            callback = function()
                                wipe(TSM.db.profile.transmogs.itemList)
                                Options:RefreshTransmogsTab()
                            end,
                        },
                        {
                            type = "Button",
                            text = L["Refresh Stock"],
                            relativeWidth = 0.14,
                            callback = function()
                                Options:RefreshTransmogStock()
                            end,
                        },
                    },
                },
                {
                    type = "HeadingLine",
                },
                -- Filter Dropdown
                {
                    type = "Dropdown",
                    label = L["Filter"],
                    relativeWidth = 0.30,
                    list = GetFilterDropdownList(),
                    order = GetFilterDropdownOrder(),
                    value = Options.tmogFilterTab,
                    callback = function(widget, _, value)
                        Options.tmogFilterTab = value
                        Options:RefreshTransmogsTab()
                    end,
                },
                -- Item List Section
                {
                    type = "InlineGroup",
                    title = L["Transmog List"] .. " (" .. #filteredItems .. " " .. L["items"] .. ")",
                    layout = "Flow",
                    fullWidth = true,
                    children = Options:GetTransmogListWidgets(filteredItems),
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
        else
            show = (item.tmogType == filterValue)
        end
        if show then
            tinsert(filtered, { index = i, item = item })
        end
    end
    return filtered
end

-- Get widgets for the transmog item list
function Options:GetTransmogListWidgets(filteredItems)
    local children = {}

    if #filteredItems == 0 then
        tinsert(children, {
            type = "Label",
            text = L["No transmog items. Add items above."],
            fullWidth = true,
        })
        return children
    end

    -- Header row
    tinsert(children, { type = "Label", text = "|cffffd100" .. L["Item"] .. "|r", relativeWidth = 0.28 })
    tinsert(children, { type = "Label", text = "|cffffd100" .. L["Price"] .. "|r", relativeWidth = 0.10 })
    tinsert(children, { type = "Label", text = "|cffffd100" .. L["Type"] .. "|r", relativeWidth = 0.18 })
    tinsert(children, { type = "Label", text = "|cffffd100" .. L["SubType"] .. "|r", relativeWidth = 0.18 })
    tinsert(children, { type = "Label", text = "", relativeWidth = 0.12 })

    -- Item rows
    for _, entry in ipairs(filteredItems) do
        local originalIndex = entry.index
        local item = entry.item
        local priceGold = (item.price and item.price > 0) and tostring(math.floor(item.price / 10000)) or ""
        local currentType = item.tmogType or "misc"
        local currentSubType = item.tmogSubType or "none"

        -- Stock indicator prefix
        local stockPrefix = ""
        if item.inStock == true then
            stockPrefix = "|cff00ff00[S]|r "
        elseif item.inStock == false then
            stockPrefix = "|cffff0000[X]|r "
        end

        tinsert(children, {
            type = "InteractiveLabel",
            text = stockPrefix .. (item.link or item.name or "Unknown"),
            relativeWidth = 0.28,
            tooltip = item.link,
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
            local total = (playerTotal or 0) + (altTotal or 0) + guildTotal + personalBanksTotal + realmBankTotal
            item.inStock = (total > 0)
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

    -- Get item info (just need the name and link for validation)
    local name, itemLink = GetItemInfo(link)

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
        TSM:Print(format(L["Updated %s in transmog list."], itemLink))
    else
        -- Add new item
        tinsert(TSM.db.profile.transmogs.itemList, {
            link = itemLink,
            price = price,
            name = name,
            tmogType = tmogType,
            tmogSubType = tmogSubType,
            source = "Manual",
        })
        TSM:Print(format(L["Added %s to transmog list."], itemLink))
    end

    -- Save to item history (regardless of add or update)
    TSM.db.profile.transmogs.itemHistory[name] = {
        price = price,
        tmogType = tmogType,
        tmogSubType = tmogSubType,
    }

    -- Clear input fields (keep dropdown selections for convenience)
    Options.pendingTmogLink = nil
    Options.pendingTmogPrice = nil

    -- Refresh the tab
    Options:RefreshTransmogsTab()
end
