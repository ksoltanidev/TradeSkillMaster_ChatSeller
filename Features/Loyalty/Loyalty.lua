-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Loyalty Points System
-- Awards points to buyers on completed purchases. Players can check balance via whisper.
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")

-- Normalize player name to WoW canonical format: first letter uppercase, rest lowercase
local function NormalizeName(name)
    if not name or name == "" then return name end
    return strupper(strsub(name, 1, 1)) .. strlower(strsub(name, 2))
end

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

    buyer = NormalizeName(buyer)
    local loyalty = TSM.db.profile.loyalty
    local pointsPerGold = loyalty.pointsPerGold or 10
    local pointsAwarded = math.floor(copperAmount * pointsPerGold / 10000)

    if pointsAwarded <= 0 then
        return 0, loyalty.playerPoints[buyer] or 0
    end

    loyalty.playerPoints[buyer] = (loyalty.playerPoints[buyer] or 0) + pointsAwarded
    loyalty.playerTotalPoints[buyer] = (loyalty.playerTotalPoints[buyer] or 0) + pointsAwarded
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

        -- Referral program promo
        local prefix = TSM.db.profile.commandPrefix or ""
        local cmdPrefix = (prefix ~= "") and (prefix .. " ") or ""
        local bonusPct = loyalty.referrerBonusPct or 20
        SendChatMessage(
            format(L["Share the shop with your friends! Tell them to send me \"%sref [your name]\" and you'll receive %d%% of the points they earn!"],
                cmdPrefix, bonusPct),
            "WHISPER", nil, offer.buyer
        )
    end

    -- Award referrer bonus points
    if pointsAwarded > 0 and offer.buyer then
        local normalizedBuyer = NormalizeName(offer.buyer)
        local referrer = loyalty.playerReferrers and loyalty.playerReferrers[normalizedBuyer]
        if referrer then referrer = NormalizeName(referrer) end
        if referrer then
            local bonusPct = loyalty.referrerBonusPct or 20
            local referrerBonus = math.floor(pointsAwarded * bonusPct / 100)
            if referrerBonus > 0 then
                loyalty.playerPoints[referrer] = (loyalty.playerPoints[referrer] or 0) + referrerBonus
                loyalty.playerTotalPoints[referrer] = (loyalty.playerTotalPoints[referrer] or 0) + referrerBonus

                -- Whisper the referrer about their bonus points
                local prefix = TSM.db.profile.commandPrefix or ""
                local cmdPrefix = (prefix ~= "") and (prefix .. " ") or ""
                SendChatMessage(
                    format(L["You've been credited %d referral points from %s's purchase! Send \"%sloyalty\" to view your balance."],
                        referrerBonus, offer.buyer, cmdPrefix),
                    "WHISPER", nil, referrer
                )

                TSM:Print(format(
                    L["Referrer bonus: %s earned %d points from %s's purchase."],
                    referrer, referrerBonus, offer.buyer
                ))
            end
        end
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
    sender = NormalizeName(sender)
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

    -- Message 4: Referral program promo
    local prefix = TSM.db.profile.commandPrefix or ""
    local cmdPrefix = (prefix ~= "") and (prefix .. " ") or ""
    local bonusPct = loyalty.referrerBonusPct or 20
    SendChatMessage(
        format(L["Share the shop with your friends! Tell them to send me \"%sref [your name]\" and you'll receive %d%% of the points they earn!"],
            cmdPrefix, bonusPct),
        "WHISPER", nil, sender
    )

    -- Message 5: Rank promo
    local leaderboard = {}
    for name, total in pairs(loyalty.playerTotalPoints) do
        if total > 0 then
            tinsert(leaderboard, { name = name, total = total })
        end
    end
    table.sort(leaderboard, function(a, b)
        if a.total == b.total then
            return strlower(a.name) < strlower(b.name)
        end
        return a.total > b.total
    end)
    local senderRank = nil
    for i, entry in ipairs(leaderboard) do
        if entry.name == sender then
            senderRank = i
            break
        end
    end

    if senderRank then
        SendChatMessage(
            format(L["You are ranked %s! Send \"%srank\" to see the Top 3 buyers."],
                TSM:FormatOrdinal(senderRank), cmdPrefix),
            "WHISPER", nil, sender
        )
    else
        SendChatMessage(
            format(L["Send \"%srank\" to see the Top 3 buyers."], cmdPrefix),
            "WHISPER", nil, sender
        )
    end
