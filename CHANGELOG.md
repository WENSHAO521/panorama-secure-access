## v3.3.20

- Bump version to 3.3.20

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Add Korean and Traditional Chinese locales

- Two new supported languages: Korean (ko) - a fresh translation of

- every string - and Traditional Chinese (zh_TW) - derived from the

- complete zh_CN source via OpenCC's s2twp (Simplified-to-Traditional

- with Taiwan phrasing) conversion, then hand-checked against common

- mainland/Taiwan tech-terminology divergences (e.g. avoiding "質量"

- where Taiwan usage means "品質"). The disclaimer's quotation marks

- use Taiwan-standard 「」 brackets instead of the mainland-style

- curly quotes carried over by the conversion.

- Every existing locale (en/zh_CN/ja/ru) also gets translated display

- names for these two new locales so the language picker shows correct

- labels for them regardless of which language is currently active.

- All six arb files now carry the same 556 keys with matching ICU

- placeholders, verified programmatically before generating.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Translate leftover English strings in ja/ru locales

- A batch of location-permission/battery-optimization/on-demand/exclude-SSID

- strings had zh_CN and en translations but were never carried over to

- Japanese and Russian - found by diffing every locale's values against

- en.arb. ja is now fully translated; ru keeps Logcat/User-Agent in Latin

- script deliberately, matching how SSID/Wi-Fi are already left

- untranslated everywhere - they're technical proper nouns, not gaps.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

## v3.3.19

- Bump version to 3.3.19

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Rewrite the disclaimer with a more professional, on-brand tone

- Restructures disclaimerDesc (en/zh_CN/ja/ru) from one dense run-on

- paragraph into clearly separated statements - scope of use, no

- warranty, user responsibility, limitation of liability - opening with

- a brand-voiced line instead of jumping straight into legal boilerplate.

- The legal substance is unchanged (internal testing/education only, no

- commercial use, "AS IS", user bears the risk, liability capped to the

- extent the law allows) across all four languages.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

## v3.3.18

- Bump version to 3.3.18

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Adopt Inter as the app-wide font; brand-tint the desktop sidebar glass

- Bundles Inter (SIL Open Font License, from Google Fonts' variable-font

- release - one file covers every weight) as assets/fonts/Inter.ttf and

- sets it as ThemeData.fontFamily, replacing the per-platform Material

- default (Roboto/San Francisco/Segoe) for a consistent brand look

- across desktop and mobile. Inter only covers Latin/Cyrillic/Greek -

- CJK glyphs (zh/ja locales) fall through to the platform's system font

- the same way they already render today, so this only changes Latin

- text, numerals, and the en/ru locales.

- Also brings the desktop NavigationRail's background (AppSidebarContainer

- ._buildBackground in app_manager.dart) in line with the AppBar/bottom

- NavigationBar/GlassSurface brand tint added earlier - it already blurred

- and tinted with GlassSurfaceType.chrome opacity, it just predated

- GlassTokens.tint() and was still using a flat neutral colour and a

- hand-rolled border instead of the shared GlassTokens.borderSideFor().

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

## v3.3.17

- Bump version to 3.3.17

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Drop OpenContainer for Tools sub-page navigation; push like every other page

- The AmbientBackground fix in the previous commit didn't fix the

- Android flash - it made it more visible. OpenContainer's own code has

- been unchanged since v3.3.12, so the flash was never really about

- what color/background sits behind it; it's a structural issue in the

- animations package itself. OpenContainer's buildPage swaps to a

- completely different widget tree the instant its animation completes

- (mid-transition: a FittedBox-scaled preview inside a scrim Container;

- settled: a plain Material) - an abrupt rebuild that can drop a frame

- on Android, and that dropped frame has nothing to paint but the bare

- window colour. Making openColor/the destination transparent (previous

- commit) turned that into a stark white pop against a colorful

- gradient instead of a same-toned blip, which is why it got worse

- rather than better.

- Mobile now pushes the destination page through BaseNavigator (the

- same SharedAxisTransition + outside-the-animation AmbientBackground

- every other page in the app already uses, fixed in fe5348e) instead

- of OpenContainer's container-transform. No structural tree swap, no

- flash. Desktop and debug builds are unaffected - they already used

- showExtend, never OpenContainer.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

## v3.3.16

- Bump version to 3.3.16

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Fix Android Tools-page white flash; replace Liquid Glass sheen with brand-tinted glass

- The white flash on Android when opening a Tools sub-page (Theme,

- Backup, Language, etc.) wasn't in CommonRoute/CommonDesktopRoute

- (already fixed) - ListItem.open funnels mobile navigation through

- OpenContainer (container_transform) instead, a separate code path

- that fix never touched. OpenContainer's openColor was a flat

- colorScheme.surface, and since its route is opaque, once the

- transition settles Flutter stops painting anything behind it - so

- the destination page sat on a plain surface-toned screen instead of

- the app's gradient AmbientBackground, reading as a flash. Both

- closedColor/openColor are now transparent and openBuilder paints its

- own AmbientBackground behind the destination widget, matching every

- other route in the app.

- Also drops the "Liquid Glass" top-edge sheen highlight added

- alongside that fix - it read as an Apple-style effect that didn't

- fit the app. In its place, GlassSurface/GlassTokens now mix a small

- amount of the theme's ColorScheme.primary into every glass panel's

- fill and border instead of a flat grey tint (GlassTokens.tint()),

- cascading to dialogs, sheets, popups, proxy cards, the AppBar, and

- the bottom NavigationBar. The tint follows whatever primary color is

- active - default brand violet, a user-picked accent, or Material You

- dynamic color - so the frosted-glass look stays consistent with the

- rest of the theme without borrowing another platform's visual

- signature.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Remove the Windows-only preview workflow

- Unneeded now that we're going through the normal all-platform tagged

- release build instead.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

## v3.3.15

- Bump version to 3.3.15

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Fix Tools page-transition white flash; add Liquid Glass sheen globally

- CommonRoute/CommonDesktopRoute painted AmbientBackground inside the

- push transition's Fade/SharedAxis animation. Since both routes are

- opaque, Flutter stops painting whatever sits behind them as soon as

- they're pushed, not once the transition settles - so the first frames

