# Platforms, builds and performance gates

## Support status

The project has a shared GDScript implementation and starter export presets for Windows x86-64, Android ARM64 and iOS ARM64. A **Windows x64 release EXE and shareable ZIP have now been exported** using the official matching templates. The EXE is unsigned and has not been run natively on Windows. No signed Android APK/AAB, Xcode archive, TestFlight build, or store submission has been produced here. The available host is Linux; no physical phone or Windows system is connected.

The following are **provisional minimum target devices**, not certified minimum supported devices. Final support requires passing the gates below on those devices; raise the floor or optimize further if any gate fails.

| Target | Proposed minimum test configuration | Goal |
| --- | --- | --- |
| Android | Pixel 4a-class Snapdragon 730G / Adreno 618, 6 GB RAM, Android 11+, ARM64 | Low preset, landscape, 30 FPS |
| iOS | iPhone 11 / A13, 4 GB RAM, iOS 16+ | Low or Balanced after measurement, landscape, 30 FPS |
| Windows | Windows 10 64-bit, Ryzen 5 3500U-class CPU, 8 GB RAM, GTX 1050-class or equivalent GPU | Balanced at 1280×720 viewport, 60 FPS |
| Local verification only | Ryzen 7 5825U integrated Radeon, Linux/Mesa | See VALIDATION.md; does not certify Windows |

These floors are game targets, not a restatement of [Godot's engine minimum requirements](https://docs.godotengine.org/en/4.5/about/system_requirements.html). Device thermal behavior and driver issues can require stricter requirements.

## Quality policy implemented

| Preset | 3D render scale | Antialiasing | Frame cap |
| --- | --- | --- | --- |
| Low | 65% of viewport dimensions | Off | 30 |
| Balanced | 85% | 2× MSAA | Mobile 30 / desktop 60 |
| High | 100% | 2× MSAA | Mobile 30 / desktop 60 |

UI is drawn at viewport resolution independently of 3D render scale. A render scale is not a fixed pixel budget on an arbitrary phone display, so measure the actual device's resolution and workload. VSync can impose its own scheduling; a cap is not a performance guarantee. Compatibility-path scaling and MSAA must be verified on each platform. If a driver does not implement the expected scaling path, use a fixed lower 3D SubViewport in the next optimization pass.

Current content is small, with geometry grouped by material, low-segment character meshes, a single shader surface and no texture streaming. Production budgets to validate are under 100 scene draw calls in this slice, under 50,000 visible triangles, and no real-time shadow or volumetric pass. Benchmarks record the actual visible counts; these are budget goals rather than mobile measurements.

## Native build prerequisites

Install the **matching Godot 4.5.2 export templates** through Editor → Manage Export Templates. Create the output directories used by each preset before command-line export. The presets are scaffolding and have not been exercised against SDKs here. Use unique production identifiers, icons and signing credentials before distribution.

### Windows

Install matching Windows export templates. From the repository root:

```sh
godot --headless --path godot --export-debug "Windows Desktop" builds/windows/isomet.exe
```

The configured export path is relative to the Godot project if exporting from the editor. Ensure the output location is correct for the command invocation. Test the resulting application on physical Windows hardware, including save folder permissions, mouse capture/focus, Alt+Tab, quit, display scaling and graphics drivers. Release distribution should use code signing and final application icons. See [official Windows export instructions](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_windows.html).

### Android

Install/configure JDK 17 and the Android SDK toolchain for the pinned Godot version. Its [Android export guide](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_android.html) specifies platform/build tools 35 and NDK r28b for this release. Configure Java and SDK paths in Godot. The included Android preset targets ARM64 and an immersive screen, enables a Gradle build, and sets minimum SDK 30 (Android 11) and target SDK 35. Install the Android build template using Godot’s Project → Install Android Build Template command before export. Gradle also needs its dependencies available. The preset does not supply a keystore. Recheck target SDK requirements before a future store submission.

Export a debug APK, install via Android Studio/ADB on a physical device and test touch, safe areas, keyboard entry, lifecycle saves, storage and thermal performance. Release builds require a non-debug keystore; store distribution uses a signed AAB and current store policy checks. Signing secrets must remain outside source control. No internet permission is needed by gameplay.

### iOS

Use a Mac with Xcode, matching export templates, an Apple developer team and a physical device. Set the bundle identifier and **App Store Team ID** in the iOS export preset. The preset sets iOS 16.0 as its minimum and exports project files for Xcode. Export the Xcode project, select signing/provisioning, and build/deploy from Xcode. The blank team ID is an intentional unresolved build requirement, not a fake credential. [Godot's iOS instructions](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_ios.html) require macOS and Xcode.

Start by validating the renderer on iPhone 11. If the Compatibility path is unsuitable, select Godot's Mobile renderer and Metal for the iOS platform override, then recheck lighting, shader appearance, antialiasing and frame pacing. That is a platform renderer configuration change; the gameplay/UI scripts stay shared. No iOS renderer path is certified by the Linux result.

## Hardware acceptance procedure

For each target device and each relevant graphics preset:

1. Install an exported native build; record commit, OS, GPU driver, resolution, render scale and power mode.
2. Cold launch: verify Continue disabled without a valid checkpoint, all menu options, overwrite cancellation, character/name/location, and each intro.
3. Complete the console → arch → portal route using platform-native controls. Save, terminate the app, relaunch and continue. Suspend/resume during play; try low storage and malformed saves.
4. Check touchscreen safe areas, native keyboard and multitouch on notched phones; verify minimum tap sizes and accessibility settings visually. Test keyboard-only focus and readable Windows DPI scaling.
5. Run a 15-minute repeated route after a 2-minute warm-up, unplugged at a documented brightness and ambient temperature. Collect CPU/GPU frame traces, memory, temperature/throttling, battery draw and crashes with Android GPU Inspector/Perfetto or Xcode Instruments; use PresentMon/Godot profiler on Windows.
6. Acceptance targets: sustained median at least 30 FPS mobile / 60 FPS PC, p95 frame time at most 33.3 ms / 16.7 ms excluding documented loading transitions, no persistent thermal collapse, and no memory growth across repeated menus/intros.
7. Repeat on at least one larger phone, one different Android GPU vendor and one lower-spec device to establish the actual support floor.

The built-in 30-second benchmark is a quick local regression tool, not this certification procedure. Do not advertise stable 30/60 FPS until native-device traces support it.

## Additional production assets and services

No external art pack or paid service is required to open this slice. Production still needs original rigged characters/dog, authored modular Deco geometry and material atlases, richer scene furnishings, baked lighting, final sound/music and mix, application/adaptive icons and launch screens, store metadata, signing accounts/certificates, and hardware access. Preserve licenses and attribution for any future imported assets. Current geometry, wordmark, shader and synthesized loops are generated specifically for this project.
