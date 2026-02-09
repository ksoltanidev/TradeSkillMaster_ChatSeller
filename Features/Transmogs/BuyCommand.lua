-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Buy Command
-- Handles "buy [item link] [optional gold amount]" whisper commands
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")

-- ===================================================================================== --
-- Utility Functions
-- ===================================================================================== --

-- Find a transmog item in the itemList by matching item name
function TSM:FindTransmogItemByLink(itemLink)
    local searchName = GetItemInfo(itemLink)
    if not searchName then return nil end

    for _, item in ipairs(TSM.db.profile.transmogs.itemList) do
        if item.name == searchName then
            return item
        end
    end
    return nil
end

-- Extract gold amount from text (supports "10", "10g", "10 g", "10gold", "10 gold")
function TSM:ExtractGoldAmount(text)
    if not text or text == "" then return nil end
    local trimmed = strtrim(text)
    local goldStr = strmatch(trimmed, "^(%d+)%s*g?o?l?d?$")
    if goldStr then
        local gold = tonumber(goldStr)
        if gold and gold > 0 then
            return gold * 10000
        end
    end
    return nil
end

-- ===================================================================================== --
-- Buy Command Handler
-- ===================================================================================== --

-- Handle the buy command: gem buy [item link] [optional gold amount]
-- @param sender: the player who sent the whisper
-- @param message: the original (non-lowered) whisper message
function TSM:HandleBuyCommand(sender, message)
    -- Extract item links from the original message
    local itemLinks = TSM:ExtractItemLinks(message)
    if #itemLinks == 0 then
        local prefix = TSM.db.profile.commandPrefix or ""
        local cmdPrefix = (prefix ~= "") and (prefix .. " ") or ""
        SendChatMessage("Usage: " .. cmdPrefix .. "buy [item link] [gold amount]", "WHISPER", nil, sender)
        return
    end

    local itemLink = itemLinks[1]

    -- Find the item in the transmog list
    local item = TSM:FindTransmogItemByLink(itemLink)
    if not item then
        SendChatMessage(L["Item not found in transmog list."], "WHISPER", nil, sender)
        return
    end

    -- Check stock status (inStock == nil means unchecked, treat as available)
    if item.inStock == false then
        SendChatMessage(L["Item is out of stock."], "WHISPER", nil, sender)
        return
    end

    -- Extract optional gold amount from text after the item link
    -- The item link ends with "|r", find text after the last "|r"
    local afterLink = ""
    local lastR = strfind(message, "|r[^|]*$")
    if lastR then
        afterLink = strsub(message, lastR + 2)
    end

    local offeredPriceCopper = TSM:ExtractGoldAmount(afterLink)

    -- If no gold amount provided, use the item's set price (0 for free items)
    if not offeredPriceCopper then
        offeredPriceCopper = item.price or 0
    end

    -- Check for duplicate offers from same buyer for same item
    local offerList = TSM.db.profile.transmogs.offerList
    for _, existingOffer in ipairs(offerList) do
        if existingOffer.buyer == sender and existingOffer.itemName == item.name and existingOffer.status == "Offered" then
            SendChatMessage(format(L["You already have a pending offer for %s."], item.link or item.name), "WHISPER", nil, sender)
            return
        end
    end

    -- Determine if offer is under the set price
    local isUnderSetPrice = false
    if item.price and item.price > 0 then
        isUnderSetPrice = offeredPriceCopper < item.price
    end

    -- Create the offer
    local offer = {
        itemName = item.name,
        itemLink = item.link,
        buyer = sender,
        offeredPrice = offeredPriceCopper,
        setPrice = item.price,
        isUnderSetPrice = isUnderSetPrice,
        status = "Offered",
        timestamp = time(),
    }
    tinsert(offerList, offer)

    -- Send confirmation whisper to buyer
    local priceGold = math.floor(offeredPriceCopper / 10000)
    SendChatMessage(format(L["Offer received for %s at %sg. I'll get back to you!"], item.link or item.name, priceGold), "WHISPER", nil, sender)

    -- Loyalty program promo
    local loyalty = TSM.db.profile.loyalty
    if loyalty.enabled then
        local prefix = TSM.db.profile.commandPrefix or ""
        local cmdPrefix = (prefix ~= "") and (prefix .. " ") or ""
        local goldForReward = (loyalty.rewardThreshold or 10000) / (loyalty.pointsPerGold or 10)
        local discount = loyalty.rewardGoldDiscount or 100
        SendChatMessage(
            format(L["At %dg of purchase, you'll be rewarded with %dg discount with the loyalty program. Send \"%sloyalty\" to learn more."],
                goldForReward, discount, cmdPrefix),
            "WHISPER", nil, sender
        )
    end

    -- Print notification for the seller
    TSM:Print(format("New offer from %s for %s at %sg", sender, item.link or item.name, priceGold))

    -- Open the offers window (auto-show on new offer)
    if TSM.OffersWindow then
        TSM.OffersWindow:Show()
    end
end
