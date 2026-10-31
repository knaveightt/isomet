# Miswander — flowing world boards

The four supplied reference images in `guidance/` guide the current environment direction. The game now places sixty distinct landmarks on irregular terrain connected by broad, curved paths. Logical room IDs still identify checkpoints, quest tasks and puzzle gates, but they no longer define square platform outlines.

## Worlds and landmarks

- **Crooked Kiln:** warm sandstone and basalt, lava channels, pottery, a pump workshop, mechanical eye, foundry and cooling aqueduct.
- **Upside-Down Harbor:** pale limestone, turquoise water, boat repair, mooring gardens, a flooded archive, conservatory and tide machinery.
- **Midnight Snowfair:** snow-dusted stone and ice, ticket and prize stalls, sleds, mirrors, lantern carousel, nursery and Glass Owl observatory.
- **Buried Orchard:** roots, moss and worn garden paths, hanging herbs, portraits, bell court, weighhouse, singing wall and the companion chamber.

Each world has fifteen different landmark illustrations, assigned once to its fifteen existing area identities. Ground materials, native terrain details, character appearances, chest sprites and doorway styles remain reusable building blocks. Layout placements, shoreline contours and landscape arrangements vary by world and area. There are no copied full-reference screenshots masquerading as playable terrain.

## Movement and connections

Click a clear path in the active area to walk there. Click its doorway, or an adjacent discovered area, to approach the connecting gate. Click a task-room chest to approach and inspect the room. Arrow keys/WASD, running, the movement pad, zoom, pan and follow controls remain available. Manual movement cancels a click route.

Paths find safe routes around the existing solid props and pillars. Organic land margins outside the previous rectangular bounds are walkable. Doorway puzzles, quest-item locks and permanent passage unlocks still control access; the new landscape does not bypass them. Completed crossings follow the same curved route used by the terrain mesh. Help, puzzles and other panels stop queued click movement.

The bottom toolbar and corner HUD leave more room for the world. Hover a doorway for its destination and lock status; the map and current-area header retain area names. Fog remains anonymous until a room is unlocked and visited.

## Activity and lighting

Workers have sixty area-specific job labels. Fishermen cast and reel their lines, vendors exchange goods with a customer, and snow workers scrape or shovel with moving tools and flying chips. Other workers reach, turn, tend or hammer, using different timings. These are decorative time-driven actions using the traveler art plus articulated hands/tools; they do not add a trading economy or change quest rewards.

Lanterns, selected landmark lights and furnace glows breathe on slow asynchronous cycles. Kiln smoke rises; snow drifts; water has moving highlights. Pip appears beside the player in the current area rather than repeating across every visible region.

## Implementation

- `terrain_shape.lua`: stable, individually shaped land boundaries and cubic connection paths.
- `environment.lua`: textured ground/cliff meshes, curved terrain ribbons, vistas, mist and weather. Repeating ground uses ordinary Images so window resizing does not erase it.
- `navigation.lua`: room-local pathfinding, obstacle clearance and safe segment checks.
- `tabletop.lua`: unique world placements, shared route traversal, camera, fog, drawing order and screen-to-ground picking.
- `scenery.lua` / `ambient_npc.lua`: unique landmark selection, task chests, worker poses/tools and slow light effects.
- `main.lua`: click controls, scaled HUD/hit regions and existing campaign callbacks.
- `progress.lua`: bounded saved coordinates now include organic land margins; the save version and old journey compatibility are unchanged.

The world and HUD scale for larger viewports. The integration test exports **3840×2160** captures of all four worlds. This is rendering resolution, not a claim that each bitmap is individually 4K; exact native asset sizes and complete generation prompts are in [WORLD_ART.md](assets/cartoon/WORLD_ART.md). Full-scene screenshots are test galleries with the world revealed, not a change to normal discovery rules.

## Verification and previews

`lua tests/navigation_test.lua` checks sixty distinct outlines, safe click paths, obstacle detours, organic margins, four layouts, curved routes and saved border positions. `python3 tests/assets_test.py` validates atlas bounds and distinct source regions. `python3 tests/run_love_tests.py` exercises real click-to-walk and doorway callbacks, puzzles, all 32 tasks, rescue, saved progress, animated worker frames, minimum-size UI and four 4K world renders.

- [Kiln — 4K](docs/images/miswander-world-kiln-4k.png)
- [Harbor — 4K](docs/images/miswander-world-harbor-4k.png)
- [Snowfair — 4K](docs/images/miswander-world-snowfair-4k.png)
- [Orchard — 4K](docs/images/miswander-world-orchard-4k.png)
- [Working NPC close-up](docs/images/miswander-workers.png)
