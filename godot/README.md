# ISOMET — The Quiet Between / 3D vertical slice

An original Art Deco threshold observatory: petrol teal, ivory stone, aged brass, violet energy, and a suspended void. This is the **first conversion milestone**, not the completed 3D game or a release-ready mobile app. The original playable Lua/LÖVE game remains intact in the parent directory.

## Ready-to-share Windows demo

The exported [ISOMET-Windows-x64.zip](builds/windows/ISOMET-Windows-x64.zip) contains a self-contained Windows x64 release EXE, instructions and license notices. Send that ZIP; the recipient extracts it and double-clicks `ISOMET.exe`. Godot and the source folder are not required. The output is unsigned and has not yet been run on physical Windows hardware. Its embedded game data passed local smoke and rendering checks.

## Run

Use **Godot 4.5.2 standard**, the version used to validate this project. Import `project.godot` and press F6 on `main.tscn` or F5 to run the project. No C# runtime or external asset package is required.

On this Linux workspace, from the repository root:

```sh
./run-3d.sh
```

The launcher finds an installed `godot4`/`godot`, an executable specified by `GODOT_BIN`, or the temporary portable engine downloaded for this implementation. The temporary engine under `/tmp` is not a permanent installation. Elsewhere, install Godot and open this project or use:

```sh
godot --path godot
```

`love .` in the repository root still runs the earlier 2D game.

## Play the slice

1. Choose **New Game**, enter a name, choose one of the eight original character variants and City/Suburb/Midwest.
2. Watch the brief 3D story blockout: the opposite-gender loved one and dog disappear through the TV, mirror, or puddle; your character reacts and follows.
3. Explore the first chamber. Approach the illuminated console on the left and interact to receive a familiar voice and a dog's bark described in the transmission.
4. Walk through the stepped arch into the second chamber. Approach the violet threshold and interact to escape.

The console is a small added interaction to exercise the 3D slice. The original exploration/escape objective is preserved. The twelve-room procedural maze, room-file editing workflow, fuller cinematic staging, and a reunion sequence are **not yet converted**. The loved one and dog are cinematic actors, not followers or rescue targets in this area.

### Controls

| PC | Phone / touch preview |
| --- | --- |
| WASD or arrows: camera-relative movement | Left thumb stick: movement |
| Mouse: orbit third-person camera | Swipe upper/right area: camera |
| E: contextual interaction | Tap the context button |
| Shift: run | Walking speed; no separate run button in this slice |
| Escape or II: pause / resume | II: pause |
| Tab/arrows and Enter, or mouse: menus | Tap menus and native text entry |

Touch is automatic on Android/iOS. Turn on **Show touch controls on PC** in Settings to inspect the overlay, though true multi-touch still requires a touch device. Landscape orientation is selected. Mobile menu buttons use 76 logical-pixel targets (desktop buttons use 50–54); menus scroll, and margins use the reported phone safe area. Physical device checks are still required for display cutouts, keyboards, backgrounding, and multi-touch.

## Title and persistence

The title is a live view of the playable observatory, with slow camera motion, animated portal, original vector wordmark, and two synthesized looping ambient/music layers. Reduced motion disables the camera drift and portal animation. There are no borrowed game assets or recordings.

- **Continue** is enabled only for a valid version-1 journey checkpoint.
- **New Game** asks before replacing an existing valid checkpoint. Replacement occurs on entering gameplay after the introduction, so backing out of creation preserves progress.
- **Settings** saves master/music/ambience volume, quality, sensitivity, vertical invert, reduced motion, larger text, and PC touch preview.
- **Credits** includes engine attribution and a link to the engine license.
- **Quit to Desktop** appears on Windows. Other platforms use their normal app/window lifecycle.

Journey and settings files are separate JSON files in Godot's `user://` directory. They do not modify LÖVE room files. Checkpoints save on entering the slice, console activation, escape, every 20 seconds of play, manual save, returning to title, and application pause/close during play. Writes go through a temporary file before rename. A failed manual return-to-title save keeps the pause screen visible.

## Tests and inspection

```sh
godot --headless --path godot --fixed-fps 60 --script res://tests/run.gd -- --tests
godot --headless --path godot -- --smoke
godot --path godot -- --gallery
godot --path godot -- --benchmark
```

Run from the repository root; substitute the full engine executable as needed. `--tests` and `--smoke` use `smoke_journey.json`/`smoke_settings.json`, separate from normal progress. Gallery and benchmark runs do not save journey progress. The gallery captures menus, gameplay and the three scenes to `user://preview_*.png`. The benchmark walks a repeating route through both chambers and writes wall-clock frame intervals, p95, draw calls, and triangles to `user://benchmark.json`. It stops after about 32 seconds; the first two seconds are warm-up. These tools do not certify a platform or sustained thermal performance.

See [ENGINE_ASSESSMENT.md](docs/ENGINE_ASSESSMENT.md), [PLATFORMS.md](docs/PLATFORMS.md), and [VALIDATION.md](docs/VALIDATION.md) for scope, build prerequisites, provisional device floors, and measured evidence.
