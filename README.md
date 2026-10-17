# ISOMET — The Quiet Between

A small exploration game for **LÖVE 11.5** and Lua. An original, SNES-inspired pixel traveler is stranded among floating chambers. Walk through the glowing stone arches to discover twelve connected rooms and find the violet escape portal. No additional assets or libraries are needed.


## New 3D vertical slice

The original 2D/LÖVE prototype below remains playable. A separate **Godot 4.5.2** project now provides the first 3D conversion milestone: a live Art Deco title screen, eight character variants, adapted introductions, third-person exploration across two connected chambers, a resonance-console interaction, an escape portal, checkpoints, settings, and touch/PC input.

Run `./run-3d.sh` on this workspace, or import [godot/project.godot](godot/project.godot) in Godot. See the [3D guide](godot/README.md), [engine assessment](godot/docs/ENGINE_ASSESSMENT.md), [platform requirements](godot/docs/PLATFORMS.md), and [validation report](godot/docs/VALIDATION.md).

This is a procedural 3D art blockout and functional slice, not the complete maze conversion or a shipped Android/iOS/Windows build. The device support floor remains provisional pending native-device testing.

## Play

On launch, choose one of eight travelers: four male and four female variants, each with a different skin tone and clothing palette. Click a portrait or use the arrow keys, type a name (up to 20 characters), then click **Continue** or press **Enter**. Backspace edits your name. Your name appears beside the current room name. Selection and name last for the current application session, including F5 restarts and Ctrl+N mazes; launching again asks you to choose anew.

From this folder, run:

```sh
love .
```

You can also drag this project folder onto the LÖVE application.

- **Up / W:** northeast
- **Right / D:** southeast
- **Down / S:** southwest
- **Left / A:** northwest
- **Shift:** run
- **F5:** restart the same maze (also reloads edited room files)
- **O:** open the saved room folder
- **Ctrl+N:** replace the saved maze with a new random maze immediately
- **Escape:** quit

Walk into an arch to change rooms. Walk into the violet portal to escape. Pillars block movement; the central paths stay open. Diagonal key combinations work too. There is no combat in this first version.

## Introduction

After character creation, choose **City**, **Suburb**, or **Midwest** using the mouse or arrow keys, then click **Begin your story** or press Enter. A roughly 12.5-second pixel-art scene shows your character, a randomly selected loved one of the opposite gender, and a dog.

- **City:** a bedroom at night; the television pulls your loved one and dog inside.
- **Suburb:** dinner in a dining room; a mirror becomes the doorway.
- **Midwest:** a ranch surrounded by corn; a puddle opens into the void.

Your character reacts and follows them, then the scene fades into the first maze room. Movement and maze shortcuts are paused during the introduction; Escape still quits. F5 and Ctrl+N restart gameplay directly without replaying the introduction. Location and companion choices last only for this launch and do not change saved room data.

## Persistent, editable rooms

The first launch generates the maze and writes it to LÖVE's save directory. Subsequent launches read those files instead of generating new rooms. The layout persists; the player starts in room 1 each session.

Press **O** to open the save directory. On a typical Linux installation it is `~/.local/share/love/isomet-void/`; on Windows it is `%APPDATA%/LOVE/isomet-void/`; on macOS it is `~/Library/Application Support/LOVE/isomet-void/`.

`world.txt` contains the number of rooms. `rooms/1.room`, `rooms/2.room`, etc. contain plain text:

```text
# Comments begin with #
name = A Quiet Observatory
size = 8 9
portal = false
exit = NE 2
exit = SE 3
pillar = 2.5 2.5
pillar = 5.5 6.5
```

`size` specifies width and height in floor tiles (5–16 each). Floor coordinates range from zero to the room size. Half-tile coordinates put pillars at tile centers. Keep pillars away from entrances and leave paths between all exits and the center.

Each room may have at most one exit per side. An `exit` contains a direction and destination room number. Arches are centered on the corresponding edges. Connections must be reciprocal: if room 1 has `exit = NE 2`, room 2 must have `exit = SW 1`. The other opposite pair is NW / SE. Use exactly one `portal = true` in the world; the escape appears in that room's center. All rooms must connect to room 1. The loader checks these rules and displays errors without overwriting your files. Back up custom rooms before pressing Ctrl+N.

Edit files while the game is closed, or press F5 after saving changes. Names and dimensions can be freely changed. To add a room, create the next numbered file, update `world.txt`, and add reciprocal exits. Use consecutive room numbers starting at 1.

## Project

See [DESIGN.md](DESIGN.md) for a complete source walkthrough, algorithms, data format, programming principles, and current limitations.

- `main.lua`: movement, room transitions, isometric rendering, void animation, interface
- `characters.lua`: eight pixel portraits, selection screen, and character-name input
- `intro.lua`: location selection, pixel-art environments, and timed introduction
- `pixel_font.lua`: crisp 5×7 bitmap lettering for cutscene captions
- `world.lua`: maze generation, plain-text serialization, validation
- `conf.lua`: window and LÖVE configuration
- `tests/world_test.lua`: generation and persistence checks

Run the data checks with `lua tests/world_test.lua` or `luajit tests/world_test.lua`. They verify 200 seeded worlds, connected and reciprocal exits, a unique escape, clear central corridors, and exact room-file round trips. `ISOMET_SMOKE=1 love .` runs briefly and saves a screenshot in the save directory. For isolated testing on Linux, use `XDG_DATA_HOME=/tmp/isomet-test ISOMET_SMOKE=1 love .`.

Character selection checks: `lua tests/characters_test.lua` (Lua 5.4). These cover unique sprites, keyboard/mouse selection, UTF-8 backspace, name length, and confirmation.

Introduction state checks: `lua tests/intro_test.lua`. These cover opposite-gender companions, keyboard/mouse choices, timeline completion, and one-time handoff.
