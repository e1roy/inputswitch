# Bench test plan

The list of everything the `input-switch-bench-test` skill measures and checks. Results go into [baseline.md](baseline.md) (best / previous / latest per metric) and [history.csv](history.csv) (every measurement of every run).

## Maintaining this plan

Every feature in [docs/features.md](../features.md) is covered here. A feature that is added or changed gets its rows here **in the same change**, and their IDs go into that feature's Functional / Performance columns:

- At least one functional row (`F-…`) per user-visible behaviour.
- Performance rows (`P-…`) when the feature touches the switch → HUD path, runs or animates while the app is idle, holds a cache or long-lived objects, or adds a Settings page.
- IDs are permanent: `P|F-<component>-<nn>`. Take the next free number. Never renumber or reuse an ID. To retire a row, strike it through and append `retired YYYY-MM-DD`, so the history still resolves.
- Every metric is defined so that **lower is better** (express targets as a deviation, e.g. P-HUD-04).
- **Noise** is the change between runs that counts as "no change". Set it from the spread of the first three runs if unsure.

Components: `APP` process-wide · `HUD` [HUD/](../../inputswitch/HUD/) · `SRC` [InputSourceService](../../inputswitch/Core/InputSourceService.swift) · `SET` [Settings/](../../inputswitch/Settings/) · `MENU` [MenuBar/](../../inputswitch/MenuBar/) · `LIFE` [App/](../../inputswitch/App/) + persistence.

## Phases

Shorthand used below. `PID=$(pgrep -x inputswitch)`, `probe=build/bench/probe`.

- **idle**: 60 s after launch, Settings closed, HUD hidden, no switching.
- **burst**: `probe cycle --pid $PID --count 200 --interval-ms 150` (HUD never gets to hide).
- **paced**: `probe cycle --pid $PID --count 100 --interval-ms 1500` (each HUD fully appears and hides).
- **soak**: `probe cycle --pid $PID --count 2000 --interval-ms 400` (~15 min).
- **churn**: open Settings (`open /Applications/inputswitch.app`), visit every sidebar page, close it. 30×.

Timing metrics (latency, hitches, CPU, stalls) are the **median of 3 repeats** of their phase. Memory metrics come from a single run.

## Performance

### APP

| ID | Metric | How | Unit | Budget | Noise |
|---|---|---|---|---|---|
| P-APP-01 | Idle footprint | `footprint --pid $PID` (phys_footprint) after idle | MB | < 40 | 1 |
| P-APP-02 | Idle CPU | `top -pid $PID -l 30 -s 2 -stats pid,cpu,idlew,power`, average | % | 0.0 | 0.1 |
| P-APP-03 | Idle wakeups | same, `idlew` average. Steady wakeups mean a timer, animation or observation loop is still running | /s | < 1 | 0.5 |
| P-APP-04 | App-owned leaks | `leaks $PID` after soak + churn. System-framework leaks are listed in the report, not counted | count | 0 | 0 |
| P-APP-05 | Cold first-switch latency | `appear_ms` of the first paced row right after a relaunch | ms | < 300 | 30 |

### HUD

