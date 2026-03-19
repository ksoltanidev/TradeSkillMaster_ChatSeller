-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Bagnon GuildBank Integration
-- Adds transmog management buttons to the Bagnon GuildBank frame
-- Works with Personal Bank and Realm Bank (both use GuildBank API on Ascension)
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")

-- ===================================================================================== --
-- Constants
-- ===================================================================================== --

local SLOTS_PER_TAB = 98
local BTN_WIDTH = 100
local BTN_HEIGHT = 20
local BTN_Y = 4
local BTN_SPACING = 4
local NUM_BAG_SLOTS = NUM_BAG_SLOTS or 4

-- ===================================================================================== --
-- State
-- ===================================================================================== --

local buttons = {}
local allButtons = {}
local buttonsCreated = false

-- Move queue
local moveQueue = {}
local moveFrame = CreateFrame("Frame")
local moveTimer = 0
local isMoving = false
local moveCallback = nil
moveFrame:Hide()

-- ===================================================================================== --
-- Bank Type Detection
-- ===================================================================================== --

local function GetCurrentAscensionBankType()
    if GuildBankFrame and GuildBankFrame.IsPersonalBank then
        return "personal"
    elseif GuildBankFrame and GuildBankFrame.IsRealmBank then
        return "realm"
    else
        return "guild"
    end
end

-- ===================================================================================== --
-- Helper Functions
-- ===================================================================================== --

-- Extract itemID string from an item link
local function GetItemIdFromLink(link)
    return link and link:match("item:(%d+)")
end

-- Build lookup of all transmog itemIDs -> item data
local function BuildTmogIdSet()
    local idSet = {}
    for _, item in ipairs(TSM.db.profile.transmogs.itemList) do
        local itemId = GetItemIdFromLink(item.link)
        if itemId then
            idSet[itemId] = item
        end
    end
    return idSet
end

-- Build lookup of free transmog itemIDs (price == 0 or nil)
local function BuildFreeTmogIdSet()
    local idSet = {}
    for _, item in ipairs(TSM.db.profile.transmogs.itemList) do
        if item.link and (not item.price or item.price == 0) then
            local itemId = GetItemIdFromLink(item.link)
            if itemId then
                idSet[itemId] = true
            end
        end
    end
    return idSet
end

-- Scan the current tab of the open guild bank, return { [itemId] = { {tab,slot}, ... } }
-- Only includes items whose itemID is in the provided idSet (or all items if idSet is nil)
local function ScanCurrentTabSlots(idSet)
    local currentTab = GetCurrentGuildBankTab()
    if not currentTab or currentTab == 0 then return {} end

    local result = {}
    for slot = 1, SLOTS_PER_TAB do
        local link = GetGuildBankItemLink(currentTab, slot)
        if link then
            local itemId = GetItemIdFromLink(link)
            if itemId and (not idSet or idSet[itemId]) then
                if not result[itemId] then result[itemId] = {} end
                tinsert(result[itemId], { tab = currentTab, slot = slot })
            end
        end
    end
    return result
end

-- Scan ALL tabs of the open bank, return { [itemId] = true }
-- Uses live API which works for all tabs (BagnonForever queries all tabs on bank open)
local function ScanAllBankTabIds(idSet)
    local ids = {}
    local numTabs = GetNumGuildBankTabs()
    for tab = 1, numTabs do
        for slot = 1, SLOTS_PER_TAB do
            local link = GetGuildBankItemLink(tab, slot)
            if link then
                local itemId = GetItemIdFromLink(link)
                if itemId and (not idSet or idSet[itemId]) then
                    ids[itemId] = true
                end
            end
        end
    end
    return ids
end

