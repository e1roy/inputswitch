# Bench baseline

Per-metric standing from the full-plan run on 2026-11-01 (`cdeae4a`, `build/bench/20261101-105000`). Definitions are in [test-plan.md](test-plan.md). This is the first run that covers the whole plan — `P-APP-01…04` and `P-SET-01…08` have no earlier value, and functional results are recorded for the first time.

- **Env of record**: `Mac16,8/26B123/3x/2x/2src`
- **Last run**: 2026-11-01 · `cdeae4a-dirty` · re-measure of the HUD rows after the Settings-preview and HUD-hide fixes (see `REPORT.md` §6); the APP and SET rows are from the clean `cdeae4a` measurement earlier the same day and were not re-measured.
- **Paced method**: 3 rounds × 20 switches at 1,500 ms for `P-HUD-01…03`; duration variants d0.1 / d0.8 / d1.0 (3 rounds × 20 each) for `P-HUD-04`.
- **Memory method**: one 100-switch soak at 400 ms for `P-HUD-08` (`footprint --sample`) and `P-HUD-09` (`leaks --outputGraph` before/after + `heap --diffFrom`).
- **Shortened tail**: the user asked for one group per variant and no further drilling while the run was in progress. Everything measured before that point keeps its 3-repeat median; the `▼` rows in this run were therefore *not* re-measured twice more.
- **`P-HUD-17` note**: 1,588 ms comes from the recorded `gone`→`CPU 0` timestamp pairs (1,580–1,588 ms, 3 trials). The 3.8–4.7 s readings quoted earlier in the run came from polling `top -s 1` and include its sampling granularity.

Trend vs. previous: `▲ improved` · `≈ within noise` · `▼ regressed` · `new`. `⚠` marks a value over its budget. The previous comparable run is `fcb33f6` (focused switch path, `P-APP-05` + `P-HUD-01…17` only); its 2000-switch `P-HUD-08`/`P-HUD-09` ancestors remain in history but are excluded from comparison.

## APP

| ID | Metric (unit) | Variant | Budget | Best (value @ commit, date) | Previous | Latest | Δ prev | Noise | Trend |
|---|---|---|---|---|---|---|---|---|---|
| P-APP-01 | Idle footprint (MB) | — | < 40 | 41 MB @ cdeae4a, 2026-11-01 | — | 41 MB ⚠ | — | 1 | new |
| P-APP-02 | Idle CPU (%) | — | 0.0 | 0.0 % @ cdeae4a, 2026-11-01 | — | 0.0 % | — | 0.1 | new |
| P-APP-03 | Idle wakeups (/s) | — | < 1 | 0 /s @ cdeae4a, 2026-11-01 | — | 0 /s | — | 0.5 | new |
| P-APP-04 | App-owned leaks (count) | — | 0 | 0 count @ cdeae4a, 2026-11-01 | — | 0 count | — | 0 | new |
| P-APP-05 | Cold first-switch latency (ms) | — | < 300 | 40.6 ms @ cdeae4a, 2026-11-01 | 48.6 ms | 40.6 ms | -8.0 ms | 30 | ≈ |

## HUD

