-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Chat Handler Module
-- Handles incoming whispers and routes to appropriate features
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)

-- ===================================================================================== --
-- Chat Message Handler
-- ===================================================================================== --

function TSM:CHAT_MSG_WHISPER(event, message, sender, ...)
    -- Get prefix (can be empty)
    local prefix = TSM.db.profile.commandPrefix or ""
    local lowerMessage = strlower(message)
    local lowerPrefix = strlower(prefix)

    -- Build patterns based on whether prefix is empty or not
    local pricePattern, gearPattern, tmogPattern
    if lowerPrefix == "" then
        -- No prefix: commands start directly with "price", "gear", or "tmog"
        pricePattern = "^price%s+"
        gearPattern = "^gear%s*(.*)$"
        tmogPattern = "^tmog%s*(.*)$"
    else
        -- With prefix: "prefix price", "prefix gear", or "prefix tmog"
        pricePattern = "^" .. lowerPrefix .. "%s+price%s+"
        gearPattern = "^" .. lowerPrefix .. "%s+gear%s*(.*)$"
        tmogPattern = "^" .. lowerPrefix .. "%s+tmog%s*(.*)$"
    end

    -- Check for price command
    if TSM.db.profile.prices.enabled then
        if strmatch(lowerMessage, pricePattern) then
            -- Extract item links from the message
            local itemLinks = TSM:ExtractItemLinks(message)
            if #itemLinks > 0 then
                TSM:HandlePriceCommand(sender, itemLinks)
            end
            return
        end
    end

    -- Check for gear command
    if TSM.db.profile.gears.enabled then
        local gearArgs = strmatch(lowerMessage, gearPattern)
        if gearArgs then
            TSM:HandleGearCommand(sender, gearArgs)
            return
        end
    end

    -- Check for tmog command
    if TSM.db.profile.transmogs.enabled then
        local tmogArgs = strmatch(lowerMessage, tmogPattern)
        if tmogArgs then
            TSM:HandleTransmogCommand(sender, tmogArgs)
            return
        end
    end
end

-- ===================================================================================== --
-- Utility Functions
-- ===================================================================================== --

-- Extract all item links from a message
function TSM:ExtractItemLinks(message)
    local links = {}
    local startPos = 1

    while true do
        -- Find the start of an item link (|c starts the color code)
        local s = strfind(message, "|c", startPos)
        if not s then break end

        -- Find the end of the item link (|r ends it)
        local _, e = strfind(message, "|r", s)
        if not e then break end

        -- Extract the full link
        local link = strsub(message, s, e)

        -- Verify it's a valid item link
        if strfind(link, "|Hitem:") then
            tinsert(links, link)
        end

        startPos = e + 1
    end

    return links
end