-- Scan ALL tabs of the open bank, return { [itemId] = count }
-- Needed by Gather Dupes to know total copies across all tabs
local function ScanAllBankTabCounts(idSet)
    local counts = {}
    local numTabs = GetNumGuildBankTabs()
    for tab = 1, numTabs do
        for slot = 1, SLOTS_PER_TAB do
            local link = GetGuildBankItemLink(tab, slot)
            if link then
                local itemId = GetItemIdFromLink(link)
                if itemId and (not idSet or idSet[itemId]) then
                    counts[itemId] = (counts[itemId] or 0) + 1
                end
            end
        end
    end
    return counts
end

-- Scan cached realm bank via BagnonForever, return { [itemId] = true }
local function ScanCachedRealmBankIds()
    local ids = {}
    if not BagnonDB then return ids end

    local ASC_REALM_BANK_OFFSET = ASC_REALM_BANK_OFFSET or 2000
    local cachePlayer = GetRealmName()

    for tab = 1, 6 do
        local bag = tab + ASC_REALM_BANK_OFFSET
        local size = BagnonDB:GetBagData(bag, cachePlayer)
        if size then
            for slot = 1, size do
                local hyperLink = BagnonDB:GetItemData(bag, slot, cachePlayer)
                if hyperLink then
                    local itemId = GetItemIdFromLink(hyperLink)
                    if itemId then
                        ids[itemId] = true
                    end
                end
            end
        end
    end
    return ids
end

-- Scan player bags for transmog items in idSet, return { [itemId] = { {bag,slot}, ... } }
local function ScanBagsForTmogItems(idSet)
    local found = {}
    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local itemId = GetItemIdFromLink(link)
                if itemId and idSet[itemId] then
                    if not found[itemId] then found[itemId] = {} end
                    tinsert(found[itemId], { bag = bag, slot = slot })
                end
            end
        end
    end
    return found
end

-- Find empty slots in the currently selected guild bank tab
local function FindEmptySlotsInCurrentTab()
    local currentTab = GetCurrentGuildBankTab()
    if not currentTab or currentTab == 0 then return {} end

    local empties = {}
    for slot = 1, SLOTS_PER_TAB do
        local texture = GetGuildBankItemInfo(currentTab, slot)
        if not texture then
            tinsert(empties, { tab = currentTab, slot = slot })
        end
    end
    return empties
end

-- Count total free bag slots
local function CountFreeBagSlots()
    local free = 0
    for bag = 0, NUM_BAG_SLOTS do
        local freeSlots = GetContainerNumFreeSlots(bag)
        free = free + (freeSlots or 0)
    end
    return free
end

-- ===================================================================================== --
-- Move Queue System
-- ===================================================================================== --

moveFrame:SetScript("OnUpdate", function()
    moveTimer = moveTimer + (arg1 or 0)
    if moveTimer < 0.05 then return end
    moveTimer = 0

    if #moveQueue == 0 then
        moveFrame:Hide()
        isMoving = false
        if moveCallback then
            local cb = moveCallback
            moveCallback = nil
            cb()
        end
        return
    end

    -- Don't process if cursor is busy
    if CursorHasItem() then
        ClearCursor()
        return
    end

    local move = tremove(moveQueue, 1)
    if move.moveType == "bankToBags" then
        AutoStoreGuildBankItem(move.tab, move.slot)
    elseif move.moveType == "bagsToBankTab" then
        PickupContainerItem(move.bag, move.slot)
        if CursorHasItem() then
            PickupGuildBankItem(move.targetTab, move.targetSlot)
        end
    end
end)

local function StartMoveQueue(moves, callback)
    if isMoving then
        TSM:Print(L["Move operation already in progress."])
        return false
    end
    if #moves == 0 then
        if callback then callback() end
        return true
    end
    moveQueue = moves
    moveCallback = callback
    isMoving = true
    moveTimer = 0
    moveFrame:Show()
    return true
end

-- ===================================================================================== --
-- Button Operations
-- ===================================================================================== --

