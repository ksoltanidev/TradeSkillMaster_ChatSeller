-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Chat-based selling automation module for TSM
-- ------------------------------------------------------------------------------------- --

-- Initialize addon namespace
local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TSM_ChatSeller", "AceEvent-3.0", "AceConsole-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ChatSeller")

-- Expose globally for other addons (e.g., AuctionsTab integration)
TSM_ChatSeller = TSM

-- Default saved variables
local savedDBDefaults = {
    profile = {
        commandPrefix = "gem",  -- Global command prefix for all features
        prices = {
            enabled = true,     -- Enable/disable price lookup feature
        },
        gears = {
            enabled = true,     -- Enable/disable gear lookup feature
            itemList = {},      -- {link, price, name, equipLoc, itemClass, itemSubClass, source}
        },
    },
}

-- ===================================================================================== --
-- Gear Category/Subcategory Aliases (Multilingual: EN/FR/ES)
-- ===================================================================================== --

-- Category aliases -> canonical category name (case handled at lookup time)
local CATEGORY_ALIASES = {
    -- Cloth armor
    cloth = "cloth", cloths = "cloth", tissu = "cloth", tela = "cloth",
    -- Leather armor
    leather = "leather", cuir = "leather", cuero = "leather",
    -- Mail armor
    mail = "mail", mailles = "mail", malla = "mail",
    -- Plate armor
    plate = "plate", plaques = "plate", placas = "plate",
    -- Neck
    neck = "neck", necklace = "neck", cou = "neck", collier = "neck", cuello = "neck", collar = "neck",
    -- Ring
    ring = "ring", rings = "ring", anneau = "ring", bague = "ring", anillo = "ring",
    -- Trinket
    trinket = "trinket", bijou = "trinket", abalorio = "trinket",
    -- Back/Cloak
    back = "back", cloak = "back", cape = "back", dos = "back", espalda = "back", capa = "back",
    -- Weapon
    weapon = "weapon", weapons = "weapon", arme = "weapon", armes = "weapon", arma = "weapon", armas = "weapon",
}

-- Armor slot subcategory aliases
local SUBCATEGORY_ALIASES = {
    -- Head
    head = "head", helm = "head", helmet = "head", tete = "head", casque = "head", cabeza = "head", casco = "head",
    -- Shoulders
    shoulders = "shoulders", shoulder = "shoulders", epaules = "shoulders", hombros = "shoulders",
    -- Chest
    chest = "chest", robe = "chest", torse = "chest", poitrine = "chest", pecho = "chest",
    -- Wrist
    wrist = "wrist", bracers = "wrist", poignets = "wrist", munecas = "wrist",
    -- Gloves
    gloves = "gloves", hands = "gloves", gants = "gloves", mains = "gloves", guantes = "gloves", manos = "gloves",
    -- Waist
    waist = "waist", belt = "waist", taille = "waist", ceinture = "waist", cintura = "waist",
    -- Legs
    legs = "legs", pants = "legs", jambes = "legs", pantalon = "legs", piernas = "legs",
    -- Feet
    feet = "feet", boots = "feet", pieds = "feet", bottes = "feet", pies = "feet", botas = "feet",
}

-- Weapon subcategory aliases
local WEAPON_SUBCATEGORY_ALIASES = {
    -- Sword
    sword = "sword", swords = "sword", epee = "sword", espada = "sword",
    -- Axe
    axe = "axe", axes = "axe", hache = "axe", hacha = "axe",
    -- Mace
    mace = "mace", maces = "mace", masse = "mace", maza = "mace",
    -- Dagger
    dagger = "dagger", daggers = "dagger", dague = "dagger", punal = "dagger",
    -- Staff
    staff = "staff", staves = "staff", baton = "staff", baston = "staff",
    -- Polearm
    polearm = "polearm", polearms = "polearm",
    -- Fist
    fist = "fist",
    -- Bow
    bow = "bow", bows = "bow", arc = "bow", arco = "bow",
    -- Gun
    gun = "gun", guns = "gun", fusil = "gun",
    -- Crossbow
    crossbow = "crossbow", crossbows = "crossbow", arbalete = "crossbow", ballesta = "crossbow",
    -- Wand
    wand = "wand", wands = "wand", baguette = "wand", varita = "wand",
    -- Thrown
    thrown = "thrown", lance = "thrown", arrojadiza = "thrown",
    -- Shield
    shield = "shield", shields = "shield", bouclier = "shield", escudo = "shield",
}