| ID | Metric | How | Unit | Budget | Noise |
|---|---|---|---|---|---|
| P-HUD-01 | Switch → visible, p50 | paced CSV `appear_ms` | ms | < 50 | 5 |
| P-HUD-02 | Switch → visible, p95 | same | ms | < 100 | 10 |
| P-HUD-03 | Switch → visible, max | same | ms | < 200 | 20 |
| P-HUD-04 | Visible-span error | paced, median of \|`gone_ms` − (duration + 320)\|. Variants `d0.1`, `d0.8`, `d1.0` (duration set in Settings) | ms | ≤ 80 | 20 |
| P-HUD-05 | Missed HUDs | rows with `appear_ms = -1`, burst + paced | count | 0 | 0 |
| P-HUD-06 | Leftover HUD | `probe windows --pid $PID` 2 s after burst: windows with layer > 1000 | count | 0 | 0 |
| P-HUD-07 | Panel oversize | after burst, then one paced switch to the shortest-named source: its `width` minus the width of that source's first fresh appearance (the panel only grows while visible; it must re-fit) | pt | 0 | 2 |
| P-HUD-08 | Soak memory growth | footprint after soak − before, sampled with `footprint --pid $PID --sample 30` (plot vs. switch count; slope must flatten after warm-up) | MB | < 3 | 0.5 |
| P-HUD-09 | Per-switch object growth | `leaks $PID --outputGraph=…` before and after soak, `heap --diffFrom=before after`: net new `NSHostingView`, `HUDOverlayView`, `HUDPanel`, `NSImage`, `CGImage`, closures, `Task` | /1000 switches | 0 | 0 |
| P-HUD-10 | Live hosting views | `heap $PID --addresses='NSHostingView'` after burst | count | ≤ 2 | 0 |
| P-HUD-11 | Hitches, paced | `xctrace record --template 'Animation Hitches' --attach $PID --time-limit 30s`: hitches > 1 frame. Variants `glass-small`, `glass-large`, `solid-small`, `solid-large`, `glass-reduce-transparency` | count/30 s | 0 | 0 |
| P-HUD-12 | Hitches, burst | same during burst, default style | count/30 s | 0 | 1 |
| P-HUD-13 | Worst hitch | longest hitch across P-HUD-11/12 | ms | < 17 | 4 |
| P-HUD-14 | Main-thread cost per switch | Time Profiler during burst: `HUDController.show` incl. the `fittingSize` measurement, ÷ switches | ms | < 4 | 0.5 |
| P-HUD-15 | Longest main-thread stall, burst | Time Profiler hangs lane | ms | < 100 | 20 |
| P-HUD-16 | CPU during burst | `top` average during burst | % | < 20 | 3 |
| P-HUD-17 | CPU settle after hide | time from HUD gone to CPU 0 (`top -s 1`) after a paced switch | ms | < 1000 | 250 |

### SET

| ID | Metric | How | Unit | Budget | Noise |
|---|---|---|---|---|---|
| P-SET-01 | Churn memory growth | footprint after 30 churn cycles − after the first cycle (must not be linear in cycles) | MB | < 5 | 1 |
| P-SET-02 | Retained after close | footprint 30 s after closing Settings − idle footprint (P-APP-01) | MB | < 15 | 2 |
| P-SET-03 | Idle CPU, Settings open | `top` 30 s, Settings frontmost and untouched. Steady CPU means a SwiftUI update loop | % | 0.0 | 0.2 |
| P-SET-04 | Wallpaper accumulation | footprint growth over 20 visits to the Input Sources page (HUDPreview loads a 1200 px thumbnail each time) | MB | < 2 | 0.5 |
| P-SET-05 | Slider drag hitches | Animation Hitches while dragging Intensity end to end over 2 s, 3× | count | 0 | 0 |
| P-SET-06 | Tint writes during drag | `HUDTintsBySourceID` writes per second of drag (Time Profiler / `fs_usage -w -f filesys $PID`) | /s | < 30 | 5 |
| P-SET-07 | Longest main-thread stall, churn | Time Profiler hangs lane during churn | ms | < 100 | 20 |
| P-SET-08 | SwiftUI updates at idle | `SwiftUI` template, 10 s with Settings open and untouched: view body updates | count | 0 | 2 |

## Functional

Observe each item for real (probe CSV, `probe windows`, `screencapture -x`, UI scripting). Preferences are read once at launch (`AppSettings` does not watch `defaults`), so change them in Settings, or with `defaults write github.e1roy.inputswitch <key> …` and a relaunch. Keys are in [Constants.swift](../../inputswitch/Support/Constants.swift).

### HUD

