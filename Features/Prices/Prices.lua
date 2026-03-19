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

    local hasAuctionData = false
    local response = ""

    -- Get AuctionDB addon reference
    local AuctionDB = LibStub("AceAddon-3.0"):GetAddon("TSM_AuctionDB", true)
    if AuctionDB then
        -- Ensure data is decoded
        if AuctionDB.DecodeItemData then
            AuctionDB:DecodeItemData(itemID)
        end

        if AuctionDB.data and AuctionDB.data[itemID] then
            hasAuctionData = true
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

            -- Build auction response
            response = format(
                L["%s There were %d auctions %s ago, starting from %s. Average price is %s."],
                itemLink,
                quantity,
                timeAgo,
                minBuyoutText,
                marketValueText
            )
        end
    end

    -- Append or build Bazaar info
    local bazaarInfo = TSM:GetBazaarInfo(itemLink)
    if bazaarInfo then
        if hasAuctionData then
            response = response .. " " .. bazaarInfo
        else
            response = format("%s %s", itemLink, bazaarInfo)
        end
    elseif not hasAuctionData then
        response = format(L["%s No auction data available."], itemLink)
    end

    return response
end

-- Get Tiraxis Bazaar info from TSM_Merchant
-- Returns string like "Last seen 2d ago in Tiraxis Bazaar for 5 Bazaar Tokens"
function TSM:GetBazaarInfo(itemLink)
    local Merchant = LibStub("AceAddon-3.0"):GetAddon("TSM_Merchant", true)
    if not Merchant or not Merchant.GetMerchantEntry then return nil end

    local itemString = TSMAPI:GetItemString(itemLink)
    if not itemString then return nil end

    local entry = Merchant:GetMerchantEntry(itemString)
    if not entry then return nil end

    -- Build "Last seen Xd ago in Tiraxis Bazaar for N Bazaar Tokens"
    local timeStr
    if entry.lastSeen then
        local elapsed = time() - entry.lastSeen
        if elapsed < 3600 then
            timeStr = format("%dm ago", math.floor(elapsed / 60))
        elseif elapsed < 86400 then
            timeStr = format("%dh ago", math.floor(elapsed / 3600))
        else
            timeStr = format("%dd ago", math.floor(elapsed / 86400))
        end
    end

    -- Get total token count
    local tokenCount = 0
    if entry.extendedCost and entry.costItems then
        for _, cost in ipairs(entry.costItems) do
            if cost.value and cost.value > 0 then
                tokenCount = tokenCount + cost.value
            end
        end
    end

    if timeStr and tokenCount > 0 then
        return format("Last seen %s in Tiraxis Bazaar for %d Bazaar Tokens", timeStr, tokenCount)
    elseif timeStr then
        return format("Last seen %s in Tiraxis Bazaar", timeStr)
    elseif tokenCount > 0 then
        return format("Available in Tiraxis Bazaar for %d Bazaar Tokens", tokenCount)
    end

    return nil
end
