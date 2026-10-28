# SimForge — install and update

SimForge is a MATLAB IDE for the classroom (editor, command window, figures,
workspace, ForgeLink, Circuit Lab and more). This repository holds the
**released builds only**; it is the place students install and update from.

## Install or update

Run the same command the first time and every time you want the newest
version. It installs SimForge if it is missing, updates it if a newer version
is out, and does nothing if you are already up to date.

**Windows 10/11** — open **PowerShell** (Start menu → type `PowerShell`) and run:

```powershell
irm https://raw.githubusercontent.com/Niel-TCH/simforge-releases/main/update.ps1 | iex
```

SimForge goes into `%LOCALAPPDATA%\Programs\SimForge`, with shortcuts on the
Desktop and in the Start Menu. No admin rights needed.

**macOS (Apple Silicon, M1 or newer)** — open **Terminal** and run:

```bash
curl -fsSL https://raw.githubusercontent.com/Niel-TCH/simforge-releases/main/update.sh | bash
```

SimForge goes into `/Applications` (or `~/Applications` if you are not an admin).

Save your work before updating: the updater closes SimForge if it is open.

## Requirements

- **Python 3.9 or newer.** SimForge runs your code on a Python engine.
  Windows: install from [python.org](https://www.python.org/downloads/) and tick
  **"Add python.exe to PATH"** (the Microsoft Store shortcut does not work).
  macOS: run `xcode-select --install`.
- **Windows only: Microsoft Edge WebView2.** Already on Windows 11 and updated
  Windows 10. If it is missing, SimForge tells you and opens the download page.
- **MATLAB (optional).** With MATLAB and the matching `matlabengine` pip
  package, your code runs on real MATLAB. Without it SimForge runs its built-in
  engine, which covers a large MATLAB subset including signals and filter design.

## Manual download

Every release on the [Releases page](https://github.com/Niel-TCH/simforge-releases/releases)
has `SimForge-win-x64.zip` (unzip, keep the files together, run `SimForge.exe`)
and `SimForge-macos-arm64.dmg`. Both builds are unsigned: on Windows click
**More info → Run anyway**; on macOS right-click the app → **Open** the first time.