-- Gather Free: move all free transmogs from bank to bags
local function OnGatherFree()
    local freeIds = BuildFreeTmogIdSet()
    if not next(freeIds) then
        TSM:Print(L["No free transmogs found in bank."])
        return
    end

    local bankSlots = ScanCurrentTabSlots(freeIds)
    local moves = {}
    local freeBagSlots = CountFreeBagSlots()

    for itemId, slots in pairs(bankSlots) do
        for _, info in ipairs(slots) do
            if #moves >= freeBagSlots then break end
            tinsert(moves, { moveType = "bankToBags", tab = info.tab, slot = info.slot })
        end
        if #moves >= freeBagSlots then break end
    end

    local totalFound = 0
    for _, slots in pairs(bankSlots) do
        totalFound = totalFound + #slots
    end

    if #moves == 0 then
        TSM:Print(L["No free transmogs found in bank."])
        return
    end

    local skipped = totalFound - #moves
    local moveCount = #moves
    StartMoveQueue(moves, function()
        TSM:Print(format(L["Gathered %d free transmogs from bank."], moveCount))
        if skipped > 0 then
            TSM:Print(format(L["Bags full - %d items not gathered."], skipped))
        end
    end)
end

-- Gather Dupes: move duplicate transmogs from realm bank to bags (keep 1 of each across ALL tabs)
local function OnGatherDupes()
    local tmogIds = BuildTmogIdSet()
    local allBankCounts = ScanAllBankTabCounts(tmogIds)    -- total copies across ALL tabs
    local currentTabSlots = ScanCurrentTabSlots(tmogIds)   -- slots on current tab only
    local moves = {}
    local freeBagSlots = CountFreeBagSlots()

    for itemId, slots in pairs(currentTabSlots) do
        local totalCount = allBankCounts[itemId] or 0
        if totalCount > 1 then
            local currentTabCount = #slots
            local otherTabCount = totalCount - currentTabCount
            -- How many to gather from this tab
            local toGather
            if otherTabCount > 0 then
                -- Item exists on other tabs, gather ALL from current tab
                toGather = currentTabCount
            else
                -- Item only on this tab, keep 1
                toGather = currentTabCount - 1
            end
            for i = 1, toGather do
                if #moves >= freeBagSlots then break end
                tinsert(moves, { moveType = "bankToBags", tab = slots[currentTabCount - i + 1].tab, slot = slots[currentTabCount - i + 1].slot })
            end
        end
        if #moves >= freeBagSlots then break end
    end

    if #moves == 0 then
        TSM:Print(L["No duplicate transmogs found in realm bank."])
        return
    end

    local moveCount = #moves
    StartMoveQueue(moves, function()
        TSM:Print(format(L["Gathered %d duplicate transmogs from realm bank."], moveCount))
    end)
end

-- Put Missing: deposit transmogs from bags that are NOT in realm bank into current tab
local function OnPutMissing()
    local currentTab = GetCurrentGuildBankTab()
    if not currentTab or currentTab == 0 then
        TSM:Print(L["No guild bank tab selected."])
        return
    end

    local tmogIds = BuildTmogIdSet()
    local allBankIds = ScanAllBankTabIds(tmogIds)  -- check ALL tabs, not just current
    local bagItems = ScanBagsForTmogItems(tmogIds)
    local emptySlots = FindEmptySlotsInCurrentTab()

    local moves = {}
    local emptyIdx = 1

    for itemId, bagSlots in pairs(bagItems) do
        if not allBankIds[itemId] then
            -- This item is missing from ALL bank tabs, deposit ONE
            if emptyIdx <= #emptySlots then
                local bagInfo = bagSlots[1]
                local target = emptySlots[emptyIdx]
                tinsert(moves, {
                    moveType = "bagsToBankTab",
                    bag = bagInfo.bag,
                    slot = bagInfo.slot,
                    targetTab = target.tab,
                    targetSlot = target.slot,
                })
                emptyIdx = emptyIdx + 1
            end
        end
    end

    if #moves == 0 then
        TSM:Print(L["No missing transmogs to store in realm bank."])
        return
    end

    local moveCount = #moves
    local tabNum = currentTab
    StartMoveQueue(moves, function()
        TSM:Print(format(L["Stored %d missing transmogs to realm bank (tab %d)."], moveCount, tabNum))
    end)
