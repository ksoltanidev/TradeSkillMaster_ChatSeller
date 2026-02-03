-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Prices Feature
-- Price lookup command handling
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")

-- ===================================================================================== --
-- Price Command Handler
-- ===================================================================================== --

-- Handle the price command: gem price [item links]
function TSM:HandlePriceCommand(sender, itemLinks)
    for _, itemLink in ipairs(itemLinks) do
        local response = TSM:GetPriceResponse(itemLink)
        if response then
            SendChatMessage(response, "WHISPER", nil, sender)
        end
    end
end

-- Build price response message for an item
function TSM:GetPriceResponse(itemLink)
    -- Get item ID
    local itemID = TSMAPI:GetItemID(itemLink)
    if not itemID then return nil end

    -- Get AuctionDB addon reference
    local AuctionDB = LibStub("AceAddon-3.0"):GetAddon("TSM_AuctionDB", true)
    if not AuctionDB then
        return format(L["%s No auction data available."], itemLink)
    end

    -- Ensure data is decoded
    if AuctionDB.DecodeItemData then
        AuctionDB:DecodeItemData(itemID)
    end

    -- Check if we have data for this item
    if not AuctionDB.data or not AuctionDB.data[itemID] then
        return format(L["%s No auction data available."], itemLink)
    end

    local itemData = AuctionDB.data[itemID]

    -- Get price values
    local marketValue = TSMAPI:GetItemValue(itemLink, "DBMarket")
    local minBuyout = TSMAPI:GetItemValue(itemLink, "DBMinBuyout")
    local quantity = itemData.quantity or 0
    local lastScan = itemData.lastScan or 0

    -- Format the time difference
    local timeAgo = L["unknown"]
    if lastScan and lastScan > 0 then
        local seconds = time() - lastScan
        if seconds < 60 then
            timeAgo = format("%d sec", seconds)
        elseif seconds < 3600 then
            timeAgo = format("%d min", math.floor(seconds / 60))
        elseif seconds < 86400 then
            timeAgo = format("%d hr", math.floor(seconds / 3600))
        else
            timeAgo = format("%d days", math.floor(seconds / 86400))
        end
    end

    -- Format prices for chat
    local minBuyoutText = TSM:FormatMoneyForChat(minBuyout) or L["N/A"]
    local marketValueText = TSM:FormatMoneyForChat(marketValue) or L["N/A"]

    -- Build response message
    local response = format(
        L["%s There were %d auctions %s ago, starting from %s. Average price is %s."],
        itemLink,
        quantity,
        timeAgo,
        minBuyoutText,
        marketValueText
    )

    return response
end
