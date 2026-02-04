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
    -- One-hand / Two-hand filters
    ["1h"] = "1h", onehand = "1h", onehanded = "1h",
    ["1main"] = "1h", unemain = "1h",       -- FR
    ["1mano"] = "1h", unamano = "1h",       -- ES
    ["2h"] = "2h", twohand = "2h", twohanded = "2h",
    ["2mains"] = "2h", deuxmains = "2h",    -- FR
    ["2manos"] = "2h", dosmanos = "2h",     -- ES
    -- Main hand / Off hand filters
    mh = "mh", mainhand = "mh",
    mainprinc = "mh",                       -- FR
    manoprinc = "mh",                       -- ES
    oh = "oh", offhand = "oh",
    mainsec = "oh",                         -- FR
    manosec = "oh",                         -- ES
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
    -- One-hand / Two-hand filters (by equipLoc)
    ["1h"] = { equipLocs = {"INVTYPE_WEAPON", "INVTYPE_WEAPONMAINHAND", "INVTYPE_WEAPONOFFHAND"} },
    ["2h"] = { equipLoc = "INVTYPE_2HWEAPON" },
    mh = { equipLoc = "INVTYPE_WEAPONMAINHAND" },
    oh = { equipLocs = {"INVTYPE_WEAPONOFFHAND", "INVTYPE_HOLDABLE"} },
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

-- ===================================================================================== --
-- Level/iLevel Filter Keywords (Multilingual: EN/FR/ES)
-- ===================================================================================== --

-- Level filter keywords (required player level)
GD.LEVEL_KEYWORDS = {
    -- Range syntax
    lvl = "level", level = "level",
    niveau = "level",   -- FR
    nivel = "level",    -- ES
    -- Minimum only
    minlvl = "minlevel", ["min-lvl"] = "minlevel", minlevel = "minlevel",
    -- Maximum only
    maxlvl = "maxlevel", ["max-lvl"] = "maxlevel", maxlevel = "maxlevel",
}

-- Item level filter keywords
GD.ILVL_KEYWORDS = {
    -- Range syntax
    ilvl = "ilvl", itemlevel = "ilvl", ["item-level"] = "ilvl",
    niveauobjet = "ilvl",   -- FR
    nivelobj = "ilvl",      -- ES
    -- Minimum only
    minilvl = "minilvl", ["min-ilvl"] = "minilvl",
    -- Maximum only
    maxilvl = "maxilvl", ["max-ilvl"] = "maxilvl",
}

-- ===================================================================================== --
-- Stat Aliases (Multilingual: EN/FR/ES)
-- ===================================================================================== --

