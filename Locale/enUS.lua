-- Localization for TradeSkillMaster_ChatSeller

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_ChatSeller", "enUS", true)
if not L then return end

-- Module name
L["ChatSeller"] = true

-- Tab labels
L["Prices"] = true
L["Gears"] = true
L["Transmogs"] = true
L["Options"] = true

-- Option labels (placeholders for future)
L["Enable ChatSeller"] = true
L["ChatSeller enabled"] = true
L["ChatSeller disabled"] = true

-- Descriptions
L["Toggle the ChatSeller module"] = true
L["Opens the TSM window to the ChatSeller page"] = true

-- Options Tab - Command Prefix
L["General Settings"] = true
L["Command Prefix"] = true
L["Command Prefix is used by all chat features. Example: If prefix is 'gem', users whisper 'gem price [item]' to get prices."] = true
L["The prefix for all chat commands (e.g., 'gem' for 'gem price [item]')"] = true

-- Prices Tab
L["Price Lookup"] = true
L["Enable Price Lookup"] = true
L["Allow users to whisper you for price information."] = true
L["When enabled, other players can whisper you with:"] = true
L["Response format:"] = true
L["[Item] There were X auctions Y ago, starting from Z. Average price is W."] = true

-- Price Response Messages
L["%s There were %d auctions %s ago, starting from %s. Average price is %s."] = true
L["%s No auction data available."] = true
L["N/A"] = true
L["unknown"] = true

-- Gears Tab
L["Gear Lookup"] = true
L["Enable Gear Lookup"] = true
L["Allow users to whisper you for gear listings."] = true
L["Categories: cloth, leather, mail, plate, neck, ring, trinket, back, weapon"] = true
L["Armor slots: head, shoulders, chest, wrist, gloves, waist, legs, feet"] = true
L["Weapons: sword, axe, mace, dagger, staff, polearm, bow, gun, crossbow, wand, shield"] = true
L["Add Gear Item"] = true
L["Gear List"] = true
L["No gear items. Add items above."] = true
L["No matching gear found."] = true
L["Item link (Shift+Click item)"] = true
L["Price (gold)"] = true
L["Item"] = true
L["Price"] = true
L["Type"] = true
L["Slot"] = true
L["Source"] = true
L["Add"] = true
L["Delete"] = true
L["Clear All"] = true
L["Please enter an item link."] = true
L["Invalid item link or item not cached."] = true
L["%s is not equippable gear."] = true
L["%s is already in the list."] = true
L["Added %s to gear list."] = true
L["items"] = true

-- Gear Help Message
L["Gear Shop - Usage:"] = true
L["Example: %s gear cloth head"] = true
L["Accepts English, French and Spanish keywords."] = true

-- Transmogs Tab
L["Transmog Lookup"] = true
L["Enable Transmog Lookup"] = true
L["Allow users to whisper you for transmog listings."] = true
L["Types: weapon, mount, pet, set, shield, tabard, misc, illusions, altars"] = true
L["Subtypes: sword, axe, mace, dagger, staff, polearm, bow, gun, crossbow, wand, thrown"] = true
L["Armor subtypes: head, shoulders, chest, wrist, gloves, waist, legs, feet, back"] = true
L["Add Transmog Item"] = true
L["Transmog List"] = true
L["No transmog items. Add items above."] = true
L["No matching transmog items found."] = true
L["SubType"] = true
L["%s is already in the transmog list."] = true
L["Added %s to transmog list."] = true
L["Updated %s in transmog list."] = true
L["All"] = true
L["Free"] = true
L["Filter"] = true

-- Stock Tracking
L["Refresh Stock"] = true
L["Stock refreshed: %d in stock, %d out of stock."] = true
L["ItemTracker not loaded."] = true
L["Out of Stock"] = true

-- GuildBank Integration
L["Sync Tmog"] = true
L["No guild bank tab selected."] = true
L["Tmog sync: added %d items (%d skipped)."] = true

-- Buy Command
L["Item not found in transmog list."] = true
L["Item is out of stock."] = true
L["Offer received for %s at %sg. I'll get back to you!"] = true
L["You already have a pending offer for %s."] = true

-- Offers Window
L["Tmog Offers"] = true
L["Toggle Tmog Offers window"] = true
L["Buyer"] = true
L["Status"] = true
L["Actions"] = true
L["Offered"] = true
L["Accepted"] = true
L["CoD Sent"] = true
L["Accept"] = true
L["Refuse"] = true
L["Ask How"] = true
L["CoD"] = true
L["Gather All"] = true
L["No offers yet."] = true
L["I accept your offer for %s at %sg. Trade or CoD?"] = true
L["How would you like to receive %s? Trade or CoD?"] = true
L["Mailbox must be open to send CoD."] = true
L["Item not found in your bags."] = true
L["CoD sent for %s to %s."] = true
L["Add Offer"] = true
L["Cancel"] = true
L["Please enter an item link and a buyer name."] = true
L["Manually added offer for %s from %s."] = true
L["Confirm"] = true