-- ===================================================================================== --
-- Gear Filter Definitions
-- ===================================================================================== --

-- Category filters (by itemSubClass for armor types, by equipLoc for accessories)
local CATEGORY_FILTERS = {
    cloth = { subClass = "Cloth" },
    leather = { subClass = "Leather" },
    mail = { subClass = "Mail" },
    plate = { subClass = "Plate" },
    neck = { equipLoc = "INVTYPE_NECK" },
    ring = { equipLoc = "INVTYPE_FINGER" },
    trinket = { equipLoc = "INVTYPE_TRINKET" },
    back = { equipLoc = "INVTYPE_CLOAK" },
    weapon = { isWeapon = true },
}

-- Armor slot subcategory filters (by equipLoc)
local SUBCATEGORY_FILTERS = {
    head = { equipLoc = "INVTYPE_HEAD" },
    shoulders = { equipLoc = "INVTYPE_SHOULDER" },
    chest = { equipLocs = {"INVTYPE_CHEST", "INVTYPE_ROBE"} },
    wrist = { equipLoc = "INVTYPE_WRIST" },
    gloves = { equipLoc = "INVTYPE_HAND" },
    waist = { equipLoc = "INVTYPE_WAIST" },
    legs = { equipLoc = "INVTYPE_LEGS" },
    feet = { equipLoc = "INVTYPE_FEET" },
}

-- Weapon subcategory filters (by itemSubClass, except shield by equipLoc)
local WEAPON_FILTERS = {
    sword = { subClasses = {"One-Handed Swords", "Two-Handed Swords"} },
    axe = { subClasses = {"One-Handed Axes", "Two-Handed Axes"} },
    mace = { subClasses = {"One-Handed Maces", "Two-Handed Maces"} },
    dagger = { subClass = "Daggers" },
    staff = { subClass = "Staves" },
    polearm = { subClass = "Polearms" },
    fist = { subClass = "Fist Weapons" },
    bow = { subClass = "Bows" },
    gun = { subClass = "Guns" },
    crossbow = { subClass = "Crossbows" },
    wand = { subClass = "Wands" },
    thrown = { subClass = "Thrown" },
    shield = { equipLoc = "INVTYPE_SHIELD" },
}

-- Equipment locations that indicate a weapon
local WEAPON_EQUIP_LOCS = {
    ["INVTYPE_WEAPON"] = true,
    ["INVTYPE_2HWEAPON"] = true,
    ["INVTYPE_WEAPONMAINHAND"] = true,
    ["INVTYPE_WEAPONOFFHAND"] = true,
    ["INVTYPE_RANGED"] = true,
    ["INVTYPE_RANGEDRIGHT"] = true,
    ["INVTYPE_THROWN"] = true,
}

-- Categories that support subcategories
local CATEGORIES_WITH_SUBCATEGORIES = {
    cloth = true,
    leather = true,
    mail = true,
    plate = true,
    weapon = true,
}

-- Valid equipment locations for gear items
local VALID_EQUIP_LOCS = {
    ["INVTYPE_HEAD"] = true,
    ["INVTYPE_NECK"] = true,
    ["INVTYPE_SHOULDER"] = true,
    ["INVTYPE_CHEST"] = true,
    ["INVTYPE_ROBE"] = true,
    ["INVTYPE_WAIST"] = true,
    ["INVTYPE_LEGS"] = true,
    ["INVTYPE_FEET"] = true,
    ["INVTYPE_WRIST"] = true,
    ["INVTYPE_HAND"] = true,
    ["INVTYPE_FINGER"] = true,
    ["INVTYPE_TRINKET"] = true,
    ["INVTYPE_CLOAK"] = true,
    ["INVTYPE_WEAPON"] = true,
    ["INVTYPE_2HWEAPON"] = true,
    ["INVTYPE_WEAPONMAINHAND"] = true,
    ["INVTYPE_WEAPONOFFHAND"] = true,
    ["INVTYPE_HOLDABLE"] = true,
    ["INVTYPE_SHIELD"] = true,
    ["INVTYPE_RANGED"] = true,
    ["INVTYPE_RANGEDRIGHT"] = true,
    ["INVTYPE_THROWN"] = true,
}

