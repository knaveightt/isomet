> **Visual/tabletop update:** See [ART_DIRECTION.md](ART_DIRECTION.md). Rendering now shows connected discovered rooms with scrolling, zoom and persistent fog. The campaign rules below remain current; descriptions of the preceding art and title image are historical where superseded.

# Miswander — master-plan implementation

This document maps the current Lua/LÖVE campaign to the supplied **Miswander Master Plan, design draft 1.0, October 28, 2026**. The PDF is design input. Proposed prices and future content are not instructions to create a shop, configure payments, or make external purchases. The latest request specifically selects the 2D game and match-three as the initial passage minigame.

## Playable scope

The campaign includes the four named environments, all 32 named door destinations, their required-item chains, the Warden/Pip mystery, origin-specific traces, safe early inspections, optional rooms/shortcuts, permanent quest progression, lives and recovery, satchel compartments, optional crafting, and a checkpointed rescue ending.

It is a **campaign prototype**, not a production adaptation of every bespoke encounter or a released mobile game. In particular, hazard and guardian rooms use a shared timing challenge, and most room discoveries and later narrative scenes are presented through readable panels rather than full animation. The existing 12-room random escape mode has been superseded by an authored campaign graph with generated room geometry. Its old saves remain untouched.

The three-second splash now uses an original bright procedural portal diorama matching the new art. LÖVE still defers character images, room loading and campaign setup until the splash has been displayed. The older PDF-derived image is retained as an unused reference in `assets/`, with provenance in `assets/NOTICE.md`.

## Source responsibilities

| File | Responsibility |
| --- | --- |
| `main.lua` | Deferred splash/setup, callbacks, state routing, checkpoint integration, floor movement, room presentation and toolbar |
| `campaign.lua` | Authored environments, 32 door records, dependencies, origin identity, corridor graphs and campaign validation |
| `progress.lua` | Engine-independent quest state, inventory derivation, one-time rewards, lives, regeneration, free economy and text serialization |
| `adventure.lua` | Passage challenges, inspection, task dispatch, hazards/guardians, notebook, map, hints, satchel, dialogue and finale |
| `match3.lua` | Engine-independent board creation, legal swaps, match detection, cascades, moves, goals and dead-board recovery |
| `savefile.lua` | Temporary writes, replacement, backup/rollback and recovery-file reading |
| `scenery.lua` | Shaded isometric buildings, gabled roofs, planting, recurring home props and Pip |
| `visual.lua` | Shared palette, parchment cards, tactile controls, icons, roof geometry and bright void |
| `tabletop.lua` | Connected room placement, bridge rendering, persistent fog presentation, camera, zoom/pan and animated crossings |
| `world.lua` | Existing room-text encoding and parsing; legacy generator retained for its existing tests |
| `characters.lua` | Existing eight traveler appearances and name entry |
| `intro.lua` | Location selection and animated origin-specific abduction |
| `pixel_font.lua` | Crisp image-font lettering for the animated introductions |
| `conf.lua` | Miswander window title; existing save identity retained |

No Godot source or existing executable archive is updated by this change.

## Campaign geometry and stable IDs

Each environment has fifteen room records: seven corridor spaces and eight destination interiors. For level index `l`, local slot `s` maps to `(l-1)*15+s`. Slots 1–7 are corridor anchors; slots 8–15 are doors 1–8. IDs remain stable across launches and regenerated dimensions.

The local corridor topology follows the plan:

```text
Arrival ↔ Upper ↔ Outer ↔ Lower ↔ Echo ↔ Arrival
                              ↘     ↙
                           Guardian Approach
                                  ↕
                           Guardian interior
                                  ↕
                             Exit Landing
                                  ↕
                            Exit / finale room
```

Doors 1 and 4 branch from Arrival; door 2 from Upper; door 3 from Outer; door 5 from Lower; door 6 from Echo. Optional door 4 reveals a panel-operated side exit to Echo, saved as a shortcut. This shortcut obeys the same first-time match-three unlock rule as other passages.

The four local graphs are separate geometry components. Completing each environment's exit and acknowledging its story panel moves the player to the next environment's arrival. The player cannot bypass the guardian by walking from its unsolved interior to Exit Landing. A final portal exists only in the companion chamber and does not automatically end the campaign just by touching it; the finale's key and sequence checks control rescue.