| ID | Metric (unit) | Variant | Budget | Best (value @ commit, date) | Previous | Latest | Δ prev | Noise | Trend |
|---|---|---|---|---|---|---|---|---|---|
| P-HUD-01 | Switch → visible, p50 (ms) | — | < 50 | 28.8 ms @ cdeae4a, 2026-11-01 | 28.8 ms | 30.6 ms | +1.8 ms | 5 | ≈ |
| P-HUD-02 | Switch → visible, p95 (ms) | — | < 100 | 39.5 ms @ f2a2b73, 2026-11-01 | 40.2 ms | 39.9 ms | -0.3 ms | 10 | ≈ |
| P-HUD-03 | Switch → visible, max (ms) | — | < 200 | 44.9 ms @ cdeae4a, 2026-11-01 | 44.9 ms | 47.3 ms | +2.4 ms | 20 | ≈ |
| P-HUD-04 | Visible-span error (ms) | d0.1 | ≤ 80 | 33.2 ms @ cdeae4a, 2026-11-01 | 36.7 ms | 33.2 ms | -3.5 ms | 20 | ≈ |
| P-HUD-04 | Visible-span error (ms) | d0.8 | ≤ 80 | 19.2 ms @ cdeae4a, 2026-11-01 | 21.8 ms | 19.2 ms | -2.6 ms | 20 | ≈ |
| P-HUD-04 | Visible-span error (ms) | d1.0 | ≤ 80 | 20.3 ms @ cdeae4a, 2026-11-01 | 21.9 ms | 20.3 ms | -1.6 ms | 20 | ≈ |
| P-HUD-05 | Missed HUDs (count) | — | 0 | 0 count @ fcb33f6, 2026-11-01 | 0 count | 1 count ⚠ | +1 count | 0 | ▼ regressed ⚠ |
| P-HUD-06 | Leftover HUD (count) | — | 0 | 0 count @ e81e185, 2026-11-01 | 0 count | 0 count | +0 count | 0 | ≈ |
| P-HUD-07 | Panel oversize (pt) | — | 0 | 0 pt @ e81e185, 2026-11-01 | 0 pt | 0 pt | +0 pt | 2 | ≈ |
| P-HUD-08 | Soak memory growth (MB) | — | < 3 | -1.0 MB @ fcb33f6, 2026-11-01 | 0 MB | 0 MB | +0 MB | 0.5 | ≈ |
| P-HUD-09 | Per-switch object growth (/1000 switches) | — | 0 | 10 /1000 switches @ cdeae4a-dirty, 2026-11-01 | 20 /1000 switches | 10 /1000 switches ⚠ | -10 /1000 switches | 0 | ▲ improved ⚠ |
| P-HUD-10 | Live hosting views (count) | — | ≤ 2 | 0 count @ f2a2b73, 2026-11-01 | 0 count | 1 count | +1 count | 0 | ▼ regressed |
| P-HUD-11 | Hitches, paced (count/30 s) | glass-small | 0 | — | blocked | blocked | — | 0 | blocked |
| P-HUD-11 | Hitches, paced (count/30 s) | glass-large | 0 | — | blocked | blocked | — | 0 | blocked |
| P-HUD-11 | Hitches, paced (count/30 s) | solid-small | 0 | — | blocked | blocked | — | 0 | blocked |
| P-HUD-11 | Hitches, paced (count/30 s) | solid-large | 0 | — | blocked | blocked | — | 0 | blocked |
| P-HUD-11 | Hitches, paced (count/30 s) | glass-reduce-transparency | 0 | — | blocked | blocked | — | 0 | blocked |
| P-HUD-12 | Hitches, burst (count/30 s) | — | 0 | — | blocked | blocked | — | 1 | blocked |
| P-HUD-13 | Worst hitch (ms) | — | < 17 | — | blocked | blocked | — | 4 | blocked |
| P-HUD-14 | Main-thread cost per switch (ms/switch) | — | < 4 | — | blocked | blocked | — | 0.5 | blocked |
| P-HUD-15 | Longest main-thread stall, burst (ms) | — | < 100 | — | blocked | blocked | — | 20 | blocked |
| P-HUD-16 | CPU during burst (%) | — | < 20 | 16.6 % @ fcb33f6, 2026-11-01 | 18.2 % | 18.6 % | +0.4 % | 3 | ≈ |
| P-HUD-17 | CPU settle after hide (ms) | — | < 1000 | 782.3 ms @ e81e185, 2026-11-01 | 1588 ms | 884 ms | -704 ms | 250 | ▲ improved |

## SET

| ID | Metric (unit) | Variant | Budget | Best (value @ commit, date) | Previous | Latest | Δ prev | Noise | Trend |
|---|---|---|---|---|---|---|---|---|---|
| P-SET-01 | Churn memory growth (MB) | — | < 5 | 0 MB @ cdeae4a, 2026-11-01 | — | 0 MB | — | 1 | new |
| P-SET-02 | Retained after close (MB) | — | < 15 | 6 MB @ cdeae4a, 2026-11-01 | — | 6 MB | — | 2 | new |
| P-SET-03 | Idle CPU, Settings open (%) | — | 0.0 | 0.0 % @ cdeae4a, 2026-11-01 | — | 0.0 % | — | 0.2 | new |
| P-SET-04 | Wallpaper accumulation (MB) | — | < 2 | 0 MB @ cdeae4a, 2026-11-01 | — | 0 MB | — | 0.5 | new |
| P-SET-05 | Slider drag hitches (count) | — | 0 | — | blocked | blocked | — | 0 | blocked |
| P-SET-06 | Tint writes during drag (/s) | — | < 30 | — | blocked | blocked | — | 5 | blocked |
| P-SET-07 | Longest main-thread stall, churn (ms) | — | < 100 | — | blocked | blocked | — | 20 | blocked |
| P-SET-08 | SwiftUI updates at idle (count) | — | 0 | — | blocked | blocked | — | 2 | blocked |

## Functional

