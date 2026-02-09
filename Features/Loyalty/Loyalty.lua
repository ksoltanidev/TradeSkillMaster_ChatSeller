-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Loyalty Points System
-- Awards points to buyers on completed purchases. Players can check balance via whisper.
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")

-- ===================================================================================== --
-- Award Loyalty Points
-- ===================================================================================== --

-- Award loyalty points to a player based on copper spent
-- @param buyer: player name string
-- @param copperAmount: price in copper
-- @return pointsAwarded, newTotal
function TSM:AwardLoyaltyPoints(buyer, copperAmount)
    if not buyer or not copperAmount or copperAmount <= 0 then
        return 0, 0
    end

    local loyalty = TSM.db.profile.loyalty
    local pointsPerGold = loyalty.pointsPerGold or 10
    local pointsAwarded = math.floor(copperAmount * pointsPerGold / 10000)

    if pointsAwarded <= 0 then
        return 0, loyalty.playerPoints[buyer] or 0
    end

    loyalty.playerPoints[buyer] = (loyalty.playerPoints[buyer] or 0) + pointsAwarded
    return pointsAwarded, loyalty.playerPoints[buyer]
end

-- ===================================================================================== --
-- Complete Offer
-- ===================================================================================== --

-- Complete an offer: mark as completed, award points, archive it
-- @param offerIndex: index in the offerList
-- @return the completed offer, or nil if invalid
function TSM:CompleteOffer(offerIndex)
    local offerList = TSM.db.profile.transmogs.offerList
    local offer = offerList[offerIndex]
    if not offer then return nil end

    local loyalty = TSM.db.profile.loyalty

    -- Mark as completed
    offer.status = "Completed"
    offer.completedTimestamp = time()

    -- Award loyalty points
    local pointsAwarded, newTotal = 0, 0
    if loyalty.enabled and offer.offeredPrice and offer.offeredPrice > 0 and offer.buyer then
        pointsAwarded, newTotal = TSM:AwardLoyaltyPoints(offer.buyer, offer.offeredPrice)
    end

    -- Whisper buyer about credited points
    if pointsAwarded > 0 and offer.buyer then
        SendChatMessage(
            format(L["You've been credited %d loyalty points! At %d points, you'll be granted a %dg discount on the item of your choice!"],
                pointsAwarded, loyalty.rewardThreshold or 10000, loyalty.rewardGoldDiscount or 100),
            "WHISPER", nil, offer.buyer
        )
    end

    -- Remove from active offer list
    tremove(offerList, offerIndex)

    -- Archive to completed offers
    local completedOffers = loyalty.completedOffers
    tinsert(completedOffers, offer)

    -- Prune if over cap (remove oldest first)
    local maxCompleted = loyalty.maxCompletedOffers or 200
    while #completedOffers > maxCompleted do
        tremove(completedOffers, 1)
    end

    -- Print summary
    local itemName = offer.itemLink or offer.itemName or "item"
    local buyer = offer.buyer or "?"
    local priceGold = math.floor((offer.offeredPrice or 0) / 10000)

    if pointsAwarded > 0 then
        TSM:Print(format(
            L["Sale completed: %s to %s for %sg. Awarded %d loyalty points (total: %d)."],
            itemName, buyer, priceGold, pointsAwarded, newTotal
        ))
    else
        TSM:Print(format(
            L["Sale completed: %s to %s for %sg."],
            itemName, buyer, priceGold
        ))
    end

    return offer
end

-- ===================================================================================== --
-- Loyalty Whisper Command
-- ===================================================================================== --

-- Handle the "loyalty" whisper command
-- @param sender: player name who whispered
function TSM:HandleLoyaltyCommand(sender)
    local loyalty = TSM.db.profile.loyalty
    local currentPoints = loyalty.playerPoints[sender] or 0
    local threshold = loyalty.rewardThreshold or 10000
    local discount = loyalty.rewardGoldDiscount or 100
    local pointsPerGold = loyalty.pointsPerGold or 10

    -- Message 1: Current balance
    SendChatMessage(
        format(L["Loyalty Points: You have %d points."], currentPoints),
        "WHISPER", nil, sender
    )

    -- Message 2: How it works
    SendChatMessage(
        format(L["You earn %d points for every gold spent."], pointsPerGold),
        "WHISPER", nil, sender
    )

    -- Message 3: Reward info
    if currentPoints >= threshold then
        SendChatMessage(
            format(L["You have reached %d points! You can claim a %dg discount on your next purchase. Just mention it when buying!"],
                threshold, discount),
            "WHISPER", nil, sender
        )
    else
        local remaining = threshold - currentPoints
        SendChatMessage(
            format(L["At %d points, you get a %dg discount on an item of your choice. You need %d more points!"],
                threshold, discount, remaining),
            "WHISPER", nil, sender
        )
    end
end
