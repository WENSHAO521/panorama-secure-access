# Changelog

## v3.5.9 (2026-11-13)

**Breaking Changes**

- **desktop** Own binary, Helper, service and bundle identifiers (eb63f64)
- **android** Ship as com.panoramasg.secureaccess (25f5cc6)
- **android** Android installs this version as a new app. Back up the configuration in the old app, restore it in the new one, then uninstall the old app. (52d7d33)

**Features**

- Confirm beta channel changes, custom traffic on link import, clearer network diagnosis (cd82481)
- **dashboard** Arch the Northern Dipper over the desktop speed cards (5089bac)
- **uninstall** Remove leftovers when the app is uninstalled (6e7ad4f)
- **diagnosis** One-click network diagnosis with repairs (a0ae682)
- **update** Back up the data before installing an update and offer to restore it (6f309f9)
- **dashboard** Show the exit flag as a round flag under the Northern Dipper (148d405)
- **desktop** Check for a busy mixed port and other proxy clients before start (25f79a5)
- **app** Carry data over from installs under FlClash's identifiers (5456f9c)
- **desktop** Own binary, Helper, service and bundle identifiers (eb63f64)
- **android** Ship as com.panoramasg.secureaccess (25f5cc6)
- **linux** Linux asks for administrator authorization once for TUN; the service survives reboots and upgrades and recovers without a password (7c892a4)
- **dashboard** Show the exit flag on a round disc (40cdaa8)
- **dashboard** Refine the exit flag badge (ac691f1)
- **profiles** Custom traffic totals can be entered in MB, GB or TB (db9770e)
- **dashboard** The dashboard shows the current exit's flag (a53a91e)
- **core** Core updated to mihomo v1.19.34 (cb2cd3f)
- **profiles** Profiles can set a custom traffic total, monthly or permanent (6c4914d)
- **android** The Android app installs alongside FlClash under its own package name (52d7d33)
- **core** Every proxy group and provider tests its nodes every 300 seconds (b4200c8)
- **delay** Delay tests use http://cp.cloudflare.com/generate_204 by default (edbe798)

**Bug Fixes**

- **core** Build with Go 1.27.4 and patched brotli and compress (f913486)
- **security** Redact secrets from app logs and audit dependencies in CI (68bbfc1)
- **release** Derive every platform's version from the release tag (4263693)
- **dashboard** Set the dipper arch over the speed figure (875b764)
- **proxy** Put back the Windows and Linux proxy settings a start replaced (c9bf018)
- **providers** Finish removing a stale download before putProvider returns (906aa17)
- **proxy** Put back the macOS proxy settings a start replaced (abb1adb)
- **core** Replace a TUN device name the OS cannot create (44e9717)
- **windows** Install under an own AppId and stop deleting FlClash's data (f4d532d)
- **dashboard** Size the exit flag through AppTextStyle.custom (ea3d9f0)
- **android** Android betas show their own version number when installed (e1819ad)
- **update** Updates that cannot be verified are no longer installed, and Linux updates match how the app was installed (e273458)
- **core** Desktop TUN no longer loses the network when it starts after the network changed (d135ef0)
- **update** Updates are verified against the published checksums again (7ca950d)
- **windows** Hand the foreground back after the tray menu closes (6b0587e)
- **core** Update sing-tun to v0.4.29 plus the macOS DNS flush fix (297ab2b)
- **dns** Keep proxy nameservers when respect-rules is enabled (9facfce)
- **macos** Keep the menu bar menu working with traffic titles and full-screen apps (0b99841)

## v3.5.8 (2026-11-09)

**Bug Fixes**

- **tun** Hysteria2 connects over TUN again: every install moves to the mips TUN stack, the only one it works on macOS (f3d333d)

## v3.5.7 (2026-11-08)

**Breaking Changes**

- **macos** macOS 12 is no longer supported; macOS 13 or later is required. (3d161f0)

**Features**

- **profiles** Send custom request headers with a subscription download (84a81d8)
- **proxies** Copy a proxy node as Clash YAML from its context menu (553ced6)
- **delay** Show "DNS failed" when a delay test fails to resolve the node (41798b0)
- **update** Stop offering macOS updates the system is too old to run (31dd5bd)

**Bug Fixes**

- **core** Keep the geodata URLs a profile sets instead of the app's (6c81f30)
- **linux** Clear the system proxy a crashed run left on Linux (3e09929)
- **windows** Clear the system proxy a crashed run left on Windows (74a63c3)
- **android** Fix Android crashes and a stuck launch screen caused by the Vulkan renderer (fb0712a)

