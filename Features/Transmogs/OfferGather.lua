-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Offer Gather
-- Gather items from bank for transmog offers using TSMAPI:MoveItems
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")
local OW = TSM.OffersWindow
local private = OW._private

-- ===================================================================================== --
-- Bank Helpers
-- ===================================================================================== --

function OW:IsBankOpen()
    if BagnonFrameguildbank and BagnonFrameguildbank:IsVisible() then
        return true
    elseif BagnonFramebank and BagnonFramebank:IsVisible() then
        return true
    elseif GuildBankFrame and GuildBankFrame:IsVisible() then
        return true
    elseif BankFrame and BankFrame:IsVisible() then
        return true
    end
    return false
end

function OW:FindItemStringInBank(itemName)
    -- Check guild bank (covers personal/realm bank on Ascension too)
    if (GuildBankFrame and GuildBankFrame:IsVisible()) or (BagnonFrameguildbank and BagnonFrameguildbank:IsVisible()) then
        for tab = 1, GetNumGuildBankTabs() do
            for slot = 1, (MAX_GUILDBANK_SLOTS_PER_TAB or 98) do
                local link = GetGuildBankItemLink(tab, slot)
                if link then
                    local name = GetItemInfo(link)
                    if name and name == itemName then
                        return TSMAPI:GetBaseItemString(link, true)
                    end
                end
            end
        end
    end

    -- Check regular bank
    if (BankFrame and BankFrame:IsVisible()) or (BagnonFramebank and BagnonFramebank:IsVisible()) then
        for _, bag in ipairs({-1, 5, 6, 7, 8, 9, 10, 11}) do
            local numSlots = GetContainerNumSlots(bag)
            for slot = 1, numSlots do
                local link = GetContainerItemLink(bag, slot)
                if link then
                    local name = GetItemInfo(link)
                    if name and name == itemName then
                        return TSMAPI:GetBaseItemString(link, true)
                    end
                end
            end
        end
    end

    return nil
end

-- ===================================================================================== --
-- Gather Item
-- ===================================================================================== --

function OW:GatherItem(offerIndex)
    local offer = TSM.db.profile.transmogs.offerList[offerIndex]
    if not offer then return end

    -- Check if a bank is open
    if not OW:IsBankOpen() then
        TSM:Print(L["No bank is open."])
        return
    end

    -- Get itemString from the offer's itemLink
    local itemString = nil
    if offer.itemLink then
        itemString = TSMAPI:GetBaseItemString(offer.itemLink, true)
    end

    -- Fallback: scan the bank by item name
    if not itemString and offer.itemName then
        itemString = OW:FindItemStringInBank(offer.itemName)
    end

    if not itemString then
        TSM:Print(L["Item not found in bank."])
        return
    end

    -- Move 1 item from bank to bags
    local moveTable = { [itemString] = 1 }
    local itemDisplay = offer.itemLink or offer.itemName or "item"

    TSM:Print(format(L["Gathering %s from bank..."], itemDisplay))

    TSMAPI:MoveItems(moveTable, function(msg)
        if msg then
            TSM:Print(msg)
        end
    end, true) -- includeSoulbound = true (transmog items may be soulbound)
end