33 checks recorded: 18 pass, 15 blocked (details in the run's `functional.csv`).

| ID | Status | Note |
|---|---|---|
| F-HUD-01 | pass | names/width correct per source (ABC 248 pt, 微信输入法 316 pt); icon tint in light/dark unverified |
| F-HUD-02 | blocked | tint rendering needs pixels |
| F-HUD-03 | pass | burst ends on the last source, 200/200, no stale fade |
| F-HUD-04 | pass | 10 switches at 800 ms, 0 misses, HUD revives |
| F-HUD-05 | pass | 248↔316 pt with x recentring −10 pt |
| F-HUD-06 | pass | y = 178 / 583 / 988 for top / center / bottom |
| F-HUD-07 | blocked | mixed scale + display connect/disconnect not exercised |
| F-HUD-08 | blocked | full-screen / other Space not exercised |
| F-HUD-09 | blocked | size × style × icon rendering needs pixels |
| F-HUD-10 | pass | `focus_stolen` 0/780; typing continued |
| F-HUD-11 | blocked | click-through not exercised |
| F-HUD-12 | blocked | Reduce Motion/Transparency not toggled |
| F-HUD-13 | blocked | glass edge highlights need pixels |
| F-SRC-01 | blocked | would modify the user's input sources |
| F-SRC-02 | pass | third-party IM 微信输入法 shows the HUD |
| F-SRC-03 | blocked | Ctrl-Space run left no HUD row |
| F-MENU-01 | pass | sources listed, current one checked |
| F-MENU-02 | blocked | ⌘, / ⌘Q not exercised |
| F-MENU-03 | blocked | icon rendering needs pixels |
| F-MENU-04 | pass | hidden icon keeps working, `open` restores Settings |
| F-SET-01 | pass | Dock icon appears/removes with the window |
| F-SET-02 | pass | always exactly one window |
| F-SET-03 | pass | 4 pages, title follows page, min 680×546 |
| F-SET-04 | pass | all controls survive relaunch |
| F-SET-05 | blocked | presets/Intensity/Reset not exercised |
| F-SET-06 | blocked | preview vs. real HUD needs pixels |
| F-SET-07 | pass | zh-Hans/zh-Hant/ja titles localise |
| F-SET-08 | blocked | login item not compared with System Settings |
| F-SET-09 | pass | About 1.0 (1) matches the bundle |
| F-LIFE-01 | pass | first launch and relaunch open Settings |
| F-LIFE-02 | pass | 3 corrupt-preference cases fall back without crashing |
| F-LIFE-03 | pass | legacy `InputSourceColors` migrates to `HUDTintsBySourceID` |
| F-LIFE-04 | blocked | sleep/wake, lock/unlock, Fast User Switching not exercised |
| F-LIFE-05 | pass | no crash reports, 0 log faults |
| F-LIFE-06 | pass | 14/14 unit tests |

## Run notes

- `P-HUD-09` is down to 1 retained HUD object per 100 switches (one `CGImage`, 10/1,000). The graph diff also shows 540 net-new malloc nodes, dominated by 16–48 byte allocations. Still over the 0 budget, far below the 1,080 recorded before.
- `P-HUD-08` is flat: 41 → 41 MB before the fix, 57 → 57 MB after it (the higher starting point is the Settings-preview cache plus a long-lived Settings window in that session). Neither shows linear growth.
- `P-HUD-05` recorded 1 miss in this run: 1 of 60 paced samples (`fix2-paced-d0.8-2.csv` row 7). It arrived as a stale-geometry frame first — the previous ABC switch was reported at the WeType panel's 316 pt/`x=2078` — then the next switch showed nothing. The pre-fix baseline history also contains a 1-miss run, so this is treated as the known intermittent case, not a new regression, but it needs a dedicated repro; at 100 ms intervals the sample never misses.
- `P-HUD-17` is now 884 ms by the plan's method (875 / 903 / 884 over three trials), inside the < 1,000 ms budget; the previous 1,588 ms came from the same method. At 50 ms resolution the app stops working ~138 ms after the panel is ordered out, down from ~290 ms — see `REPORT.md` §6.2.
- `P-SET-01…04` are clean, and after the §6.1 fix they stay clean for the harder case too: with the Settings window left open, footprint is 63/64 MB over four HUD-page visits and 65/65 over two Input Sources visits, i.e. 0 MB per visit (previously +6–8 MB per visit, 48 → 101 MB). Proposed as `P-SET-09`.
- `P-HUD-11…15` and `P-SET-05…08` remain blocked: `xctrace --attach` fails with `Cannot find process for provided pid` on Release and Debug, and all-process recording fails at `DTServiceHub`.
- Visual checks are blocked because the HUD panel (`layer=1019`, on a secondary display at `x≈2078`) is not composited into `screencapture` output over the frontmost app.