## v3.5.6 (2026-11-07)

**Features**

- **android** The quick settings tile toggles without closing the panel and shows the current profile (d6f50c7)

**Bug Fixes**

- **macos** Show one decimal for macOS menu bar speeds in MB and above (daa7146)
- **android** Improve compatibility with Android devices using 16 KB memory pages. (742d3ae)
- **macos** Clear the system proxy a crashed run left on macOS (7b2c57e)
- **network** Turning on IPv6 now enables it for the core resolver and DNS, so IPv6 proxy servers connect instead of failing with "ip version error". (19af3ac)

## v3.5.5 (2026-11-06)

**Bug Fixes**

- **core** Hysteria2 and other nodes connect at once after turning on TUN on Windows, macOS and Linux (4ef0199)
- **core** Status checks on Windows and macOS finish in one pass when turning on TUN (10be40c)
- **dashboard** The dashboard keeps a passed status check on show while it re-checks (56bdf3d)
- **network** Status checks on desktop finish in one pass after turning on TUN (b173da6)
- **tun** Desktop TUN uses an MTU of 1500 unless the profile or settings pick one (8614458)
- **core** Hysteria2 and other nodes no longer fail right after turning on TUN on desktop (10bab66)

## v3.5.4 (2026-11-06)

**Features**

- **proxies** The proxies page keeps its search when you come back to it (2ecbf55)
- **proxies** The proxies page warns when a group's filter leaves no node, or GLOBAL is set to DIRECT in global mode (a907d7d)

**Bug Fixes**

- **core** Switching mode closes the connections the old mode routed, like switching proxies (3a11b43)
- **linux** Fix the Linux AppImage opening to a black window on newer distributions (e47f312)

## v3.5.3 (2026-11-05)

**Features**

- **app** Requests and live connections on one page, a smoother traffic card and new log lists, from upstream FlClash v0.9.3 (e61d9f9)
- **app** Auto-select groups leave an unusable first node at once, from upstream FlClash v0.9.3-pre.2 (053d84c)
- **update** Windows updates install silently and reopen the app (2b03025)
- **app** A rebuilt interface and reworked Core protocol, from upstream FlClash v0.9.3-pre.1 (875cab6)

**Bug Fixes**

- **android** Hysteria2 and other QUIC nodes connect right after the VPN starts (6b6404e)
- **core** Hysteria2 nodes no longer fail right after the app starts or the network changes (132648d)
- **tun** The TUN MTU defaults to 1500 so large downloads no longer stall; an MTU left at the old 9000 moves to it (2ebcf42)
- **android** Fix a build error in the Android plugin (cd01992)

## v3.5.2 (2026-10-24)

**Features**

- **app** Optional general overrides that apply sooner, from upstream FlClash v0.9.2 (94e5002)
- **update** A beta program page to join or leave the beta and see the current channel (b26f18a)
- **update** A beta channel in the updater that returns to the stable release once it ships (bc2c3fd)
- **app** DNS cache clearing, profile QR codes, phone-to-TV links, an access control bar and mihomo v1.19.33 (7054062)

## v3.5.1 (2026-10-17)

**Features**

- **app** Proxy group tabs as chips, a reworked scan page, no more password keyboard on plain text fields, popup and drag-back fixes, and the corrected strict route description in every language (11f975c)

## v3.5.0 (2026-10-17)

**Breaking Changes**

- **app** Custom overwrites are removed; rebuild them as custom profiles (79686f5)

**Features**

- **app** Redesigned dashboard, theme colors and proxy cards, French, Spanish and Korean, rewritten terms of use to sign once more, and no more Firebase analytics or crash reporting (8798eba)
- **app** Custom profiles, per-key DNS, NTP, sniffer and TUN settings, stacked sheets and context menus, and Android launcher shortcuts (79686f5)

**Bug Fixes**

- **branding** The macOS menu bar, Dock and the Linux link handler show Panorama Secure Access (664e575)

## v3.4.3 (2026-10-10)

Internal improvements only.

## v3.4.2 (2026-10-10)

**Features**

- **update** Updates now download in the background with a progress card and install in one tap (f2882e7)

## v3.4.1 (2026-10-10)

**Features**

- **branding** New keyhole logo across the app, tray and launcher icons (e1178b4)

## v3.4.0 (2026-10-09)