end

-- ===================================================================================== --
-- Referral Command
-- ===================================================================================== --

-- Handle the "ref" whisper command: gem ref [referrerName]
-- @param sender: player name who whispered
-- @param refName: the referrer name provided
function TSM:HandleRefCommand(sender, refName)
    local loyalty = TSM.db.profile.loyalty
    local prefix = TSM.db.profile.commandPrefix or ""
    local cmdPrefix = (prefix ~= "") and (prefix .. " ") or ""

    -- Validate referrer name provided
    refName = strtrim(refName or "")
    if refName == "" then
        SendChatMessage(
            format(L["Please specify a player name: \"%sref [name]\"."], cmdPrefix),
            "WHISPER", nil, sender
        )
        return
    end

    -- Can't refer yourself
    if strlower(refName) == strlower(sender) then
        SendChatMessage(
            L["You cannot set yourself as your own referrer."],
            "WHISPER", nil, sender
        )
        return
    end

    -- Normalize names for consistent storage
    local normalizedSender = NormalizeName(sender)
    local normalizedRef = NormalizeName(refName)

    -- Set referrer (overwrites silently if already set)
    loyalty.playerReferrers[normalizedSender] = normalizedRef

    -- Whisper confirmation to the referred player
    SendChatMessage(
        format(L["%s has been set as your referrer! They will earn bonus points from your purchases."], normalizedRef),
        "WHISPER", nil, sender
    )

    -- Whisper the referrer to notify them
    local bonusPct = loyalty.referrerBonusPct or 20
    SendChatMessage(
        format(L["%s added you as their referrer! You will earn %d%% of the loyalty points they make!"],
            sender, bonusPct),
        "WHISPER", nil, normalizedRef
    )

    -- Print to seller's chat
    TSM:Print(format(L["%s set %s as their referrer."], normalizedSender, normalizedRef))
end

-- ===================================================================================== --
-- Leaderboard / Rank Command
-- ===================================================================================== --

-- Format a number as ordinal: 1st, 2nd, 3rd, 4th, etc.
function TSM:FormatOrdinal(n)
    local suffix = "th"
    local lastTwo = n % 100
    if lastTwo == 11 or lastTwo == 12 or lastTwo == 13 then
        suffix = "th"
    else
        local lastOne = n % 10
        if lastOne == 1 then suffix = "st"
        elseif lastOne == 2 then suffix = "nd"
        elseif lastOne == 3 then suffix = "rd"
        end
    end
    return tostring(n) .. suffix
end

-- Handle the "rank" whisper command: show Top 3 + sender's rank
-- @param sender: player name who whispered
function TSM:HandleRankCommand(sender)
    local loyalty = TSM.db.profile.loyalty
    sender = NormalizeName(sender)
    local senderTotal = loyalty.playerTotalPoints[sender] or 0

    -- Build leaderboard from playerTotalPoints, sorted descending
    local leaderboard = {}
    for name, total in pairs(loyalty.playerTotalPoints) do
        if total > 0 then
            tinsert(leaderboard, { name = name, total = total })
        end
    end
    table.sort(leaderboard, function(a, b)
        if a.total == b.total then
            return strlower(a.name) < strlower(b.name)
        end
        return a.total > b.total
    end)

    -- Find sender's rank
    local senderRank = nil
    for i, entry in ipairs(leaderboard) do
        if entry.name == sender then
            senderRank = i
            break
        end
    end

    -- Message 1: Sender's total and rank
    if senderRank then
        SendChatMessage(
            format(L["You have earned a total of %d points, you are %s."],
                senderTotal, TSM:FormatOrdinal(senderRank)),
            "WHISPER", nil, sender
        )
    else
        SendChatMessage(
            format(L["You have earned a total of %d points."], senderTotal),
            "WHISPER", nil, sender
        )
    end

    -- Messages 2-4: Top 3
    for rank = 1, math.min(3, #leaderboard) do
        local entry = leaderboard[rank]
        SendChatMessage(
            format(L["Top %d - %s with %d points."],
                rank, entry.name, entry.total),
            "WHISPER", nil, sender
        )
    end
end