Dimensions and off-center pillars are randomized once, then stored. Canonical room names and story metadata are attached by stable ID at load time. Room names, item dependencies and origin lore are authored in `campaign.lua`; editing a room's text geometry does not change its quest identity. The generator leaves broad central crossing paths free. Manual geometry edits are not physically pathfound.

## Passage contract and match-three rules

The new user requirement applies a minigame to the first unlock of each traversed connection, including corridor rooms. This extends the PDF's door system: an **open** door needs no quest item, but still participates in the prototype's first-time passage challenge. Locked entrances first show their missing item without charging a life or launching a board.

A passage key is an unordered pair, such as `1-8`. Winning saves that key. Crossing either direction afterward is free. Retreat resets only the unfinished board and leaves the player just inside the original room, preventing an immediate accidental retrigger. Guardian and item checks remain authoritative even for an otherwise-unlocked passage.

The initial board is 7×7, with six shape-and-color combinations. It has no pre-existing matches and at least one valid move. The objective is five horizontal/vertical lines within eighteen neighboring-swap attempts. A neighboring swap that forms no line reverts but uses one attempt; selecting nonadjacent cells does not count as a swap. A line of four or five still counts as one match; a crossing can count as two lines. Cleared cells fall and refill; cascades contribute matches. Dead boards reshuffle at no cost. There are no boosters or payments. A bounded cascade loop protects against pathological custom random functions.

Room mechanisms identified as matching tasks have their own board in addition to passage unlocking. This separates **entering a room** from **operating its inner mechanism**, allowing safe early visits before the required item is owned. Board difficulty is currently uniform; the PDF's different collection, bubble and seal objectives are not yet distinct board modes.

Mouse/touch uses two adjacent taps. Keyboard uses arrows to position a cursor and Space/Enter to select the two cells. Instructions, goal, moves, progress bar and hearts remain visible. Different piece shapes supplement color differences. The match rules are independent of graphics and use an injected RNG for testing.

## Door coverage

Each reward is deterministic and granted only once. Earlier unique rewards are retained after use; installed tools remain recorded. Door 4 rewards are never required for the main route.

| Door | Reward or state | Requirement | Current task |
| --- | --- | --- | --- |
| K1 | Potter's Mitts | None | Inspection |
| K2 | Little Tooth Key | Mitts at lever | Match-three |
| K3 | Emberglass Lens | Little Tooth Key at cache | Three safe timing crossings |
| K4 | Brass Button + shortcut | None | Warned safe/risky route choice |
| K5 | Crooked-Tooth Cog | Emberglass Lens | Match-three |
| K6 | Smith rhythm | Cog for full trace | Story inspection |
| K7 | Kiln Key | Cog + rhythm | Three timed seal actions |
| K8 | Harbor arrival | Kiln Key | Transition transcript |
| H1 | Ship's Smile Wheel | None | Inspection |
| H2 | Archive Drained | Wheel at sluice | Match-three |
| H3 | Brass Gillfish | Archive Drained | Three safe timing crossings |
| H4 | Bent Teaspoon + shortcut | None | Warned safe/risky route choice |
| H5 | Pearlglass Eye | Brass Gillfish | Match-three |
| H6 | Low-Tide Sequence | Pearlglass Eye for full trace | Story inspection |
| H7 | Harbor Key | Sequence | Three timed floodgate actions |
| H8 | Snowfair arrival | Harbor Key | Transition transcript |
| F1 | Fairground Grippers | None | Inspection |
| F2 | Laughing Mirror Sliver | Grippers at reward | Three safe timing crossings |
| F3 | Sleeping Sun | Mirror Sliver | Match-three |
| F4 | Clockwork Ticket + shortcut | None | Warned safe/risky route choice |
| F5 | Prizekeeper Key | Sleeping Sun | Non-scored picture ordering |
| F6 | Owl Shadow Clue | Prizekeeper Key for full trace | Story inspection |
| F7 | Snowfair Key | Key + clue | Three timed beam actions |
| F8 | Orchard arrival | Snowfair Key | Transition transcript |
| O1 | Dozing Stone | None | Match-three |
| O2 | Knotwake Rope | Installed Dozing Stone | Three safe timing crossings |
| O3 | Bellhead Hammer | Anchored Rope | Three safe timing crossings |
| O4 | Wooden Nest + shortcut | None | Safe refusal/route choice; keepsake retained |
| O5 | Orchard Seal | Bellhead Hammer | Match-three |
| O6 | Homeward Sequence | Orchard Seal exposes room | Story reveal |
| O7 | Orchard Key | Orchard Seal | Three timed resonant-stone actions |
| O8 | Rescue and homecoming | Orchard Key + Homeward Sequence | Four saved escape interactions |