| ID | Check |
|---|---|
| F-HUD-01 | Every enabled source shows the right name and icon; template icons are tinted correctly in light and dark mode. Include a long or CJK name |
| F-HUD-02 | Per-source tint applies to the right source; text stays readable on light and dark tints |
| F-HUD-03 | Burst: the HUD always ends on the **last** source. No stale fade hides a newer HUD, no flicker or blank frame |
| F-HUD-04 | Switching during the fade-out revives the HUD cleanly |
| F-HUD-05 | Morphing between a short and a long name while visible is never clipped, and the card stays centered |
| F-HUD-06 | Position top / center / bottom lands correctly on the screen with keyboard focus |
| F-HUD-07 | Multiple displays: follows the focused screen, with mixed scale factors, and through a display connect/disconnect while running |
| F-HUD-08 | Appears over a full-screen app and on other Spaces |
| F-HUD-09 | Size small / medium / large × style glass / solid × icon on / off all render correctly |
| F-HUD-10 | Never steals focus: `focus_stolen` always 0; typing into a text field continues uninterrupted during switching |
| F-HUD-11 | Click-through: clicks on the HUD area reach the window beneath |
| F-HUD-12 | Reduce Motion removes the scale animation. Under Reduce Transparency and Increase Contrast, glass falls back and stays legible |
| F-HUD-13 | Liquid Glass has edge highlights (the `_hasActiveAppearance` override still works on this macOS); compare a screenshot with the Settings preview |

### SRC

| ID | Check |
|---|---|
| F-SRC-01 | Adding or removing an input source in System Settings updates the Settings list and the menu live |
| F-SRC-02 | Third-party input methods and input modes (e.g. Pinyin) trigger the HUD the same way keyboard layouts do |
| F-SRC-03 | Switching via the system shortcut (Ctrl-Space / Fn) and via the system input menu both show the HUD |

### MENU

| ID | Check |
|---|---|
| F-MENU-01 | The menu lists every enabled source with the current one checked; choosing one switches and shows the HUD |
| F-MENU-02 | Settings… and Quit work, including ⌘, and ⌘Q while the menu is open |
| F-MENU-03 | The icon is a crisp template image in light/dark mode and on a tinted menu bar |
| F-MENU-04 | With the menu bar icon hidden the app keeps working, and `open /Applications/inputswitch.app` brings Settings back |

### SET

| ID | Check |
|---|---|
| F-SET-01 | Opening Settings adds a Dock icon and ⌘-Tab entry; closing removes both. 10× quickly |
| F-SET-02 | Opening from the menu, a Dock reopen, and `open` while already open gives one window, in front, on the current Space |
| F-SET-03 | Every sidebar page renders, the title follows the page, and the minimum window size has no clipping or overlap |
| F-SET-04 | Every control persists across a relaunch (style, position, size, icon, duration, menu bar icon, launch at login, tints) |
| F-SET-05 | Input Sources: row selection updates the preview; presets, custom color, Intensity (disabled at default), Reset, and Show on Screen all work |
| F-SET-06 | The HUD preview shows the wallpaper and matches the real HUD |
| F-SET-07 | Localizations zh-Hans, zh-Hant, ja (`-AppleLanguages '(zh-Hans)'`): no untranslated strings, no truncation |
| F-SET-08 | The launch-at-login toggle matches System Settings › General › Login Items, including the needs-approval state |
| F-SET-09 | About shows the same version and build as the app bundle (`CFBundleShortVersionString` / `CFBundleVersion`); the GitHub and isHUD links open in the browser |

### LIFE

| ID | Check |
|---|---|
| F-LIFE-01 | First launch (after `defaults delete github.e1roy.inputswitch`) and a normal relaunch open Settings; a login-item launch stays silent |
| F-LIFE-02 | Corrupt preferences fall back to defaults without crashing. One at a time with a relaunch each: invalid `HUDStyle`, `HudDisplayDuration` −5 and 99, garbage JSON in `HUDTintsBySourceID`, a tint for a removed source |
| F-LIFE-03 | Legacy migration: a name-keyed color seeded in `InputSourceColors` moves to `HUDTintsBySourceID` on relaunch |
| F-LIFE-04 | After sleep/wake, lock/unlock and Fast User Switching, switching still shows the HUD |
| F-LIFE-05 | After the whole run: no `inputswitch` report in `~/Library/Logs/DiagnosticReports`, and `log show --last 2h --predicate 'process == "inputswitch"'` has no faults (notably "too many Update Constraints passes") |
| F-LIFE-06 | The unit test suite passes |
