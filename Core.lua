-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Core
-- Chat-based selling automation module for TSM
-- ------------------------------------------------------------------------------------- --

-- Initialize addon namespace
local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TSM_ChatSeller", "AceEvent-3.0", "AceConsole-3.0")

-- Expose globally for other addons (e.g., AuctionsTab integration)
TSM_ChatSeller = TSM

-- Localization
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")

-- ===================================================================================== --
-- Default Saved Variables
-- ===================================================================================== --

local savedDBDefaults = {
    profile = {
        commandPrefix = "gem",  -- Global command prefix for all features
        prices = {
            enabled = true,     -- Enable/disable price lookup feature
        },
        gears = {
            enabled = true,     -- Enable/disable gear lookup feature
            itemList = {},      -- {link, price, name, equipLoc, itemClass, itemSubClass, source}
        },
        transmogs = {
            enabled = true,     -- Enable/disable transmog lookup feature
            itemList = {},      -- {link, price, name, tmogType, tmogSubType, source}
            itemHistory = {},   -- { ["Item Name"] = { price = copper, tmogType = "weapon", tmogSubType = "sword" } }
            offerList = {},     -- {itemName, itemLink, buyer, offeredPrice, setPrice, isUnderSetPrice, status, timestamp}
        },
        loyalty = {
            enabled = true,             -- Enable/disable loyalty points system
            playerPoints = {},          -- { ["PlayerName"] = pointsInteger }
            pointsPerGold = 10,         -- Points awarded per gold spent
            rewardThreshold = 10000,    -- Points needed for reward
            rewardGoldDiscount = 100,   -- Gold discount when threshold reached
            completedOffers = {},       -- Archived completed offers
            maxCompletedOffers = 200,   -- Cap on completed offer history
        },
    },
}

-- ===================================================================================== --
-- Addon Lifecycle
-- ===================================================================================== --

function TSM:OnInitialize()
    -- Initialize saved variables database
    TSM.db = LibStub("AceDB-3.0"):New("AscensionTSM_ChatSellerDB", savedDBDefaults, true)

    -- Make module references accessible on TSM object
    for moduleName, module in pairs(TSM.modules) do
        TSM[moduleName] = module
    end

    -- Register with TSM
    TSM:RegisterModule()
end

function TSM:OnEnable()
    -- Register whisper event listener
    self:RegisterEvent("CHAT_MSG_WHISPER")
end

function TSM:OnDisable()
    -- Unregister events
    self:UnregisterEvent("CHAT_MSG_WHISPER")
end

-- ===================================================================================== --
-- TSM Module Registration
-- ===================================================================================== --

function TSM:RegisterModule()
    TSM.icons = {
        {
            side = "module",
            desc = "ChatSeller",
            slashCommand = "chatseller",
            callback = "Options:Load",
            icon = "Interface\\Icons\\INV_Misc_Note_01",
        },
    }

    TSM.slashCommands = {
        {
            key = "chatseller",
            label = L["Opens the TSM window to the ChatSeller page"],
            callback = function()
                TSMAPI:OpenFrame()
                TSMAPI:SelectIcon("TSM_ChatSeller", "ChatSeller")
            end
        },
        {
            key = "tmogoffers",
            label = L["Toggle Tmog Offers window"],
            callback = function()
                TSM:ToggleOffersWindow()
            end
        },
        {
            key = "loyalty",
            label = L["Toggle Loyalty Points window"],
            callback = function()
                TSM:ToggleLoyaltyWindow()
            end
        },
    }

    TSMAPI:NewModule(TSM)
end

-- ===================================================================================== --
-- Offers Window Toggle
-- ===================================================================================== --

function TSM:ToggleOffersWindow()
    if TSM.OffersWindow then
        TSM.OffersWindow:Toggle()
    end
end

function TSM:ToggleLoyaltyWindow()
    if TSM.LoyaltyWindow then
        TSM.LoyaltyWindow:Toggle()
    end
end

-- ===================================================================================== --
-- Shared Utilities
-- ===================================================================================== --

