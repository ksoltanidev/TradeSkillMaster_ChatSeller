-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Gears Feature
-- Gear lookup command handling and filtering
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")

-- Shortcut to GearsData
local GD = TSM.GearsData

-- ===================================================================================== --
-- Argument Parsing
-- ===================================================================================== --

-- Hand filter keywords (1h, 2h, mh, oh) - treated separately from weapon type
local HAND_FILTERS = {
    ["1h"] = true, ["2h"] = true, mh = true, oh = true,
}

-- Parse gear command arguments into structured filters
-- Supports flexible order: "cloth head lvl 10-50 str" = "str lvl 10-50 cloth head"
function TSM:ParseGearArguments(args)
    local filters = {
        category = nil,
        subcategory = nil,
        handFilter = nil,   -- 1h, 2h, mh, oh (separate from weapon type)
        minLevel = nil,
        maxLevel = nil,
        minILevel = nil,
        maxILevel = nil,
        stats = {},  -- list of canonical stat names
        unrecognized = {},  -- list of words that weren't recognized
    }

    local words = {}
    for word in string.gmatch(args, "%S+") do
        tinsert(words, strlower(word))
    end

    local i = 1
    while i <= #words do
        local word = words[i]
        local consumed = false

        -- Check for level keywords
        local levelType = GD.LEVEL_KEYWORDS[word]
        if levelType then
            local nextWord = words[i + 1]
            if nextWord then
                if levelType == "level" then
                    -- Parse range "5-55" or single value "50"
                    local min, max = strmatch(nextWord, "^(%d+)%-(%d+)$")
                    if min and max then
                        filters.minLevel = tonumber(min)
                        filters.maxLevel = tonumber(max)
                    else
                        local val = tonumber(nextWord)
                        if val then
                            filters.minLevel = val
                            filters.maxLevel = val
                        end
                    end
                    i = i + 1  -- consume next word
                elseif levelType == "minlevel" then
                    filters.minLevel = tonumber(nextWord)
                    i = i + 1
                elseif levelType == "maxlevel" then
                    filters.maxLevel = tonumber(nextWord)
                    i = i + 1
                end
            end
            consumed = true
        end

        -- Check for ilvl keywords
        if not consumed then
            local ilvlType = GD.ILVL_KEYWORDS[word]
            if ilvlType then
                local nextWord = words[i + 1]
                if nextWord then
                    if ilvlType == "ilvl" then
                        local min, max = strmatch(nextWord, "^(%d+)%-(%d+)$")
                        if min and max then
                            filters.minILevel = tonumber(min)
                            filters.maxILevel = tonumber(max)
                        else
                            local val = tonumber(nextWord)
                            if val then
                                filters.minILevel = val
                                filters.maxILevel = val
                            end
                        end
                        i = i + 1
                    elseif ilvlType == "minilvl" then
                        filters.minILevel = tonumber(nextWord)
                        i = i + 1
                    elseif ilvlType == "maxilvl" then
                        filters.maxILevel = tonumber(nextWord)
                        i = i + 1
                    end
                end
                consumed = true
            end
        end

        -- Check for stat aliases
        if not consumed then
            local stat = GD.STAT_ALIASES[word]
            if stat then
                tinsert(filters.stats, stat)
                consumed = true
            end
        end

        -- Check for category
        if not consumed then
            local cat = GD.CATEGORY_ALIASES[word]
            if cat then
                filters.category = cat
                consumed = true
            end
        end

        -- Check for subcategory (works with or without category already set)
        if not consumed then
            -- Try weapon subcategory first
            local weaponSubcat = GD.WEAPON_SUBCATEGORY_ALIASES[word]
            if weaponSubcat then
                -- Check if it's a hand filter (1h, 2h, mh, oh)
                if HAND_FILTERS[weaponSubcat] then
                    filters.handFilter = weaponSubcat
                    -- If no category set, imply weapon category
                    if not filters.category then
                        filters.category = "weapon"
                    end
                else
                    -- It's a weapon type (sword, axe, etc.)
                    filters.subcategory = weaponSubcat
                    -- If no category set and it's a weapon subcategory, imply weapon category
                    if not filters.category then
                        filters.category = "weapon"
                    end
                end
                consumed = true
            else
                -- Try armor subcategory
                local armorSubcat = GD.SUBCATEGORY_ALIASES[word]
                if armorSubcat then
                    filters.subcategory = armorSubcat
                    consumed = true
                end
            end
        end

        -- Check for bare level range (e.g., "15-20") or single number (e.g., "50")
        -- Only if no level filter has been set yet
        if not consumed and not filters.minLevel and not filters.maxLevel then
            local min, max = strmatch(word, "^(%d+)%-(%d+)$")
            if min and max then
                filters.minLevel = tonumber(min)
                filters.maxLevel = tonumber(max)
                consumed = true
            else
                local val = tonumber(word)
                if val then
                    filters.minLevel = val
                    filters.maxLevel = val
                    consumed = true
                end
            end
        end

        -- Track unrecognized words
        if not consumed then
            tinsert(filters.unrecognized, word)
        end

        i = i + 1
    end

    return filters
