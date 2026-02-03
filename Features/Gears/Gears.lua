-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Gears Feature
-- Gear lookup command handling and filtering
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")

-- Shortcut to GearsData
local GD = TSM.GearsData

-- ===================================================================================== --
-- Gear Command Handler
-- ===================================================================================== --

-- Handle the gear command: gem gear [category] [subcategory]
function TSM:HandleGearCommand(sender, args)
    -- Parse arguments into words
    local words = {}
    for word in string.gmatch(args, "%S+") do
        tinsert(words, strlower(word))
    end

    -- If no category provided, send help message
    if #words == 0 then
        TSM:SendGearHelpMessage(sender)
        return
    end

    local category = nil
    local subcategory = nil

    -- First word is category (resolve alias)
    if words[1] then
        category = GD.CATEGORY_ALIASES[words[1]]
    end

    -- Second word is subcategory (if applicable)
    if words[2] and category then
        if category == "weapon" then
            subcategory = GD.WEAPON_SUBCATEGORY_ALIASES[words[2]]
        elseif GD.CATEGORIES_WITH_SUBCATEGORIES[category] then
            subcategory = GD.SUBCATEGORY_ALIASES[words[2]]
        end
    end

    -- Get matching items
    local matchingItems = TSM:FilterGearItems(category, subcategory)

    if #matchingItems == 0 then
        SendChatMessage(L["No matching gear found."], "WHISPER", nil, sender)
        return
    end

    -- Send responses (up to 10 items, 2 per message)
    TSM:SendGearResponses(sender, matchingItems)
end

-- ===================================================================================== --
-- Filtering
-- ===================================================================================== --

-- Filter gear items by category and subcategory
function TSM:FilterGearItems(category, subcategory)
    local items = TSM.db.profile.gears.itemList
    local results = {}

    for _, item in ipairs(items) do
        if TSM:ItemMatchesFilter(item, category, subcategory) then
            tinsert(results, item)
        end
    end

    return results
end

-- Check if an item matches the filter criteria
function TSM:ItemMatchesFilter(item, category, subcategory)
    -- No filter = return all items
    if not category then
        return true
    end

    local catFilter = GD.CATEGORY_FILTERS[category]
    if not catFilter then
        return false
    end

    -- Check category match
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

    -- Check subcategory match (if provided)
    if subcategory then
        if category == "weapon" then
            -- Weapon subcategory filter
            local subFilter = GD.WEAPON_FILTERS[subcategory]
            if not subFilter then
                return true  -- Unknown subcategory, skip filtering
            end

            if subFilter.equipLoc then
                -- Shield special case
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
                if not matched then
                    return false
                end
            end
        else
            -- Armor slot subcategory filter
            local slotFilter = GD.SUBCATEGORY_FILTERS[subcategory]
            if not slotFilter then
                return true  -- Unknown subcategory, skip filtering
            end

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
                if not matched then
                    return false
                end
            end
        end
    end

    return true
end

-- ===================================================================================== --
-- Response Functions
-- ===================================================================================== --

-- Send gear item responses (2 items per message, max 10 items)
function TSM:SendGearResponses(sender, items)
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

-- Send help message for gear command
function TSM:SendGearHelpMessage(sender)
    local prefix = TSM.db.profile.commandPrefix or "gem"
    SendChatMessage("Welcome to my Gear Shop - To view what I am selling, use the following command:", "WHISPER", nil, sender)
    SendChatMessage(prefix .. " gear [category] [subcategory]", "WHISPER", nil, sender)
    SendChatMessage("Categories - cloth, leather, mail, plate, back, neck, ring, trinket, weapon", "WHISPER", nil, sender)
    SendChatMessage("Armor subcategories - head, shoulders, chest, wrist, gloves, waist, legs, feet", "WHISPER", nil, sender)
    SendChatMessage("Weapons subcategories - sword, axe, mace, dagger, staff, polearm, bow, gun, crossbow, wand, shield", "WHISPER", nil, sender)
    SendChatMessage("Example - " .. prefix .. " gear cloth head", "WHISPER", nil, sender)
    SendChatMessage("Accepts English, French and Spanish keywords.", "WHISPER", nil, sender)
end
