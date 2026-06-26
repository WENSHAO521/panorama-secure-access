<div>

[**简体中文**](README_zh_CN.md)

</div>

## Panorama Secure Access

[![Downloads](https://img.shields.io/github/downloads/WENSHAO521/FlClash-/total?style=flat-square&logo=github)](https://github.com/WENSHAO521/FlClash-/releases/)
[![Last Version](https://img.shields.io/github/release/WENSHAO521/FlClash-/all.svg?style=flat-square)](https://github.com/WENSHAO521/FlClash-/releases/)
[![License](https://img.shields.io/github/license/WENSHAO521/FlClash-?style=flat-square)](LICENSE)

A multi-platform secure proxy client built by **Publishing Society Group (PSG)**, based on [ClashMeta](https://github.com/MetaCubeX/mihomo). Simple to use, open-source, and ad-free.

Official website: [panorama-sg.com](https://panorama-sg.com/)

## Features

- **Multi-platform** — Android, Windows, macOS and Linux
- **Adaptive UI** — Responsive layout for all screen sizes, multiple color themes
- **Material You** — Clean, modern design inspired by [Surfboard](https://github.com/getsurfboard/surfboard)
- **WebDAV Sync** — Sync profiles and settings across devices
- **Subscription support** — Import proxy subscriptions with one click
- **Dark mode** — Full dark/light theme support

## Download

Get the latest release from [GitHub Releases](https://github.com/WENSHAO521/FlClash-/releases).

| Platform | File |
|---|---|
| Android | `PSA-{version}-android-arm64-v8a.apk` |
| Windows (x64) | `PSA-{version}-windows-amd64-setup.exe` |
| Windows (ARM) | `PSA-{version}-windows-arm64-setup.exe` |
| macOS (Intel) | `PSA-{version}-macos-amd64.dmg` |
| macOS (Apple Silicon) | `PSA-{version}-macos-arm64.dmg` |
| Linux (x64) | `PSA-{version}-linux-amd64.AppImage` |

## Usage

### Linux

Install required system dependencies before first run:

```bash
sudo apt-get install libayatana-appindicator3-dev
sudo apt-get install libkeybinder-3.0-dev
```

### Android

The following broadcast intents are supported for automation:

```
com.follow.clash.action.START
com.follow.clash.action.STOP
com.follow.clash.action.TOGGLE
```

## Build

1. Clone with submodules:
   ```bash
   git clone --recurse-submodules https://github.com/WENSHAO521/FlClash-
   cd FlClash-
   ```

2. Install [Flutter](https://flutter.dev/docs/get-started/install) and [Go](https://golang.org/dl/) (1.24+)

3. Build for your target platform:

   **Android**
   ```bash
   # Install Android SDK and NDK (r28c), set ANDROID_NDK
   dart setup.dart android
   ```

   **Windows**
   ```bash
   # Requires GCC and Inno Setup
   dart setup.dart windows
   ```

   **Linux**
   ```bash
   # Dependencies are installed automatically, or manually:
   sudo apt-get install -y libayatana-appindicator3-dev libkeybinder-3.0-dev
   dart setup.dart linux
   ```

   **macOS**
   ```bash
   dart setup.dart macos
   ```

## License

[GPL-3.0](LICENSE) — Publishing Society Group
