-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Prices Tab UI
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")

-- Get Options module reference
local Options = TSM:GetModule("Options")

-- ===================================================================================== --
-- Prices Tab
-- ===================================================================================== --

function Options:LoadPricesTab(container)
    local prefix = TSM.db.profile.commandPrefix or "gem"
    local page = {
        {
            type = "ScrollFrame",
            layout = "Flow",
            children = {
                {
                    type = "InlineGroup",
                    title = L["Price Lookup"],
                    layout = "Flow",
                    fullWidth = true,
                    children = {
                        {
                            type = "CheckBox",
                            label = L["Enable Price Lookup"],
                            settingInfo = { TSM.db.profile.prices, "enabled" },
                            tooltip = L["Allow users to whisper you for price information."],
                        },
                        {
                            type = "HeadingLine",
                        },
                        {
                            type = "Label",
                            text = L["When enabled, other players can whisper you with:"],
                            fullWidth = true,
                        },
                        {
                            type = "Label",
                            text = "  " .. prefix .. " price [item link]",
                            fullWidth = true,
                        },
                        {
                            type = "HeadingLine",
                        },
                        {
                            type = "Label",
                            text = L["Response format:"],
                            fullWidth = true,
                        },
                        {
                            type = "Label",
                            text = L["[Item] There were X auctions Y ago, starting from Z. Average price is W."],
                            fullWidth = true,
                        },
                    },
                },
            },
        },
    }

    TSMAPI:BuildPage(container, page)
end
