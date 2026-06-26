<div>

[**English**](README.md)

</div>

## Panorama Secure Access

[![Downloads](https://img.shields.io/github/downloads/WENSHAO521/FlClash-/total?style=flat-square&logo=github)](https://github.com/WENSHAO521/FlClash-/releases/)
[![Last Version](https://img.shields.io/github/release/WENSHAO521/FlClash-/all.svg?style=flat-square)](https://github.com/WENSHAO521/FlClash-/releases/)
[![License](https://img.shields.io/github/license/WENSHAO521/FlClash-?style=flat-square)](LICENSE)

**Publishing Society Group (PSG)** 出品的多平台安全代理客户端，基于 [ClashMeta](https://github.com/MetaCubeX/mihomo)，简单易用，开源无广告。

官网：[panorama-sg.com](https://panorama-sg.com/)

## 功能特性

- **多平台支持** — Android、Windows、macOS、Linux 全平台覆盖
- **自适应界面** — 支持多种屏幕尺寸与颜色主题
- **Material You 设计** — 简洁现代的界面风格，类 [Surfboard](https://github.com/getsurfboard/surfboard) 体验
- **WebDAV 同步** — 跨设备同步配置与设置
- **订阅一键导入** — 快速导入代理订阅链接
- **深色模式** — 完整深色/浅色主题支持

## 下载

前往 [GitHub Releases](https://github.com/WENSHAO521/FlClash-/releases) 下载最新版本。

| 平台 | 文件 |
|---|---|
| Android | `PSA-{version}-android-arm64-v8a.apk` |
| Windows (x64) | `PSA-{version}-windows-amd64-setup.exe` |
| Windows (ARM) | `PSA-{version}-windows-arm64-setup.exe` |
| macOS (Intel) | `PSA-{version}-macos-amd64.dmg` |
| macOS (Apple Silicon) | `PSA-{version}-macos-arm64.dmg` |
| Linux (x64) | `PSA-{version}-linux-amd64.AppImage` |

## 使用说明

### Linux

首次使用前请安装以下系统依赖：

```bash
sudo apt-get install libayatana-appindicator3-dev
sudo apt-get install libkeybinder-3.0-dev
```

### Android

支持以下广播 Intent 用于自动化控制：

```
com.follow.clash.action.START
com.follow.clash.action.STOP
com.follow.clash.action.TOGGLE
```

## 构建

1. 克隆仓库（包含子模块）：
   ```bash
   git clone --recurse-submodules https://github.com/WENSHAO521/FlClash-
   cd FlClash-
   ```

2. 安装 [Flutter](https://flutter.dev/docs/get-started/install) 和 [Go](https://golang.org/dl/)（1.24+）

3. 构建目标平台：

   **Android**
   ```bash
   # 安装 Android SDK 和 NDK（r28c），设置 ANDROID_NDK 环境变量
   dart setup.dart android
   ```

   **Windows**
   ```bash
   # 需要 GCC 和 Inno Setup
   dart setup.dart windows
   ```

   **Linux**
   ```bash
   # 依赖会由脚本自动安装，或手动安装：
   sudo apt-get install -y libayatana-appindicator3-dev libkeybinder-3.0-dev
   dart setup.dart linux
   ```

   **macOS**
   ```bash
   dart setup.dart macos
   ```

## 开源协议

[GPL-3.0](LICENSE) — Publishing Society Group
