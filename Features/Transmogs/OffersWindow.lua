-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Offers Window
-- Standalone movable frame for managing transmog buy offers
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")

-- ===================================================================================== --
-- Module Setup
-- ===================================================================================== --

TSM.OffersWindow = {}
local OW = TSM.OffersWindow

local private = {
    frame = nil,
    rows = {},
    headCols = {},
    scrollFrame = nil,
    NUM_ROWS = 8,
    ROW_HEIGHT = 28,
}

local FRAME_WIDTH = 650
local FRAME_HEIGHT = 320
local HEAD_HEIGHT = 22
local HEAD_SPACE = 2

local COL_INFO = {
    { name = L["Item"],    width = 0.25 },
    { name = L["Buyer"],   width = 0.13 },
    { name = L["Price"],   width = 0.12 },
    { name = L["Status"],  width = 0.12 },
    { name = L["Actions"], width = 0.38 },
}

-- ===================================================================================== --
-- Public API
-- ===================================================================================== --

function OW:Toggle()
    if not private.frame then
        OW:CreateFrame()
    end
    if private.frame:IsShown() then
        private.frame:Hide()
    else
        private.frame:Show()
        OW:Refresh()
    end
end

function OW:Show()
    if not private.frame then
        OW:CreateFrame()
    end
    private.frame:Show()
    OW:DrawRows()
end

function OW:Refresh()
    if not private.frame or not private.frame:IsShown() then return end
    OW:DrawRows()
end

-- ===================================================================================== --
-- Frame Creation
-- ===================================================================================== --

function OW:CreateFrame()
    local frameDefaults = {
        x = 400,
        y = 350,
        width = FRAME_WIDTH,
        height = FRAME_HEIGHT,
        scale = 1,
    }
    local frame = TSMAPI:CreateMovableFrame("TSMChatSellerOffersFrame", frameDefaults)
    frame:SetFrameStrata("HIGH")
    TSMAPI.Design:SetFrameBackdropColor(frame)
    frame:SetResizable(true)
    frame:SetMinResize(500, 220)
    frame:SetMaxResize(1000, 600)

    -- Title
    local title = TSMAPI.GUI:CreateLabel(frame)
    title:SetText(L["Tmog Offers"])
    title:SetPoint("TOPLEFT")
    title:SetPoint("TOPRIGHT")
    title:SetHeight(20)

    -- Vertical line before close button
    local line = TSMAPI.GUI:CreateVerticalLine(frame, 0)
    line:ClearAllPoints()
    line:SetPoint("TOPRIGHT", -25, -1)
    line:SetWidth(2)
    line:SetHeight(22)

    -- Close button
    local closeBtn = TSMAPI.GUI:CreateButton(frame, 18)
    closeBtn:SetPoint("TOPRIGHT", -3, -3)
    closeBtn:SetWidth(19)
    closeBtn:SetHeight(19)
    closeBtn:SetText("X")
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- Horizontal separator below title
    TSMAPI.GUI:CreateHorizontalLine(frame, -23)

    -- Content container (between title and bottom button)
    local stContainer = CreateFrame("Frame", nil, frame)
    stContainer:SetPoint("TOPLEFT", 0, -25)
    stContainer:SetPoint("BOTTOMRIGHT", 0, 30)
    TSMAPI.Design:SetFrameColor(stContainer)
    private.stContainer = stContainer

    -- Create column headers
    OW:CreateHeaders(stContainer)

    -- Create FauxScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", "TSMChatSellerOffersScrollFrame", stContainer, "FauxScrollFrameTemplate")
    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, private.ROW_HEIGHT, function() OW:DrawRows() end)
    end)
    scrollFrame:SetAllPoints(stContainer)
    private.scrollFrame = scrollFrame

    -- Style scroll bar
    local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
    scrollBar:ClearAllPoints()
    scrollBar:SetPoint("BOTTOMRIGHT", stContainer, -2, 0)
    scrollBar:SetPoint("TOPRIGHT", stContainer, -2, -HEAD_HEIGHT - 4)
    scrollBar:SetWidth(12)
    local thumbTex = scrollBar:GetThumbTexture()
    thumbTex:SetPoint("CENTER")
    TSMAPI.Design:SetFrameColor(thumbTex)
    thumbTex:SetHeight(50)
    thumbTex:SetWidth(scrollBar:GetWidth())
    _G[scrollBar:GetName() .. "ScrollUpButton"]:Hide()
    _G[scrollBar:GetName() .. "ScrollDownButton"]:Hide()

    -- Create rows
    OW:CreateRows(stContainer)

    -- Resize handle (bottom-right corner)
    local resizeHandle = CreateFrame("Frame", nil, frame)
    resizeHandle:SetSize(16, 16)
    resizeHandle:SetPoint("BOTTOMRIGHT", -1, 1)
    resizeHandle:EnableMouse(true)
    resizeHandle:SetScript("OnMouseDown", function()
        frame:StartSizing("BOTTOMRIGHT")
    end)
    resizeHandle:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        frame:SavePositionAndSize()
        OW:UpdateLayout()
    end)
    -- Resize grip texture
    local gripTex = resizeHandle:CreateTexture(nil, "OVERLAY")
    gripTex:SetAllPoints()
    gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeHandle:SetScript("OnEnter", function()
        gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    end)
    resizeHandle:SetScript("OnLeave", function()
        gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    end)

    -- Hook OnSizeChanged for live resize
    frame:SetScript("OnSizeChanged", function(self)
        self:SavePositionAndSize()
        OW:UpdateLayout()
    end)

    -- "Gather All" button at the bottom
    local gatherBtn = TSMAPI.GUI:CreateButton(frame, 14)
    gatherBtn:SetPoint("BOTTOMLEFT", 3, 3)
    gatherBtn:SetPoint("BOTTOMRIGHT", -18, 3)
    gatherBtn:SetHeight(20)
    gatherBtn:SetText(L["Gather All"])
    gatherBtn:SetScript("OnClick", function()
        TSM:Print("Gather All - coming soon")
    end)

    private.frame = frame
    frame:Hide()
