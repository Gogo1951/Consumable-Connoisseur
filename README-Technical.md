# Connoisseur — Technical Reference

This document combines architecture notes and contribution guidance for developers working on Connoisseur. For end-user documentation, see [README.md](README.md).

---

## File Map

```
Consumable-Connoisseur/
├── Consumable-Connoisseur.toc    Load order and metadata
├── Core.lua                       Event dispatch, throttling, error handling
├── Macro-Builder.lua              Macro composition and write-back
├── Minimap-Button.lua             LDB data object and minimap UI
├── Options.lua                    Settings panel
├── Data/
│   ├── Bandages.lua               Bandage item definitions
│   ├── Data-General.lua           Brand colors, defaults, conjure spell tables
│   ├── Food-and-Water.lua         Food/water/buff-food definitions
│   ├── Healthstones.lua           Healthstone item definitions
│   ├── Mana-Gems.lua              Mana gem item definitions
│   ├── Pet-Foods.lua              Hunter pet food itemLevel/diet/quest data
│   ├── Potions.lua                Health and mana potion definitions
│   ├── Scrolls.lua                Scroll item, buff, and conflict-spell data
│   └── Soulstones.lua             Soulstone item definitions
├── Locales/
│   └── enUS.lua                   English strings (other locales loaded by .toc)
└── Scanner/
    ├── Buffs.lua                  Aura inspection: Well Fed, scrolls, pet buffs
    ├── Inventory.lua              Bag scan and best-item selection
    └── Item-Data.lua              Async item data fetch and cache
```

`Data/General.lua` does **not** exist in the load order — only `Data/Data-General.lua`. If you find a `General.lua` file, it is stale and should be deleted.

---

## Architecture

### Event Loop

Core.lua owns a single hidden frame that listens for the events that should trigger a rescan: `BAG_UPDATE_DELAYED`, `PLAYER_LEVEL_UP`, `ZONE_CHANGED_NEW_AREA`, `PLAYER_TARGET_CHANGED`, `UNIT_PET`, `UNIT_AURA`, etc. All of these route through `RequestUpdate()`, which sets a "dirty" flag and a 0.5-second throttle timer. The actual rescan and macro rewrite happens on the next `OnUpdate` tick where the throttle has elapsed.

This deliberate coalescing prevents macro thrashing — looting a 30-stack of bandages fires `BAG_UPDATE_DELAYED` once, but a vendor sweep can fire it dozens of times in a few frames.

### Combat Lockdown

Macro edits via `EditMacro` are silently dropped during combat lockdown. Any update path that runs during combat sets the dirty flag and exits early; the next post-combat tick performs the deferred rewrite. `PLAYER_REGEN_ENABLED` triggers a forced rebuild to flush whatever queued up while locked.

### Scan → Compose → Write

`ns.UpdateMacros()` runs three phases:

1. **Scan** (`Scanner/Inventory.lua`): walks all bag slots, calls `ScanBags()` which iterates `best[]` per category, applying the comparison ladder (buff food preference → percent vs flat → score → vendor price → hybrid preference → bag count). Side effects: populates `ns.BestFoodID`, `ns.ScrollOverrideIDs`, `ns.PetBuffOverrideID`.

2. **Compose** (`Macro-Builder.lua`): for each consumable type in `Config`, builds the macro body string. The body is a concatenation of: tooltip line → conjure block (Mage/Warlock click handlers) → scroll block (Food only) → state-write line → action block → optional Shadowmeld suffix.

3. **Write**: hashes the composition into a state key, compares against `currentMacroState[typeName]`, and only calls `EditMacro` if the body has actually changed. Writing during combat is a no-op; the dirty flag re-runs on `PLAYER_REGEN_ENABLED`.

### Item Data Caching

`Scanner/Item-Data.lua` lazily resolves item details (name, classID, subclassID, sell price, required level, required skill) via `GetItemInfo`. First requests on a fresh client return `nil`; the addon reschedules a retry until the data is available, then writes it to `ConnoisseurDB.itemCache`. The cache is keyed by addon version — a version bump invalidates everything to pick up new fields or corrected data without leaving stale entries behind.

### State Encoding

Every macro write is preceded by computing a state key that captures every input that affects the body:

```
ITEMID(_S:scroll1,scroll2,...)?(_C(_M:mid)?(_R:rid)?)?(_SM)?
```