**Features**

- **app** Redesigned navigation with a sidebar and floating dock, new dashboard cards, a DNS query log and system tray hotkeys (85581fc)

**Bug Fixes**

- **core** Patch known vulnerabilities in the Go networking and cryptography dependencies (golang.org/x/crypto 0.57.0, golang.org/x/net 0.60.0) (477cdcf)

<!-- changelog:frozen -->
<!-- Entries below predate the structured pipeline. Their wording is kept as written; only the heading and list style were normalized. -->

## v0.8.99 (2026-10-03)

**Features**

- **editor** Editor word wrap and snippets (e131675)
- **dashboard** More dashboard cards (e62afb7)
- **views** Hide timed-out nodes and search every list (8378c70)
- **ui** Sidebar, floating dock and drag to go back (841d603)
- **ui** New app glyphs, empty states and theme page (ee6a497)
- **overwrite** Invalid override warnings and rule presets (46fb7fe)
- **config** DNS query log and per-key DNS/NTP overrides (a390a42)
- **core** Proxied service checks and outbound IP risk (8068e68)
- **platform** Tray hotkeys, node delays and a delay test (1e97716)

**Bug Fixes**

- **core** A changed resource link is now used by the next sync and by auto update (ff23f30)
- **core** DNS lookups no longer fail on networks that report no DNS servers (e55f6d1)
- **proxies** Smaller icons in icon-only group headers (786a6ab)
- **core,android** Push notifications reconnect in Doze (1e9955d)
- **backup,database** Restores never apply halfway (bee8f24)

## v0.8.98 (2026-09-14)

**Bug Fixes**

- **resources** Refresh the geo file size and time after an update finishes (c5bf5bd)
- **core** Keep the core running while Windows sleeps with the app suspended (60f371a)

## v0.8.97 (2026-09-10)

**Features**

- **ui** Rework the app UI and refresh the localization (26cfbaf)
- **app** Rework the app layer and window handling, and add proxy authentication (aaf934c)
- **desktop** Rework the desktop runners, packaging, and native build (c0fcbc0)
- **android** Rework the Android VPN service and lifecycle handling (ae29f38)
- **plugins** Rework the desktop plugins and add the Helper service and Rust bridge (adf715f)
- **core** Rework the core IPC and process lifecycle (c6eaa0a)

<!-- changelog:frozen -->
<!-- Entries below predate the structured pipeline. Their wording is kept as written; only the heading and list style were normalized. -->

## v0.8.96 (2026-08-17)

- Optimize commented policy
- Fix whole group delay test failing on Windows
- Optimize package icon loading and connections polling

## v0.8.95 (2026-08-14)

- Optimize core service
- Optimize Android TV launcher icon
- Optimize back navigation
- Optimize more details
- Fix some issues
- Optimize app layout
- Optimize focus control
- Adjust android process

## v0.8.94 (2026-07-11)

- Fix macos performance issue
- Support custom global-ua
- Update core
- Optimize some details
- Fix linux silent launching not working

## v0.8.93 (2026-05-29)

- Support custom overwrite
- Support run on demand
- Optimize windows ipc
- Optimize windows arm64
- Optimize build
- Optimize some details
- Update core

## v0.8.92 (2026-02-02)

- Add sqlite store
- Optimize android quick action
- Optimize backup and restore
- Optimize more details

## v0.8.91 (2025-12-12)

- Fix windows some issues
- Optimize overwrite handle
- Optimize access control page
- Optimize some details

## v0.8.90 (2025-10-08)

- Fix android tile service
- Support append system DNS
- Fix some issues
- Update changelog

## v0.8.89 (2025-09-27)

- Fix some issues
- Optimize Windows service mode
- Update core
- Update changelog

## v0.8.88 (2025-09-23)

- Add android separates the core process
- Support core status check and force restart
- Optimize proxies page and access page
- Update flutter and pub dependencies
- Update go version
- Optimize more details
- Update changelog

## v0.8.87 (2025-07-29)

- Optimize desktop view
- Optimize logs, requests, connection pages
- Optimize windows tray auto hide
- Optimize some details
- Update core
- Update changelog

## v0.8.86 (2025-06-15)

- Fix windows tun issues
- Optimize android get system dns
- Optimize more details
- Update changelog

## v0.8.85 (2025-06-07)

- Support override script
- Support proxies search
- Support svg display
- Optimize config persistence
- Add some scenes auto close connections
- Update core
- Optimize more details