end

-- ===================================================================================== --
-- Gear Command Handler
-- ===================================================================================== --

-- Handle the gear command: gem gear [category] [subcategory] [filters]
function TSM:HandleGearCommand(sender, args)
    -- If no args provided, send help message
    if not args or args == "" then
        TSM:SendGearHelpMessage(sender)
        return
    end

    -- Check for help commands
    local argsLower = strlower(args)
    if argsLower == "?" or argsLower == "help" then
        TSM:SendGearHelpMessage(sender)
        return
    end

    -- Check for filter help commands
    if argsLower == "filters" or argsLower == "filter" then
        TSM:SendGearFilterHelpMessage(sender)
        return
    end

    -- Parse all arguments into structured filters
    local filters = TSM:ParseGearArguments(args)

    -- Check if any filter was recognized - if not, show help
    local hasAnyFilter = filters.category or filters.subcategory or filters.handFilter
        or filters.minLevel or filters.maxLevel or filters.minILevel or filters.maxILevel
        or (#filters.stats > 0)

    if not hasAnyFilter then
        TSM:SendGearHelpMessage(sender)
        return
    end

    -- Get matching items
    local matchingItems = TSM:FilterGearItems(filters)

    if #matchingItems == 0 then
        SendChatMessage(L["No matching gear found."], "WHISPER", nil, sender)
        return
    end

    -- Send responses (up to 10 items, 2 per message)
    TSM:SendGearResponses(sender, matchingItems, filters)
end

-- ===================================================================================== --
-- Filtering
-- ===================================================================================== --

-- Filter gear items by filters table
function TSM:FilterGearItems(filters)
    local items = TSM.db.profile.gears.itemList
    local results = {}

    for _, item in ipairs(items) do
        if TSM:ItemMatchesFilter(item, filters) then
            tinsert(results, item)
        end
    end

    return results
end

-- Check if an item matches all filter criteria
function TSM:ItemMatchesFilter(item, filters)
    -- No filters = return all items
    if not filters then
        return true
    end

    -- Check category match
    if filters.category then
        local catFilter = GD.CATEGORY_FILTERS[filters.category]
        if not catFilter then
            return false
        end

        if catFilter.subClass then
            -- Armor type filter (cloth, leather, mail, plate)
            if item.itemSubClass ~= catFilter.subClass then
                return false
            end
        elseif catFilter.equipLoc then
            -- Accessory filter (neck, ring, trinket, back)
            if item.equipLoc ~= catFilter.equipLoc then
                return false
            end
        elseif catFilter.isWeapon then
            -- Weapon category - check if equipLoc is a weapon type
            if not GD.WEAPON_EQUIP_LOCS[item.equipLoc] then
                return false
            end
        end
    end

    -- Check subcategory match
    if filters.subcategory then
        if filters.category == "weapon" then
            -- Weapon subcategory filter
            local subFilter = GD.WEAPON_FILTERS[filters.subcategory]
            if subFilter then
                if subFilter.equipLoc then
                    if item.equipLoc ~= subFilter.equipLoc then
                        return false
                    end
                elseif subFilter.subClass then
                    if item.itemSubClass ~= subFilter.subClass then
                        return false
                    end
                elseif subFilter.subClasses then
                    local matched = false
                    for _, subClass in ipairs(subFilter.subClasses) do
                        if item.itemSubClass == subClass then
                            matched = true
                            break
                        end
                    end
                    if not matched then return false end
                end
            end
        else
            -- Armor slot subcategory filter
            local slotFilter = GD.SUBCATEGORY_FILTERS[filters.subcategory]
            if slotFilter then
                if slotFilter.equipLoc then
                    if item.equipLoc ~= slotFilter.equipLoc then
                        return false
                    end
                elseif slotFilter.equipLocs then
                    local matched = false
                    for _, loc in ipairs(slotFilter.equipLocs) do
                        if item.equipLoc == loc then
                            matched = true
                            break
                        end
                    end
                    if not matched then return false end
                end
            end
        end
    end

    -- Check hand filter (1h, 2h, mh, oh) - separate from weapon type
    if filters.handFilter then
        local handFilterDef = GD.WEAPON_FILTERS[filters.handFilter]
        if handFilterDef then
            if handFilterDef.equipLoc then
                if item.equipLoc ~= handFilterDef.equipLoc then
                    return false
                end
            elseif handFilterDef.equipLocs then
                local matched = false
                for _, loc in ipairs(handFilterDef.equipLocs) do
                    if item.equipLoc == loc then
                        matched = true
                        break
                    end
                end
                if not matched then return false end
            end
        end
    end

    -- Check required level filter
    if filters.minLevel or filters.maxLevel then
        local itemReqLevel = item.reqLevel or 0
        if filters.minLevel and itemReqLevel < filters.minLevel then
            return false
        end
        if filters.maxLevel and itemReqLevel > filters.maxLevel then
            return false
        end
    end

    -- Check item level filter
    if filters.minILevel or filters.maxILevel then
        local itemILevel = item.iLevel or 0
        if filters.minILevel and itemILevel < filters.minILevel then
            return false
        end
        if filters.maxILevel and itemILevel > filters.maxILevel then
            return false
        end
    end

    -- Check stat filters (all requested stats must be present)
    if filters.stats and #filters.stats > 0 then
        local itemStats = item.stats or {}
        for _, statKey in ipairs(filters.stats) do
            if not itemStats[statKey] or itemStats[statKey] <= 0 then
                return false
            end
        end
    end

    return true
end

-- ===================================================================================== --
-- Response Functions
-- ===================================================================================== --

-- Send gear item responses (2 items per message, max 10 items)
function TSM:SendGearResponses(sender, items, filters)
    -- Limit to 10 items
    local maxItems = min(#items, 10)

    -- Send 2 items per message (up to 5 messages)
    for i = 1, maxItems, 2 do
        local item1 = items[i]
        local item2 = items[i + 1]

        local response = TSM:FormatGearItem(item1)
        if item2 and i + 1 <= maxItems then
            response = response .. ", " .. TSM:FormatGearItem(item2)
        end

        SendChatMessage(response, "WHISPER", nil, sender)
    end

    -- Check if no advanced filters were used (no stats, no levels, no ilvl)
    local hasAdvancedFilters = filters and (
        filters.minLevel or filters.maxLevel or
        filters.minILevel or filters.maxILevel or
        (filters.stats and #filters.stats > 0)
    )

    if not hasAdvancedFilters then
        TSM:SendGearLearnFilterHelpMessage(sender)
    end

    -- Notify about unrecognized options
    if filters and filters.unrecognized and #filters.unrecognized > 0 then
        local unrecognizedStr = table.concat(filters.unrecognized, ", ")
        SendChatMessage("Option(s) not recognized: " .. unrecognizedStr, "WHISPER", nil, sender)
    end
end

-- Format a gear item for chat response
function TSM:FormatGearItem(item)
    local priceStr = ""
    if item.price and item.price > 0 then
        priceStr = " " .. TSM:FormatMoneyForChat(item.price)
    end
    -- Use name as fallback if link is not available
    local itemText = item.link or item.name or "Unknown"
    return itemText .. priceStr
end

-- Get display name for equipment slot
function TSM:GetSlotDisplayName(equipLoc)
    return GD.SLOT_DISPLAY_NAMES[equipLoc]
end

-- Learn more about filtering items
function TSM:SendGearLearnFilterHelpMessage(sender)
    local prefix = TSM.db.profile.commandPrefix or ""
    local cmdPrefix = (prefix ~= "") and (prefix .. " ") or ""
    SendChatMessage("{rt6} [FILTERS] You can filter by stats, lvl and more. Learn more by typing 'gear filters' {rt6}", "WHISPER", nil, sender)
end

-- Send help message for gear command
function TSM:SendGearHelpMessage(sender)
    local prefix = TSM.db.profile.commandPrefix or ""
    local cmdPrefix = (prefix ~= "") and (prefix .. " ") or ""
    SendChatMessage("Greetings my friend, welcome to the Gear Shop. Here, you can browse through items I sell using chat messages", "WHISPER", nil, sender)
    SendChatMessage("How does it work ? just send me a message like this: '" .. cmdPrefix .. "gear [category] [optional subcategory] [optional filters]'", "WHISPER", nil, sender)
    SendChatMessage("Categories: cloth, leather, mail, plate, back, neck, ring, trinket, weapon", "WHISPER", nil, sender)
    SendChatMessage("Armor subcategories: head, shoulders, chest, wrist, gloves, waist, legs, feet", "WHISPER", nil, sender)
    SendChatMessage("Weapons subcategories: sword, axe, mace, dagger, staff, polearm, bow, gun, crossbow, wand, shield", "WHISPER", nil, sender)
    SendChatMessage("Level filters: 'lvl 10-15' OR 'minlvl 10' OR 'maxlvl 50'", "WHISPER", nil, sender)
    SendChatMessage("Example: '" .. cmdPrefix .. "gear cloth chest lvl 5-15'", "WHISPER", nil, sender)
    TSM:SendGearLearnFilterHelpMessage(sender)
    SendChatMessage("Accepts EN/FR/ES keywords.", "WHISPER", nil, sender)
end

-- Send help message for gear command
function TSM:SendGearFilterHelpMessage(sender)
    local prefix = TSM.db.profile.commandPrefix or ""
    local cmdPrefix = (prefix ~= "") and (prefix .. " ") or ""
    SendChatMessage("To filter items, you can use theses filters. You can combine multiples", "WHISPER", nil, sender)
    SendChatMessage("Level filters: 'lvl 10-15' OR 'minlvl 10' OR 'maxlvl 50'", "WHISPER", nil, sender)
    SendChatMessage("Weapon filters: '1h' OR '2h' OR 'mh' (main hand) OR 'oh' (off hand)", "WHISPER", nil, sender)
    SendChatMessage("Item level: 'ilvl 40-50' OR 'minilvl 50' OR 'maxilvl 50'", "WHISPER", nil, sender)
    SendChatMessage("Stats: 'str' OR 'agi' OR 'int' OR 'spi' OR 'sta' OR 'sp' OR 'ap' OR 'crit' OR 'haste' OR 'hit' OR 'exp'", "WHISPER", nil, sender)
    SendChatMessage("advanced stats: 'mp5' OR 'sd' (spell dmg) OR 'armpen' OR 'spellpen' OR 'block' OR 'parry' OR 'dodge' OR 'def'", "WHISPER", nil, sender)
    SendChatMessage("Example: '" .. cmdPrefix .. "gear sword 2h str armpen'", "WHISPER", nil, sender)
    SendChatMessage("Accepts EN/FR/ES keywords.", "WHISPER", nil, sender)
end