- (animation value near 0) painted neither the old route nor the new

- one, flashing the bare window colour. Moving AmbientBackground outside

- the animated subtree makes each route fully opaque from frame one.

- Also adds a subtle top-edge "sheen" highlight - the light-catching

- look of Apple's Liquid Glass material - built into the shared

- GlassSurface widget (skipped for the repeated type used by proxy list

- cards, to avoid extra paint cost there) plus the two hand-rolled glass

- surfaces that don't go through GlassSurface: the AppBar chrome and the

- bottom NavigationBar. Cascades to every existing glass surface in the

- app (dialogs, popups, sheets, Tools settings panels) with no per-call

- edits needed.

- Adds a temporary, manually-triggered CI workflow (preview-windows.yaml)

- to build just the Windows target on a GitHub-hosted runner, since this

- machine has no local Visual Studio install for `flutter run -d windows`.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

## v3.3.13

- Fix Windows installer SetupIconFile path (root cause of icon-embed failure)

- The generated .iss dumped by the new failure-debug step showed the real

- bug: SetupIconFile resolved to

-   D:\a\panorama-secure-access\panorama-secure-access\..\windows\runner\resources\app_icon.ico

- MakeExeConfig.fromJson (flutter_distributor fork) joins make_config.yaml's

- setup_icon_file onto Directory.current -- the repo root `dart setup.dart

- windows` runs from -- rather than leaving it for Inno Setup to resolve

- relative to the generated .iss's own location the way locales[].file

- does. With a leading `..\` (written as if relative to dist/, one level

- below repo root) and GitHub Actions' standard doubly-nested checkout

- path (D:\a\<repo>\<repo>\...), that overshoots past the repo root

- entirely, landing on a directory that doesn't exist. Reproduced the

- exact "Updating icons (Setup.e32): The system cannot find the path

- specified" error locally by compiling that literal absolute path, and

- confirmed the fix (dropping the `..\`, since the join already adds the

- repo root) resolves to the real file.

- This was never about the Inno Setup version -- revert the version-pin

- workaround from the previous two commits, it was chasing the wrong

- lead. Keep the .iss dump-on-failure step; it's what surfaced the real

- path.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Dump generated .iss content on Windows packaging failure for debugging

- Pinning Inno Setup to 6.7.3 (previous commit) did not fix the "Updating

- icons (Setup.e32): The system cannot find the path specified" failure

- -- CI confirmed it's actually running 6.7.3 now and still hits the

- identical error, which rules out the runner's preinstalled ISCC version

- as the cause. A local repro with a hand-reconstructed .iss (matching

- make_config.yaml's values) compiles fine under 6.7.3, so something

- about the real generated file differs from that reconstruction. Add a

- failure-only step that prints the actual generated dist/*.iss (it's

- left behind on a failed compile, only deleted after success) so the

- real content can be inspected directly instead of guessed at.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Fix Inno Setup install-verification step exiting non-zero

- ISCC.exe with no arguments prints its usage banner and exits 1 by

- design (it's a CLI tool, not a --version flag) -- calling it bare to

- confirm the install failed the step before the actual build even

- started. Check the file exists and read its version from the binary's

- own metadata instead of executing it.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Pin Inno Setup to 6.7.3 in CI to fix Windows packaging failure

- Both Windows build jobs (amd64, arm64) fail identically at "Updating

- icons (Setup.e32)" with "Error on line 15 ...: The system cannot find

- the path specified" while ISCC embeds SetupIconFile into the installer

- stub. Our packaging config, the .iss template, and app_icon.ico are

- byte-for-byte unchanged since the last Windows build that succeeded

- (v3.3.12, Aug 21), and diffing the flutter_distributor fork's exe/Inno

- Setup packaging code between then and the commit CI resolves now shows

- no relevant change either (setup.dart floats on `--git-ref FlClash`,

- so CI silently picks up whatever's newest on that branch, but the exe

- maker path is untouched). That leaves the runner image's preinstalled

- Inno Setup itself (6.7.1) as the moving part.

- Reproduced the real make_config.yaml + app_icon.ico locally: it fails

- under whatever combination the CI runner has, but compiles cleanly

- under a fresh Inno Setup 6.7.3 install. Add a step that downloads and

- silently installs 6.7.3 over the runner's preinstalled copy before

- packaging, so Windows builds don't depend on whichever Inno Setup

- version happens to ship on the image.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Fix libc version conflict in services/helper Cargo.lock

- The previous dependency bump (342c421) hand-edited Cargo.lock without

- a cargo toolchain and missed that tokio 1.43.1 tightened its own libc

- requirement, leaving it unsatisfiable against the locked backtrace/libc

- pair. This breaks MSBuild's cargo invocation on Windows (both amd64 and

- arm64) with "failed to select a version for `libc`", which is what

- failed CI on v3.3.13. Resolved properly via `cargo update -p libc`

- (0.2.167 -> 0.2.189) and verified the full dependency graph now

- compiles (only local failure left is a missing MSVC linker on this

- machine, unrelated to the fix).

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Bump version to 3.3.13

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Upgrade same-major-version dependencies (flutter pub upgrade)

- 81 packages moved to newer, semver-compatible versions already

- permitted by their existing pubspec.yaml caret constraints - this was

- just pubspec.lock being stale, no constraint changes needed except

- adding cross_file (see below).

- file_picker landed a breaking change within its 12.x beta series

- (FilePicker.saveFile/getDirectoryPath now return Uri instead of

- String, since a saved/picked file may be behind a content://, http(s)://,

- data:, or blob: URI depending on platform, not just a local file path).

- Fixed lib/common/picker.dart to convert the Uri appropriately (only

- non-Android platforms ever construct a File from the result, so only

- that branch needs toFilePath(); everywhere else just needs the

- string form for a null check) and rewrote test/common/picker_test.dart's

- PlatformFile construction against the new abstract base class shape

- (uri/xFile-based now, was a plain data constructor) - added cross_file

- as a dev_dependency since the test needs XFile directly.

- Verified with `flutter analyze` (0 issues) and `flutter test` (441

- tests, same single pre-existing NetworkDetection failure as on

- unmodified origin/main).

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Bump animations 2.1.1->3.0.0 and dynamic_color 1.8.1->2.1.0

- Both were capped below their latest major by the pubspec.yaml caret

- constraint. Checked first: our usage is only the long-stable API

- surface (SharedAxisTransition, PageTransitionSwitcher,

- FadeThroughTransition, OpenContainer, DynamicColorPlugin.getCorePalette),

- none of which changed shape in either package's 3.0.0/2.0.0 release.

- Both packages' changelogs describe their major bump as "migrate to

- material_ui" internally - this pulls in material_ui 1.2.0 and

- cupertino_ui 1.0.2 as new transitive deps (visible in the pubspec.lock

- diff), but we don't call into either package ourselves, so this is

- purely an internal implementation swap inside animations/dynamic_color.

- Verified with `flutter analyze` (0 issues) and `flutter test` (441

- tests, same single pre-existing NetworkDetection failure as on

- unmodified origin/main, unrelated to this change).

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Fix compile errors left by the icon-loading/polling cherry-pick

- flutter analyze wasn't available when be132b5 was merged (no Flutter

- SDK in that environment); with a real toolchain now on hand it reports

- 12 errors, all from pieces the cherry-picked commit (903e2b8) assumed

- were already present from other upstream commits we didn't merge:

- - coreFailureLogLevel(): used by connections.dart/memory_info.dart but

-   only ever defined in upstream's lib/core/method.dart, which doesn't

-   exist in this fork's lib/core/ layout. Added a small self-contained

-   version to lib/common/print.dart instead of porting that file -

-   upstream's version also branches on CoreMethodException, a type this

-   fork's core layer doesn't have.

- - PageActivityScope: read by ActivePollingMixin.didChangeDependencies

-   but never defined here. Ported the InheritedWidget itself (it

-   defaults isActiveOf() to true with no ancestor, so this is a no-op

-   everywhere until something actually wraps a subtree in it - not

-   wiring that up in home.dart to avoid touching page-navigation

-   structure this fork has customized).

- - lib/views/dashboard/widgets/memory_info.dart imported a nonexistent

-   lib/core/method.dart for nothing it actually used - dropped.

- - test/plugins/app_test.dart covered App.didCrashOnPreviousExecution(),

-   which upstream backs with FirebaseCrashlytics.didCrashOnPreviousExecution()

-   on the Android side. That's a third-party crash-reporting SDK this

-   fork doesn't currently pull in, and adding it isn't something to do

-   as a side effect of an icon-loading fix. Removed the 3 tests

-   covering that method; kept the icon-cache tests it was bundled with.

- Verified with `flutter analyze` (0 issues) and `flutter test` (441

- tests, only 1 failure - NetworkDetection's stale-check-cancellation

- test in test/providers/app_test.dart, unrelated file, unrelated to

- anything in this session's changes, still failing the same way on

- plain origin/main).

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Update vendored Mihomo core from a Jul-2026 snapshot to the v0.8.97 line

- The core/Clash.Meta submodule was pinned to commit 80362fc (chen08209's

- FlClash branch, committer date 2026-07-01). That branch itself hasn't

- moved, but the fork's per-release branches have: the tip of

- feature/FlClash/release/v0.8.97 (70f0570, committer date 2026-08-23) is

- 216 commits and 300 files ahead of our pin on the same fork lineage, and

- carries newer metacubex/quic-go (0.61.1, was 0.59.1) and metacubex/gvisor

- (2026-08-10, was 2025-12-27) snapshots plus whatever upstream mihomo

- protocol/perf work landed in between.

- Repointed .gitmodules at that branch and re-ran `go mod tidy` for

- core/go.mod + core/go.sum. Verified with `go build ./...` and

- `go vet ./...` for both the core wrapper module and the Clash.Meta

- submodule itself (both clean, exit 0) - this is a version bump within

- the same maintained fork lineage, not a hand re-applied patch set.

- Not verified: the submodule's own `go test ./...` (still running,

- proxy/network-facing test suites are slow and some may need real

- sockets/TUN this sandbox can't provide) and actual runtime behavior -

- no way to exercise the VPN/TUN path here. Recommend running the app

- locally before shipping a release off this core.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Bump vulnerable Rust deps flagged by Dependabot (tokio, bytes, rand)

- No cargo toolchain available in this environment, so these were

- resolved by hand against the crates.io sparse index instead of

- `cargo update`: for each bump, compared the target version's

- dependency requirements against what's already pinned in the lockfile

- to confirm the resolved dependency graph doesn't actually change, then

- swapped in the real published checksum. Recommend a local `cargo

