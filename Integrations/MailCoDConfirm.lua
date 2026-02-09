-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Mail CoD Auto-Confirm
-- Automatically confirms offers when CoD return mail is collected.
--
-- Approach: listen to MAIL_INBOX_UPDATE events instead of hooking AutoLootMailItem
-- (which is unreliable due to RawHook chains from TSM_Accounting and TSM_CRM).
--
-- Algorithm:
--   1. On MAIL_SHOW / MAIL_INBOX_UPDATE: scan inbox for money-only mails
--      that match a "CoD Sent" offer (sender=buyer, subject=itemName, money=price).
--   2. Store each match key in a "detected" set.
--   3. On subsequent MAIL_INBOX_UPDATE: if a previously-detected key is no longer
--      in the inbox, the mail was collected → auto-confirm the offer.
--   4. On MAIL_CLOSED: clear the detected set.
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")

-- State: match keys we've seen in the inbox during this mailbox session
-- key format: "buyerLower:itemName:copperAmount"
local detectedCoDReturns = {}

-- ===================================================================================== --
-- Helpers
-- ===================================================================================== --

local function MakeMatchKey(buyer, itemName, copper)
    return strlower(buyer) .. ":" .. itemName .. ":" .. copper
end

-- Scan the inbox and return a set of match keys for money-only mails
-- that correspond to a "CoD Sent" offer.
local function GetCurrentInboxMatches()
    local offerList = TSM.db and TSM.db.profile and TSM.db.profile.transmogs and TSM.db.profile.transmogs.offerList
    if not offerList then return {} end

    -- Build a lookup of "CoD Sent" offers for fast matching
    local codSentOffers = {}
    for i, offer in ipairs(offerList) do
        if offer.status == "CoD Sent" and offer.buyer and offer.itemName and offer.offeredPrice then
            local key = MakeMatchKey(offer.buyer, offer.itemName, offer.offeredPrice)
            if not codSentOffers[key] then
                codSentOffers[key] = i
            end
        end
    end

    if not next(codSentOffers) then return {} end

    -- Scan inbox mails
    local found = {}
    local numMail = GetInboxNumItems()
    for i = 1, numMail do
        local _, _, sender, subject, money, cod, _, hasItem = GetInboxHeaderInfo(i)
        -- CoD return mail: has money, no items, no CoD charge
        if money and money > 0
            and (not hasItem or hasItem == 0)
            and (not cod or cod <= 0)
            and sender and subject then
            -- CoD return mail subject format: "COD Payment: <itemName> (<qty>) TSM"
            local mailItemName = strmatch(subject, "^COD Payment: (.+) %(%d+%) TSM$")
            if not mailItemName then
                mailItemName = subject  -- fallback: exact subject
            end

            local key = MakeMatchKey(sender, mailItemName, money)
            if codSentOffers[key] then
                found[key] = true
            end
        end
    end

    return found
end

-- ===================================================================================== --
-- Core scan logic
-- ===================================================================================== --

local function ScanInboxForCoDReturns()
    local offerList = TSM.db and TSM.db.profile and TSM.db.profile.transmogs and TSM.db.profile.transmogs.offerList
    if not offerList then return end

    local currentMatches = GetCurrentInboxMatches()

    -- Check: any previously-detected match that is now GONE → mail was collected
    local needRefresh = false
    for key, _ in pairs(detectedCoDReturns) do
        if not currentMatches[key] then
            -- This mail was collected! Find and confirm the matching offer.
            for i, offer in ipairs(offerList) do
                if offer.status == "CoD Sent" and offer.buyer and offer.itemName and offer.offeredPrice then
                    local offerKey = MakeMatchKey(offer.buyer, offer.itemName, offer.offeredPrice)
                    if offerKey == key then
                        local itemName = offer.itemLink or offer.itemName or "item"
                        local buyer = offer.buyer or "?"
                        local priceGold = math.floor((offer.offeredPrice or 0) / 10000)

                        tremove(offerList, i)
                        TSM:Print(format(L["Auto-confirmed sale: %s to %s for %sg."], itemName, buyer, priceGold))
                        needRefresh = true
                        break
                    end
                end
            end
            detectedCoDReturns[key] = nil
        end
    end

    -- Update detected set with current matches
    for key, _ in pairs(currentMatches) do
        detectedCoDReturns[key] = true
    end

    if needRefresh and TSM.OffersWindow then
        TSM.OffersWindow:Refresh()
    end
end

-- ===================================================================================== --
-- Event listener
-- ===================================================================================== --

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("MAIL_SHOW")
eventFrame:RegisterEvent("MAIL_INBOX_UPDATE")
eventFrame:RegisterEvent("MAIL_CLOSED")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "MAIL_CLOSED" then
        wipe(detectedCoDReturns)
        return
    end
    ScanInboxForCoDReturns()
end)