## v0.8.84 (2025-05-01)

- Fix windows service verify issues
- Update changelog

## v0.8.83 (2025-05-01)

- Add windows server mode start process verify
- Add linux deb dependencies
- Add backup recovery strategy select
- Support custom text scaling
- Optimize the display of different text scale
- Optimize windows setup experience
- Optimize startTun performance
- Optimize android tv experience
- Optimize default option
- Optimize computed text size
- Optimize hyperOS freeform window
- Add developer mode
- Update core
- Optimize more details
- Add issues template
- Update changelog

## v0.8.82 (2025-04-18)

- Optimize android vpn performance
- Add custom primary color and color scheme
- Add linux nad windows arm release
- Optimize requests and logs page
- Fix map input page delete issues
- Update changelog

## v0.8.81 (2025-04-08)

- Add rule override
- Update core
- Optimize more details
- Update changelog

## v0.8.80 (2025-03-10)

- Optimize dashboard performance
- Fix some issues
- Fix unselected proxy group delay issues
- Fix asn url issues
- Update changelog

## v0.8.79 (2025-03-07)

- Fix tab delay view issues
- Fix tray action issues
- Fix get profile redirect client ua issues
- Fix proxy card delay view issues
- Add Russian, Japanese adaptation
- Fix some issues
- Update changelog

## v0.8.78 (2025-03-05)

- Fix list form input view issues
- Fix traffic view issues
- Update changelog

## v0.8.77 (2025-03-05)

- Optimize performance
- Update core
- Optimize core stability
- Fix linux tun authority check error
- Fix some issues
- Fix scroll physics error
- Update changelog

## v0.8.75 (2025-02-09)

- Add windows storage corruption detection
- Fix core crash caused by windows resource manager restart
- Optimize logs, requests, access to pages
- Fix macos bypass domain issues
- Update changelog

## v0.8.74 (2025-02-03)

- Fix some issues
- Update changelog

## v0.8.73 (2025-02-02)

- Update popup menu
- Add file editor
- Fix android service issues
- Optimize desktop background performance
- Optimize android main process performance
- Optimize delay test
- Optimize vpn protect
- Update changelog

## v0.8.72 (2025-01-10)

- Update core
- Fix some issues
- Update changelog

## v0.8.71 (2025-01-09)

- Remake dashboard
- Optimize theme
- Optimize more details
- Update flutter version
- Update changelog

## v0.8.70 (2024-12-09)

- Support better window position memory
- Add windows arm64 and linux arm64 build script
- Optimize some details

## v0.8.69 (2024-12-06)

- Remake desktop
- Optimize change proxy
- Optimize network check
- Fix fallback issues
- Optimize lots of details
- Update change.yaml
- Fix android tile issues
- Fix windows tray issues
- Support setting bypassDomain
- Update flutter version
- Fix android service issues
- Fix macos dock exit button issues
- Add route address setting
- Optimize provider view
- Update changelog
- Update CHANGELOG.md

## v0.8.67 (2024-11-09)

- Add android shortcuts
- Fix init params issues
- Fix dynamic color issues
- Optimize navigator animate
- Optimize window init
- Optimize fab
- Optimize save

## v0.8.66 (2024-10-26)

- Fix the collapse issues
- Add fontFamily options

## v0.8.65 (2024-10-26)

- Update core version
- Update flutter version
- Optimize ip check
- Optimize url-test

## v0.8.64 (2024-10-12)

- Update release message
- Init auto gen changelog
- Fix windows tray issues
- Fix urltest issues
- Add auto changelog
- Fix windows admin auto launch issues
- Add android vpn options
- Support proxies icon configuration
- Optimize android immersion display
- Fix some issues
- Optimize ip detection
- Support android vpn ipv6 inbound switch
- Support log export
- Optimize more details
- Fix android system dns issues
- Optimize dns default option
- Fix some issues
- Update readme

## v0.8.60 (2024-09-17)

- Fix build error2
- Fix build error
- Support desktop hotkey
- Support android ipv6 inbound
- Support android system dns
- fix some bugs

## v0.8.59 (2024-09-09)

- Fix delete profile error

## v0.8.58 (2024-09-08)

- Fix submit error 2
- Fix submit error
- Optimize DNS strategy
- Fix the problem that the tray is not displayed in some cases
- Optimize tray
- Update core
- Fix some error

## v0.8.57 (2024-09-02)