end

-- ===================================================================================== --
-- Headers
-- ===================================================================================== --

function OW:CreateHeaders(parent)
    private.headCols = {}
    local contentWidth = FRAME_WIDTH - 30

    for i, info in ipairs(COL_INFO) do
        local col = CreateFrame("Button", "TSMOffersHeadCol" .. i, parent)
        col:SetHeight(HEAD_HEIGHT)
        col:SetWidth(info.width * contentWidth)
        if i == 1 then
            col:SetPoint("TOPLEFT")
        else
            col:SetPoint("TOPLEFT", private.headCols[i - 1], "TOPRIGHT")
        end

        local text = col:CreateFontString()
        text:SetFont(TSMAPI.Design:GetContentFont("small"))
        text:SetJustifyH("CENTER")
        text:SetJustifyV("CENTER")
        text:SetAllPoints()
        TSMAPI.Design:SetWidgetTextColor(text)
        col:SetFontString(text)
        col:SetText(info.name or "")

        local tex = col:CreateTexture()
        tex:SetAllPoints()
        tex:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScore-Highlight")
        tex:SetTexCoord(0.017, 1, 0.083, 0.909)
        tex:SetAlpha(0.5)
        col:SetNormalTexture(tex)

        tinsert(private.headCols, col)
    end

    TSMAPI.GUI:CreateHorizontalLine(parent, -HEAD_HEIGHT)
end

-- ===================================================================================== --
-- Row Creation
-- ===================================================================================== --