end

-- Gather Missing: from personal bank, gather transmogs that are NOT in (cached) realm bank
local function OnGatherMissing()
    if not BagnonDB then
        TSM:Print(L["Bagnon_Forever not loaded. Cannot cross-reference banks."])
        return
    end

    local realmBankIds = ScanCachedRealmBankIds()
    if not next(realmBankIds) then
        TSM:Print(L["No cached realm bank data. Visit realm bank first."])
        return
    end

    local tmogIds = BuildTmogIdSet()
    local bankSlots = ScanCurrentTabSlots(tmogIds)
    local moves = {}
    local freeBagSlots = CountFreeBagSlots()
    local gathered = {}  -- track itemIDs to only take ONE per item

    for itemId, slots in pairs(bankSlots) do
        if not realmBankIds[itemId] and not gathered[itemId] then
            if #moves >= freeBagSlots then break end
            tinsert(moves, { moveType = "bankToBags", tab = slots[1].tab, slot = slots[1].slot })
            gathered[itemId] = true
        end
    end

    if #moves == 0 then
        TSM:Print(L["No transmogs missing from realm bank found."])
        return
    end

    local moveCount = #moves
    StartMoveQueue(moves, function()
        TSM:Print(format(L["Gathered %d transmogs missing from realm bank."], moveCount))
    end)
end

-- Put Dupes: store in personal bank all transmog items from bags that are already in (cached) realm bank
local function OnPutDupes()
    if not BagnonDB then
        TSM:Print(L["Bagnon_Forever not loaded. Cannot cross-reference banks."])
        return
    end

    local currentTab = GetCurrentGuildBankTab()
    if not currentTab or currentTab == 0 then
        TSM:Print(L["No guild bank tab selected."])
        return
    end

    local realmBankIds = ScanCachedRealmBankIds()
    if not next(realmBankIds) then
        TSM:Print(L["No cached realm bank data. Visit realm bank first."])
        return
    end

    local tmogIds = BuildTmogIdSet()
    local bagItems = ScanBagsForTmogItems(tmogIds)
    local emptySlots = FindEmptySlotsInCurrentTab()

    local moves = {}
    local emptyIdx = 1

    for itemId, bagSlots in pairs(bagItems) do
        if realmBankIds[itemId] then
            -- This item is already in realm bank, store all copies in personal bank
            for _, bagInfo in ipairs(bagSlots) do
                if emptyIdx <= #emptySlots then
                    local target = emptySlots[emptyIdx]
                    tinsert(moves, {
                        moveType = "bagsToBankTab",
                        bag = bagInfo.bag,
                        slot = bagInfo.slot,
                        targetTab = target.tab,
                        targetSlot = target.slot,
                    })
                    emptyIdx = emptyIdx + 1
                end
            end
        end
    end

    if #moves == 0 then
        TSM:Print(L["No transmog duplicates found in bags."])
        return
    end

    local moveCount = #moves
    local tabNum = currentTab
    local tabFull = emptyIdx > #emptySlots
    StartMoveQueue(moves, function()
        TSM:Print(format(L["Stored %d transmog duplicates to personal bank (tab %d)."], moveCount, tabNum))
        if tabFull then
            -- Count how many we couldn't store
            local totalWanted = 0
            for itemId, bagSlots in pairs(bagItems) do
                if realmBankIds[itemId] then
                    totalWanted = totalWanted + #bagSlots
                end
            end
            local notStored = totalWanted - moveCount
            if notStored > 0 then
                TSM:Print(format(L["Bank tab full - %d items not stored."], notStored))
            end
        end
    end)
