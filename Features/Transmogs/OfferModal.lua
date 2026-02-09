-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Offer Modal
-- Add Offer modal dialog for manually creating transmog offers
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")
local OW = TSM.OffersWindow
local private = OW._private

-- ===================================================================================== --
-- Add Offer Modal
-- ===================================================================================== --

function OW:ShowAddOfferModal()
    if private.addOfferModal then
        private.addOfferModal:Show()
        private.modalItemBox:SetText("")
        private.modalBuyerBox:SetText("")
        private.modalPriceBox:SetText("")
        private.modalItemBox:SetFocus()
        return
    end

    -- Create modal frame (no backdrop so player can Shift+Click items behind it)
    local modal = CreateFrame("Frame", "TSMOffersAddModal", UIParent)
    modal:SetSize(320, 190)
    modal:SetPoint("CENTER")
    modal:SetFrameStrata("DIALOG")
    modal:SetFrameLevel(110)
    modal:EnableMouse(true)
    modal:SetMovable(true)
    modal:RegisterForDrag("LeftButton")
    modal:SetScript("OnDragStart", function(self) self:StartMoving() end)
    modal:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    TSMAPI.Design:SetFrameBackdropColor(modal)
    private.addOfferModal = modal

    -- Title
    local title = modal:CreateFontString(nil, "OVERLAY")
    title:SetFont(TSMAPI.Design:GetContentFont("normal"))
    title:SetText(L["Add Offer"])
    title:SetPoint("TOP", 0, -8)
    TSMAPI.Design:SetWidgetTextColor(title)

    -- Close X button
    local closeBtn = TSMAPI.GUI:CreateButton(modal, 18)
    closeBtn:SetPoint("TOPRIGHT", -3, -3)
    closeBtn:SetWidth(19)
    closeBtn:SetHeight(19)
    closeBtn:SetText("X")
    closeBtn:SetScript("OnClick", function()
        OW:HideAddOfferModal()
    end)

    -- Item label + EditBox
    local itemLabel = modal:CreateFontString(nil, "OVERLAY")
    itemLabel:SetFont(TSMAPI.Design:GetContentFont("small"))
    itemLabel:SetText(L["Item link (Shift+Click item)"])
    itemLabel:SetPoint("TOPLEFT", 15, -30)
    TSMAPI.Design:SetWidgetTextColor(itemLabel)

    local itemBox = CreateFrame("EditBox", "TSMOffersModalItemBox", modal, "InputBoxTemplate")
    itemBox:SetPoint("TOPLEFT", 18, -43)
    itemBox:SetPoint("TOPRIGHT", -18, -43)
    itemBox:SetHeight(22)
    itemBox:SetAutoFocus(false)
    itemBox:SetFont(TSMAPI.Design:GetContentFont("small"))
    itemBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    itemBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    private.modalItemBox = itemBox

    -- Buyer label + EditBox
    local buyerLabel = modal:CreateFontString(nil, "OVERLAY")
    buyerLabel:SetFont(TSMAPI.Design:GetContentFont("small"))
    buyerLabel:SetText(L["Buyer"])
    buyerLabel:SetPoint("TOPLEFT", 15, -70)
    TSMAPI.Design:SetWidgetTextColor(buyerLabel)

    local buyerBox = CreateFrame("EditBox", "TSMOffersModalBuyerBox", modal, "InputBoxTemplate")
    buyerBox:SetPoint("TOPLEFT", 18, -83)
    buyerBox:SetPoint("TOPRIGHT", -18, -83)
    buyerBox:SetHeight(22)
    buyerBox:SetAutoFocus(false)
    buyerBox:SetFont(TSMAPI.Design:GetContentFont("small"))
    buyerBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    buyerBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    private.modalBuyerBox = buyerBox

    -- Price label + EditBox
    local priceLabel = modal:CreateFontString(nil, "OVERLAY")
    priceLabel:SetFont(TSMAPI.Design:GetContentFont("small"))
    priceLabel:SetText(L["Price (gold)"])
    priceLabel:SetPoint("TOPLEFT", 15, -110)
    TSMAPI.Design:SetWidgetTextColor(priceLabel)

    local priceBox = CreateFrame("EditBox", "TSMOffersModalPriceBox", modal, "InputBoxTemplate")
    priceBox:SetPoint("TOPLEFT", 18, -123)
    priceBox:SetWidth(100)
    priceBox:SetHeight(22)
    priceBox:SetAutoFocus(false)
    priceBox:SetFont(TSMAPI.Design:GetContentFont("small"))
    priceBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    priceBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    private.modalPriceBox = priceBox

    -- Add button
    local addBtn = TSMAPI.GUI:CreateButton(modal, 14)
    addBtn:SetPoint("BOTTOMLEFT", 15, 10)
    addBtn:SetWidth(130)
    addBtn:SetHeight(24)
    addBtn:SetText(L["Add"])
    addBtn:SetScript("OnClick", function()
        OW:AddManualOffer()
    end)

    -- Cancel button
    local cancelBtn = TSMAPI.GUI:CreateButton(modal, 14)
    cancelBtn:SetPoint("BOTTOMRIGHT", -15, 10)
    cancelBtn:SetWidth(130)
    cancelBtn:SetHeight(24)
    cancelBtn:SetText(CANCEL or "Cancel")
    cancelBtn:SetScript("OnClick", function()
        OW:HideAddOfferModal()
    end)

    -- Hook ChatEdit_InsertLink so Shift+Click item linking works in the item editbox
    local origChatEditInsertLink = ChatEdit_InsertLink
    ChatEdit_InsertLink = function(text)
        if private.modalItemBox and private.modalItemBox:HasFocus() then
            private.modalItemBox:Insert(text)
            return true
        end
        return origChatEditInsertLink(text)
    end

    -- Escape key closes modal (via WoW's built-in UISpecialFrames mechanism)
    tinsert(UISpecialFrames, "TSMOffersAddModal")

    itemBox:SetFocus()
end

function OW:HideAddOfferModal()
    if private.addOfferModal then
        private.addOfferModal:Hide()
    end
end

-- ===================================================================================== --
-- Manual Offer Addition
-- ===================================================================================== --

function OW:AddManualOffer()
    local itemInput = private.modalItemBox and private.modalItemBox:GetText() or ""
    local buyerInput = private.modalBuyerBox and private.modalBuyerBox:GetText() or ""
    local priceInput = private.modalPriceBox and private.modalPriceBox:GetText() or ""

    -- Validate inputs
    if itemInput == "" or buyerInput == "" then
        TSM:Print(L["Please enter an item link and a buyer name."])
        return
    end

    -- Resolve item name and link
    local itemName, itemLink = GetItemInfo(itemInput)
    if not itemName then
        -- Maybe they typed a name instead of a link, use raw text
        itemName = itemInput
        itemLink = nil
    end

    -- Parse price (gold to copper, 0 if empty)
    local priceCopper = 0
    local goldAmount = tonumber(priceInput)
    if goldAmount and goldAmount > 0 then
        priceCopper = goldAmount * 10000
    end

    -- Find set price from transmog list (if item exists there)
    local setPrice = nil
    for _, item in ipairs(TSM.db.profile.transmogs.itemList) do
        if item.name == itemName then
            setPrice = item.price
            if not itemLink then
                itemLink = item.link
            end
            break
        end
    end

    -- Determine isUnderSetPrice
    local isUnderSetPrice = false
    if setPrice and setPrice > 0 then
        isUnderSetPrice = priceCopper < setPrice
    end

    -- Create the offer directly as "Accepted"
    local offer = {
        itemName = itemName,
        itemLink = itemLink,
        buyer = strtrim(buyerInput),
        offeredPrice = priceCopper,
        setPrice = setPrice,
        isUnderSetPrice = isUnderSetPrice,
        status = "Accepted",
        timestamp = time(),
    }
    tinsert(TSM.db.profile.transmogs.offerList, offer)

    TSM:Print(format(L["Manually added offer for %s from %s."], itemLink or itemName, offer.buyer))

    -- Close modal and refresh
    OW:HideAddOfferModal()
    OW:Refresh()
end