- `ITEMID` — primary item slotted into the macro (or `none`).
- `_S:...` — comma-separated scroll item IDs included in the additive scroll block (Food macro only, in priority order, after 255-char truncation).
- `_C` — conjure block present.
- `_M:mid` — middle-click spell ID (Ritual of Refreshment / Ritual of Souls).
- `_R:rid` — right-click spell ID (current rank).
- `_SM` — Shadowmeld suffix appended (Night Elf Water macro).

If the key matches `currentMacroState[typeName]`, the macro is byte-for-byte identical to what's already written and we skip the `EditMacro` call. This is what makes `BAG_UPDATE_DELAYED` storms cheap.

---

## Macro Composition Details

### Food Macro Layout (Mage with scrolls active)

```
#showtooltip
/cast [btn:3] Ritual of Refreshment; [btn:2] Conjure Bread(Rank N);
/stopmacro [btn:3][btn:2]
/use [@player] item:SCROLL1
/use [@player] item:SCROLL2
/run ConnFire(FOODID)
/use item:FOODID
```

Bare `#showtooltip` lets the action bar resolve the icon from the first usable line in the body. For Mages with the conjure block, that's the conjure spell — visually cuing right-click to conjure. For non-Mages, no conjure block, so it resolves to the first scroll. When no scrolls are stacked into the body (e.g. all buffs covered, or targeting a friendly player), the tooltip switches to explicit `#showtooltip item:FOODID` so the bar shows the food.

The conjure block uses `/stopmacro` to short-circuit: a right-click conjures bread and stops, never reaching the scroll or food lines. A left-click skips the conjure block entirely and runs everything below it.

### The 255-Character Limit

WoW silently truncates macro bodies at 255 characters. With a Mage Food macro carrying conjure handlers, a state-write line, the food itself, and up to six scrolls, this is tight.

Two tactics handle it:

1. **`ConnFire(itemID)` global helper** in Core.lua. The state-write line collapses from `/run ConnoisseurState.lastID=NNN;ConnoisseurState.lastTime=GetTime()` (~65 chars) to `/run ConnFire(NNN)` (~19 chars). Saves around 45 chars per macro. The 8-char name is short enough to matter and distinctive enough (Conn… prefix) to keep global-collision risk negligible.

2. **Greedy truncation** in `BuildScrollBlock()`. The builder receives the length of every other line in the body, then trims scrolls from the **back** of the priority-ordered list until the total fits 255. The Food macro therefore degrades gracefully: a non-Mage with all six scroll types fits comfortably; a Mage at level 70 with a long conjure spell name and all six scrolls drops the lowest-priority ones (Stamina, then Spirit) first.

`ns.SCROLL_CHECK_ORDER` (defined in `Data/Scrolls.lua`) is the priority list: Agility, Strength, Protection, Intellect, Spirit, Stamina. Adjusting that order changes both the check sequence and which scrolls survive truncation.

### Friendly-Player Target Handling

When the player has another friendly player targeted, `HasFriendlyPlayerTarget()` returns true and the scroll block is skipped entirely. This keeps the Food macro readable as a conjure-for-friend button — a Mage can right-click their `- Food` macro while targeting a guildie to hand them bread, without firing six scrolls on themselves first.

The macro update loop registers `PLAYER_TARGET_CHANGED` so the rebuild fires (under the 0.5s throttle) the moment the target changes. Because the state encoding includes scroll IDs, swapping in or out of a friendly-player target naturally diffs the state key and triggers a rewrite.

The same `HasFriendlyPlayerTarget()` helper is used by `GetSmartSpell()` for Mage/Warlock conjure rank downranking — when targeting a lower-level friend, the conjure rank caps at their level.

### Pet Food Override

`ns.PetBuffOverrideID` substitutes the Food slot's *itemID* with Kibler's Bits or Sporeling Snacks when the player's pet lacks the food buff and the player has the items in bags. This is intentionally a substitution rather than an additive line: only one `Well Fed` buff exists, and the player can only consume one item per macro press.

Pet buff override coexists fine with scrolls — pet food targets the pet (`/use [@pet]`), scrolls target the player. Both lines can sit in the same macro body.

### Mana Gem Uniqueness

Mana Gems are unique-equipped — the player can hold only one rank in their bag at a time. `GetSmartSpell` for the Mana Gem macro passes `checkUnique = true`, which queries `C_Item.GetItemCount` for each rank's conjured item ID and skips ranks the player already has. The result: clicking the Mana Gem macro conjures the highest rank you don't already own, so a second press immediately gives you a backup gem at the next rank down.

### Hunter Feed Pet

