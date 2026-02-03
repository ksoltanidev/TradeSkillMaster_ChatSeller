-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Transmogs Tab UI
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")

-- Get Options module reference
local Options = TSM:GetModule("Options")

-- ===================================================================================== --
-- Transmogs Tab (Placeholder)
-- ===================================================================================== --

function Options:LoadTransmogsTab(container)
    local page = {
        {
            type = "ScrollFrame",
            layout = "Flow",
            children = {
                {
                    type = "InlineGroup",
                    title = L["Transmogs"],
                    layout = "Flow",
                    fullWidth = true,
                    children = {
                        {
                            type = "Label",
                            text = "Transmogs configuration will be added here.",
                            fullWidth = true,
                        },
                    },
                },
            },
        },
    }

    TSMAPI:BuildPage(container, page)
end