- Fix tun update issues
- Add DNS override
- Fixed some bugs
- Optimize more detail
- Add Hosts override

## v0.8.56 (2024-08-26)

- fix android tip error
- fix windows auto launch error

## v0.8.55 (2024-08-25)

- Fix windows tray issues
- Optimize windows logic
- Optimize app logic
- Support windows administrator auto launch
- Support android close vpn

## v0.8.53 (2024-08-15)

- Change flutter version
- Support profiles sort
- Support windows country flags display
- Optimize proxies page and profiles page columns

## v0.8.52 (2024-08-11)

- Update flutter version
- Update version
- Update timeout time
- Update access control page
- Fix bug

## v0.8.51 (2024-08-05)

- Optimize provider page
- Optimize delay test
- Support local backup and recovery
- Fix android tile service issues

## v0.8.49 (2024-07-31)

- Fix linux core build error
- Add proxy-only traffic statistics
- Update core
- Optimize more details
- Merge pull request #140 from txyyh/main
- 添加自建 F-Droid 仓库相关 workflow
- Rename readme fingerprint
- Rename workflow deploy repo name
- Add download guide to README
- Add push release files to fdroid-repo

## v0.8.48 (2024-07-25)

- Optimize proxies page
- Fix ua issues
- Optimize more details

## v0.8.47 (2024-07-22)

- Fix windows build error

## v0.8.46 (2024-07-22)

- Update app icon
- Fix desktop backup error
- Optimize request ua
- Change android icon
- Optimize dashboard

## v0.8.44 (2024-07-18)

- Remove request validate certificate
- Sync core

## v0.8.43 (2024-07-18)

- Fix windows error

## v0.8.42 (2024-07-18)

- Fix setup.dart error
- Fix android system proxy not effective
- Add macos arm64

## v0.8.41 (2024-07-17)

- Optimize proxies page
- Support mouse drag scroll
- Adjust desktop ui
- Revert "Fix android vpn issues"
- This reverts commit 891977408e6938e2acd74e9b9adb959c48c79988.

## v0.8.40 (2024-07-15)

- Fix android vpn issues
- Fix android vpn issues
- Rollback partial modification

## v0.8.39 (2024-07-15)

- Fix the problem that ui can't be synchronized when android vpn is occupied by an external
- Override default socksPort,port

## v0.8.38 (2024-07-14)

- Fix fab issues

## v0.8.37 (2024-07-14)

- Update version
- Fix the problem that vpn cannot be started in some cases
- Fix the problem that geodata url does not take effect

## v0.8.36 (2024-07-13)

- Update ua
- Fix change outbound mode without check ip issues
- Separate android ui and vpn
- Fix url validate issues 2
- Add android hidden from the recent task
- Add geoip file
- Support modify geoData URL

## v0.8.35 (2024-07-07)

- Fix url validate issues
- Fix check ip performance problem
- Optimize resources page

## v0.8.34 (2024-07-04)

- Add ua selector
- Support modify test url
- Optimize android proxy
- Fix the error that async proxy provider could not selected the proxy

## v0.8.33 (2024-07-01)

- Fix android proxy error
- Fix submit error
- Add windows tun
- Optimize android proxy
- Optimize change profile
- Update application ua
- Optimize delay test

## v0.8.32 (2024-06-28)

- Fix android repeated request notification issues

## v0.8.31 (2024-06-28)

- Fix memory overflow issues

## v0.8.30 (2024-06-27)

- Optimize proxies expansion panel 2
- Fix android scan qrcode error

## v0.8.29 (2024-06-27)

- Optimize proxies expansion panel
- Fix text error

## v0.8.28 (2024-06-26)

- Optimize proxy
- Optimize delayed sorting performance
- Add expansion panel proxies page
- Support to adjust the proxy card size
- Support to adjust proxies columns number
- Fix autoRun show issues
- Fix Android 10 issues
- Optimize ip show

## v0.8.26 (2024-06-22)

- Add intranet IP display
- Add connections page
- Add search in connections, requests
- Add keyword search in connections, requests, logs
- Add basic viewing editing capabilities
- Optimize update profile

## v0.8.25 (2024-06-19)

- Update version
- Fix the problem of excessive memory usage in traffic usage.
- Add lightBlue theme color
- Fix start unable to update profile issues
- Fix flashback caused by process

## v0.8.23 (2024-06-16)

- Add build version
- Optimize quick start
- Update system default option

## v0.8.22 (2024-06-16)