-- Format money for chat (gold/silver/copper without color codes)
function TSM:FormatMoneyForChat(money)
    if not money or money == 0 then return nil end

    local gold = math.floor(money / 10000)
    local silver = math.floor((money % 10000) / 100)
    local copper = money % 100

    if gold > 0 then
        return format("%dg %ds %dc", gold, silver, copper)
    elseif silver > 0 then
        return format("%ds %dc", silver, copper)
    else
        return format("%dc", copper)
    end
end

-- ===================================================================================== --
-- External Integration API
-- ===================================================================================== --

-- Sync gear items from AuctionsTab
-- Removes all items with source="AuctionsTab" then adds new items from the provided list
-- @param items: table of {link, price, name} from AuctionsTab
-- @return number of items added, number of items removed
function TSM:SyncFromAuctionsTab(items)
    if not items or #items == 0 then
        return 0
    end

    local gearList = TSM.db.profile.gears.itemList
    local GD = TSM.GearsData

    -- Step 1: Remove all items with source="AuctionsTab"
    local removed = 0
    for i = #gearList, 1, -1 do
        if gearList[i].source == "AuctionsTab" then
            tremove(gearList, i)
            removed = removed + 1
        end
    end

    -- Step 2: Add new items (only equippable gear)
    local added = 0
    for _, item in ipairs(items) do
        -- WoW 3.3.5 GetItemInfo returns: name, link, rarity, iLevel, reqLevel, type, subType, stackCount, equipLoc, texture, sellPrice
        local name, itemLink, _, iLevel, reqLevel, itemClass, itemSubClass, _, equipLoc = GetItemInfo(item.link)

        -- Skip if item not cached or not equippable gear
        if name and equipLoc and equipLoc ~= "" and GD.VALID_EQUIP_LOCS[equipLoc] then
            -- Check for duplicates (by name, excluding AuctionsTab source items we just removed)
            local isDuplicate = false
            for _, existing in ipairs(gearList) do
                if existing.name == name then
                    isDuplicate = true
                    break
                end
            end

            if not isDuplicate then
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

                tinsert(gearList, {
                    link = itemLink,
                    price = item.price,
                    name = name,
                    equipLoc = equipLoc,
                    itemClass = itemClass,
                    itemSubClass = itemSubClass,
                    source = "AuctionsTab",
                    iLevel = iLevel,        -- Item level
                    reqLevel = reqLevel,    -- Required player level
                    stats = stats,          -- Stats table {STRENGTH = 50, ...}
                })
                added = added + 1
            end
        end
    end

    return added, removed
end

-- Sync transmog items from currently open guild bank tab
-- Additive-only: adds new items, skips duplicates (by name)
-- Uses itemHistory for saved type/subtype/price, falls back to auto-detection
-- @param tab: guild bank tab number (1-8)
-- @return number of items added, number of items skipped
function TSM:SyncFromGuildBank(tab)
    if not tab or tab == 0 then return 0, 0 end

    local tmogList = TSM.db.profile.transmogs.itemList
    local history = TSM.db.profile.transmogs.itemHistory

    -- Build name lookup for O(1) duplicate checking
    local existingNames = {}
    for _, item in ipairs(tmogList) do
        if item.name then
            existingNames[item.name] = true
        end
    end

    local added, skipped = 0, 0
    for slot = 1, 98 do
        local itemLink = GetGuildBankItemLink(tab, slot)
        if itemLink then
            local name, _, _, _, _, _, itemSubClass, _, equipLoc = GetItemInfo(itemLink)
            if name and not existingNames[name] then
                local tmogType, tmogSubType, price
                local historyEntry = history and history[name]

                if historyEntry then
                    tmogType = historyEntry.tmogType
                    tmogSubType = historyEntry.tmogSubType
                    price = historyEntry.price
                else
                    tmogType, tmogSubType = TSM:DetectTmogTypeAndSubType(itemSubClass, equipLoc)
                end

                -- Default to "misc" if type could not be detected
                tmogType = tmogType or "misc"

                tinsert(tmogList, {
                    link = itemLink,
                    price = price,
                    name = name,
                    tmogType = tmogType,
                    tmogSubType = tmogSubType,
                    source = "GuildBank",
                })
                existingNames[name] = true
                added = added + 1
            else
                if itemLink then
                    skipped = skipped + 1
                end
            end
        end
    end

    return added, skipped
end
