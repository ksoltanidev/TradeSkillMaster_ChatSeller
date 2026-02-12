-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Loyalty Points Manager Window
-- Standalone movable frame for viewing and editing player loyalty points
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")

-- ===================================================================================== --
-- Module Setup
-- ===================================================================================== --

TSM.LoyaltyWindow = {}
local LW = TSM.LoyaltyWindow

local private = {
    frame = nil,
    rows = {},
    headCols = {},
    scrollFrame = nil,
    searchBox = nil,
    stContainer = nil,
    addModal = nil,
    modalNameBox = nil,
    modalPointsBox = nil,
    NUM_ROWS = 10,
    ROW_HEIGHT = 24,
    searchFilter = "",
    sortedPlayers = {},
}

local FRAME_WIDTH = 520
local FRAME_HEIGHT = 350
local HEAD_HEIGHT = 22
local HEAD_SPACE = 2

local COL_INFO = {
    { name = L["Player"],     width = 0.26 },
    { name = L["Points"],     width = 0.18 },
    { name = L["Total Pts"],  width = 0.18 },
    { name = L["Referrer"],   width = 0.26 },
}

-- ===================================================================================== --
-- Public API
-- ===================================================================================== --

function LW:Toggle()
    if not private.frame then
        LW:CreateFrame()
    end
    if private.frame:IsShown() then
        private.frame:Hide()
    else
        private.frame:Show()
        LW:Refresh()
    end
end

function LW:Show()
    if not private.frame then
        LW:CreateFrame()
    end
    private.frame:Show()
    LW:Refresh()
end

function LW:Refresh()
    if not private.frame or not private.frame:IsShown() then return end
    LW:BuildSortedPlayers()
    LW:DrawRows()
end

-- ===================================================================================== --
-- Data Helpers
-- ===================================================================================== --

function LW:BuildSortedPlayers()
    local players = TSM.db.profile.players
    local filter = strlower(strtrim(private.searchFilter or ""))

    wipe(private.sortedPlayers)

    for name, data in pairs(players) do
        if filter == "" or strfind(strlower(name), filter, 1, true) then
            tinsert(private.sortedPlayers, {
                name = name,
                points = data.points or 0,
                totalPoints = data.totalPoints or 0,
                referrer = data.referrer or "",
            })
        end
    end

    -- Sort alphabetically by name
    table.sort(private.sortedPlayers, function(a, b)
        return strlower(a.name) < strlower(b.name)
    end)
end

-- ===================================================================================== --
-- Frame Creation
-- ===================================================================================== --