-- Display names for equipment slots
local SLOT_DISPLAY_NAMES = {
    ["INVTYPE_HEAD"] = "Head",
    ["INVTYPE_NECK"] = "Neck",
    ["INVTYPE_SHOULDER"] = "Shoulders",
    ["INVTYPE_CHEST"] = "Chest",
    ["INVTYPE_ROBE"] = "Chest",
    ["INVTYPE_WAIST"] = "Waist",
    ["INVTYPE_LEGS"] = "Legs",
    ["INVTYPE_FEET"] = "Feet",
    ["INVTYPE_WRIST"] = "Wrist",
    ["INVTYPE_HAND"] = "Hands",
    ["INVTYPE_FINGER"] = "Finger",
    ["INVTYPE_TRINKET"] = "Trinket",
    ["INVTYPE_CLOAK"] = "Back",
    ["INVTYPE_WEAPON"] = "One-Hand",
    ["INVTYPE_2HWEAPON"] = "Two-Hand",
    ["INVTYPE_WEAPONMAINHAND"] = "Main Hand",
    ["INVTYPE_WEAPONOFFHAND"] = "Off Hand",
    ["INVTYPE_HOLDABLE"] = "Held",
    ["INVTYPE_SHIELD"] = "Shield",
    ["INVTYPE_RANGED"] = "Ranged",
    ["INVTYPE_RANGEDRIGHT"] = "Ranged",
    ["INVTYPE_THROWN"] = "Thrown",
}

-- ===================================================================================== --
-- Addon Lifecycle
-- ===================================================================================== --

function TSM:OnInitialize()
    -- Initialize saved variables database
    TSM.db = LibStub("AceDB-3.0"):New("AscensionTSM_ChatSellerDB", savedDBDefaults, true)

    -- Make module references accessible on TSM object
    for moduleName, module in pairs(TSM.modules) do
        TSM[moduleName] = module
    end

    -- Register with TSM
    TSM:RegisterModule()
end

function TSM:OnEnable()
    -- Register whisper event listener
    self:RegisterEvent("CHAT_MSG_WHISPER")
end

function TSM:OnDisable()
    -- Unregister events
    self:UnregisterEvent("CHAT_MSG_WHISPER")
end

-- ===================================================================================== --
-- Chat Message Handler
-- ===================================================================================== --

function TSM:CHAT_MSG_WHISPER(event, message, sender, ...)
    -- Get prefix and build pattern (case insensitive)
    local prefix = TSM.db.profile.commandPrefix or "gem"
    local lowerMessage = strlower(message)
    local lowerPrefix = strlower(prefix)

    -- Check for price command
    if TSM.db.profile.prices.enabled then
        local pricePattern = "^" .. lowerPrefix .. "%s+price%s+"
        if strmatch(lowerMessage, pricePattern) then
            -- Extract item links from the message
            local itemLinks = TSM:ExtractItemLinks(message)
            if #itemLinks > 0 then
                -- Process each item link and send response
                for _, itemLink in ipairs(itemLinks) do
                    local response = TSM:GetPriceResponse(itemLink)
                    if response then
                        SendChatMessage(response, "WHISPER", nil, sender)
                    end
                end
            end
            return
        end
    end

    -- Check for gear command
    if TSM.db.profile.gears.enabled then
        local gearPattern = "^" .. lowerPrefix .. "%s+gear%s*(.*)$"
        local gearArgs = strmatch(lowerMessage, gearPattern)
        if gearArgs then
            TSM:HandleGearCommand(sender, gearArgs)
            return
        end
    end
end

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