end

-- Sync Tmog: existing functionality
local function OnSyncTmog()
    local tab = GetCurrentGuildBankTab()
    if not tab or tab == 0 then
        TSM:Print(L["No guild bank tab selected."])
        return
    end
    local added, skipped = TSM:SyncFromGuildBank(tab)
    TSM:Print(format(L["Tmog sync: added %d items (%d skipped)."], added, skipped))
end

-- ===================================================================================== --
-- Button Creation and Layout
-- ===================================================================================== --

local function CreateManagementButton(name, text, xOffset, parent, onClick)
    local btn = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    btn:SetWidth(BTN_WIDTH)
    btn:SetHeight(BTN_HEIGHT)
    btn:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", xOffset, BTN_Y)
    btn:SetText(text)
    btn:SetNormalFontObject(GameFontNormalSmall)
    btn:SetHighlightFontObject(GameFontHighlightSmall)
    btn:SetScript("OnClick", onClick)
    btn:Hide()
    tinsert(allButtons, btn)
    return btn
end

local function CreateAllButtons(bagnonFrame)
    local x = 8
    buttons.gatherFree = CreateManagementButton("ChatSellerGatherFreeBtn", L["Gather Free"], x, bagnonFrame, OnGatherFree)
    x = x + BTN_WIDTH + BTN_SPACING + 8 -- extra 8px gap before Sync

    buttons.syncTmog = CreateManagementButton("ChatSellerGuildBankSyncBtn", L["Sync Tmog"], x, bagnonFrame, OnSyncTmog)
    x = x + BTN_WIDTH + BTN_SPACING

    -- Realm bank buttons (position 2-3)
    buttons.gatherDupes = CreateManagementButton("ChatSellerGatherDupesBtn", L["Gather Dupes"], x, bagnonFrame, OnGatherDupes)
    buttons.gatherMissing = CreateManagementButton("ChatSellerGatherMissingBtn", L["Gather Missing"], x, bagnonFrame, OnGatherMissing)

    x = x + BTN_WIDTH + BTN_SPACING

    buttons.putMissing = CreateManagementButton("ChatSellerPutMissingBtn", L["Put Missing"], x, bagnonFrame, OnPutMissing)
    buttons.putDupes = CreateManagementButton("ChatSellerPutDupesBtn", L["Put Dupes"], x, bagnonFrame, OnPutDupes)

    buttonsCreated = true
end

local function UpdateButtonVisibility()
    -- Hide all first
    for _, btn in ipairs(allButtons) do
        btn:Hide()
    end

    local bankType = GetCurrentAscensionBankType()

    if bankType == "personal" then
        buttons.gatherFree:Show()
        buttons.syncTmog:Show()
        buttons.gatherMissing:Show()
        buttons.putDupes:Show()
    elseif bankType == "realm" then
        buttons.gatherFree:Show()
        buttons.syncTmog:Show()
        buttons.gatherDupes:Show()
        buttons.putMissing:Show()
    end
    -- guild bank: no buttons
end

-- ===================================================================================== --
-- Event Handler
-- ===================================================================================== --

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("GUILDBANKFRAME_OPENED")
eventFrame:RegisterEvent("GUILDBANKFRAME_CLOSED")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "GUILDBANKFRAME_OPENED" then
        local bagnonFrame = _G["BagnonFrameguildbank"]
        if not bagnonFrame then return end

        if not buttonsCreated then
            CreateAllButtons(bagnonFrame)
        end
        UpdateButtonVisibility()

    elseif event == "GUILDBANKFRAME_CLOSED" then
        for _, btn in ipairs(allButtons) do
            btn:Hide()
        end
        -- Cancel any in-progress moves
        if isMoving then
            moveQueue = {}
            moveFrame:Hide()
            isMoving = false
            moveCallback = nil
        end
    end
end)