function LW:CreateFrame()
    local frameDefaults = {
        x = 500,
        y = 300,
        width = FRAME_WIDTH,
        height = FRAME_HEIGHT,
        scale = 1,
    }
    local frame = TSMAPI:CreateMovableFrame("TSMChatSellerLoyaltyFrame", frameDefaults)
    frame:SetFrameStrata("HIGH")
    TSMAPI.Design:SetFrameBackdropColor(frame)
    frame:SetResizable(true)
    frame:SetMinResize(440, 220)
    frame:SetMaxResize(800, 600)

    -- Title
    local title = TSMAPI.GUI:CreateLabel(frame)
    title:SetText(L["Clients"])
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

    -- Add button (top-left, below title)
    local addBtn = TSMAPI.GUI:CreateButton(frame, 14)
    addBtn:SetPoint("TOPLEFT", 3, -26)
    addBtn:SetWidth(60)
    addBtn:SetHeight(20)
    addBtn:SetText(L["Add"])
    addBtn:SetScript("OnClick", function()
        LW:ShowAddPlayerModal()
    end)

    -- Search bar (to right of Add button)
    local searchBox = CreateFrame("EditBox", "TSMLoyaltySearchBox", frame, "InputBoxTemplate")
    searchBox:SetPoint("TOPLEFT", addBtn, "TOPRIGHT", 6, 0)
    searchBox:SetPoint("TOPRIGHT", -6, -26)
    searchBox:SetHeight(20)
    searchBox:SetAutoFocus(false)
    searchBox:SetFont(TSMAPI.Design:GetContentFont("small"))
    searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    searchBox:SetScript("OnTextChanged", function(self)
        private.searchFilter = self:GetText() or ""
        LW:Refresh()
    end)

    -- Placeholder text for search box
    local placeholder = searchBox:CreateFontString(nil, "ARTWORK")
    placeholder:SetFont(TSMAPI.Design:GetContentFont("small"))
    placeholder:SetText(L["Search by player name..."])
    placeholder:SetTextColor(0.5, 0.5, 0.5)
    placeholder:SetPoint("LEFT", 5, 0)
    searchBox.placeholder = placeholder
    searchBox:SetScript("OnEditFocusGained", function(self)
        self.placeholder:Hide()
    end)
    searchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            self.placeholder:Show()
        end
    end)
    -- Also handle placeholder visibility on text change
    searchBox:HookScript("OnTextChanged", function(self)
        if self:GetText() ~= "" then
            self.placeholder:Hide()
        elseif not self:HasFocus() then
            self.placeholder:Show()
        end
    end)
    private.searchBox = searchBox

    -- Horizontal separator below search bar
    TSMAPI.GUI:CreateHorizontalLine(frame, -48)

    -- Content container (between search bar and bottom)
    local stContainer = CreateFrame("Frame", nil, frame)
    stContainer:SetPoint("TOPLEFT", 0, -50)
    stContainer:SetPoint("BOTTOMRIGHT", 0, 5)
    TSMAPI.Design:SetFrameColor(stContainer)
    private.stContainer = stContainer

    -- Create column headers
    LW:CreateHeaders(stContainer)

    -- Create FauxScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", "TSMChatSellerLoyaltyScrollFrame", stContainer, "FauxScrollFrameTemplate")
    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, private.ROW_HEIGHT, function() LW:DrawRows() end)
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
    TSMAPI.Design:SetContentColor(thumbTex)
    thumbTex:SetHeight(50)
    thumbTex:SetWidth(scrollBar:GetWidth())
    _G[scrollBar:GetName() .. "ScrollUpButton"]:Hide()
    _G[scrollBar:GetName() .. "ScrollDownButton"]:Hide()

    -- Create rows
    LW:CreateRows(stContainer)

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
        LW:UpdateLayout()
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
        LW:UpdateLayout()
    end)

    private.frame = frame
    frame:Hide()
end

-- ===================================================================================== --
-- Headers
-- ===================================================================================== --

function LW:CreateHeaders(parent)
    private.headCols = {}
    local contentWidth = FRAME_WIDTH - 30

    for i, info in ipairs(COL_INFO) do
        local col = CreateFrame("Button", "TSMLoyaltyHeadCol" .. i, parent)
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