-- Stat aliases -> canonical stat key
GD.STAT_ALIASES = {
    -- Strength
    str = "STRENGTH", strength = "STRENGTH",
    force = "STRENGTH",     -- FR
    fuerza = "STRENGTH",    -- ES

    -- Agility
    agi = "AGILITY", agility = "AGILITY",
    agilite = "AGILITY",    -- FR
    agilidad = "AGILITY",   -- ES

    -- Intellect
    int = "INTELLECT", intellect = "INTELLECT",
    intelligence = "INTELLECT", -- FR
    intelecto = "INTELLECT",    -- ES

    -- Spirit
    spi = "SPIRIT", spirit = "SPIRIT",
    esprit = "SPIRIT",      -- FR
    espiritu = "SPIRIT",    -- ES

    -- Stamina
    sta = "STAMINA", stamina = "STAMINA",
    endurance = "STAMINA",  -- FR
    aguante = "STAMINA",    -- ES

    -- Spell Power
    sp = "SPELL_POWER", spellpower = "SPELL_POWER", ["spell-power"] = "SPELL_POWER",
    puissancesorts = "SPELL_POWER",     -- FR
    poderhechizo = "SPELL_POWER",       -- ES

    -- Attack Power
    ap = "ATTACK_POWER", attackpower = "ATTACK_POWER", ["attack-power"] = "ATTACK_POWER",
    puissanceattaque = "ATTACK_POWER",  -- FR
    poderataque = "ATTACK_POWER",       -- ES

    -- Crit
    crit = "CRIT_RATING", critical = "CRIT_RATING",
    critique = "CRIT_RATING",   -- FR
    critico = "CRIT_RATING",    -- ES

    -- Haste
    haste = "HASTE_RATING",
    hate = "HASTE_RATING",      -- FR
    celeridad = "HASTE_RATING", -- ES

    -- Hit
    hit = "HIT_RATING",
    toucher = "HIT_RATING",     -- FR
    golpe = "HIT_RATING",       -- ES

    -- Expertise
    exp = "EXPERTISE_RATING", expertise = "EXPERTISE_RATING",
    pericia = "EXPERTISE_RATING",   -- ES

    -- ===================================================================================== --
    -- WotLK-specific Stats (confirmed on Ascension)
    -- ===================================================================================== --

    -- MP5 (Mana per 5 seconds)
    mp5 = "MP5", manaregen = "MP5",
    mana5 = "MP5",              -- FR/ES

    -- Spell Damage (separate from Spell Power in WotLK)
    sd = "SPELL_DAMAGE", spelldmg = "SPELL_DAMAGE", spelldamage = "SPELL_DAMAGE",
    degatsorts = "SPELL_DAMAGE",    -- FR
    danomagico = "SPELL_DAMAGE",    -- ES

    -- Armor Penetration
    armpen = "ARMOR_PEN", armorpen = "ARMOR_PEN",
    penarmure = "ARMOR_PEN",        -- FR
    penarmadura = "ARMOR_PEN",      -- ES

    -- Spell Penetration
    spellpen = "SPELL_PEN",
    pensorts = "SPELL_PEN",         -- FR
    penhechizo = "SPELL_PEN",       -- ES

    -- Block Rating
    block = "BLOCK_RATING", bl = "BLOCK_RATING",
    blocage = "BLOCK_RATING",       -- FR
    bloqueo = "BLOCK_RATING",       -- ES

    -- Parry Rating
    parry = "PARRY_RATING",
    parade = "PARRY_RATING",        -- FR
    parada = "PARRY_RATING",        -- ES

    -- Dodge Rating
    dodge = "DODGE_RATING",
    esquive = "DODGE_RATING",       -- FR
    esquivar = "DODGE_RATING",      -- ES

    -- Defense Rating
    def = "DEFENSE_RATING", defense = "DEFENSE_RATING",
    defensa = "DEFENSE_RATING",     -- ES
}

-- Maps canonical stat keys to WoW ITEM_MOD_* constants (used by GetItemStats)
GD.STAT_TO_ITEM_MOD = {
    -- Base stats
    STRENGTH = "ITEM_MOD_STRENGTH_SHORT",
    AGILITY = "ITEM_MOD_AGILITY_SHORT",
    INTELLECT = "ITEM_MOD_INTELLECT_SHORT",
    SPIRIT = "ITEM_MOD_SPIRIT_SHORT",
    STAMINA = "ITEM_MOD_STAMINA_SHORT",
    -- Offensive ratings
    SPELL_POWER = "ITEM_MOD_SPELL_POWER_SHORT",
    ATTACK_POWER = "ITEM_MOD_ATTACK_POWER_SHORT",
    CRIT_RATING = "ITEM_MOD_CRIT_RATING_SHORT",
    HASTE_RATING = "ITEM_MOD_HASTE_RATING_SHORT",
    HIT_RATING = "ITEM_MOD_HIT_RATING_SHORT",
    EXPERTISE_RATING = "ITEM_MOD_EXPERTISE_RATING_SHORT",
    -- WotLK-specific stats (confirmed on Ascension)
    MP5 = "ITEM_MOD_POWER_REGEN0_SHORT",                    -- Confirmed
    SPELL_DAMAGE = "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT",      -- Confirmed
    ARMOR_PEN = "ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT",  -- Confirmed
    -- Defensive ratings (confirmed on Ascension)
    BLOCK_RATING = "ITEM_MOD_BLOCK_RATING_SHORT",           -- Confirmed
    PARRY_RATING = "ITEM_MOD_PARRY_RATING_SHORT",           -- Confirmed
    DODGE_RATING = "ITEM_MOD_DODGE_RATING_SHORT",           -- Confirmed
    -- Deduced from WotLK convention
    SPELL_PEN = "ITEM_MOD_SPELL_PENETRATION_SHORT",
    DEFENSE_RATING = "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT",
}