function OW:CreateRows(parent)
    private.rows = {}
    local contentWidth = FRAME_WIDTH - 30

    for i = 1, private.NUM_ROWS do
        local row = CreateFrame("Frame", "TSMOffersRow" .. i, parent)
        row:SetHeight(private.ROW_HEIGHT)
        if i == 1 then
            row:SetPoint("TOPLEFT", 0, -(HEAD_HEIGHT + HEAD_SPACE))
            row:SetPoint("TOPRIGHT", -15, -(HEAD_HEIGHT + HEAD_SPACE))
        else
            row:SetPoint("TOPLEFT", private.rows[i - 1], "BOTTOMLEFT")
            row:SetPoint("TOPRIGHT", private.rows[i - 1], "BOTTOMRIGHT")
        end

        -- Highlight
        local highlight = row:CreateTexture()
        highlight:SetAllPoints()
        highlight:SetTexture(1, 0.9, 0, 0.3)
        highlight:Hide()
        row.highlight = highlight

        -- Alternating background
        if i % 2 == 0 then
            local bgTex = row:CreateTexture(nil, "BACKGROUND")
            bgTex:SetAllPoints()
            bgTex:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScore-Highlight")
            bgTex:SetTexCoord(0.017, 1, 0.083, 0.909)
            bgTex:SetAlpha(0.3)
        end

        -- Col 1: Item (Button with FontString + tooltip)
        local itemBtn = CreateFrame("Button", nil, row)
        itemBtn:SetPoint("TOPLEFT")
        itemBtn:SetWidth(COL_INFO[1].width * contentWidth)
        itemBtn:SetHeight(private.ROW_HEIGHT)
        local itemText = itemBtn:CreateFontString()
        itemText:SetFont(TSMAPI.Design:GetContentFont("small"))
        itemText:SetJustifyH("LEFT")
        itemText:SetJustifyV("CENTER")
        itemText:SetPoint("TOPLEFT", 2, -1)
        itemText:SetPoint("BOTTOMRIGHT", -2, 1)
        itemBtn:SetFontString(itemText)
        itemBtn:SetScript("OnEnter", function(self)
            row.highlight:Show()
            if self.link then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                TSMAPI:SafeTooltipLink(self.link)
                GameTooltip:Show()
            end
        end)
        itemBtn:SetScript("OnLeave", function()
            row.highlight:Hide()
            GameTooltip:ClearLines()
            GameTooltip:Hide()
        end)
        row.itemBtn = itemBtn

        -- Col 2: Buyer (FontString)
        local buyerText = row:CreateFontString(nil, "OVERLAY")
        buyerText:SetFont(TSMAPI.Design:GetContentFont("small"))
        buyerText:SetJustifyH("LEFT")
        buyerText:SetJustifyV("CENTER")
        buyerText:SetPoint("TOPLEFT", itemBtn, "TOPRIGHT", 2, 0)
        buyerText:SetWidth(COL_INFO[2].width * contentWidth)
        buyerText:SetHeight(private.ROW_HEIGHT)
        TSMAPI.Design:SetWidgetTextColor(buyerText)
        row.buyerText = buyerText

        -- Col 3: Price (EditBox)
        local priceBox = CreateFrame("EditBox", "TSMOffersPriceBox" .. i, row, "InputBoxTemplate")
        priceBox:SetPoint("TOPLEFT", buyerText, "TOPRIGHT", 2, -4)
        priceBox:SetWidth(COL_INFO[3].width * contentWidth - 8)
        priceBox:SetHeight(private.ROW_HEIGHT - 8)
        priceBox:SetAutoFocus(false)
        priceBox:SetFont(TSMAPI.Design:GetContentFont("small"))
        priceBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        priceBox:SetScript("OnEnterPressed", function(self)
            local offerIndex = self:GetParent().offerIndex
            if offerIndex then
                local goldAmount = tonumber(self:GetText())
                if goldAmount and goldAmount > 0 then
                    local offer = TSM.db.profile.transmogs.offerList[offerIndex]
                    if offer then
                        offer.offeredPrice = goldAmount * 10000
                        offer.isUnderSetPrice = offer.setPrice and (offer.offeredPrice < offer.setPrice) or false
                        OW:Refresh()
                    end
                end
            end
            self:ClearFocus()
        end)
        row.priceBox = priceBox

        -- Col 4: Status (FontString)
        local statusText = row:CreateFontString(nil, "OVERLAY")
        statusText:SetFont(TSMAPI.Design:GetContentFont("small"))
        statusText:SetJustifyH("CENTER")
        statusText:SetJustifyV("CENTER")
        statusText:SetPoint("TOPLEFT", priceBox, "TOPRIGHT", 6, 4)
        statusText:SetWidth(COL_INFO[4].width * contentWidth)
        statusText:SetHeight(private.ROW_HEIGHT)
        row.statusText = statusText

        -- Col 5: Actions (container with buttons)
        local actionsFrame = CreateFrame("Frame", nil, row)
        actionsFrame:SetPoint("TOPLEFT", statusText, "TOPRIGHT", 2, 0)
        actionsFrame:SetWidth(COL_INFO[5].width * contentWidth)
        actionsFrame:SetHeight(private.ROW_HEIGHT)

        -- "Offered" state buttons: Accept + Refuse
        local acceptBtn = CreateFrame("Button", nil, actionsFrame, "UIPanelButtonTemplate")
        acceptBtn:SetSize(55, private.ROW_HEIGHT - 6)
        acceptBtn:SetPoint("LEFT", 2, 0)
        acceptBtn:SetText(L["Accept"])
        acceptBtn:SetNormalFontObject(GameFontNormalSmall)
        acceptBtn:SetHighlightFontObject(GameFontHighlightSmall)
        row.acceptBtn = acceptBtn

        local refuseBtn = CreateFrame("Button", nil, actionsFrame, "UIPanelButtonTemplate")
        refuseBtn:SetSize(55, private.ROW_HEIGHT - 6)
        refuseBtn:SetPoint("LEFT", acceptBtn, "RIGHT", 4, 0)
        refuseBtn:SetText(L["Refuse"])
        refuseBtn:SetNormalFontObject(GameFontNormalSmall)
        refuseBtn:SetHighlightFontObject(GameFontHighlightSmall)
        row.refuseBtn = refuseBtn

        -- "Accepted" state buttons: Ask How + CoD + Trade
        local askHowBtn = CreateFrame("Button", nil, actionsFrame, "UIPanelButtonTemplate")
        askHowBtn:SetSize(60, private.ROW_HEIGHT - 6)
        askHowBtn:SetPoint("LEFT", 2, 0)
        askHowBtn:SetText(L["Ask How"])
        askHowBtn:SetNormalFontObject(GameFontNormalSmall)
        askHowBtn:SetHighlightFontObject(GameFontHighlightSmall)
        row.askHowBtn = askHowBtn

        local codBtn = CreateFrame("Button", nil, actionsFrame, "UIPanelButtonTemplate")
        codBtn:SetSize(45, private.ROW_HEIGHT - 6)
        codBtn:SetPoint("LEFT", askHowBtn, "RIGHT", 4, 0)
        codBtn:SetText(L["CoD"])
        codBtn:SetNormalFontObject(GameFontNormalSmall)
        codBtn:SetHighlightFontObject(GameFontHighlightSmall)
        row.codBtn = codBtn

        local tradeBtn = CreateFrame("Button", nil, actionsFrame, "UIPanelButtonTemplate")
        tradeBtn:SetSize(45, private.ROW_HEIGHT - 6)
        tradeBtn:SetPoint("LEFT", codBtn, "RIGHT", 4, 0)
        tradeBtn:SetText(L["Trade"])
        tradeBtn:SetNormalFontObject(GameFontNormalSmall)
        tradeBtn:SetHighlightFontObject(GameFontHighlightSmall)
        row.tradeBtn = tradeBtn

        -- Initially hide all action buttons
        acceptBtn:Hide()
        refuseBtn:Hide()
        askHowBtn:Hide()
        codBtn:Hide()
        tradeBtn:Hide()

        row.actionsFrame = actionsFrame
        row:Hide()
        tinsert(private.rows, row)
    end
