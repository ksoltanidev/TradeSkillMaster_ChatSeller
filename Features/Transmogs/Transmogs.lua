-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Transmogs Feature
-- Transmog lookup command handling and filtering
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")

-- ===================================================================================== --
-- Transmog Type/Subtype Data
-- ===================================================================================== --

-- Base types
local TMOG_TYPES = {
    "weapon", "mount", "pet", "armor set", "shield", "tabard", "misc", "illusions", "altars",
}

-- Type keyword aliases -> canonical type name
local TYPE_ALIASES = {
    weapon = "weapon", weapons = "weapon", arme = "weapon", armes = "weapon",
    mount = "mount", mounts = "mount", monture = "mount", montures = "mount",
    pet = "pet", pets = "pet", familier = "pet", familiers = "pet", mascota = "pet",
    set = "armor set", sets = "armor set", ["armor set"] = "armor set", armorset = "armor set", armor = "armor set",
    shield = "shield", shields = "shield", bouclier = "shield", escudo = "shield",
    tabard = "tabard", tabards = "tabard", tabardo = "tabard",
    misc = "misc", divers = "misc", varios = "misc",
    illusion = "illusions", illusions = "illusions",
    altar = "altars", altars = "altars", autel = "altars", autels = "altars",
}

-- Weapon subtype aliases -> canonical subtype name (infers tmogType = "weapon")
local WEAPON_SUBTYPE_ALIASES = {
    sword = "sword", swords = "sword", epee = "sword", espada = "sword",
    axe = "axe", axes = "axe", hache = "axe", hacha = "axe",
    mace = "mace", maces = "mace", masse = "mace", maza = "mace",
    dagger = "dagger", daggers = "dagger", dague = "dagger", punal = "dagger",
    staff = "staff", staves = "staff", baton = "staff", baston = "staff",
    polearm = "polearm", polearms = "polearm",
    fist = "fist",
    bow = "bow", bows = "bow", arc = "bow", arco = "bow",
    gun = "gun", guns = "gun", fusil = "gun",
    crossbow = "crossbow", crossbows = "crossbow", arbalete = "crossbow", ballesta = "crossbow",
    wand = "wand", wands = "wand", baguette = "wand", varita = "wand",
    thrown = "thrown", lance = "thrown", arrojadiza = "thrown",
}

-- Armor subtype aliases -> canonical subtype name (infers tmogType = "armor set")
local ARMOR_SUBTYPE_ALIASES = {
    head = "head", helm = "head", helmet = "head", tete = "head", casque = "head", cabeza = "head",
    shoulders = "shoulders", shoulder = "shoulders", epaules = "shoulders", hombros = "shoulders",
    chest = "chest", robe = "chest", torse = "chest", poitrine = "chest", pecho = "chest",
    wrist = "wrist", bracers = "wrist", poignets = "wrist", munecas = "wrist",
    gloves = "gloves", hands = "gloves", gants = "gloves", guantes = "gloves",
    waist = "waist", belt = "waist", taille = "waist", ceinture = "waist", cintura = "waist",
    legs = "legs", pants = "legs", jambes = "legs", piernas = "legs",
    feet = "feet", boots = "feet", pieds = "feet", bottes = "feet", pies = "feet", botas = "feet",
    back = "back", cloak = "back", cape = "back", dos = "back", capa = "back",
}

-- ===================================================================================== --
-- Argument Parsing
-- ===================================================================================== --

-- Parse transmog command arguments into structured filters
function TSM:ParseTransmogArguments(args)
    local filters = {
        tmogType = nil,
        tmogSubType = nil,
        nameFilter = nil,
    }

    if not args or args == "" then
        return filters
    end

    -- Step 1: Extract quoted strings as name filter
    local quotedParts = {}
    local remaining = args

    -- Extract double-quoted strings
    remaining = string.gsub(remaining, '"([^"]*)"', function(match)
        tinsert(quotedParts, match)
        return ""
    end)

    -- Extract single-quoted strings
    remaining = string.gsub(remaining, "'([^']*)'", function(match)
        tinsert(quotedParts, match)
        return ""
    end)

    -- Step 2: Parse remaining words
    local words = {}
    for word in string.gmatch(remaining, "%S+") do
        tinsert(words, strlower(word))
    end

    local unrecognized = {}
    local i = 1
    while i <= #words do
        local word = words[i]
        local consumed = false

        -- Check for "name" keyword
        if word == "name" or word == "nom" or word == "nombre" then
            local nextWord = words[i + 1]
            if nextWord then
                tinsert(quotedParts, nextWord)
                i = i + 1
            end
            consumed = true
        end

        -- Check for "free" filter keyword
        if not consumed then
            if word == "free" or word == "gratuit" or word == "gratis" then
                filters.isFree = true
                consumed = true
            end
        end

        -- Check for type aliases
        if not consumed then
            local tmogType = TYPE_ALIASES[word]
            if tmogType then
                filters.tmogType = tmogType
                consumed = true
            end
        end

        -- Check for weapon subtype aliases (auto-infer type = "weapon")
        if not consumed then
            local weaponSub = WEAPON_SUBTYPE_ALIASES[word]
            if weaponSub then
                filters.tmogSubType = weaponSub
                if not filters.tmogType then
                    filters.tmogType = "weapon"
                end
                consumed = true
            end
        end

        -- Check for armor subtype aliases (auto-infer type = "armor set")
        if not consumed then
            local armorSub = ARMOR_SUBTYPE_ALIASES[word]
            if armorSub then
                filters.tmogSubType = armorSub
                if not filters.tmogType then
                    filters.tmogType = "armor set"
                end
                consumed = true
            end
        end

        -- Unrecognized word -> name filter
        if not consumed then
            tinsert(unrecognized, word)
        end

        i = i + 1
    end

    -- Step 3: Build final name filter from quoted parts + unrecognized words
    local nameParts = {}
    for _, part in ipairs(quotedParts) do
        local trimmed = strtrim(part)
        if trimmed ~= "" then
            tinsert(nameParts, trimmed)
        end
    end
    for _, part in ipairs(unrecognized) do
        tinsert(nameParts, part)
    end

    if #nameParts > 0 then
        filters.nameFilter = table.concat(nameParts, " ")
    end

    return filters