function LW:CreateSingleRow(parent, index, contentWidth)
    local row = CreateFrame("Frame", "TSMLoyaltyRow" .. index, parent)
    row:SetHeight(private.ROW_HEIGHT)
    if index == 1 then
        row:SetPoint("TOPLEFT", 0, -(HEAD_HEIGHT + HEAD_SPACE))
        row:SetPoint("TOPRIGHT", -15, -(HEAD_HEIGHT + HEAD_SPACE))
    else
        row:SetPoint("TOPLEFT", private.rows[index - 1], "BOTTOMLEFT")
        row:SetPoint("TOPRIGHT", private.rows[index - 1], "BOTTOMRIGHT")
    end

    -- Highlight
    local highlight = row:CreateTexture()
    highlight:SetAllPoints()
    highlight:SetTexture(1, 0.9, 0, 0.3)
    highlight:Hide()
    row.highlight = highlight

    -- Alternating background
    if index % 2 == 0 then
        local bgTex = row:CreateTexture(nil, "BACKGROUND")
        bgTex:SetAllPoints()
        bgTex:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScore-Highlight")
        bgTex:SetTexCoord(0.017, 1, 0.083, 0.909)
        bgTex:SetAlpha(0.3)
    end

    -- Hover highlight
    row:EnableMouse(true)
    row:SetScript("OnEnter", function() row.highlight:Show() end)
    row:SetScript("OnLeave", function() row.highlight:Hide() end)

    -- Col 1: Player Name (FontString)
    local nameText = row:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(TSMAPI.Design:GetContentFont("small"))
    nameText:SetJustifyH("LEFT")
    nameText:SetJustifyV("CENTER")
    nameText:SetPoint("TOPLEFT", 6, 0)
    nameText:SetWidth(COL_INFO[1].width * contentWidth - 6)
    nameText:SetHeight(private.ROW_HEIGHT)
    TSMAPI.Design:SetWidgetTextColor(nameText)
    row.nameText = nameText

    -- Col 2: Points (EditBox)
    local pointsBox = CreateFrame("EditBox", "TSMLoyaltyPointsBox" .. index, row, "InputBoxTemplate")
    pointsBox:SetPoint("TOPLEFT", nameText, "TOPRIGHT", 2, -3)
    pointsBox:SetWidth(COL_INFO[2].width * contentWidth - 6)
    pointsBox:SetHeight(private.ROW_HEIGHT - 6)
    pointsBox:SetAutoFocus(false)
    pointsBox:SetFont(TSMAPI.Design:GetContentFont("small"))
    pointsBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    pointsBox:SetScript("OnEnterPressed", function(self)
        local playerName = self:GetParent().playerName
        if playerName then
            local newPoints = tonumber(self:GetText())
            if newPoints and newPoints >= 0 then
                newPoints = math.floor(newPoints)
                local pd = TSM:GetPlayerData(playerName)
                pd.points = newPoints
                TSM:Print(format(L["Updated %s to %d loyalty points."], playerName, newPoints))
                LW:Refresh()
            end
        end
        self:ClearFocus()
    end)
    row.pointsBox = pointsBox

    -- Col 3: Total Points (EditBox)
    local totalPointsBox = CreateFrame("EditBox", "TSMLoyaltyTotalPtsBox" .. index, row, "InputBoxTemplate")
    totalPointsBox:SetPoint("TOPLEFT", pointsBox, "TOPRIGHT", 2, 0)
    totalPointsBox:SetWidth(COL_INFO[3].width * contentWidth - 6)
    totalPointsBox:SetHeight(private.ROW_HEIGHT - 6)
    totalPointsBox:SetAutoFocus(false)
    totalPointsBox:SetFont(TSMAPI.Design:GetContentFont("small"))
    totalPointsBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    totalPointsBox:SetScript("OnEnterPressed", function(self)
        local playerName = self:GetParent().playerName
        if playerName then
            local newTotal = tonumber(self:GetText())
            if newTotal and newTotal >= 0 then
                newTotal = math.floor(newTotal)
                local pd = TSM:GetPlayerData(playerName)
                pd.totalPoints = newTotal
                TSM:Print(format(L["Updated %s to %d total loyalty points."], playerName, newTotal))
                LW:Refresh()
            end
        end
        self:ClearFocus()
    end)
    row.totalPointsBox = totalPointsBox

    -- Col 4: Referrer (FontString, read-only)
    local referrerText = row:CreateFontString(nil, "OVERLAY")
    referrerText:SetFont(TSMAPI.Design:GetContentFont("small"))
    referrerText:SetJustifyH("LEFT")
    referrerText:SetJustifyV("CENTER")
    referrerText:SetPoint("TOPLEFT", totalPointsBox, "TOPRIGHT", 6, 3)
    referrerText:SetWidth(COL_INFO[4].width * contentWidth - 6)
    referrerText:SetHeight(private.ROW_HEIGHT)
    TSMAPI.Design:SetWidgetTextColor(referrerText)
    row.referrerText = referrerText

    -- Remove button (X) - rightmost position
    local removeBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    removeBtn:SetSize(22, private.ROW_HEIGHT - 6)
    removeBtn:SetPoint("TOPRIGHT", row, "TOPRIGHT", -2, -3)
    removeBtn:SetText("X")
    removeBtn:SetNormalFontObject(GameFontNormalSmall)
    removeBtn:SetHighlightFontObject(GameFontHighlightSmall)
    row.removeBtn = removeBtn

    row:Hide()
    return row
end

function LW:CreateRows(parent)
    private.rows = {}
    local contentWidth = FRAME_WIDTH - 30

    for i = 1, private.NUM_ROWS do
        local row = LW:CreateSingleRow(parent, i, contentWidth)
        tinsert(private.rows, row)
    end
