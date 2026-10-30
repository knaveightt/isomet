# Miswander — bright tabletop art and exploration

## Visual direction

The new presentation uses a warm, readable mobile-adventure aesthetic within Miswander's own pixel-art identity. Township is the requested reference for a welcoming miniature-world feeling, colorful buildings, clear objects and tactile controls. The implementation does not use Township images, models, interface assets or recordings.

All active graphics are drawn from original project code: 32×32 outlined travelers, gabled miniature buildings, decorated paving, planters, fruit trees, distinct miniature guardians, reward chests, cream-and-gold arches, a paper moth, sparkling puzzle pieces, parchment cards, tool icons, and the startup portal diorama. Nearest filtering keeps the character and cinematic pixel art crisp. Larger interface typography stays readable at the 800×600 minimum size.

| Environment | Palette and architecture |
| --- | --- |
| Crooked Kiln | Apricot stone, warm plaster, terracotta roof tiles, pottery and smoking chimneys |
| Upside-Down Harbor | Turquoise paving, cream waterfront cottages, boardwalks, teal roofs and misplaced sails |
| Midnight Snowfair | Pale lavender and snow, plum roofs, striped stalls and colored lanterns |
| Buried Orchard | Leaf-green paving, red-roofed barns, apple crates, planted edges and trees |

The void is a bright, drifting cloud sea with distant anonymous floating fragments. It remains an impossible place assembled from familiar objects, rather than a normal town. Dark optional rooms still have their lantern mechanic. The three introductory scenes were redrawn with warm interiors, parquet, plants, brighter clothing and a greener cornfield while preserving their established story timing. The initial city scene still takes place at night, visible through the window.

The old PDF-derived title image remains archived for provenance but is not loaded. The new three-second title is a procedural isometric portal garden using the shared palette.

## Connected tabletop

`tabletop.lua` places all fifteen room/corridor spaces of the current environment on one stable presentation grid. Rooms no longer replace one another on screen. Multiple discovered rooms render at once, connected by visible bridges, and the camera follows the player across the expanding maze.

Each room still has its own editable local coordinates, dimensions and existing quest identity. The renderer adds a presentation origin to those coordinates before applying the isometric projection:

```text
screenX = cameraOriginX + (worldX - worldY) × 30 × zoom
screenY = cameraOriginY + (worldX + worldY) × 15 × zoom - elevation × zoom
```

All room footprints are non-overlapping. Separate environments still connect through their established story transitions; the complete four-environment campaign is not flattened into one giant map.

Floors and bridges draw first. Buildings, trees, pillars, arches, Pip and the player share one world-depth ordering, based on world X+Y. Visible roofs have two shaded facets and tile lines. The player has a final foreground locator ring and arrow so it remains possible to find them behind a doorway or roof. Corner scenery is solid, with central crossing routes and all four exit approaches preserved.

Bridge entrances use `visualExits`, attached by `campaign.lua`. These are view-facing ports for the authored tabletop and are reciprocal. Original serialized exits are retained as topology data. This lets older journey files, room IDs, rewards and unordered passage-unlock keys keep working. Custom topology edits may also need changes to the view-facing port map and presentation layout.

The current version uses suspended bridge connections between floor footprints. It does not merge room tile grids into one continuous floor mesh. During a crossing, the character follows a short interpolated walk through the two arches and bridge. Logical room state and its checkpoint update when the unlock succeeds; this short visual crossing completes in about 1.1 seconds. Normal movement is held during the crossing.

## Fog and discovery

The authoritative discovery set remains `progress.seen`, already saved in the journey file. Presentation never grants quest rewards or unlocks a passage.

- Only discovered room interiors render their buildings, props, labels, pillars and story objects.
- Nearby undiscovered neighbors appear as anonymous mist banks; rooms beyond the frontier remain absent behind the cloud sea.
- Inspecting a locked entrance does not reveal its interior.
- A successful first-time passage board saves the unlock and destination discovery immediately.
- New-room fog dissipates over about one second while the camera scrolls and the character crosses.
- Revealed rooms remain clear on returning and after resuming a saved journey.
- An unlocked return path stays free; a new connection still follows the first-time match-three rule.

Automatic task dialogue no longer covers a newly revealed room. Instead, a short toast confirms the reveal; E or Inspect opens its contents when the player is ready. Item requirements, task rewards, lives, hints, crafting and the story progression are unchanged.

## Camera controls

Default zoom is 0.68, with a range from 0.38 to 1.25. The view follows the player smoothly. Mouse wheel or +/− changes zoom. Holding the right mouse button and dragging pans the tabletop. F clears the pan offset and returns to following the player. On touch, two-finger drag and pinch are wired for panning and zooming; native-device validation is still required. Puzzle/menu input takes priority and does not move the tabletop camera.

Camera offsets and zoom are session preferences, not stored journey fields. On resume or after a death/world transition, the camera recenters on the appropriate checkpoint. Previously discovered rooms still remain revealed. Optional discovered shortcuts also animate a move between their endpoints.

## Source changes

- `visual.lua`: shared colors, cards, buttons, pixel icons, clouds, isometric boxes/roof facets and title diorama.
- `scenery.lua`: four architectural themes, trees, pottery, crates, origin anchors, Pip and solid corner footprints.
- `tabletop.lua`: static placement, view ports, bridges, fog visibility/reveal animation, common depth ordering, camera and crossing movement.
- `characters.lua`: richer 32×32 sprites, highlights/outlines, stronger outfit colors, warm portrait selection cards.
- `intro.lua`: redesigned scene environments and location cards; normalized sprite drawing retains existing cinematic character proportions.
- `adventure.lua`: unified parchment presentation, tactile buttons, six faceted fantasy puzzle-piece designs, reveal toasts and view-facing map directions.
- `main.lua`: tabletop integration, zoom/pan/follow/touch controls, new icon toolbar and removal of the old single-room renderer.

## Verification

`tests/tabletop_test.lua` checks fifty layouts for non-overlapping footprints, reciprocal view-facing ports, unchanged graph destinations, unrevealed-room isolation, persistent discovery, camera traversal, pan/zoom limits, clear central navigation routes and one-time fog fades. It runs under Lua and LuaJIT.

The real LÖVE integration test now clears several corridor challenges, waits for the crossing animations and captures the expanding connected tabletop. It also captures the redesigned character/location screens, title, puzzle board, three introductions, inventory, timing challenge, ending and minimum-size view. Existing campaign, serialization, life, crafting and rescue checks remain in place.

This is a broad original art/presentation overhaul, not a claim to finished Township-scale production assets or mobile certification. The present architecture uses a compact set of themed building archetypes; unique art for each named interior, more environmental animation, high-resolution mobile layout adaptation and bespoke guardian visuals remain natural next art tasks.
