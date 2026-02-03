-- ------------------------------------------------------------------------------------- --
-- TradeSkillMaster_ChatSeller - Gears Data
-- Category aliases, filters, and lookup tables for gear system
-- ------------------------------------------------------------------------------------- --

local TSM = select(2, ...)

-- ===================================================================================== --
-- Gears Data Tables
-- ===================================================================================== --

TSM.GearsData = {}
local GD = TSM.GearsData

-- ===================================================================================== --
-- Category/Subcategory Aliases (Multilingual: EN/FR/ES)
-- ===================================================================================== --

-- Category aliases -> canonical category name (case handled at lookup time)
GD.CATEGORY_ALIASES = {
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
GD.SUBCATEGORY_ALIASES = {
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
GD.WEAPON_SUBCATEGORY_ALIASES = {
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
-- Filter Definitions
-- ===================================================================================== --

-- Category filters (by itemSubClass for armor types, by equipLoc for accessories)
GD.CATEGORY_FILTERS = {
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
GD.SUBCATEGORY_FILTERS = {
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
GD.WEAPON_FILTERS = {
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
GD.WEAPON_EQUIP_LOCS = {
    ["INVTYPE_WEAPON"] = true,
    ["INVTYPE_2HWEAPON"] = true,
    ["INVTYPE_WEAPONMAINHAND"] = true,
    ["INVTYPE_WEAPONOFFHAND"] = true,
    ["INVTYPE_RANGED"] = true,
    ["INVTYPE_RANGEDRIGHT"] = true,
    ["INVTYPE_THROWN"] = true,
}

-- Categories that support subcategories
GD.CATEGORIES_WITH_SUBCATEGORIES = {
    cloth = true,
    leather = true,
    mail = true,
    plate = true,
    weapon = true,
}

-- Valid equipment locations for gear items
GD.VALID_EQUIP_LOCS = {
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
GD.SLOT_DISPLAY_NAMES = {
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