end

-- ===================================================================================== --
-- Dynamic Layout Update (on resize)
-- ===================================================================================== --

function LW:UpdateLayout()
    if not private.frame then return end
    local contentWidth = private.frame:GetWidth() - 30

    -- Update header columns
    for i, col in ipairs(private.headCols) do
        col:SetWidth(COL_INFO[i].width * contentWidth)
    end

    -- Calculate how many rows fit in the available height
    local containerHeight = private.stContainer:GetHeight()
    local availableHeight = containerHeight - HEAD_HEIGHT - HEAD_SPACE
    local newNumRows = math.floor(availableHeight / private.ROW_HEIGHT)
    if newNumRows < 1 then newNumRows = 1 end

    -- Create additional rows if needed
    if newNumRows > #private.rows then
        for i = #private.rows + 1, newNumRows do
            local row = LW:CreateSingleRow(private.stContainer, i, contentWidth)
            tinsert(private.rows, row)
        end
    end

    private.NUM_ROWS = newNumRows

    -- Update all row widget widths
    for _, row in ipairs(private.rows) do
        row.nameText:SetWidth(COL_INFO[1].width * contentWidth - 6)
        row.pointsBox:SetWidth(COL_INFO[2].width * contentWidth - 6)
        row.totalPointsBox:SetWidth(COL_INFO[3].width * contentWidth - 6)
        row.referrerText:SetWidth(COL_INFO[4].width * contentWidth - 6)
    end

    LW:DrawRows()
end

-- ===================================================================================== --
-- Row Drawing
-- ===================================================================================== --