end

-- ===================================================================================== --
-- Dynamic Layout Update (on resize)
-- ===================================================================================== --

function OW:UpdateLayout()
    if not private.frame then return end
    local contentWidth = private.frame:GetWidth() - 30

    -- Update header columns
    for i, col in ipairs(private.headCols) do
        col:SetWidth(COL_INFO[i].width * contentWidth)
    end

    -- Update row widgets
    for _, row in ipairs(private.rows) do
        row.itemBtn:SetWidth(COL_INFO[1].width * contentWidth)
        row.buyerText:SetWidth(COL_INFO[2].width * contentWidth)
        row.priceBox:SetWidth(COL_INFO[3].width * contentWidth - 8)
        row.statusText:SetWidth(COL_INFO[4].width * contentWidth)
        row.actionsFrame:SetWidth(COL_INFO[5].width * contentWidth)
    end

    OW:DrawRows()
end

-- ===================================================================================== --
-- Row Drawing
-- ===================================================================================== --

function OW:DrawRows()
    local offerList = TSM.db.profile.transmogs.offerList
    if not offerList then return end

    FauxScrollFrame_Update(private.scrollFrame, #offerList, private.NUM_ROWS, private.ROW_HEIGHT)
    local offset = FauxScrollFrame_GetOffset(private.scrollFrame)

    for i = 1, private.NUM_ROWS do
        local row = private.rows[i]
        local dataIndex = i + offset
        local offer = offerList[dataIndex]

        if offer then
            row:Show()
            row.offerIndex = dataIndex

            -- Item column
            row.itemBtn:SetText(offer.itemLink or offer.itemName or "Unknown")
            row.itemBtn.link = offer.itemLink

            -- Buyer column
            row.buyerText:SetText(offer.buyer or "")

            -- Price column (display in gold)
            local priceGold = offer.offeredPrice and math.floor(offer.offeredPrice / 10000) or 0
            row.priceBox:SetText(tostring(priceGold))

            -- Color the price red if under set price
            if offer.isUnderSetPrice then
                row.priceBox:SetTextColor(1, 0.3, 0.3)
            else
                row.priceBox:SetTextColor(1, 1, 1)
            end

            -- Status column with color coding
            local status = offer.status or "Offered"
            row.statusText:SetText(status)
            if status == "Offered" then
                row.statusText:SetTextColor(1, 0.82, 0)     -- Gold
            elseif status == "Accepted" then
                row.statusText:SetTextColor(0, 1, 0)        -- Green
            elseif status == "CoD Sent" then
                row.statusText:SetTextColor(0.5, 0.5, 1)    -- Blue
            end

            -- Show/hide action buttons based on status
            OW:SetupActionButtons(row, offer, dataIndex)
        else
            row:Hide()
            row.offerIndex = nil
        end
    end
end

-- ===================================================================================== --
-- Action Buttons
-- ===================================================================================== --

function OW:SetupActionButtons(row, offer, offerIndex)
    local status = offer.status or "Offered"

    -- Hide all first
    row.acceptBtn:Hide()
    row.refuseBtn:Hide()
    row.askHowBtn:Hide()
    row.codBtn:Hide()
    row.tradeBtn:Hide()

    if status == "Offered" then
        row.acceptBtn:Show()
        row.refuseBtn:Show()

        row.acceptBtn:SetScript("OnClick", function()
            OW:AcceptOffer(offerIndex)
        end)
        row.refuseBtn:SetScript("OnClick", function()
            OW:RefuseOffer(offerIndex)
        end)

    elseif status == "Accepted" or status == "CoD Sent" then
        row.askHowBtn:Show()
        row.codBtn:Show()
        row.tradeBtn:Show()

        row.askHowBtn:SetScript("OnClick", function()
            OW:AskHow(offerIndex)
        end)
        row.codBtn:SetScript("OnClick", function()
            OW:SendCoD(offerIndex)
        end)
        row.tradeBtn:SetScript("OnClick", function()
            OW:InitiateTrade(offerIndex)
        end)
    end
end

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

function OW:InitiateTrade(offerIndex)
    TSM:Print("Trade functionality coming soon.")
end