O6 and O7 can be completed in either order. O8 remains unavailable with only one prerequisite. Initial open rooms, missing mechanism items, story traces that are still incomplete, optional exits, and safe retreat remain recoverable.

## Narrative and origin identity

The Warden initially offers help; records gradually reveal the refuge's origin. Kiln evidence establishes that familiar objects arrived earlier. Harbor records call captives replacements. Snowfair records repeat one evening. The Original Room identifies the Warden as the bereaved builder. The text does not excuse his captivity of others or introduce a love-powered engine/four-element repair mission.

Pip appears as a folded-map moth in rooms and provides optional hints. The journal records evidence, companion traces, observed failure warnings and every environment-transition transcript. Transition panels can be dismissed; their transcript has already been saved. The next arrival is committed on choosing to cross. Closing before that choice resumes at the old exit so it remains recoverable.

The opening now follows the master plan's companion identities:

- **City:** a child in an upper-floor apartment, TV portal, high-five, chair/intercom/remote motifs.
- **Suburb:** a partner at dinner, mirror portal, shared joke, dining chair/place card/garage remote motifs.
- **Midwest:** the dog at a ranch, puddle portal, fetch, barn/feed scoop/blanket motifs.

The original opposite-gender sprite selection remains for human companions; City renders that sprite at child scale. The character roster has not yet gained dedicated child art. The dog communicates through actions and traces, never written dialogue. The origin changes narrative and recurring props, never required rewards or dependencies.

The current visual pass uses generated illustrated terrain, four detailed building archetypes, rounded trees, planters, benches, chests, guardians and eight travelers. The prior minimal pixel/voxel presentation has been replaced in the world view; smooth shaded art and detailed rope bridges provide the requested casual mobile-game direction. See ART_DIRECTION.md and assets/cartoon/README.md for the current pipeline and generation prompts. Audio motifs remain unimplemented because this LÖVE build has no audio system enabled.

## Failure, checkpoint and zero-heart behavior

A scored loss or warned fatal choice costs one heart. Each attempt carries an identifier; the failure handler ignores duplicate failure events for that attempt. Timing tasks clear their active state immediately on failure. Respawn is the **current environment's arrival**, not the previous environment or the failed room's doorstep.

Persisted state includes unique tasks/rewards, opened passages, visited rooms, inspected locks, story records, warnings, shortcuts, profile, checkpoint, hearts, optional supplies and finale steps. Failed boards and timing stages reset. A completed reward cannot be farmed. Nonadjacent selections, missing items, picture-order mistakes and voluntary retreat cost no life. A scored board loses one life only if its swap allowance is exhausted before reaching the goal.

Five hearts maximum; one free heart every twenty minutes. Time away counts. Zero-heart players can return later, use their notebook and satchel, and move through already-open safe passages; new challenges and dangerous entries wait. A backward system-clock change resets the regeneration baseline rather than granting a windfall. There is no server-authoritative clock or anti-cheat claim.

`miswander-journey.txt` is non-executable, versioned text. A temporary file is replaced into place. On platforms that reject overwriting with rename, the prior file is moved to a backup first and restored on a failed final rename. If the primary file is missing, reading checks the backup. A malformed existing primary is shown as an error instead of being silently replaced. Save failures are displayed in the exploration HUD.

Normal quit, focus loss, pause, meaningful actions and ten-second exploration intervals save the journey. Focus loss also pauses simulation and lantern time. Platform process termination between events is not guaranteed; native mobile lifecycle testing remains required.

## Optional inventory, crafting and light

The satchel exposes Quest, Supplies, Materials, Memories and Wardrobe views. Known item uses are shown only after the relevant destination has been inspected. The map does not reveal undiscovered room names, although door markings visible from the current corridor are shown in the room HUD. Detailed illustrated item cards and item-to-map tracking remain future UI work.

Quest storage is unlimited and cannot be sold or consumed. The Dozing Stone and Rope show their installed/anchored states. Materials start at capacity 30, can expand by ten for 3 Scrap + 2 Thread, and have an unlimited overflow tray. Recipes can draw directly from overflow, so a full satchel cannot trap the crafting loop. Reward storage never blocks quest acquisition.

