# Engine assessment and conversion boundary

## Existing project inspected

The source was a self-contained LÖVE 11.5/Lua prototype, with no 3D assets or external libraries:

| Existing component | Reuse decision |
| --- | --- |
| `world.lua` | Preserve as the authoritative 2D procedural maze and file-format reference. Its graph, reciprocal edges, unique portal and clear routes remain useful design invariants; no Lua runtime has been embedded in Godot. |
| `characters.lua` | Preserve eight gender/palette combinations and naming. Rebuild as simple 3D character silhouettes and Godot controls. |
| `intro.lua` | Preserve City/Suburb/Midwest, opposite-gender loved one, dog, TV/mirror/puddle, reaction and pursuit. Rebuild a short timed 3D blockout. |
| `main.lua` | Preserve exploration and escape intent. Rebuild movement, collision, camera, rendering, interactions and save management. |
| `pixel_font.lua` | Keep in the 2D version. Use scalable UI and world labels in 3D. |
| Existing tests | Keep runnable unchanged. Add independent Godot integration tests. |
| `DESIGN.md` / `README.md` | Keep the original implementation history and add links to the new milestone. |

## Why change engines

LÖVE exposes meshes, shaders, and depth testing, and has mobile ports. However, it does not supply a complete 3D scene system, authoring tools, character controller, collision-aware 3D camera, or integrated 3D/mobile export pipeline. Its [depth-mode documentation](https://love2d.org/wiki/love.graphics.setDepthMode) specifically describes low-level depth support rather than a high-level 3D API. Building these systems on LÖVE is possible, but would make this conversion largely an engine-development project.

The new `godot/` project uses **Godot 4.5.2 standard with GDScript**, deliberately pinned to the portable version downloaded and tested here. This is an engine and implementation-language change from Lua, not an in-place conversion of Lua syntax. GDScript gameplay is shared across Windows, Android and iOS; platform checks choose input presentation and frame-rate caps. The existing Lua game remains fully available.

Godot supplies CharacterBody3D, physics queries, 3D cameras, GUI focus/navigation, touch events, audio, materials, and native export targets. The [renderer overview](https://docs.godotengine.org/en/4.5/tutorials/rendering/renderers.html) explains the Compatibility/Mobile/Forward+ choices. Compatibility is the conservative baseline for this slice; platform rendering must be checked on hardware before release. Do not assume that a desktop renderer test establishes identical behavior on iOS.

## Original visual identity: the threshold observatory

The design uses broad Art Deco and retrofuturist references rather than recreating an existing game's locations or assets. The room is a machine for listening across dimensions, now abandoned after opening the wrong door.

- Architecture: stepped lintels, fan-shaped crowns, fluted wall ribs and paired columns.
- Materials: petrol enamel, ivory columns, oxidized brass and dark stone.
- Lighting: warm/cool contrast, cyan fixtures, a violet animated threshold, and darkness beyond the open ceiling.
- Story: a resonance terminal, a recorded fragment, and an inscription that implies a failed experiment.
- Audio: two original synthesized loops, an electrical drone and a simple sustained harmonic layer.
- Type: an original geometric vector ISOMET wordmark, readable engine UI text, and brass rules.

These are procedural **art-direction blockouts**, not finished stylized-realism character art, authored PBR surfaces, rigged animation, a professionally mixed score, or final cinematography. The visual language can be judged now; production art is an additional milestone.

## Architecture

| New file | Responsibility |
| --- | --- |
| `project.godot`, `main.tscn` | Application identity, viewport/rendering settings, boot scene |
| `scripts/main.gd` | Slice state machine, menus, profile, home scene, gameplay, camera, audio, checkpoints, gallery and benchmark |
| `scripts/art.gd` | Shared material cache, original geometry builders, characters/dog, arches, static mesh batching |
| `scripts/touch.gd` | Independent left-stick and right-look touch tracking, input reset, visual touch overlay |
| `scripts/store.gd` | Versioned JSON read/write and journey validation |
| `assets/wordmark.svg` | Original scalable title art |
| `assets/threshold.gdshader` | Lightweight animated spatial portal shader |
| `tests/run.gd` | Real physics and state-transition checks |
| `export_presets.cfg` | Starter Windows/Android/iOS export configuration; credentials intentionally absent |

State progression is title → creation → loading → intro → play. Pause, settings, note, credits and victory use the same UI layer. The world is constructed once rather than streamed, so loading feedback yields frames before a transition but is not an asynchronous asset-loader implementation.

Movement is camera-relative on the horizontal plane, using a capsule CharacterBody3D with gravity and `move_and_slide`. Floors, perimeter walls, the dividing wall and pillars have physical colliders. The camera orbits behind the character, clamps pitch, stays within the chamber envelope, and raycasts to avoid intervening walls. No jumping or combat is added.

The two chambers are one connected test area. A central walk-through arch gives access to the second chamber. This differs from the legacy single-room renderer and is intentional for evaluating the 3D camera and sightlines. The twelve-room graph and one-room-at-a-time loading remain future work.

`Art.batch_static` merges direct static mesh geometry by shared material, retaining separate physics bodies. Character meshes and the portal remain independently animated. No light/shadow maps, large image textures, volumetrics, SSR or SSAO are used. One directional light and three limited-range unshadowed local lights keep the scene inexpensive. Simple dark discs suggest contact at column bases.

## Remaining conversion work

1. Review the slice's art direction, movement, and camera on target devices.
2. Port the room graph generator and text parser, or provide an offline Lua-to-JSON content converter; preserve reciprocal exits and unique-portal tests.
3. Build modular rooms from that data, unload distant rooms, and save graph/discoveries alongside the character session.
4. Replace primitive characters with original rigged models matching the eight established variants; add locomotion, alarm, sitting/eating, and pursuit animations.
5. Replace environment blockouts with bevelled modular Deco assets, authored material atlases and baked lighting.
6. Refine all three introductions with camera blocking, furnishings, facial/body reactions and sound.
7. Package signed native builds and complete the physical-device/performance matrix before claiming support.

No legacy room files are imported or overwritten by this milestone. The slice adds a resonance-console step to validate contextual 3D interaction while retaining escape as its goal. It is deliberately not presented as the full maze conversion.