- Update build.yml
- Fix android vpn close issues
- Add requests page
- Fix checkUpdate dark mode style error
- Fix quickStart error open app
- Add memory proxies tab index
- Support hidden group
- Optimize logs
- Fix externalController hot load error

## v0.8.21 (2024-06-13)

- Add tcp concurrent switch
- Add system proxy switch
- Add geodata loader switch
- Add external controller switch
- Add auto gc on trim memory
- Fix android notification error

## v0.8.20 (2024-06-12)

- Fix ipv6 error
- Fix android udp direct error
- Add ipv6 switch
- Add access all selected button
- Remove android low version splash

## v0.8.19 (2024-06-10)

- Update version
- Add allowBypass
- Fix Android only pick .text file issues

## v0.8.18 (2024-06-09)

- Fix search issues

## v0.8.17 (2024-06-09)

- Fix LoadBalance, Relay load error
- Fix build.yml4
- Fix build.yml3
- Fix build.yml2
- Fix build.yml
- Add search function at access control
- Fix the issues with the profile add button to cover the edit button
- Adapt LoadBalance and Relay
- Add arm
- Fix android notification icon error

## v0.8.16 (2024-06-08)

- Add one-click update all profiles
- Add expire show

## v0.8.15 (2024-06-06)

- Temp remove tun mode
- Remove macos in workflow
- Change go version

## v0.8.14 (2024-06-06)

- Update Version
- Fix tun unable to open

## v0.8.13 (2024-06-06)

- Optimize delay test2
- Optimize delay test
- Add check ip
- add check ip request

## v0.8.12 (2024-06-06)

- Fix the problem that the download of remote resources failed after GeodataMode was turned on, which caused the
  application to flash back.
- Fix edit profile error
- Fix quickStart change proxy error
- Fix core version

## v0.8.10 (2024-06-05)

- Fix core version

## v0.8.9 (2024-06-05)

- Update file_picker
- Add resources page
- Optimize more detail
- Add access selected sorted
- Fix notification duplicate creation issue
- Fix AccessControl click issue

## v0.8.7 (2024-05-31)

- Fix Workflow
- Fix Linux unable to open
- Update README.md 3
- Create LICENSE
- Update README.md 2
- Update README.md
- Optimize workFlow

## v0.8.6 (2024-05-31)

- optimize checkUpdate

## v0.8.5 (2024-05-30)

- Fix submit error

## v0.8.4 (2024-05-30)

- add WebDAV
- add Auto check updates
- Optimize more details
- optimize delayTest

## v0.8.2 (2024-05-15)

- upgrade flutter version

## v0.8.1 (2024-05-15)

- Update kernel
- Add import profile via QR code image

## v0.8.0 (2024-05-11)

- Add compatibility mode and adapt clash scheme.

## v0.7.14 (2024-05-07)

- update Version
- Reconstruction application proxy logic

## v0.7.13 (2024-05-06)

- Fix Tab destroy error

## v0.7.12 (2024-05-06)

- Optimize repeat healthcheck

## v0.7.11 (2024-05-06)

- Optimize Direct mode ui

## v0.7.10 (2024-05-06)

- Optimize Healthcheck
- Remove proxies position animation, improve performance
- Add Telegram Link
- Update healthcheck policy
- New Check URLTest
- Fix the problem of invalid auto-selection

## v0.7.8 (2024-05-05)

- New Async UpdateConfig
- add changeProfileDebounce
- Update Workflow
- Fix ChangeProfile block
- Fix Release Message Error

## v0.7.7 (2024-05-04)

- Update Selector 2

## v0.7.6 (2024-05-04)

- Update Version
- Fix Proxies Select Error

## v0.7.5 (2024-05-03)

- Fix the problem that the proxy group is empty in global mode.
- Fix the problem that the proxy group is empty in global mode.

## v0.7.4 (2024-05-03)

- Add ProxyProvider2

## v0.7.3 (2024-05-03)

- Add ProxyProvider
- Update Version
- Update ProxyGroup Sort
- Fix Android quickStart VpnService some problems

## v0.7.1 (2024-05-01)

- Update version
- Set Android notification low importance
- Fix the issue that VpnService can't be closed correctly in special cases
- Fix the problem that TileService is not destroyed correctly in some cases
- Adjust tab animation defaults
- Add Telegram in README_zh_CN.md
- Add Telegram

## v0.7.0 (2024-04-30)

- update mobile_scanner
- Initial commit