The Feed Pet macro is built separately by `UpdateFeedPetMacro()` because its conditional structure is unlike the consumable macros — a single button needs to dispatch to Feed, Mend, Call, Revive, or Dismiss based on modifiers, button, pet state, and combat state.

The compact form uses bracket conditional groups to stay well under 255 chars even in heavily-localized clients (German has the longest spell names):

```
/cast [mod:ctrl] Dismiss Pet; [mod:shift][@pet,dead] Revive Pet; [nopet] Call Pet; [btn:2][combat] Mend Pet; Feed Pet
/stopmacro [mod][btn:2][nopet][@pet,dead][combat]
/use item:FOODID
```

When the pet is dead and dismissed, `[nopet]` swaps to Revive Pet so a single click works regardless of pet state. Combat forces Mend Pet because Feed Pet can't be cast in combat.

---

## Saved Variables

Two scopes:

- **`ConnoisseurDB`** (account-wide): `minimap` table for LibDBIcon, `itemCache` table keyed by item ID, `version` for cache invalidation.
- **`ConnoisseurCharDB`** (per-character): `ignoreList` (set of item IDs), `settings` table with all toggle/mode/type fields. Defaults are merged from `ns.SETTINGS_DEFAULTS` on load so new settings introduced in updates pick up sensible values.

`MigrateFromLegacy()` in Core.lua handles legacy variable layouts. Add a new migration step there when changing the saved-variable schema; never silently rewrite user data.

---

## Adding a New Consumable Category

1. Add a data file in `Data/` describing item IDs, restore values, vendor prices, level requirements, and any zone restrictions or required skills. Use existing files as templates — keep the structure flat (a numeric-keyed item table) for easy diffing.
2. Add the file to the load order in `Consumable-Connoisseur.toc`.
3. Add a `Config` entry in `Data/Data-General.lua` with the macro name (use a localized string from `Locales/enUS.lua`) and a `defaultID` for the placeholder tooltip.
4. Add a `best[]` entry in `Scanner/Inventory.lua` and a branch in the `itemType` dispatch.
5. Add the `Item-Data.lua` `itemType` classification for the new category.
6. Add the macro name to `enabledMacros` defaults in `Data-General.lua`.
7. Add a localization key to `Locales/enUS.lua` (`MACRO_*` prefix).

Test against the 255-character limit with the longest possible spell names. German enables this by setting `SET locale "deDE"` in the .toc — most overflow bugs surface in deDE, frFR, or ruRU first.

---

## Adding a New Locale

Copy `Locales/enUS.lua` to `Locales/<locale>.lua`. Change the `NewLocale("Connoisseur", "<locale>", true)` call to drop the `true` (which marks the file as the default fallback). Translate every string. Add the file to the .toc immediately after `Locales/enUS.lua`.

Be conservative with macro string lengths. Macro names cap at 16 characters. The `MSG_BUG_REPORT` template can be longer but should still fit a chat line. Macro action lines that include localized spell names (Mage conjure, Warlock conjure, Hunter Mend Pet, Shadowmeld) are the most likely places to hit the 255-char cap.

---

## Common Pitfalls

- **Editing macros in combat**: silently fails. Always defer via the dirty flag.
- **Querying `GetItemInfo` cold**: returns nil on first call. Use the retry path in `Item-Data.lua`, don't loop until it succeeds.
- **Forgetting state encoding**: if you add a new input that affects the macro body, add it to the state key. Otherwise the body won't rewrite when that input changes.
- **Hardcoding spell names**: always resolve via `GetSpellInfo(spellID)`. Names vary across locales and patch revisions.
- **Stacking too many lines in Food**: anything you add to the Food macro body shrinks the budget for scrolls. If your addition is conditional, account for both the worst-case length and how it interacts with `BuildScrollBlock`.

---

## Contributing

Pull requests welcome at https://github.com/Gogo1951/Consumable-Connoisseur. For bugs or feature ideas, please open a GitHub issue with:

- Game version and locale
- Class and level
- Reproduction steps
- The relevant macro body, copied from the in-game macro window

Discussion happens on Discord: https://discord.gg/eh8hKq992Q.

When opening a PR:

- Keep changes scoped — one concern per PR is easier to review.
- Match the existing code style (4-space indent, no trailing whitespace, comments above non-obvious blocks).
- If you change saved-variable structure, add a migration step in `MigrateFromLegacy()`.
- If you change the macro body composition, walk the worst-case 255-char check on a deDE-locale Mage at max level.
- Update this document if the architecture or file map changes.