-- Build price response message for an item
function TSM:GetPriceResponse(itemLink)
    -- Get item ID
    local itemID = TSMAPI:GetItemID(itemLink)
    if not itemID then return nil end

    -- Get AuctionDB addon reference
    local AuctionDB = LibStub("AceAddon-3.0"):GetAddon("TSM_AuctionDB", true)
    if not AuctionDB then
        return format(L["%s No auction data available."], itemLink)
    end

    -- Ensure data is decoded
    if AuctionDB.DecodeItemData then
        AuctionDB:DecodeItemData(itemID)
    end

    -- Check if we have data for this item
    if not AuctionDB.data or not AuctionDB.data[itemID] then
        return format(L["%s No auction data available."], itemLink)
    end

    local itemData = AuctionDB.data[itemID]

    -- Get price values
    local marketValue = TSMAPI:GetItemValue(itemLink, "DBMarket")
    local minBuyout = TSMAPI:GetItemValue(itemLink, "DBMinBuyout")
    local quantity = itemData.quantity or 0
    local lastScan = itemData.lastScan or 0

    -- Format the time difference
    local timeAgo = L["unknown"]
    if lastScan and lastScan > 0 then
        local seconds = time() - lastScan
        if seconds < 60 then
            timeAgo = format("%d sec", seconds)
        elseif seconds < 3600 then
            timeAgo = format("%d min", math.floor(seconds / 60))
        elseif seconds < 86400 then
            timeAgo = format("%d hr", math.floor(seconds / 3600))
        else
            timeAgo = format("%d days", math.floor(seconds / 86400))
        end
    end

    -- Format prices for chat
    local minBuyoutText = TSM:FormatMoneyForChat(minBuyout) or L["N/A"]
    local marketValueText = TSM:FormatMoneyForChat(marketValue) or L["N/A"]

    -- Build response message
    local response = format(
        L["%s There were %d auctions %s ago, starting from %s. Average price is %s."],
        itemLink,
        quantity,
        timeAgo,
        minBuyoutText,
        marketValueText
    )

    return response
end

-- Format money for chat (gold/silver/copper without color codes)
function TSM:FormatMoneyForChat(money)
    if not money or money == 0 then return nil end

    local gold = math.floor(money / 10000)
    local silver = math.floor((money % 10000) / 100)
    local copper = money % 100

    if gold > 0 then
        return format("%dg %ds %dc", gold, silver, copper)
    elseif silver > 0 then
        return format("%ds %dc", silver, copper)
    else
        return format("%dc", copper)
    end
end

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
        category = CATEGORY_ALIASES[words[1]]
    end

    -- Second word is subcategory (if applicable)
    if words[2] and category then
        if category == "weapon" then
            subcategory = WEAPON_SUBCATEGORY_ALIASES[words[2]]
        elseif CATEGORIES_WITH_SUBCATEGORIES[category] then
            subcategory = SUBCATEGORY_ALIASES[words[2]]
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

    local catFilter = CATEGORY_FILTERS[category]
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
        if not WEAPON_EQUIP_LOCS[item.equipLoc] then
            return false
        end
    end

    -- Check subcategory match (if provided)
    if subcategory then
        if category == "weapon" then
            -- Weapon subcategory filter
            local subFilter = WEAPON_FILTERS[subcategory]
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
            local slotFilter = SUBCATEGORY_FILTERS[subcategory]
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
            response = response .. " | " .. TSM:FormatGearItem(item2)
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
    return SLOT_DISPLAY_NAMES[equipLoc]
end

-- Send help message for gear command
function TSM:SendGearHelpMessage(sender)
    local prefix = TSM.db.profile.commandPrefix or "gem"
    SendChatMessage("Gear Shop - Usage", "WHISPER", nil, sender)
    SendChatMessage(prefix .. " gear [category] [slot]", "WHISPER", nil, sender)
    SendChatMessage("Categories - cloth, leather, mail, plate, back, neck, ring, trinket, weapon", "WHISPER", nil, sender)
    SendChatMessage("Armor slots - head, shoulders, chest, wrist, gloves, waist, legs, feet", "WHISPER", nil, sender)
    SendChatMessage("Weapons - sword, axe, mace, dagger, staff, polearm, bow, gun, crossbow, wand, shield", "WHISPER", nil, sender)
    SendChatMessage("Example - " .. prefix .. " gear cloth head", "WHISPER", nil, sender)
    SendChatMessage("Accepts English, French and Spanish keywords.", "WHISPER", nil, sender)
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

