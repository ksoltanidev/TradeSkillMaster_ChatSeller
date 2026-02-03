-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Chat-based selling automation module for TSM
-- ------------------------------------------------------------------------------------- --

-- Initialize addon namespace
local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TSM_ChatSeller", "AceEvent-3.0", "AceConsole-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")

-- Default saved variables
local savedDBDefaults = {
    profile = {
        enabled = true,
    },
}

-- ===================================================================================== --
-- Addon Lifecycle
-- ===================================================================================== --

function TSM:OnInitialize()
    -- Initialize saved variables database
    TSM.db = LibStub("AceDB-3.0"):New("AscensionTSM_ChatSellerDB", savedDBDefaults, true)

    -- Register with TSM
    TSM:RegisterModule()
end

function TSM:OnEnable()
    -- Called when the addon is enabled
end

function TSM:OnDisable()
    -- Called when the addon is disabled
end

-- ===================================================================================== --
-- TSM Module Registration
-- ===================================================================================== --

function TSM:RegisterModule()
    TSM.icons = {
        {
            side = "module",
            desc = "ChatSeller",
            slashCommand = "chatseller",
            callback = "Options:Load",
            icon = "Interface\\Icons\\INV_Misc_Note_01",
        },
    }

    TSM.slashCommands = {
        {
            key = "chatseller",
            label = L["Opens the TSM window to the ChatSeller page"],
            callback = function()
                TSMAPI:OpenFrame()
                TSMAPI:SelectIcon("TSM_ChatSeller", "ChatSeller")
            end
        },
    }

    TSMAPI:NewModule(TSM)
end

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
        { text = L["Options"], value = 1 },
    })

    tabGroup:SetCallback("OnGroupSelected", function(self, _, value)
        tabGroup:ReleaseChildren()

        if value == 1 then
            Options:LoadOptionsTab(self)
        end
    end)

    container:AddChild(tabGroup)
    tabGroup:SelectTab(1)
end

function Options:LoadOptionsTab(container)
    local page = {
        {
            type = "ScrollFrame",
            layout = "Flow",
            children = {
                {
                    type = "InlineGroup",
                    title = L["ChatSeller"],
                    layout = "Flow",
                    fullWidth = true,
                    children = {
                        {
                            type = "Label",
                            text = "ChatSeller options will be added here.",
                            fullWidth = true,
                        },
                        {
                            type = "HeadingLine",
                        },
                        {
                            type = "CheckBox",
                            label = L["Enable ChatSeller"],
                            settingInfo = { TSM.db.profile, "enabled" },
                            tooltip = L["Toggle the ChatSeller module"],
                        },
                    },
                },
            },
        },
    }

    TSMAPI:BuildPage(container, page)
end
