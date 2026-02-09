-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Offer Actions
-- Accept, Refuse, Cancel, Confirm, AskHow, SendCoD actions for transmog offers
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")
local OW = TSM.OffersWindow
local private = OW._private

-- ===================================================================================== --
-- Offer Actions
-- ===================================================================================== --

function OW:AcceptOffer(offerIndex)
    local offer = TSM.db.profile.transmogs.offerList[offerIndex]
    if not offer then return end

    offer.status = "Accepted"

    -- Send acceptance whisper to buyer
    local priceGold = math.floor(offer.offeredPrice / 10000)
    local itemName = offer.itemLink or offer.itemName or "item"
    SendChatMessage(format(L["I accept your offer for %s at %sg. Trade or CoD?"], itemName, priceGold), "WHISPER", nil, offer.buyer)

    OW:Refresh()
end

function OW:RefuseOffer(offerIndex)
    tremove(TSM.db.profile.transmogs.offerList, offerIndex)
    OW:Refresh()
end

function OW:CancelOffer(offerIndex)
    tremove(TSM.db.profile.transmogs.offerList, offerIndex)
    OW:Refresh()
end

function OW:ConfirmOffer(offerIndex)
    TSM:CompleteOffer(offerIndex)
    OW:Refresh()
end

function OW:AskHow(offerIndex)
    local offer = TSM.db.profile.transmogs.offerList[offerIndex]
    if not offer then return end

    local itemName = offer.itemLink or offer.itemName or "item"
    SendChatMessage(format(L["How would you like to receive %s? Trade or CoD?"], itemName), "WHISPER", nil, offer.buyer)
end

function OW:SendCoD(offerIndex)
    local offer = TSM.db.profile.transmogs.offerList[offerIndex]
    if not offer then return end

    -- Check mailbox is open
    if not MailFrame or not MailFrame:IsVisible() then
        TSM:Print(L["Mailbox must be open to send CoD."])
        return
    end

    -- Find the item in bags by name
    local foundBag, foundSlot
    for bag, slot, itemString, quantity, locked in TSMAPI:GetBagIterator() do
        if not locked then
            local link = GetContainerItemLink(bag, slot)
            if link then
                local name = GetItemInfo(link)
                if name and name == offer.itemName then
                    foundBag = bag
                    foundSlot = slot
                    break
                end
            end
        end
    end

    if not foundBag then
        TSM:Print(L["Item not found in your bags."])
        return
    end

    -- Store pending CoD info for the success callback
    private.pendingCoD = offerIndex

    -- Register for mail send success (one-shot)
    if not private.codEventFrame then
        private.codEventFrame = CreateFrame("Frame")
    end
    private.codEventFrame:RegisterEvent("MAIL_SEND_SUCCESS")
    private.codEventFrame:RegisterEvent("MAIL_FAILED")
    private.codEventFrame:SetScript("OnEvent", function(self, event)
        self:UnregisterEvent("MAIL_SEND_SUCCESS")
        self:UnregisterEvent("MAIL_FAILED")
        if event == "MAIL_SEND_SUCCESS" and private.pendingCoD then
            local idx = private.pendingCoD
            local pendingOffer = TSM.db.profile.transmogs.offerList[idx]
            if pendingOffer then
                pendingOffer.status = "CoD Sent"
                local itemName = pendingOffer.itemLink or pendingOffer.itemName or "item"
                TSM:Print(format(L["CoD sent for %s to %s."], itemName, pendingOffer.buyer))
            end
            private.pendingCoD = nil
            OW:Refresh()
        elseif event == "MAIL_FAILED" then
            TSM:Print("CoD mail failed to send.")
            private.pendingCoD = nil
        end
    end)

    -- Attach item to mail
    PickupContainerItem(foundBag, foundSlot)
    ClickSendMailItemButton()

    -- Set recipient and CoD amount
    SendMailNameEditBox:SetText(offer.buyer)
    SetSendMailCOD(offer.offeredPrice)
    SetSendMailMoney(0)

    -- Send the mail
    SendMail(offer.buyer, offer.itemName or "CoD", "")
end
