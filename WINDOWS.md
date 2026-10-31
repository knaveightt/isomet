# Run Miswander on Windows

You need the project folder and **LÖVE 11.5**. LÖVE includes Lua; you do not need to install Lua separately, compile the game, or install development tools.

## 1. Install LÖVE

Download the **Windows 64-bit installer** from the [official LÖVE website](https://love2d.org/). This project targets version **11.5**; its downloads are also available on the [official 11.5 release page](https://github.com/love2d/love/releases/tag/11.5).

Run the installer. The usual installation folder is `C:\Program Files\LOVE`.

Alternatively, download the Windows 64-bit ZIP and extract it. Keep `love.exe` together with all the other files supplied in that ZIP.

## 2. Extract the game folder

If someone sent you a project ZIP, right-click it in File Explorer and choose **Extract All**. Open the extracted folder and locate the folder containing **`main.lua`**, **`conf.lua`**, and **`assets`** together. This is the game folder.

Keep the entire project together. Do not run it from inside the ZIP, move `main.lua` out of the folder, or remove the `assets` folder.

For example, your files might be:

```text
C:\Games\Miswander\main.lua
C:\Games\Miswander\conf.lua
C:\Games\Miswander\assets\
```

## 3. Launch the game

In File Explorer, drag the **whole game folder** onto `love.exe` in the LÖVE installation folder, or onto a shortcut to `love.exe`. Dragging a game folder onto the executable is the [official Windows launch method](https://love2d.org/wiki/Getting_Started).

The Miswander splash screen appears for about three seconds. Then choose your traveler, enter a name, choose an origin, and watch the introduction. If a journey is already saved, you can continue it.

### Alternative: launch from PowerShell

Open PowerShell and enter the following, replacing the game path with your actual extracted folder:

```powershell
& "C:\Program Files\LOVE\love.exe" "C:\Games\Miswander"
```

If you used the portable ZIP, replace the first path with the location of its `love.exe`. Keep the quotes around paths containing spaces and the `&` at the beginning.

### Optional desktop shortcut

Right-click the desktop, choose **New → Shortcut**, and use this as the location, adjusting both paths as needed:

```text
"C:\Program Files\LOVE\love.exe" "C:\Games\Miswander"
```

Name the shortcut **Miswander**. Keep the game folder in that location afterward.

## Playing and saving

- Move with the **arrow keys** or **WASD**; hold **Shift** to run.
- Press **E** to inspect a room. Use the bottom toolbar for inventory, notebook, map, and hints.
- Zoom with the **mouse wheel**; pan with **right-button drag**; press **F** to follow the traveler again.
- In a passage puzzle, click two neighboring pieces. Click **How to play** or press **H** for the puzzle guide.
- Press **Escape** to pause during exploration.

Progress saves automatically. During exploration, press **O** to open the game's save folder. On Windows this is normally `%APPDATA%\LOVE\isomet-void`; you can paste that path into File Explorer's address bar. Back up the entire save folder if you want to transfer or preserve a journey. Saves are separate from the downloaded project folder.

## Troubleshooting

| What you see | What to do |
| --- | --- |
| LÖVE's “No Game” screen | Launch with the game folder as described above. Opening `love.exe` alone does not select Miswander. |
| A text editor opens | You opened `main.lua` directly. Drag its containing folder onto `love.exe` instead. |
| An error about a missing image, font, or Lua module | Extract the complete project again and keep its files and subfolders together. |
| The command cannot find `love.exe` | Check where LÖVE was installed or extracted, then correct the first path. |
| A blue LÖVE error screen | Take a screenshot of the complete error text and share it when reporting the problem. |

The full control list and gameplay details are in [README.md](README.md).
