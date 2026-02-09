-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Options Module
-- Main UI framework with tab navigation
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")

-- ===================================================================================== --
-- Options Module
-- ===================================================================================== --

local Options = TSM:NewModule("Options")

function Options:Load(container)
    -- Create tab group
    local tabGroup = AceGUI:Create("TSMTabGroup")
    tabGroup:SetLayout("Fill")
    tabGroup:SetFullHeight(true)
    tabGroup:SetFullWidth(true)
    tabGroup:SetTabs({
        { text = L["Prices"], value = 1 },
        { text = L["Gears"], value = 2 },
        { text = L["Transmogs"], value = 3 },
        { text = L["Options"], value = 4 },
    })

    tabGroup:SetCallback("OnGroupSelected", function(self, _, value)
        tabGroup:ReleaseChildren()

        if value == 1 then
            Options:LoadPricesTab(self)
        elseif value == 2 then
            Options:LoadGearsTab(self)
        elseif value == 3 then
            Options:LoadTransmogsTab(self)
        elseif value == 4 then
            Options:LoadOptionsTab(self)
        end
    end)

    container:AddChild(tabGroup)
    tabGroup:SelectTab(1)
end

-- ===================================================================================== --
-- Options Tab (General Settings)
-- ===================================================================================== --

function Options:LoadOptionsTab(container)
    local page = {
        {
            type = "ScrollFrame",
            layout = "Flow",
            children = {
                {
                    type = "InlineGroup",
                    title = L["General Settings"],
                    layout = "Flow",
                    fullWidth = true,
                    children = {
                        {
                            type = "Label",
                            text = L["Command Prefix is used by all chat features. Example: If prefix is 'gem', users whisper 'gem price [item]' to get prices."],
                            fullWidth = true,
                        },
                        {
                            type = "HeadingLine",
                        },
                        {
                            type = "EditBox",
                            label = L["Command Prefix"],
                            settingInfo = { TSM.db.profile, "commandPrefix" },
                            tooltip = L["The prefix for all chat commands (e.g., 'gem' for 'gem price [item]')"],
                        },
                    },
                },
                {
                    type = "InlineGroup",
                    title = L["Loyalty Program Settings"],
                    layout = "Flow",
                    fullWidth = true,
                    children = {
                        {
                            type = "Label",
                            text = L["Configure the loyalty points system for returning customers."],
                            fullWidth = true,
                        },
                        {
                            type = "HeadingLine",
                        },
                        {
                            type = "CheckBox",
                            label = L["Enable Loyalty Program"],
                            settingInfo = { TSM.db.profile.loyalty, "enabled" },
                            tooltip = L["Configure the loyalty points system for returning customers."],
                        },
                        {
                            type = "EditBox",
                            label = L["Points Per Gold"],
                            settingInfo = { TSM.db.profile.loyalty, "pointsPerGold" },
                            tooltip = L["Points Per Gold"],
                        },
                        {
                            type = "EditBox",
                            label = L["Reward Threshold"],
                            settingInfo = { TSM.db.profile.loyalty, "rewardThreshold" },
                            tooltip = L["Reward Threshold"],
                        },
                        {
                            type = "EditBox",
                            label = L["Reward Discount (gold)"],
                            settingInfo = { TSM.db.profile.loyalty, "rewardGoldDiscount" },
                            tooltip = L["Reward Discount (gold)"],
                        },
                    },
                },
            },
        },
    }

    TSMAPI:BuildPage(container, page)
end