- check` as a final sanity pass.

- - services/helper/Cargo.lock: bytes 1.9.0 -> 1.11.1 (GHSA-434x-w66g-qw3r,

-   BytesMut::reserve integer overflow), rand 0.8.5 -> 0.8.6

-   (GHSA-cq8v-f236-94qc), tokio 1.41.1 -> 1.43.1 and its tokio-macros

-   dependency 2.4.0 -> 2.5.0 to satisfy tokio 1.43.1's ~2.5.0 requirement

-   (GHSA-rr8g-9fpq-6wmg, broadcast channel Sync unsoundness)

- - plugins/rust_api/rust/Cargo.lock: tokio 1.34.0 -> 1.38.2 (same GHSA)

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Optimize package icon loading and connections polling

- (cherry picked from commit 903e2b88799915349941b79c125593fd39bc171f)

- Conflicts resolved manually against this fork's connections/memory-info

- polling refactor and TV-icon cherry-pick; no upstream branding assets

- included.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Fix TV launcher icon branding after upstream cherry-pick

- The cherry-picked commit (9a99897) added FlClash's own wing-logo

- artwork for the new mipmap-television-* / ic_launcher_foreground_tv

- assets, which conflicts with this fork's rebrand (fed83db). Repoint

- the TV adaptive icon at our existing ic_launcher_foreground PNGs

- instead of the upstream vector, and drop the legacy pre-API26 webp

- fallbacks that still carried the original logo.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Optimize Android TV launcher icon

- (cherry picked from commit 9a99897864850e77a75ce0ee0d45a0053ebff4fb)

## v3.3.12

- Bump version to 3.3.12

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Replace deprecated withOpacity with withValues and fix const lint

- Resolves deprecated_member_use warnings in SliderDefaultsM3 by

- switching Color.withOpacity to Color.withValues(alpha:), and fixes

- a prefer_const_constructors warning in dialog_test.dart. Also

- includes dart format's reflow of lib/state.dart and

- lib/views/proxies/tab.dart.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Redesign Dashboard connection-status control as compact glass badge

- Replaces the flat solid-green success circle with an AppBar-scale

- tinted status control (connected/connecting/disconnected) matching

- the app's glass chrome, sized to sit naturally beside the edit action.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

## v3.3.11

- Bump version to 3.3.11

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Fix Windows installer branding, Publisher metadata, and install path

- Runner.rc's VERSIONINFO still carried legacy CompanyName=com.follow,

- InternalName=clash, and ProductName=clash; rebranded these plus

- LegalCopyright to Panorama Secure Access / Panorama Scholarly Group.

- OriginalFilename intentionally kept as FlClash.exe: it's a claim about the

- real on-disk filename (matches BINARY_NAME in windows/CMakeLists.txt), and

- AV/EDR tooling treats a mismatch there as a tamper signal.

- Found and fixed a real (not cosmetic) bug while auditing the Inno Setup

- packaging config: windows/packaging/exe/make_config.yaml used a `publisher`

- key, but the flutter_distributor fork's MakeExeConfig.fromJson only reads

- `publisher_name` — so the Add/Remove Programs "Publisher" column has been

- rendering blank regardless of its value. Renamed to the key the loader

- actually reads and set it to Panorama Scholarly Group.

- Also added install_dir_name pointing fresh installs at

- "Program Files\Panorama Secure Access" instead of the legacy "...\FlClash".

- This only seeds Inno Setup's DefaultDirName for a first-time install --

- upgrades are matched by AppId (unchanged), and Inno Setup reads the

- previously installed path back out of the existing uninstall registry key,

- so an existing FlClash-directory install keeps upgrading in place with no

- automatic rename/migration attempted.

- The full app-icon reference chain (Runner.rc -> app_icon.ico -> Inno

- Setup's SetupIconFile/UninstallDisplayIcon -> Start Menu/desktop shortcuts)

- was independently verified correct via the fork's actual source; none of

- it needed to change.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Redesign proxy strategy-group navigation and add semantic paragraph typography

- The strategy-group bar's trailing "open all groups" control rendered as an

- opaque near-solid rectangle (a right-edge fade whose gradient reached full

- opacity within 10% of its width). Replaced it with Row(Expanded(scrollable

- tabs), fixed selector button): a transparent 44x44 IconButton with real

- hover/press/focus overlay states, expand_more_rounded/chevron_right_rounded

- icon, and a genuinely subtle right-edge fade capped well below full chrome

- opacity. Selected tab now uses primary text plus a single rounded underline

- indicator (TabBarIndicatorSize.label) instead of any background/pill.

- Added AppTitle/AppBody/AppParagraph reusable text widgets. AppParagraph

- justifies long-form prose responsively (TextAlign.justify at >=280px,

- TextAlign.start below that, to avoid excessive CJK letter-spacing on narrow

- screens) and exposes an allowJustify escape hatch for paragraphs that read

- worse justified. Applied to the disclaimer dialog and About-page disclaimer

- card, and wired showMessage() with an opt-in longForm parameter (default

- false, zero behavior change for its other ~50 call sites) so the Crashlytics

- data-collection dialog also gets paragraph-quality typography.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

## v3.3.10

- Bump version to 3.3.10

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Fix desktop dialog width regression from the AlertDialog -> Dialog + GlassSurface migration

- CommonDialog capped its content area at maxWidth: 300 while the outer

- Column used CrossAxisAlignment.start, so a wide title or actions row

- could stretch the GlassSurface past 300px while content (text fields,

- message text) stayed pinned at 300px, left-aligned, with dead space on

- the right. Affected every CommonDialog/InputDialog call site, not just

- the URL import dialog.

- Central fix in lib/widgets/dialog.dart: a responsive max width (560px

- default, 640px via a new opt-in isLarge flag, both clamped to the

- window size on desktop; screen width minus a safe inset on mobile) via

- ConstrainedBox, plus CrossAxisAlignment.stretch so title/content/

- actions always share that width instead of each shrink-wrapping

- independently. Public API is additive only (isLarge defaults false).

- Audited every CommonDialog/InputDialog call site: removed two

- now-redundant width: 300 hacks that would have fought the central fix

- (showMessage in state.dart, and dead code in profiles/add.dart's

- unused URLFormDialog); wrapped the palette and hotkey-recorder dialogs'

- genuinely-narrow content in Center so it doesn't end up left-aligned

- in the wider surface; marked the rule add/edit dialog isLarge (dropdown

- + field + dropdown + chips is the one genuinely content-heavy case).

- Everything else needed no changes since Wrap already passes a bounded

- max-width to its children.

- Added test/widgets/dialog_test.dart covering the 560/640 caps, the

- mobile inset, the stretch behavior, a long title no longer widening

- the surface past the cap, long text still scrolling within a capped

- height, and no overflow across devicePixelRatio 1.0-3.0.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

## v3.3.9

- Bump version to 3.3.9

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Regenerate core/go.sum after the golang.org/x/* version bumps

- The previous commit only bumped go.mod version constraints without

- go.sum, since no Go toolchain was available at the time — that broke

- every platform build in CI with "missing go.sum entry" errors (v3.3.8

- build run 32278684532).

- Ran `go mod tidy` in core/ for real this time, which also pulled in a

- few more transitive bumps (x/mod, x/sys, x/term, x/text, x/tools,

- x/sync) and raised the go directive to 1.25.0 to satisfy them — still

- well under CI's Go 1.26.4. Verified `go build ./...` succeeds locally.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

## v3.3.8

- Bump version to 3.3.8

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Bump vulnerable golang.org/x/* deps in core/go.mod

- Addresses 20 open Dependabot alerts (7 critical) against

- golang.org/x/crypto, golang.org/x/net, and golang.org/x/oauth2 —

- all transitively pulled into core/go.mod at versions below their

- patched releases.

- go.sum is NOT regenerated here (no Go toolchain in this environment).

- Run `go mod tidy` inside core/ before building so the checksums and

- any further transitive bumps get resolved.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Bump version to 3.3.7

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Fix sub-pages leaking the previous page's content through glass gaps

- CommonRoute/CommonDesktopRoute were deliberately non-opaque so a

- transparent Scaffold could reveal the single AmbientBackground painted

- at the app shell root. That kept whatever page was underneath fully

- mounted and painted, so gaps between glass panels on a pushed page

- showed the actual content of the page behind it, not just the ambient

- gradient.

- Each pushed page now paints its own AmbientBackground and the routes

- are opaque again, so Flutter properly offstages the page underneath

- once the transition ends. Also drops the FloatLayout bottom-nav-bar

- avoidance hack in profiles/edit's floating save button, since the nav

- bar is no longer visible behind pushed pages.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

## v3.3.6

- Bump version to 3.3.6

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Fix double-borders, dead-code input styling, and a sheet header regression

- An 8-agent review pass over the v3.3.5 glass token diff found and this

- fixes:

- - CommonCard painted its own border (_buildBorderSide) and GlassSurface's

-   new default border on the same outline, compositing to roughly double

-   the intended alpha on every idle proxy/provider card. GlassSurface.repeated

-   now gets showBorder: false so the button's own side: is the only source.

- - glassInputDecoration() was built as the opt-in replacement for the

-   removed global InputDecorationTheme but was never actually called,

-   leaving the profile editor, code editor find bar, general config's

-   port fields, backup/WebDAV fields, and InputDialog/AddDialog rendering

-   as bare unfilled outlines. Wired it into all of them.

- - The AdaptiveSheetScaffold rewrite's suffixPop positioning (move the

-   close button to the trailing slot when there are no other actions)

-   only survived in the bottom-sheet branch; the AppBar used for

-   SheetType.page/sideSheet ignored it, silently moving the close button

-   from trailing back to leading. Applied the same rule there.

- - sheetAppBarHeight (reserved top padding under a floating sheet header)

-   was stale against the new header's actual rendered height, clipping

-   a couple pixels of scrolled content at rest.

- Also removes a couple of now-dead symbols this same diff introduced

- (a deprecated alias with zero callers, a blur constant hand-synced with

- GlassTokens.blurChrome instead of just reading it).

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

## v3.3.5

- Bump version to 3.3.5

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Introduce a formal glass token system and fix the config editor regression

- The previous glass pass used a single flat opacity for every physical

- surface, which was wrong: a settings panel, a modal BottomSheet, and a

- repeated proxy card all need different opacity/blur. Replaces the ad-hoc

- glassPanelOpacity with GlassSurfaceType (chrome/panel/modal/floating/

- repeated) and GlassTokens, and migrates AppBar, NavigationBar, sidebar,

- title bar, dialogs, popups, toasts, and both sheet paths onto it.

- Fixes the config/profile editor regression the previous global

- InputDecorationTheme caused: removed the app-wide filled/fillColor/border

- forcing (every field already defines its own decoration), added an

- opt-in glassInputDecoration() helper, pulled the URL field out of a

- ListTile (which was silently capping it at one-line height), and fixed

- the Save FAB overlapping the still-visible HomePage bottom NavigationBar

- on pages pushed as non-opaque routes.

- Rebuilds the BottomSheet's glass hierarchy: the physical sheet previously

- had no BackdropFilter at all (only a flat, unblurred tint), so anything

- behind it — including the bottom NavigationBar — stayed sharply readable.

- Now wraps the whole sheet in one GlassSurface.modal, fixes the default

- modal barrier (Colors.black54 was excessively dark), rebuilds the header

- as a deterministic Row with reserved slot widths instead of AppBar's

- centring math, and drops CommonCard/strategy-button opacity to a

- repeated-tier value so it no longer reads as nested glass inside the

- sheet's own glass.

- Also fixes a dead/misleading opaque Colors.white/grey[900] override on

- the search-mode AppBar, and a raw Card badge and popup-menu rows that

- painted opaque backgrounds over their glass parents.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

## v3.3.4

- Bump version to 3.3.4

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Fix nested opaque row backgrounds on Settings/Tools list

- ListItem.open's container-transform (package:animations) painted an

- opaque colorScheme.surface Material behind every row at rest, on top

- of the transparent AmbientBackground shell, which is what actually

- produced the near-solid white rows. Rows are now transparent, and each

- Tools/Settings section renders as a single glass panel (one

- BackdropFilter per group via a new generateGlassSection helper)

- instead of a flat divided list.

- Also makes glassPanelOpacity brightness-aware (0.36 light / 0.50 dark,

- down from a flat 0.62) and gives Dividers a low-alpha outlineVariant

- theme, so groups read as frosted glass instead of a stack of

- near-opaque cards.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

## v3.3.3

- Bump version to 3.3.3

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- Give dialogs real backdrop blur and unify status colors

- CommonDialog now wraps GlassSurface instead of AlertDialog's flat tint,

- matching the AppBar/NavBar/popup menu blur. Status colors (connected/

- warning) are now fixed semantic colors instead of ad hoc/inconsistent

- green-orange-red literals scattered across dashboard, backup/restore,

- groups, and rule views, and inputs/chips pick up glass-consistent

- theming globally.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

## v3.3.2

- Bump version to 3.3.2

- Fix unused import left over from the opaque-route fix

- Making CommonRoute/CommonDesktopRoute's transparent fillColor a

- literal Colors.transparent (instead of context.colorScheme.surface)

- removed the last use of common/common.dart in this file, which

- flutter analyze correctly flagged as a warning and failed the v3.3.1

- CI build at the Analyze step before it ever reached the actual builds.

## v3.3.1

- Bump version to 3.3.1

- Extend the glass system to popups, toasts, and full-page pushes

- - CommonPopupMenu (right-click/dropdown menus) and StatusManager's

-   floating toast card now use GlassSurface instead of an opaque Card.

- - The proxy list's sticky group header, and the group-tab-bar's

-   fade-to-background gradient, were still painting/fading to an

-   opaque colorScheme.surface — now glass/translucent to match the

-   AmbientBackground actually behind them.

- - The real fix for "nothing past the Tools list looks changed":

-   CommonRoute and CommonDesktopRoute (lib/common/navigator.dart) are

-   PageRoute subclasses and default to opaque=true. Once their push

-   transition finished, Flutter was offstaging whatever sat below them

-   in the same Navigator — on mobile, where each tab has no nested

-   Navigator of its own, that's HomePage itself, taking the

-   AmbientBackground down with it. Every full-page push (any

-   ListItem.open, which is most of Settings/Tools) was rendering on

-   nothing behind its own transparent Scaffold. Both routes now

-   override opaque to false.

## v3.3.0

- Bump version to 3.3.0

- Drop the ring from tray status icons, encode state by glyph color

- The dashed status ring around the P mark read as visual noise at tray

- size and wasn't wanted. status_1/2/3 are now just the P glyph itself,

- larger and centered, colored by state instead of ring-bordered:

- graphite gray (idle), violet gradient (running, system proxy), amber

- (running, TUN) — same semantic mapping as before, carried by the

- glyph's own color rather than a ring around it.

- Frosted-glass visual system across the app shell

- Adds a shared glass design system (lib/widgets/glass.dart):

- - AmbientBackground: one gradient + soft color-blob layer painted once

-   behind the whole app shell, derived from the active ColorScheme so

-   it follows dynamic color / the user's chosen primary automatically.

- - GlassSurface: translucent panel with an opt-in BackdropFilter blur.

-   Blur is real only where a surface can only appear once on screen at

-   a time (top bar, nav rail/bar, dialogs, settings groups); it's

-   skipped in favor of flat tint for anything that can appear dozens of

-   times at once (CommonCard, used in proxy grids/lists) since stacking

-   that many backdrop filters is a real scroll-jank risk.

- Wires it into the app shell: WindowHeader (desktop title bar),

- CommonScaffold's AppBar, the desktop nav rail and mobile nav bar,

- CommonCard/SettingsBlock, CommonDialog, and AdaptiveSheetScaffold's

- bottom/side sheets. ThemeData.scaffoldBackgroundColor is now

- transparent globally so every page reveals the ambient background

- instead of each needing its own override.

- Fix Windows whole-group delay-test flooding and a WebDAV ping race

- Two bug fixes identified while diffing against upstream FlClash (this

- fork's Linux silent-launch fix and the real 220-commit upstream

- history are already merged in via the earlier upstream-sync work, so

- just these two remain):

- - delayTest() was batching already-created Futures instead of the

-   proxy list itself - an async closure starts running up to its first

-   await the moment it's created, so `.map().toList()` was firing every

-   delay-test request immediately regardless of "batch" size. That's

-   exactly what floods the Core's own delay-test queue and times out

-   whole-group tests, especially noticeable on Windows. Now batches the

-   proxies first, capped at the Core's own concurrency

-   (maxConcurrentDelayTests = 50, matching mBatch in core/common.go).

- - The backup/restore screen's WebDAV connectivity check was fired

-   fire-and-forget from build(), so a slow ping for an old credential

-   set could resolve after (and overwrite) a newer one. Adds

-   DAVConnectionController, a small request-generation guard, and wires

-   it into the settings page.

- Rebrand: abstract P monogram logo and unified icon set

- Replaces the shield-and-globe mark with a geometric P monogram (stem +

- aperture bowl, an off-center counter hole standing in for "panorama"

- and "secure access") in a new ink-to-violet palette (#14162B ->

- #6D5EF7), replacing the old navy-to-cyan gradient this fork used

- before the upstream sync.

- Regenerates every platform's app icon from the same vector-equivalent

- geometry so they're pixel-consistent: macOS iconset, Windows .ico

- (app + installer + tray), Android adaptive icon (foreground now

- per-density raster PNGs in this codebase rather than a vector

- drawable, rescaled to the 66dp safe zone) plus legacy mipmap

- webp/Play Store/TV banner, and the icon.png used by the

- AppImage/deb/rpm packaging configs. Tray status icons keep their

- existing gray/blue/amber ring (a functional state indicator, not

- branding) and only swap the center glyph. The service module's

- tile/notification icons (ic.png/ic_service.png, also per-density

- raster here) get the same new glyph as flat white silhouettes,

- matching how this codebase already treated them.

- Also updates the app's default Material You seed color and preset

- palette to the new violet (was upstream's default black/mixed

- palette, unrelated to this fork's branding).

## v3.2.3

- Change default proxy delay/speed-test URL back to gstatic generate_204 (Dart default and Go core
  fallback default)

## v3.2.2

- Change default proxy delay/speed-test URL from speed.cloudflare.com to cp.cloudflare.com (Dart
  default and Go core fallback default)

## v3.2.1

- Remove About page's Telegram link, which pointed at upstream FlClash's own community channel
  instead of this fork's
- Remove the Homebrew and F-Droid tap publish CI steps, which were hardcoded to push to upstream's
  own repos (chen08209/homebrew-tap, chen08209/FlClash-fdroid-repo); the Homebrew one had no secret
  guard and was failing the release build's upload job on every stable tag
- Fix release notes generation comparing against upstream's latest release tag instead of this repo's
  own, which caused release notes to re-include every prior release's changes

## v3.2.0

- Sync with upstream FlClash v0.8.94: macOS performance fix, custom global-ua support, updated core,
  new l10n system, and various dependency/detail updates (graft-assisted merge onto this fork's own
  history, keeping this fork's branding, monochrome theme, and release URLs)
- Change default proxy delay/speed-test URL from gstatic generate_204 to speed.cloudflare.com (Dart
  default and Go core fallback default)
- Retry the core process's IPC pipe/socket dial instead of panicking on the first timeout right after
  a restart
- Fix the Windows uninstaller showing a generic icon instead of the branded one in Add/Remove Programs;
  clean up a stale helper service before install
- Give the TUN adapter its own short device name instead of a leftover unbranded literal, avoiding a
  wintun adapter-creation issue tied to long/space-containing device names
- Bound the core IPC connect wait instead of hanging forever (with more headroom when launched via the
  Windows helper, since TUN bring-up can be slow), with diagnostics surfaced on timeout
- Bound Windows helper sc.exe queries with a timeout and add a catch-all around core connect, so a
  hung system call can no longer leave the UI stuck on "connecting" forever
- Attempt a graceful shutdown of the core process on Windows before force-killing it, so the wintun
  adapter it created gets torn down instead of leaking orphaned adapters across restarts
- Cache the Windows helper's core-binary SHA256 check (keyed by file mtime) and widen the client
  timeout, fixing helper /start timing out on a slow disk or during antivirus scanning
- Propagate a real error when the TUN adapter fails to come up instead of silently reporting success
- Stop the core restart flow before further init when the core failed to connect, instead of
  continuing into steps that would just hang; remove a dead duplicate code path

## v3.1.2

- Change default test URL to speed.cloudflare.com; bump to v3.1.2

## v3.1.1

- Sync Android notification and quick-settings tile icons to the new logo (were still showing the old mark)
- Update the Android TV banner to the new logo and brand name
- Fix release page download links to point to this fork's releases

## v3.1.0

- Point in-app update checks at this fork's own releases instead of upstream FlClash

- Update dialog now downloads the matching platform/arch release asset in the background with a progress
  indicator, then hands it to the platform installer (Windows installer, macOS Finder/dmg, Linux
  AppImage/deb/rpm via xdg-open, Android install intent) instead of just opening a browser link

- README: added License & Credits section (GPL-3.0, attribution to original FlClash project), pointed
  download/star-history links at this fork's repo

## v3.0.0

- Rebrand to Panorama Secure Access (new name, logo, and app icons across all platforms)

- Add disclaimer identifying Panorama Scholarly Group as producer, for internal/educational use only

- Default UI color scheme switched to monochrome (black and white)

## v0.8.94

- Fix macos performance issue

- Support custom global-ua

- Update core

- Optimize some details

- Fix linux silent launching not working

## v0.8.93

- Support custom overwrite

- Support run on demand

- Optimize windows ipc

- Optimize windows arm64

- Optimize build

- Optimize some details

- Update core

## v0.8.92

- Add sqlite store

- Optimize android quick action

- Optimize backup and restore

- Optimize more details

## v0.8.91

- Fix windows some issues

- Optimize overwrite handle

- Optimize access control page

- Optimize some details

## v0.8.90

- Fix android tile service

- Support append system DNS

- Fix some issues

- Update changelog

## v0.8.89

- Fix some issues

- Optimize Windows service mode

- Update core

- Update changelog

## v0.8.88

- Add android separates the core process

- Support core status check and force restart

- Optimize proxies page and access page

- Update flutter and pub dependencies

- Update go version

- Optimize more details

- Update changelog

## v0.8.87

- Optimize desktop view

- Optimize logs, requests, connection pages

- Optimize windows tray auto hide

- Optimize some details

- Update core

- Update changelog

## v0.8.86

- Fix windows tun issues

- Optimize android get system dns

- Optimize more details

- Update changelog

## v0.8.85

- Support override script

- Support proxies search

- Support svg display

- Optimize config persistence

- Add some scenes auto close connections

- Update core

- Optimize more details

## v0.8.84

- Fix windows service verify issues

- Update changelog

## v0.8.83

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

## v0.8.82

- Optimize android vpn performance

- Add custom primary color and color scheme

- Add linux nad windows arm release

- Optimize requests and logs page

- Fix map input page delete issues

- Update changelog

## v0.8.81

- Add rule override

- Update core

- Optimize more details

- Update changelog

## v0.8.80

- Optimize dashboard performance

- Fix some issues

- Fix unselected proxy group delay issues

- Fix asn url issues

- Update changelog

## v0.8.79

- Fix tab delay view issues

- Fix tray action issues

- Fix get profile redirect client ua issues

- Fix proxy card delay view issues

- Add Russian, Japanese adaptation

- Fix some issues

- Update changelog

## v0.8.78

- Fix list form input view issues

- Fix traffic view issues

- Update changelog

## v0.8.77

- Optimize performance

- Update core

- Optimize core stability

- Fix linux tun authority check error

- Fix some issues

- Fix scroll physics error

- Update changelog

## v0.8.75

- Add windows storage corruption detection

- Fix core crash caused by windows resource manager restart

- Optimize logs, requests, access to pages

- Fix macos bypass domain issues

- Update changelog

## v0.8.74

- Fix some issues

- Update changelog

## v0.8.73

- Update popup menu

- Add file editor

- Fix android service issues

- Optimize desktop background performance

- Optimize android main process performance

- Optimize delay test

- Optimize vpn protect

- Update changelog

## v0.8.72

- Update core

- Fix some issues

- Update changelog

## v0.8.71

- Remake dashboard

- Optimize theme

- Optimize more details

- Update flutter version

- Update changelog

## v0.8.70

- Support better window position memory

- Add windows arm64 and linux arm64 build script

- Optimize some details

## v0.8.69

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

## v0.8.67

- Add android shortcuts

- Fix init params issues

- Fix dynamic color issues

- Optimize navigator animate

- Optimize window init

- Optimize fab

- Optimize save

## v0.8.66

- Fix the collapse issues

- Add fontFamily options

## v0.8.65

- Update core version

- Update flutter version

- Optimize ip check

- Optimize url-test

## v0.8.64

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

## v0.8.60

- Fix build error2

- Fix build error

- Support desktop hotkey

- Support android ipv6 inbound

- Support android system dns

- fix some bugs

## v0.8.59

- Fix delete profile error

## v0.8.58

- Fix submit error 2

- Fix submit error

- Optimize DNS strategy

- Fix the problem that the tray is not displayed in some cases

- Optimize tray

- Update core

- Fix some error

## v0.8.57

- Fix tun update issues

- Add DNS override
- Fixed some bugs
- Optimize more detail

- Add Hosts override

## v0.8.56

- fix android tip error
- fix windows auto launch error

## v0.8.55

- Fix windows tray issues

- Optimize windows logic

- Optimize app logic

- Support windows administrator auto launch

- Support android close vpn

## v0.8.53

- Change flutter version

- Support profiles sort

- Support windows country flags display

- Optimize proxies page and profiles page columns

## v0.8.52

- Update flutter version

- Update version

- Update timeout time

- Update access control page

- Fix bug

## v0.8.51

- Optimize provider page

- Optimize delay test

- Support local backup and recovery

- Fix android tile service issues

## v0.8.49

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

## v0.8.48

- Optimize proxies page

- Fix ua issues

- Optimize more details

## v0.8.47

- Fix windows build error

## v0.8.46

- Update app icon

- Fix desktop backup error

- Optimize request ua

- Change android icon

- Optimize dashboard

## v0.8.44

- Remove request validate certificate

- Sync core

## v0.8.43

- Fix windows error

## v0.8.42

- Fix setup.dart error

- Fix android system proxy not effective

- Add macos arm64

## v0.8.41

- Optimize proxies page

- Support mouse drag scroll

- Adjust desktop ui

- Revert "Fix android vpn issues"

- This reverts commit 891977408e6938e2acd74e9b9adb959c48c79988.

## v0.8.40

- Fix android vpn issues

- Fix android vpn issues

- Rollback partial modification

## v0.8.39

- Fix the problem that ui can't be synchronized when android vpn is occupied by an external

- Override default socksPort,port

## v0.8.38

- Fix fab issues

## v0.8.37

- Update version

- Fix the problem that vpn cannot be started in some cases

- Fix the problem that geodata url does not take effect

## v0.8.36

- Update ua

- Fix change outbound mode without check ip issues

- Separate android ui and vpn

- Fix url validate issues 2

- Add android hidden from the recent task

- Add geoip file

- Support modify geoData URL

## v0.8.35

- Fix url validate issues

- Fix check ip performance problem

- Optimize resources page

## v0.8.34

- Add ua selector

- Support modify test url

- Optimize android proxy

- Fix the error that async proxy provider could not selected the proxy

## v0.8.33

- Fix android proxy error

- Fix submit error

- Add windows tun

- Optimize android proxy

- Optimize change profile

- Update application ua

- Optimize delay test

## v0.8.32

- Fix android repeated request notification issues

## v0.8.31

- Fix memory overflow issues

## v0.8.30

- Optimize proxies expansion panel 2

- Fix android scan qrcode error

## v0.8.29

- Optimize proxies expansion panel

- Fix text error

## v0.8.28

- Optimize proxy

- Optimize delayed sorting performance

- Add expansion panel proxies page

- Support to adjust the proxy card size

- Support to adjust proxies columns number

- Fix autoRun show issues

- Fix Android 10 issues

- Optimize ip show

## v0.8.26

- Add intranet IP display

- Add connections page

- Add search in connections, requests

- Add keyword search in connections, requests, logs

- Add basic viewing editing capabilities

- Optimize update profile

## v0.8.25

- Update version

- Fix the problem of excessive memory usage in traffic usage.

- Add lightBlue theme color

- Fix start unable to update profile issues

- Fix flashback caused by process

## v0.8.23

- Add build version

- Optimize quick start

- Update system default option

## v0.8.22

- Update build.yml

- Fix android vpn close issues

- Add requests page

- Fix checkUpdate dark mode style error

- Fix quickStart error open app

- Add memory proxies tab index

- Support hidden group

- Optimize logs

- Fix externalController hot load error

## v0.8.21

- Add tcp concurrent switch

- Add system proxy switch

- Add geodata loader switch

- Add external controller switch

- Add auto gc on trim memory

- Fix android notification error

## v0.8.20

- Fix ipv6 error

- Fix android udp direct error

- Add ipv6 switch

- Add access all selected button

- Remove android low version splash

## v0.8.19

- Update version

- Add allowBypass

- Fix Android only pick .text file issues

## v0.8.18

- Fix search issues

## v0.8.17

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

## v0.8.16

- Add one-click update all profiles
- Add expire show

## v0.8.15

- Temp remove tun mode

- Remove macos in workflow

- Change go version

## v0.8.14

- Update Version

- Fix tun unable to open

## v0.8.13

- Optimize delay test2

- Optimize delay test

- Add check ip

- add check ip request

## v0.8.12

- Fix the problem that the download of remote resources failed after GeodataMode was turned on, which caused the
  application to flash back.

- Fix edit profile error

- Fix quickStart change proxy error

- Fix core version

## v0.8.10

- Fix core version

## v0.8.9

- Update file_picker

- Add resources page

- Optimize more detail

- Add access selected sorted

- Fix notification duplicate creation issue

- Fix AccessControl click issue

## v0.8.7

- Fix Workflow

- Fix Linux unable to open

- Update README.md 3

- Create LICENSE
- Update README.md 2

- Update README.md

- Optimize workFlow

## v0.8.6

- optimize checkUpdate

## v0.8.5

- Fix submit error

## v0.8.4

- add WebDAV

- add Auto check updates

- Optimize more details

- optimize delayTest

## v0.8.2

- upgrade flutter version

## v0.8.1

- Update kernel
- Add import profile via QR code image

## v0.8.0

- Add compatibility mode and adapt clash scheme.

## v0.7.14

- update Version

- Reconstruction application proxy logic

## v0.7.13

- Fix Tab destroy error

## v0.7.12

- Optimize repeat healthcheck

## v0.7.11

- Optimize Direct mode ui

## v0.7.10

- Optimize Healthcheck

- Remove proxies position animation, improve performance
- Add Telegram Link

- Update healthcheck policy

- New Check URLTest

- Fix the problem of invalid auto-selection

## v0.7.8

- New Async UpdateConfig

- add changeProfileDebounce

- Update Workflow

- Fix ChangeProfile block

- Fix Release Message Error

## v0.7.7

- Update Selector 2

## v0.7.6

- Update Version

- Fix Proxies Select Error

## v0.7.5

- Fix the problem that the proxy group is empty in global mode.

- Fix the problem that the proxy group is empty in global mode.

## v0.7.4

- Add ProxyProvider2

## v0.7.3

- Add ProxyProvider

- Update Version

- Update ProxyGroup Sort

- Fix Android quickStart VpnService some problems

## v0.7.1

- Update version

- Set Android notification low importance

- Fix the issue that VpnService can't be closed correctly in special cases

- Fix the problem that TileService is not destroyed correctly in some cases

- Adjust tab animation defaults

- Add Telegram in README_zh_CN.md

- Add Telegram

## v0.7.0

- update mobile_scanner

- Initial commit