A completed matching mechanism offers an optional practice board: rewards alternate one Glow Shard and one Copper Scrap. Optional room completions grant one Thread once. A Power Cell costs 2 Shards + 1 Scrap. The player starts with one cell; another is freely claimable every twenty minutes. Each cell grants five minutes of bright light. Optional side rooms have a dim return-path glow without it. Light time pauses during puzzles, dialogue, menus, introductions and loss of focus. It is never needed to finish the rescue.

No real purchases, localized prices, store SDKs, subscriptions, ads, paid cosmetics or paid room packs are implemented. The Wardrobe reports the selected free starting look. The document's prices remain unapproved commercial proposals.

## Finale

Both Orchard prerequisites are checked. The companion opens the inner latch while the player completes four saved steps: cool a handle, redirect a flow, recognize a shadow and strike a resonant latch. No new key, consumable or paid gate is introduced. The Warden releases the catch, other captives find exits, and the written reunion returns to the selected origin. The changed object and later signal provide the sequel hook only after rescue has been resolved.

This is an interactive narrative sequence rather than the plan's full checkpointed movement escape and animated reunion. If the application closes midway, saved finale progress remains. The ending can be revisited by inspecting the companion chamber, and the notebook preserves the homecoming.

## Tests and remaining production work

Core tests cover 200 seeded campaign geometries, encoded/decoded rooms, required reward chains, unique grants, both Orchard prerequisite orders, 200 playable match-three boards, exhaustion, regeneration, serialization, crafting and overflow. Separate savefile tests simulate Windows-style replacement and rollback.

The isolated LÖVE integration runner uses actual game callbacks and valid board swaps. It covers splash deferral, character/origin input, intro completion, a first-time passage and free return, all 32 tasks, every task type, rescue, one-life failure deduplication, current-world respawn, persistence/resume and 800×600 rendering. It produces screenshots for visual review. Scripted checks do not certify a full manual playthrough or physical mobile performance.

Next production steps are bespoke room geometry and movement hazards, distinct guardian logic and art, animated discoveries/transitions/finale, audio identity, more varied and animated match-three objectives, illustrated item cards and tracking, richer origin props, mobile-safe layout/accessibility testing, native packaging and save migration/version policy. Word mode and any commercial systems require their own design and implementation decisions.


## Special pieces and passage objectives

`match3.lua` keeps a 49-element color board, a sparse `specials` map that moves with gravity, and a sparse `clay` map fixed to tile positions. Connected horizontal/vertical match runs create one special: five has priority over an intersection, which has priority over four. The player's destination tile is preferred for its birth; cascade births choose a stable tile. Newly created specials survive their creation match. Existing specials expand the cleared-cell set recursively before seals, collection counters and column gravity are resolved.

A Star/color swap activates without a normal match; two specials also activate without one. Double Stars clear all tiles. Line Sparks clear their indicated axis; Blooms clear a 3×3 area. Special hits can chain. Collection counts removed target gems, while seal progress counts unique broken fixed overlays, independently of the normal match count. No-move reshuffles retain specials and seals, consume no swaps, and produce a board without automatic starting matches.

`Match.profile(room,target)` chooses one of three modest starting move budgets from the canonical connection endpoints, so a doorway's objective does not change with direction, restart or retry. Existing unlocked passages and saved progress need no migration. Authored task/practice boards retain their existing match goals and gain the same special-piece rules. `adventure.lua` displays objective-specific progress, marks special pieces/sealed tiles, and offers a scrollable guide via mouse/touch or H; closing help resumes the exact board. Timer pressure is deferred.

Validation includes fixed special-creation/effect fixtures, invalid-swap rollback, objective-specific wins/failures, fixed seal retention, special retention on reshuffle, and real LÖVE clearing of all three objectives plus help-overlay input at 800×600.


### Puzzle rendering and effects

`puzzle_art.lua` replaces the procedural gem renderer with cached `cartoon.lua` atlas sprites. `puzzle_fx.lua` reads the presentation-only `board.events` snapshots. Rule resolution stays synchronous and independent of frame rate; effects never alter counts or use gameplay randomness. `adventure.lua` holds a brief `boardResolving` input lock and delays `finishBoard()` until effects end, preventing an earned special or final winning burst from disappearing immediately. Opening help pauses presentation time, while retreat clears it. The integration test exercises real selection callbacks and asserts that a winning callback runs once after feedback, with no extra swaps accepted during the lock.
