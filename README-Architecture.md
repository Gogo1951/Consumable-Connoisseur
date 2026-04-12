# Architecture — Consumable Connoisseur

This document explains how the addon is structured internally, how data flows from bags to macros, and the key design decisions behind the code.

## File Map

```
Consumable-Connoisseur/
  Consumable-Connoisseur.toc   -- Load manifest and metadata
  Includes/                    -- Bundled libraries (Ace3, LibDataBroker, LibDBIcon)
  Locales/
    enUS.lua                   -- Source-of-truth locale (10 languages total)
  Data/
    General.lua                -- Colors, URLs, icons, macro config, spell tables, defaults, utility
    Scrolls.lua                -- Scroll item/buff/conflict data per stat type
    Bandages.lua               -- Raw bandage data: {healAmount, requiredFirstAid, zones?}
    Food-and-Water.lua         -- Raw food/water data: {isBuffFood, %hp, flatHP, %mp, flatMP, zones?}
    Healthstones.lua           -- Raw healthstone data: {healAmount}
    Soulstones.lua             -- Raw soulstone data: {healAmount}
    Mana-Gems.lua              -- Raw mana gem data: {manaAmount}
    Potions.lua                -- Raw potion data: {healAmount, manaAmount, zones?, requiredAlchemy?}
    Pet-Foods.lua              -- Pet food data: {itemLevel, dietID, sellPrice, questIDs?}
  Core.lua                     -- Initialization, event routing, update throttle
  Scanner.lua                  -- Bag scanning, item caching, best-item comparison, buff detection
  Macro-Builder.lua            -- Macro creation/editing, conjure spell resolution, Feed Pet logic
  Minimap-Button.lua           -- LibDBIcon button, tooltip rendering, click handlers
  Options.lua                  -- AceConfig options panel and /foodie slash command
```

## Load Order and Why It Matters

The TOC loads files in this exact sequence: Includes, Locales, Data, then Core files. This matters because each layer depends on the previous one being fully loaded.

Data files populate `ns.RawData` tables and `ns.ConjureSpells` before Core.lua runs. Core.lua initializes saved variables and registers events. Scanner.lua provides `ns.ScanBags()` which Macro-Builder.lua calls during `ns.UpdateMacros()`. Minimap-Button.lua and Options.lua are loaded last because they depend on all the above being ready.

## The Namespace (`ns`)

Every file receives the shared addon namespace via `local _, ns = ...` (or `local addonName, ns = ...` when the addon name is needed). All cross-file communication goes through `ns`. There are no global functions or variables besides the slash command registration and saved variable names declared in the TOC.

Key namespace members include `ns.Config` (macro name and default icon per consumable type), `ns.RawData` (raw item tables keyed by item ID), `ns.ConjureSpells` (Mage/Warlock spell lists sorted by rank descending), and functions like `ns.RequestUpdate()`, `ns.ScanBags()`, `ns.UpdateMacros()`, and `ns.UpdateLDB()`.

## Data Flow: Bag Change to Macro Update

The full pipeline runs every time your bags change, you level up, change zones, gain an aura, or any other triggering event fires.

**Step 1 — Event fires.** Core.lua's event handler receives events like `BAG_UPDATE_DELAYED`, `PLAYER_LEVEL_UP`, or `UNIT_AURA`. If the player is in combat, it sets a pending flag and defers until `PLAYER_REGEN_ENABLED`.

**Step 2 — Throttled update.** `ns.RequestUpdate()` sets an `OnUpdate` script with a 0.5-second throttle. This collapses rapid-fire events (e.g. multiple bag slots updating at once) into a single scan.

**Step 3 — Bag scan.** `ns.ScanBags()` in Scanner.lua iterates every bag slot. For each item, it checks the item cache (`ConnoisseurDB.itemCache`). On a cache miss, it calls `CacheItemData()` which reads `GetItemInfo()` and cross-references the raw data tables to build a structured cache entry with type, values, required levels, zone restrictions, and flags. If `GetItemInfo()` returns nil (item data not yet loaded from the server), the scan sets a retry flag.

**Step 4 — Best-item selection.** For each consumable category (Food, Water, Health Potion, etc.), the scan runs `IsBetter()` to compare candidates. The comparison priority is: buff food preferred > percentage-based > highest value > lowest vendor price > hybrid preference > fewest in bags. Scroll overrides and pet buff overrides are resolved separately before the main scan loop.

