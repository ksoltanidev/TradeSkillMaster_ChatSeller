-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Transmogs Feature
-- Transmog lookup command handling and filtering
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")

-- Pagination
local ITEMS_PER_PAGE = 50

-- ===================================================================================== --
-- Transmog Type/Subtype Data
-- ===================================================================================== --

-- Base types
local TMOG_TYPES = {
    "weapon", "mount", "pet", "whistle", "demon", "incarnation", "armor set", "shield", "tabard", "misc", "illusions", "altars",
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
    whistle = "whistle", whistles = "whistle", sifflet = "whistle", sifflets = "whistle", silbato = "whistle", silbatos = "whistle",
    demon = "demon", demons = "demon", ["démon"] = "demon", ["démons"] = "demon", demonio = "demon", demonios = "demon",
    incarnation = "incarnation", incarnations = "incarnation", incarnacion = "incarnation", incarnaciones = "incarnation",
    wings = "wings",
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
    glaive = "glaive", glaives = "glaive",
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

-- Class subtype aliases -> canonical subtype name (no type inference)
local CLASS_SUBTYPE_ALIASES = {
    warrior = "warrior", guerrier = "warrior", guerrero = "warrior",
    paladin = "paladin",
    hunter = "hunter", chasseur = "hunter", cazador = "hunter",
    rogue = "rogue", voleur = "rogue", picaro = "rogue",
    priest = "priest", pretre = "priest", sacerdote = "priest",
    shaman = "shaman", chaman = "shaman",
    mage = "mage",
    warlock = "warlock", demoniste = "warlock", brujo = "warlock",
    druid = "druid", druide = "druid", druida = "druid",
}

-- ===================================================================================== --
-- Argument Parsing
-- ===================================================================================== --

-- Parse transmog command arguments into structured filters
function TSM:ParseTransmogArguments(args)
    local filters = {
        tmogType = nil,
        tmogSubType = nil,
        tmogHand = nil,
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

        -- Check for "new" filter keyword
        if not consumed then
            if word == "new" or word == "nouveau" or word == "nuevo" then
                filters.isNew = true
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

        -- Check for class subtype aliases (no type inference)
        if not consumed then
            local classSub = CLASS_SUBTYPE_ALIASES[word]
            if classSub then
                filters.tmogSubType = classSub
                consumed = true
            end
        end

        -- Check for hand filter (1h/2h)
        if not consumed then
            if word == "1h" or word == "1main" or word == "1mano" then
                filters.tmogHand = "1h"
                if not filters.tmogType then
                    filters.tmogType = "weapon"
                end
                consumed = true
            elseif word == "2h" or word == "2main" or word == "2mano" then
                filters.tmogHand = "2h"
                if not filters.tmogType then
                    filters.tmogType = "weapon"
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
    -- Auto add friend if enabled
    if TSM.db.profile.transmogs.autoAddFriend then
        AddFriend(sender)
    end

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
    local hasAnyFilter = filters.tmogType or filters.tmogSubType or filters.tmogHand or filters.nameFilter or filters.isFree or filters.isNew

    if not hasAnyFilter then
        TSM:SendTransmogHelpMessage(sender)
        return
    end

    -- Record last tmog search for this player
    local pd = TSM:GetPlayerData(TSM:NormalizeName(sender))
    pd.lastTmogSearch = args
    pd.lastTmogSearchTime = time()
    pd.lastTmogPage = 1

    -- Get matching items
    local matchingItems = TSM:FilterTransmogItems(filters)

    if #matchingItems == 0 then
        SendChatMessage(L["No matching transmog items found."], "WHISPER", nil, sender)
        return
    end

    -- Send responses (first page)
    TSM:SendTransmogResponses(sender, matchingItems, 1)
end

-- Handle "+" / "more" pagination command
function TSM:HandleTransmogMoreCommand(sender)
    local pd = TSM:GetPlayerData(TSM:NormalizeName(sender))
    if not pd or not pd.lastTmogSearch or pd.lastTmogSearch == "" then
        return  -- no previous search, ignore silently
    end

    -- Re-run the last search
    local filters = TSM:ParseTransmogArguments(pd.lastTmogSearch)
    local matchingItems = TSM:FilterTransmogItems(filters)

    -- Advance to next page
    local nextPage = (pd.lastTmogPage or 1) + 1
    pd.lastTmogPage = nextPage

    -- Check if there are items for this page
    local startIdx = (nextPage - 1) * ITEMS_PER_PAGE + 1
    if startIdx > #matchingItems then
        SendChatMessage(L["No more results."], "WHISPER", nil, sender)
        return
    end

    TSM:SendTransmogResponses(sender, matchingItems, nextPage)
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

    -- Sort by price ascending (free items first)
    table.sort(results, function(a, b)
        return (a.price or 0) < (b.price or 0)
    end)

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

    -- Hide unpublished items from chat (nil = published for backward compat)
    if item.published == false then
        return false
    end

    -- Check free filter - only show items with no price or price == 0
    if filters.isFree then
        if item.price and item.price > 0 then
            return false
        end
    end

    -- Check new filter - only show items available within the last 3 days
    if filters.isNew then
        if not item.availableSince or (time() - item.availableSince) >= 3 * 24 * 3600 then
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

    -- Check hand match (1h/2h)
    if filters.tmogHand then
        if not item.tmogHand or item.tmogHand ~= filters.tmogHand then
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

-- Send transmog item responses (3 items per message, paginated)
function TSM:SendTransmogResponses(sender, items, page)
    page = page or 1
    local startIdx = (page - 1) * ITEMS_PER_PAGE + 1
    local endIdx = min(startIdx + ITEMS_PER_PAGE - 1, #items)

    -- Send 3 items per message
    for i = startIdx, endIdx, 3 do
        local parts = {}
        for j = 0, 2 do
            local idx = i + j
            if idx <= endIdx then
                tinsert(parts, TSM:FormatTransmogItem(items[idx]))
            end
        end
        local response = table.concat(parts, ", ")
        SendChatMessage(response, "WHISPER", nil, sender)
    end

    -- "More results" message if there are remaining items
    local remaining = #items - endIdx
    if remaining > 0 then
        SendChatMessage(
            format(L["There are %d more results. Send \"+\" or \"more\" to see the next page."], remaining),
            "WHISPER", nil, sender
        )
    end

    -- Buy promo (only on first page to avoid spam)
    if page == 1 then
        local prefix = TSM.db.profile.commandPrefix or ""
        local cmdPrefix = (prefix ~= "") and (prefix .. " ") or ""
        SendChatMessage(
            format(L["Make an offer by sending \"%sbuy [ItemLink]\". You can add the price to make an offer under the set price \"%sbuy [ItemLink] 100g\"."],
                cmdPrefix, cmdPrefix),
            "WHISPER", nil, sender
        )
    end
end

-- Send help message for tmog command. Never use "|" char because its throws an error.
function TSM:SendTransmogHelpMessage(sender)
    local prefix = TSM.db.profile.commandPrefix or ""
    local cmdPrefix = (prefix ~= "") and (prefix .. " ") or ""
    SendChatMessage("Welcome to the Transmog Shop! Browse cosmetic items using chat messages.", "WHISPER", nil, sender)
    SendChatMessage("Usage Examples: '" .. cmdPrefix .. "tmog mount', '" .. cmdPrefix .. "tmog weapon sword', '" .. cmdPrefix .. "tmog windfury'", "WHISPER", nil, sender)
    SendChatMessage("Types: weapon, mount, pet, whistle, demon, incarnation, wings, set, shield, tabard, misc, illusions, altars, free, new", "WHISPER", nil, sender)
    SendChatMessage("Weapon subtypes: sword, axe, mace, dagger, staff, polearm, glaive, bow, gun, crossbow, wand, thrown, 1h, 2h", "WHISPER", nil, sender)
    SendChatMessage("Armor subtypes: head, shoulders, chest, wrist, gloves, waist, legs, feet, back", "WHISPER", nil, sender)
    SendChatMessage("Class subtypes: warrior, paladin, hunter, rogue, priest, shaman, mage, warlock, druid", "WHISPER", nil, sender)
    SendChatMessage("Name filter: use quotes for multi-word search, e.g. " .. cmdPrefix .. "tmog \"fire sword\"", "WHISPER", nil, sender)
    SendChatMessage("Example: '" .. cmdPrefix .. "tmog weapon sword' or '" .. cmdPrefix .. "tmog fire'", "WHISPER", nil, sender)
end
