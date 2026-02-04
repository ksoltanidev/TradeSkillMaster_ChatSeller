-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Gears Tab UI
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")

-- Get Options module reference
local Options = TSM:GetModule("Options")

-- Shortcut to GearsData
local GD = TSM.GearsData

-- ===================================================================================== --
-- Gears Tab
-- ===================================================================================== --

function Options:LoadGearsTab(container)
    Options.gearsContainer = container
    local prefix = TSM.db.profile.commandPrefix or ""
    local cmdPrefix = (prefix ~= "") and (prefix .. " ") or ""
    local items = TSM.db.profile.gears.itemList

    local page = {
        {
            type = "ScrollFrame",
            layout = "Flow",
            children = {
                -- Enable/Disable Section
                {
                    type = "InlineGroup",
                    title = L["Gear Lookup"],
                    layout = "Flow",
                    fullWidth = true,
                    children = {
                        {
                            type = "CheckBox",
                            label = L["Enable Gear Lookup"],
                            settingInfo = { TSM.db.profile.gears, "enabled" },
                            tooltip = L["Allow users to whisper you for gear listings."],
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
                            text = "  " .. cmdPrefix .. "gear [category] [subcategory]",
                            fullWidth = true,
                        },
                        {
                            type = "Label",
                            text = L["Categories: cloth, leather, mail, plate, neck, ring, trinket, back, weapon"],
                            fullWidth = true,
                        },
                        {
                            type = "Label",
                            text = L["Armor slots: head, shoulders, chest, wrist, gloves, waist, legs, feet"],
                            fullWidth = true,
                        },
                        {
                            type = "Label",
                            text = L["Weapons: sword, axe, mace, dagger, staff, polearm, bow, gun, crossbow, wand, shield"],
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
                    title = L["Add Gear Item"],
                    layout = "Flow",
                    fullWidth = true,
                    children = {
                        {
                            type = "EditBox",
                            label = L["Item link (Shift+Click item)"],
                            relativeWidth = 0.5,
                            value = Options.pendingGearLink or "",
                            callback = function(widget, _, value)
                                Options.pendingGearLink = value
                            end,
                        },
                        {
                            type = "EditBox",
                            label = L["Price (gold)"],
                            relativeWidth = 0.25,
                            value = Options.pendingGearPrice or "",
                            callback = function(widget, _, value)
                                Options.pendingGearPrice = value
                            end,
                        },
                        {
                            type = "Button",
                            text = L["Add"],
                            relativeWidth = 0.12,
                            callback = function()
                                Options:AddGearItemFromInput()
                            end,
                        },
                        {
                            type = "Button",
                            text = L["Clear All"],
                            relativeWidth = 0.12,
                            callback = function()
                                wipe(TSM.db.profile.gears.itemList)
                                Options:RefreshGearsTab()
                            end,
                        },
                    },
                },
                {
                    type = "HeadingLine",
                },
                -- Item List Section
                {
                    type = "InlineGroup",
                    title = L["Gear List"] .. " (" .. #items .. " " .. L["items"] .. ")",
                    layout = "Flow",
                    fullWidth = true,
                    children = Options:GetGearListWidgets(),
                },
            },
        },
    }

    TSMAPI:BuildPage(container, page)
end

-- ===================================================================================== --
-- Gear List Management
-- ===================================================================================== --

-- Get widgets for the gear item list
function Options:GetGearListWidgets()
    local children = {}
    local items = TSM.db.profile.gears.itemList

    if #items == 0 then
        tinsert(children, {
            type = "Label",
            text = L["No gear items. Add items above."],
            fullWidth = true,
        })
        return children
    end

    -- Header row
    tinsert(children, { type = "Label", text = "|cffffd100" .. L["Item"] .. "|r", relativeWidth = 0.30 })
    tinsert(children, { type = "Label", text = "|cffffd100" .. L["Price"] .. "|r", relativeWidth = 0.12 })
    tinsert(children, { type = "Label", text = "|cffffd100" .. L["Type"] .. "|r", relativeWidth = 0.12 })
    tinsert(children, { type = "Label", text = "|cffffd100" .. L["Slot"] .. "|r", relativeWidth = 0.12 })
    tinsert(children, { type = "Label", text = "|cffffd100" .. L["Source"] .. "|r", relativeWidth = 0.12 })
    tinsert(children, { type = "Label", text = "", relativeWidth = 0.22 })

    -- Item rows
    for i, item in ipairs(items) do
        -- Source display: "AH" for AuctionsTab, "Manual" otherwise
        local sourceText = item.source == "AuctionsTab" and "|cff00ff00AH|r" or "|cffffffffManual|r"

        tinsert(children, {
            type = "Label",
            text = item.link or item.name or "Unknown",
            relativeWidth = 0.30,
        })
        tinsert(children, {
            type = "Label",
            text = item.price and TSM:FormatMoneyForChat(item.price) or L["N/A"],
            relativeWidth = 0.12,
        })
        tinsert(children, {
            type = "Label",
            text = item.itemSubClass or L["N/A"],
            relativeWidth = 0.12,
        })
        tinsert(children, {
            type = "Label",
            text = TSM:GetSlotDisplayName(item.equipLoc) or L["N/A"],
            relativeWidth = 0.12,
        })
        tinsert(children, {
            type = "Label",
            text = sourceText,
            relativeWidth = 0.12,
        })
        tinsert(children, {
            type = "Button",
            text = L["Delete"],
            relativeWidth = 0.22,
            callback = function()
                tremove(TSM.db.profile.gears.itemList, i)
                Options:RefreshGearsTab()
            end,
        })
    end

    return children
end

-- Refresh the gears tab
function Options:RefreshGearsTab()
    if Options.gearsContainer then
        Options.gearsContainer:ReleaseChildren()
        Options:LoadGearsTab(Options.gearsContainer)
    end
end

-- Add a gear item from input fields
function Options:AddGearItemFromInput()
    local link = Options.pendingGearLink
    local priceStr = Options.pendingGearPrice

    if not link or link == "" then
        TSM:Print(L["Please enter an item link."])
        return
    end

    -- Get item info (WoW 3.3.5 GetItemInfo returns: name, link, rarity, iLevel, reqLevel, type, subType, stackCount, equipLoc, texture, sellPrice)
    local name, itemLink, _, iLevel, reqLevel, itemClass, itemSubClass, _, equipLoc = GetItemInfo(link)

    if not name then
        TSM:Print(L["Invalid item link or item not cached."])
        return
    end

    -- Validate it's equippable gear
    if not equipLoc or equipLoc == "" or not GD.VALID_EQUIP_LOCS[equipLoc] then
        TSM:Print(format(L["%s is not equippable gear."], itemLink or link))
        return
    end

    -- Check for duplicates
    for _, existing in ipairs(TSM.db.profile.gears.itemList) do
        if existing.name == name then
            TSM:Print(format(L["%s is already in the list."], itemLink or link))
            return
        end
    end

    -- Parse price (input in gold, store in copper)
    local price = nil
    if priceStr and priceStr ~= "" then
        local goldAmount = tonumber(priceStr)
        if goldAmount then
            price = goldAmount * 10000  -- Convert gold to copper
        end
    end

    -- Extract item stats using GetItemStats API
    local stats = {}
    local itemStats = GetItemStats(itemLink)
    if itemStats then
        for statKey, modKey in pairs(GD.STAT_TO_ITEM_MOD) do
            if itemStats[modKey] and itemStats[modKey] > 0 then
                stats[statKey] = itemStats[modKey]
            end
        end
    end

    -- Add to list
    tinsert(TSM.db.profile.gears.itemList, {
        link = itemLink,
        price = price,
        name = name,
        equipLoc = equipLoc,
        itemClass = itemClass,
        itemSubClass = itemSubClass,
        iLevel = iLevel,        -- Item level
        reqLevel = reqLevel,    -- Required player level
        stats = stats,          -- Stats table {STRENGTH = 50, ...}
    })

    TSM:Print(format(L["Added %s to gear list."], itemLink))

    -- Clear input fields
    Options.pendingGearLink = nil
    Options.pendingGearPrice = nil

    -- Refresh the tab
    Options:RefreshGearsTab()
end