function Options:LoadGearsTab(container)
    Options.gearsContainer = container
    local prefix = TSM.db.profile.commandPrefix or "gem"
    local items = TSM.db.profile.gears.itemList

    local page = {
        {
            type = "ScrollFrame",
            layout = "Flow",
            children = {
                -- Enable/Disable Section
                {
                    type = "InlineGroup",
                    title = L["Gear Lookup"],
                    layout = "Flow",
                    fullWidth = true,
                    children = {
                        {
                            type = "CheckBox",
                            label = L["Enable Gear Lookup"],
                            settingInfo = { TSM.db.profile.gears, "enabled" },
                            tooltip = L["Allow users to whisper you for gear listings."],
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
                            text = "  " .. prefix .. " gear [category] [subcategory]",
                            fullWidth = true,
                        },
                        {
                            type = "Label",
                            text = L["Categories: cloth, leather, mail, plate, neck, ring, trinket, back, weapon"],
                            fullWidth = true,
                        },
                        {
                            type = "Label",
                            text = L["Armor slots: head, shoulders, chest, wrist, gloves, waist, legs, feet"],
                            fullWidth = true,
                        },
                        {
                            type = "Label",
                            text = L["Weapons: sword, axe, mace, dagger, staff, polearm, bow, gun, crossbow, wand, shield"],
                            fullWidth = true,
                        },
                    },
                },
                {
                    type = "HeadingLine",
                },
                -- Add Item Section
                {
                    type = "InlineGroup",
                    title = L["Add Gear Item"],
                    layout = "Flow",
                    fullWidth = true,
                    children = {
                        {
                            type = "EditBox",
                            label = L["Item link (Shift+Click item)"],
                            relativeWidth = 0.5,
                            value = Options.pendingGearLink or "",
                            callback = function(widget, _, value)
                                Options.pendingGearLink = value
                            end,
                        },
                        {
                            type = "EditBox",
                            label = L["Price (gold)"],
                            relativeWidth = 0.25,
                            value = Options.pendingGearPrice or "",
                            callback = function(widget, _, value)
                                Options.pendingGearPrice = value
                            end,
                        },
                        {
                            type = "Button",
                            text = L["Add"],
                            relativeWidth = 0.12,
                            callback = function()
                                Options:AddGearItemFromInput()
                            end,
                        },
                        {
                            type = "Button",
                            text = L["Clear All"],
                            relativeWidth = 0.12,
                            callback = function()
                                wipe(TSM.db.profile.gears.itemList)
                                Options:RefreshGearsTab()
                            end,
                        },
                    },
                },
                {
                    type = "HeadingLine",
                },
                -- Item List Section
                {
                    type = "InlineGroup",
                    title = L["Gear List"] .. " (" .. #items .. " " .. L["items"] .. ")",
                    layout = "Flow",
                    fullWidth = true,
                    children = Options:GetGearListWidgets(),
                },
            },
        },
    }

    TSMAPI:BuildPage(container, page)
end

-- Get widgets for the gear item list
function Options:GetGearListWidgets()
    local children = {}
    local items = TSM.db.profile.gears.itemList

    if #items == 0 then
        tinsert(children, {
            type = "Label",
            text = L["No gear items. Add items above."],
            fullWidth = true,
        })
        return children
    end

    -- Header row
    tinsert(children, { type = "Label", text = "|cffffd100" .. L["Item"] .. "|r", relativeWidth = 0.30 })
    tinsert(children, { type = "Label", text = "|cffffd100" .. L["Price"] .. "|r", relativeWidth = 0.12 })
    tinsert(children, { type = "Label", text = "|cffffd100" .. L["Type"] .. "|r", relativeWidth = 0.12 })
    tinsert(children, { type = "Label", text = "|cffffd100" .. L["Slot"] .. "|r", relativeWidth = 0.12 })
    tinsert(children, { type = "Label", text = "|cffffd100" .. L["Source"] .. "|r", relativeWidth = 0.12 })
    tinsert(children, { type = "Label", text = "", relativeWidth = 0.22 })

    -- Item rows
    for i, item in ipairs(items) do
        -- Source display: "AH" for AuctionsTab, "Manual" otherwise
        local sourceText = item.source == "AuctionsTab" and "|cff00ff00AH|r" or "|cffffffffManual|r"

        tinsert(children, {
            type = "Label",
            text = item.link or item.name or "Unknown",
            relativeWidth = 0.30,
        })
        tinsert(children, {
            type = "Label",
            text = item.price and TSM:FormatMoneyForChat(item.price) or L["N/A"],
            relativeWidth = 0.12,
        })
        tinsert(children, {
            type = "Label",
            text = item.itemSubClass or L["N/A"],
            relativeWidth = 0.12,
        })
        tinsert(children, {
            type = "Label",
            text = TSM:GetSlotDisplayName(item.equipLoc) or L["N/A"],
            relativeWidth = 0.12,
        })
        tinsert(children, {
            type = "Label",
            text = sourceText,
            relativeWidth = 0.12,
        })
        tinsert(children, {
            type = "Button",
            text = L["Delete"],
            relativeWidth = 0.22,
            callback = function()
                tremove(TSM.db.profile.gears.itemList, i)
                Options:RefreshGearsTab()
            end,
        })
    end

    return children