end

-- ===================================================================================== --
-- Transmog Command Handler
-- ===================================================================================== --

-- Handle the tmog command: gem tmog [type] [subtype] [name filter]
function TSM:HandleTransmogCommand(sender, args)
    -- If no args provided, send help message
    if not args or args == "" then
        TSM:SendTransmogHelpMessage(sender)
        return
    end

    -- Check for help commands
    local argsLower = strlower(args)
    if argsLower == "?" or argsLower == "help" then
        TSM:SendTransmogHelpMessage(sender)
        return
    end

    -- Parse all arguments into structured filters
    local filters = TSM:ParseTransmogArguments(args)

    -- Check if any filter was recognized
    local hasAnyFilter = filters.tmogType or filters.tmogSubType or filters.nameFilter or filters.isFree

    if not hasAnyFilter then
        TSM:SendTransmogHelpMessage(sender)
        return
    end

    -- Get matching items
    local matchingItems = TSM:FilterTransmogItems(filters)

    if #matchingItems == 0 then
        SendChatMessage(L["No matching transmog items found."], "WHISPER", nil, sender)
        return
    end

    -- Send responses (up to 50 items, 3 per message)
    TSM:SendTransmogResponses(sender, matchingItems)
end

-- ===================================================================================== --
-- Filtering
-- ===================================================================================== --

-- Filter transmog items by filters table
function TSM:FilterTransmogItems(filters)
    local items = TSM.db.profile.transmogs.itemList
    local results = {}

    for _, item in ipairs(items) do
        if TSM:TransmogItemMatchesFilter(item, filters) then
            tinsert(results, item)
        end
    end

    return results
end

-- Check if a transmog item matches all filter criteria
function TSM:TransmogItemMatchesFilter(item, filters)
    if not filters then
        return true
    end

    -- Check stock status - only show items in stock
    -- Items with inStock == nil (never checked) are still shown
    if item.inStock == false then
        return false
    end

    -- Check free filter - only show items with no price or price == 0
    if filters.isFree then
        if item.price and item.price > 0 then
            return false
        end
    end

    -- Check type match
    if filters.tmogType then
        if not item.tmogType or strlower(item.tmogType) ~= strlower(filters.tmogType) then
            return false
        end
    end

    -- Check subtype match
    if filters.tmogSubType then
        if not item.tmogSubType or strlower(item.tmogSubType) ~= strlower(filters.tmogSubType) then
            return false
        end
    end

    -- Check name filter (case-insensitive contains)
    if filters.nameFilter then
        local itemName = strlower(item.name or "")
        local searchName = strlower(filters.nameFilter)
        if not strfind(itemName, searchName, 1, true) then
            return false
        end
    end

    return true
end

-- ===================================================================================== --
-- Response Functions
-- ===================================================================================== --

-- Format money as gold only (g)
function TSM:FormatGoldOnly(money)
    if not money or money == 0 then return "0g" end
    local gold = math.floor(money / 10000)
    return gold .. "g"
end

-- Format a transmog item for chat response
function TSM:FormatTransmogItem(item)
    local priceStr = " Free"
    if item.price and item.price > 0 then
        priceStr = " " .. TSM:FormatGoldOnly(item.price)
    end
    local itemText = item.link or item.name or "Unknown"
    return itemText .. priceStr
end

-- Send transmog item responses (3 items per message, max 50 items)
function TSM:SendTransmogResponses(sender, items)
    local maxItems = min(#items, 50)

    -- Send 3 items per message
    for i = 1, maxItems, 3 do
        local parts = {}
        for j = 0, 2 do
            local idx = i + j
            if idx <= maxItems then
                tinsert(parts, TSM:FormatTransmogItem(items[idx]))
            end
        end
        local response = table.concat(parts, ", ")
        SendChatMessage(response, "WHISPER", nil, sender)
    end
end

-- Send help message for tmog command
function TSM:SendTransmogHelpMessage(sender)
    local prefix = TSM.db.profile.commandPrefix or ""
    local cmdPrefix = (prefix ~= "") and (prefix .. " ") or ""
    SendChatMessage("Welcome to the Transmog Shop! Browse cosmetic items using chat messages.", "WHISPER", nil, sender)
    SendChatMessage("Usage Examples: '" .. cmdPrefix .. "tmog mount', '" .. cmdPrefix .. "tmog weapon sword', '" .. cmdPrefix .. "tmog windfury'", "WHISPER", nil, sender)
    SendChatMessage("Types: weapon, mount, pet, set, shield, tabard, misc, illusions, altars, free", "WHISPER", nil, sender)
    SendChatMessage("Weapon subtypes: sword, axe, mace, dagger, staff, polearm, bow, gun, crossbow, wand, thrown", "WHISPER", nil, sender)
    SendChatMessage("Armor subtypes: head, shoulders, chest, wrist, gloves, waist, legs, feet, back", "WHISPER", nil, sender)
    SendChatMessage("Name filter: use quotes for multi-word search, e.g. " .. cmdPrefix .. "tmog \"fire sword\"", "WHISPER", nil, sender)
    SendChatMessage("Example: '" .. cmdPrefix .. "tmog weapon sword' or '" .. cmdPrefix .. "tmog name fire'", "WHISPER", nil, sender)
end