function LW:DrawRows()
    local data = private.sortedPlayers
    if not data then return end

    FauxScrollFrame_Update(private.scrollFrame, #data, private.NUM_ROWS, private.ROW_HEIGHT)
    local offset = FauxScrollFrame_GetOffset(private.scrollFrame)

    for i = 1, #private.rows do
        local row = private.rows[i]

        -- Hide rows beyond current NUM_ROWS (window was resized smaller)
        if i > private.NUM_ROWS then
            row:Hide()
            row.playerName = nil
        else
            local dataIndex = i + offset
            local entry = data[dataIndex]

            if entry then
                row:Show()
                row.playerName = entry.name

                -- Player name column
                row.nameText:SetText(entry.name)

                -- Points column
                row.pointsBox:SetText(tostring(entry.points))
                row.pointsBox:SetTextColor(1, 1, 1)

                -- Total Points column
                row.totalPointsBox:SetText(tostring(entry.totalPoints or 0))
                row.totalPointsBox:SetTextColor(1, 1, 1)

                -- Referrer column
                row.referrerText:SetText(entry.referrer or "")

                -- Remove button callback
                row.removeBtn:SetScript("OnClick", function()
                    TSM.db.profile.players[entry.name] = nil
                    TSM:Print(format(L["Removed %s from clients."], entry.name))
                    LW:Refresh()
                end)
            else
                row:Hide()
                row.playerName = nil
            end
        end
    end
end

-- ===================================================================================== --
-- Add Player Modal
-- ===================================================================================== --

function LW:ShowAddPlayerModal()
    if private.addModal then
        private.addModal:Show()
        private.modalNameBox:SetText("")
        private.modalPointsBox:SetText("")
        private.modalNameBox:SetFocus()
        return
    end

    -- Create modal frame
    local modal = CreateFrame("Frame", "TSMLoyaltyAddModal", UIParent)
    modal:SetSize(280, 150)
    modal:SetPoint("CENTER")
    modal:SetFrameStrata("DIALOG")
    modal:SetFrameLevel(110)
    modal:EnableMouse(true)
    modal:SetMovable(true)
    modal:RegisterForDrag("LeftButton")
    modal:SetScript("OnDragStart", function(self) self:StartMoving() end)
    modal:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    TSMAPI.Design:SetFrameBackdropColor(modal)
    private.addModal = modal

    -- Title
    local title = modal:CreateFontString(nil, "OVERLAY")
    title:SetFont(TSMAPI.Design:GetContentFont("normal"))
    title:SetText(L["Add Player"])
    title:SetPoint("TOP", 0, -8)
    TSMAPI.Design:SetWidgetTextColor(title)

    -- Close X button
    local closeBtn = TSMAPI.GUI:CreateButton(modal, 18)
    closeBtn:SetPoint("TOPRIGHT", -3, -3)
    closeBtn:SetWidth(19)
    closeBtn:SetHeight(19)
    closeBtn:SetText("X")
    closeBtn:SetScript("OnClick", function()
        LW:HideAddPlayerModal()
    end)

    -- Player name label + EditBox
    local nameLabel = modal:CreateFontString(nil, "OVERLAY")
    nameLabel:SetFont(TSMAPI.Design:GetContentFont("small"))
    nameLabel:SetText(L["Player name"])
    nameLabel:SetPoint("TOPLEFT", 15, -30)
    TSMAPI.Design:SetWidgetTextColor(nameLabel)

    local nameBox = CreateFrame("EditBox", "TSMLoyaltyModalNameBox", modal, "InputBoxTemplate")
    nameBox:SetPoint("TOPLEFT", 18, -43)
    nameBox:SetPoint("TOPRIGHT", -18, -43)
    nameBox:SetHeight(22)
    nameBox:SetAutoFocus(false)
    nameBox:SetFont(TSMAPI.Design:GetContentFont("small"))
    nameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    nameBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    private.modalNameBox = nameBox

    -- Points label + EditBox
    local pointsLabel = modal:CreateFontString(nil, "OVERLAY")
    pointsLabel:SetFont(TSMAPI.Design:GetContentFont("small"))
    pointsLabel:SetText(L["Points"])
    pointsLabel:SetPoint("TOPLEFT", 15, -70)
    TSMAPI.Design:SetWidgetTextColor(pointsLabel)

    local pointsBox = CreateFrame("EditBox", "TSMLoyaltyModalPointsBox", modal, "InputBoxTemplate")
    pointsBox:SetPoint("TOPLEFT", 18, -83)
    pointsBox:SetWidth(100)
    pointsBox:SetHeight(22)
    pointsBox:SetAutoFocus(false)
    pointsBox:SetFont(TSMAPI.Design:GetContentFont("small"))
    pointsBox:SetText("0")
    pointsBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    pointsBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    private.modalPointsBox = pointsBox

    -- Add button
    local addBtn = TSMAPI.GUI:CreateButton(modal, 14)
    addBtn:SetPoint("BOTTOMLEFT", 15, 10)
    addBtn:SetWidth(110)
    addBtn:SetHeight(24)
    addBtn:SetText(L["Add"])
    addBtn:SetScript("OnClick", function()
        LW:AddPlayer()
    end)

    -- Cancel button
    local cancelBtn = TSMAPI.GUI:CreateButton(modal, 14)
    cancelBtn:SetPoint("BOTTOMRIGHT", -15, 10)
    cancelBtn:SetWidth(110)
    cancelBtn:SetHeight(24)
    cancelBtn:SetText(CANCEL or "Cancel")
    cancelBtn:SetScript("OnClick", function()
        LW:HideAddPlayerModal()
    end)

    -- Escape key closes modal
    tinsert(UISpecialFrames, "TSMLoyaltyAddModal")

    nameBox:SetFocus()
end

function LW:HideAddPlayerModal()
    if private.addModal then
        private.addModal:Hide()
    end
end

-- ===================================================================================== --
-- Add Player Logic
-- ===================================================================================== --

function LW:AddPlayer()
    local nameInput = private.modalNameBox and private.modalNameBox:GetText() or ""
    local pointsInput = private.modalPointsBox and private.modalPointsBox:GetText() or "0"

    -- Validate
    nameInput = strtrim(nameInput)
    if nameInput == "" then
        TSM:Print(L["Please enter a player name."])
        return
    end

    -- Parse points (default 0)
    local points = tonumber(pointsInput) or 0
    points = math.floor(math.max(0, points))

    -- Set points and total points
    local pd = TSM:GetPlayerData(nameInput)
    pd.points = points
    pd.totalPoints = points
    TSM:Print(format(L["Added %s with %d loyalty points."], nameInput, points))

    -- Close modal and refresh
    LW:HideAddPlayerModal()
    LW:Refresh()
end