end

-- Refresh the gears tab
function Options:RefreshGearsTab()
    if Options.gearsContainer then
        Options.gearsContainer:ReleaseChildren()
        Options:LoadGearsTab(Options.gearsContainer)
    end
end

-- Add a gear item from input fields
function Options:AddGearItemFromInput()
    local link = Options.pendingGearLink
    local priceStr = Options.pendingGearPrice

    if not link or link == "" then
        TSM:Print(L["Please enter an item link."])
        return
    end

    -- Get item info
    local name, itemLink, _, _, _, itemClass, itemSubClass, _, equipLoc = GetItemInfo(link)

    if not name then
        TSM:Print(L["Invalid item link or item not cached."])
        return
    end

    -- Validate it's equippable gear
    if not equipLoc or equipLoc == "" or not VALID_EQUIP_LOCS[equipLoc] then
        TSM:Print(format(L["%s is not equippable gear."], itemLink or link))
        return
    end

    -- Check for duplicates
    for _, existing in ipairs(TSM.db.profile.gears.itemList) do
        if existing.name == name then
            TSM:Print(format(L["%s is already in the list."], itemLink or link))
            return
        end
    end

    -- Parse price (input in gold, store in copper)
    local price = nil
    if priceStr and priceStr ~= "" then
        local goldAmount = tonumber(priceStr)
        if goldAmount then
            price = goldAmount * 10000  -- Convert gold to copper
        end
    end

    -- Add to list
    tinsert(TSM.db.profile.gears.itemList, {
        link = itemLink,
        price = price,
        name = name,
        equipLoc = equipLoc,
        itemClass = itemClass,
        itemSubClass = itemSubClass,
    })

    TSM:Print(format(L["Added %s to gear list."], itemLink))

    -- Clear input fields
    Options.pendingGearLink = nil
    Options.pendingGearPrice = nil

    -- Refresh the tab
    Options:RefreshGearsTab()
end

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
            },
        },
    }

    TSMAPI:BuildPage(container, page)
end

-- ===================================================================================== --
-- External Integration API
-- ===================================================================================== --

-- Sync gear items from AuctionsTab
-- Removes all items with source="AuctionsTab" then adds new items from the provided list
-- @param items: table of {link, price, name} from AuctionsTab
-- @return number of items added
function TSM:SyncFromAuctionsTab(items)
    if not items or #items == 0 then
        return 0
    end

    local gearList = TSM.db.profile.gears.itemList

    -- Step 1: Remove all items with source="AuctionsTab"
    local removed = 0
    for i = #gearList, 1, -1 do
        if gearList[i].source == "AuctionsTab" then
            tremove(gearList, i)
            removed = removed + 1
        end
    end

    -- Step 2: Add new items (only equippable gear)
    local added = 0
    for _, item in ipairs(items) do
        local name, itemLink, _, _, _, itemClass, itemSubClass, _, equipLoc = GetItemInfo(item.link)

        -- Skip if item not cached or not equippable gear
        if name and equipLoc and equipLoc ~= "" and VALID_EQUIP_LOCS[equipLoc] then
            -- Check for duplicates (by name, excluding AuctionsTab source items we just removed)
            local isDuplicate = false
            for _, existing in ipairs(gearList) do
                if existing.name == name then
                    isDuplicate = true
                    break
                end
            end

            if not isDuplicate then
                tinsert(gearList, {
                    link = itemLink,
                    price = item.price,
                    name = name,
                    equipLoc = equipLoc,
                    itemClass = itemClass,
                    itemSubClass = itemSubClass,
                    source = "AuctionsTab",
                })
                added = added + 1
            end
        end
    end

    return added, removed
end
