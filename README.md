# toggle-sleep

A macOS utility and native menu bar application to toggle system sleep prevention on demand — keeping your Mac awake even with the lid closed.

![macOS 13+](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

---

## Overview

`toggle-sleep` gives you full control over macOS sleep behavior using `pmset disablesleep`. It includes two components:

1. **`toggle-sleep` CLI**: A fast shell script for terminal use or custom keyboard shortcuts.
2. **`Toggle Sleep.app`**: A native, zero-dependency macOS menu bar extra with live status indicators and login item management.

### Menu Bar Display

- ☕ **Coffee** (`cup.and.saucer.fill`): Sleep is disabled. Your Mac stays awake even when the lid is closed.
- 🌙 **Moon** (`moon.fill`): Sleep is enabled. Follows your normal system sleep and energy settings.

### Dropdown Menu

- **`ON: Don't sleep, even with the laptop closed`**
- **`OFF: Sleep normally, following the laptop's settings`**
- **`Open at Login`** (native macOS `SMAppService`)
- **`Quit Toggle Sleep`**

---

## Quick Install (Release)

1. Download the latest `Toggle-Sleep.zip` from [Releases](https://github.com/Hikari9/toggle-sleep/releases).
2. Unzip and drag `Toggle Sleep.app` to `/Applications` or `~/Applications`.
   The build is unsigned (ad-hoc signed only), so on first launch **right-click the app and choose Open**, then confirm Open in the dialog. A normal double-click is blocked by Gatekeeper.
3. Copy `toggle-sleep` to your `PATH` (e.g. `~/.local/bin/toggle-sleep`):
   ```bash
   cp toggle-sleep ~/.local/bin/
   chmod +x ~/.local/bin/toggle-sleep
   ```

---

## One-Time Sudoers Configuration

`pmset disablesleep` requires root permissions. To allow toggling without password prompts:

```bash
./setup-sudoers.sh
```

Or manually:
```bash
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/pmset disablesleep *, $HOME/.local/bin/toggle-sleep" | sudo tee /etc/sudoers.d/toggle_sleep
sudo chmod 0440 /etc/sudoers.d/toggle_sleep
```

---

## CLI Usage

```bash
# Toggle current state
toggle-sleep

# Force disable sleep (stay awake / ON)
toggle-sleep 0

# Force enable sleep (normal sleep / OFF)
toggle-sleep 1
```

---

## Building from Source

Requirements: macOS 13+, Xcode Command Line Tools (`swiftc`).

```bash
git clone https://github.com/Hikari9/toggle-sleep.git
cd toggle-sleep
./build.sh
```

This compiles `Toggle Sleep.app` with the Swift toolchain bundled in Xcode and installs it to `~/Applications/Toggle Sleep.app`.

---

## License

MIT