**Step 5 — Macro writing.** `ns.UpdateMacros()` in Macro-Builder.lua compares a state string for each macro type against the previously written state. If nothing changed, it skips that macro. If the state differs, it builds the macro body (tooltip line, optional conjure cast/stopmacro lines, use-item line, optional Shadowmeld line) and calls `CreateMacro()` or `EditMacro()`. The Feed Pet macro has its own dedicated function with distinct logic for pet states.

**Step 6 — LDB update.** `ns.UpdateLDB()` sets the minimap button icon to the current best food item icon and refreshes the tooltip if it's currently visible.

## Item Cache Design

The item cache lives in `ConnoisseurDB.itemCache` (account-wide saved variable) and persists across sessions. Each entry is keyed by item ID and holds pre-computed fields: `itemType`, `healthValue`, `manaValue`, `requiredLevel`, `requiredFirstAid`, `requiredAlchemy`, `price`, `isBuffFood`, `isPercent`, and `zones` (a set of allowed map IDs, or nil for unrestricted items).

Items that aren't recognized as any known consumable type get cached as the string `"IGNORE"` so they aren't re-checked on every scan. The entire cache is wiped whenever the addon version changes, which forces a full rebuild from the raw data tables on the first login after an update.

When `GetItemInfo()` returns nil for an item (server hasn't sent the data yet), the scan registers for `GET_ITEM_INFO_RECEIVED` events and sets a 2-second timer to retry. This handles the cold-cache scenario on first login gracefully.

## Scroll Override System

Scroll handling is separate from the main consumable pipeline. When the scroll feature is enabled, `ns.FindScrollOverride()` iterates the player's enabled scroll types in a fixed priority order (`ns.SCROLL_CHECK_ORDER`), finds the best available scroll of each type from bags, and checks whether the player already has that buff or a conflicting class buff of equal or greater value. The first missing scroll buff becomes the override, replacing the Food macro's item for one use.

Scroll data in Scrolls.lua defines both the item/buff mappings and a `conflictSpells` table per stat type. For example, Intellect scrolls conflict with Arcane Intellect — if the Mage buff provides >= the scroll's stat amount, the scroll is skipped.

## Conjure Spell Resolution

Macro-Builder.lua's `GetSmartSpell()` walks a spell list (sorted highest rank first) and returns the first spell the player knows whose required level is at or below a level cap. By default the cap is the player's level, but when targeting a lower-level friendly player, it drops to the target's level. This means right-clicking to conjure Water for a level 20 alt automatically picks the appropriate rank.

If the player knows spells in the list but none match the cap (extremely low-level target), it falls back to the lowest rank as a safety net.

## Hunter Feed Pet

The Feed Pet macro packs five pet management actions into a single button under the 255-character macro limit by combining WoW macro conditionals. The priority is: Ctrl = Dismiss, Shift or dead pet = Revive, no pet = Call (or Revive if dead-dismissed), right-click or combat = Mend, default = Feed + /use food. Pet food selection prefers the lowest item-level food that still gives maximum happiness (pet level minus food item level between 0 and 10), breaking ties by sell price then bag count. Quest objective foods are automatically skipped when the associated quest is active.

The dead-but-dismissed state is detected by catching `SPELL_FAILED_TARGETS_DEAD` via `UI_ERROR_MESSAGE` when Call Pet fails. This flips a flag so the macro rebuilds with Revive Pet on the next cycle.

## Saved Variable Migration

Core.lua includes a `MigrateFromLegacy()` function that runs once on login. It moves data from old flat saved variables (`CC_MinimapSettings`, `CC_ItemCache`, `CC_IgnoreList`, `CC_Settings`) into the new structured `ConnoisseurDB` and `ConnoisseurCharDB` tables, then nils out the old variables. The TOC still declares the old variable names so WoW loads them for migration, but they're cleaned up immediately.

## Combat Lockdown

All macro writes are deferred during combat lockdown. The `OnUpdate` handler checks `InCombatLockdown()` before proceeding, and the main event handler sets `isUpdatePending = true` when events fire during combat. `PLAYER_REGEN_ENABLED` triggers the deferred update.

## Localization

The addon uses AceLocale-3.0 with enUS as the source of truth. Ten locale files are loaded, but only the matching client locale activates. All user-facing strings go through `L["KEY"]` lookups. Macro names are localized but capped at 16 characters (WoW's macro name limit).
