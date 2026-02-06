-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Bagnon GuildBank Integration
-- Adds a "Sync Tmog" button to the Bagnon GuildBank frame
-- Works with Personal Bank, Realm Bank, and Guild Bank (all use GuildBank API on Ascension)
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")

local syncButton = nil

-- Create the sync button and anchor it to the Bagnon GuildBank frame
local function CreateSyncButton(bagnonFrame)
    local btn = CreateFrame("Button", "ChatSellerGuildBankSyncBtn", bagnonFrame, "UIPanelButtonTemplate")
    btn:SetWidth(100)
    btn:SetHeight(20)
    btn:SetPoint("BOTTOMLEFT", bagnonFrame, "BOTTOMLEFT", 8, 4)
    btn:SetText(L["Sync Tmog"])
    btn:SetNormalFontObject(GameFontNormalSmall)
    btn:SetHighlightFontObject(GameFontHighlightSmall)
    btn:SetScript("OnClick", function()
        local tab = GetCurrentGuildBankTab()
        if not tab or tab == 0 then
            TSM:Print(L["No guild bank tab selected."])
            return
        end
        local added, skipped = TSM:SyncFromGuildBank(tab)
        TSM:Print(format(L["Tmog sync: added %d items (%d skipped)."], added, skipped))
    end)
    btn:Hide()

    syncButton = btn
    return btn
end

-- Event handler: show/hide button when guild bank opens/closes
local frame = CreateFrame("Frame")
frame:RegisterEvent("GUILDBANKFRAME_OPENED")
frame:RegisterEvent("GUILDBANKFRAME_CLOSED")
frame:SetScript("OnEvent", function(self, event)
    if event == "GUILDBANKFRAME_OPENED" then
        local bagnonFrame = _G["BagnonFrameguildbank"]
        if not bagnonFrame then return end

        if not syncButton then
            CreateSyncButton(bagnonFrame)
        end
        syncButton:Show()

    elseif event == "GUILDBANKFRAME_CLOSED" then
        if syncButton then
            syncButton:Hide()
        end
    end
end)
