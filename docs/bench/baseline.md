# Bench baseline

Per-metric standing from the focused switch-path run on 2026-11-01 (`f2a2b73`). Definitions are in [test-plan.md](test-plan.md). This baseline intentionally contains only the user-approved performance scope: `P-APP-05` and `P-HUD-01…17`; functional and `P-SET-*` results were not collected.

- **Env of record**: `Mac16,8/26B123/3x/2x/2src`
- **Last run**: 2026-11-01 · `f2a2b73` · focused switch path
- **Paced method**: 3 rounds × 20 switches; 60 total latency samples (this was a per-run override in the first run, and is the plan default from 2026-11-01). Duration intervals: d0.1/500 ms, d0.8/1200 ms, d1.0/1500 ms.
- **Soak method change**: `P-HUD-08` and `P-HUD-09` below were measured on the former 2000-switch soak. From 2026-11-01 the soak is 20 switches by default and 100 for the leak rows only, so the next run's values for those two IDs are a new method, not a comparable `previous`.

Trend vs. previous: `▲ improved` · `≈ within noise` · `▼ regressed` · `new`. `⚠` marks a value over its budget. The previous comparable run is `e81e185` (`build/bench/20261101-014330`). The old 2000-switch values for `P-HUD-08`/`P-HUD-09` remain in [history.csv](history.csv) but are not used as `previous` because their method changed.

## APP

| ID | Metric (unit) | Variant | Budget | Best (value @ commit, date) | Previous | Latest | Δ prev | Noise | Trend |
|---|---|---|---|---|---|---|---|---|---|
| P-APP-05 | Cold first-switch latency (ms) | — | < 300 | 43.4 ms @ f2a2b73, 2026-11-01 | 57.4 ms | 43.4 ms | -14.0 ms | 30 | ≈ |

## HUD

| ID | Metric (unit) | Variant | Budget | Best (value @ commit, date) | Previous | Latest | Δ prev | Noise | Trend |
|---|---|---|---|---|---|---|---|---|---|
| P-HUD-01 | Switch → visible, p50 (ms) | — | < 50 | 31.5 ms @ f2a2b73, 2026-11-01 | 32.5 ms | 31.5 ms | -1.0 ms | 5 | ≈ |
| P-HUD-02 | Switch → visible, p95 (ms) | — | < 100 | 39.5 ms @ f2a2b73, 2026-11-01 | 42.3 ms | 39.5 ms | -2.8 ms | 10 | ≈ |
| P-HUD-03 | Switch → visible, max (ms) | — | < 200 | 48.5 ms @ f2a2b73, 2026-11-01 | 70.7 ms | 48.5 ms | -22.2 ms | 20 | ▲ improved |
| P-HUD-04 | Visible-span error (ms) | d0.1 | ≤ 80 | 35.7 ms @ f2a2b73, 2026-11-01 | 37.0 ms | 35.7 ms | -1.3 ms | 20 | ≈ |
| P-HUD-04 | Visible-span error (ms) | d0.8 | ≤ 80 | 22.5 ms @ f2a2b73, 2026-11-01 | 54.9 ms | 22.5 ms | -32.4 ms | 20 | ▲ improved |
| P-HUD-04 | Visible-span error (ms) | d1.0 | ≤ 80 | 21.7 ms @ f2a2b73, 2026-11-01 | 74.4 ms | 21.7 ms | -52.7 ms | 20 | ▲ improved |
| P-HUD-05 | Missed HUDs (count) | — | 0 | 1 count @ f2a2b73, 2026-11-01 | 3 count | 1 count ⚠ | -2 count | 0 | ▲ improved ⚠ |
| P-HUD-06 | Leftover HUD (count) | — | 0 | 0 count @ e81e185, 2026-11-01 | 0 count | 0 count | 0 count | 0 | ≈ |
| P-HUD-07 | Panel oversize (pt) | — | 0 | 0 pt @ e81e185, 2026-11-01 | 0 pt | 0 pt | 0 pt | 2 | ≈ |
| P-HUD-08 | Soak memory growth (MB) | — | < 3 | 1.0 MB @ f2a2b73, 2026-11-01 | — (method changed) | 1.0 MB | — | 0.5 | new |
| P-HUD-09 | Per-switch object growth (/1000 switches) | — | 0 | 1040.0 /1000 switches @ f2a2b73, 2026-11-01 | — (method changed) | 1040.0 /1000 switches ⚠ | — | 0 | new ⚠ |
| P-HUD-10 | Live hosting views (count) | — | ≤ 2 | 0 count @ f2a2b73, 2026-11-01 | 1 count | 0 count | -1 count | 0 | ▲ improved |
| P-HUD-11 | Hitches, paced (count/30 s) | glass-small | 0 | — | blocked | blocked | — | 0 | blocked |
| P-HUD-11 | Hitches, paced (count/30 s) | glass-large | 0 | — | blocked | blocked | — | 0 | blocked |
| P-HUD-11 | Hitches, paced (count/30 s) | solid-small | 0 | — | blocked | blocked | — | 0 | blocked |
| P-HUD-11 | Hitches, paced (count/30 s) | solid-large | 0 | — | blocked | blocked | — | 0 | blocked |
| P-HUD-11 | Hitches, paced (count/30 s) | glass-reduce-transparency | 0 | — | blocked | blocked | — | 0 | blocked |
| P-HUD-12 | Hitches, burst (count/30 s) | — | 0 | — | blocked | blocked | — | 1 | blocked |
| P-HUD-13 | Worst hitch (ms) | — | < 17 | — | blocked | blocked | — | 4 | blocked |
| P-HUD-14 | Main-thread cost per switch (ms) | — | < 4 | — | blocked | blocked | — | 0.5 | blocked |
| P-HUD-15 | Longest main-thread stall, burst (ms) | — | < 100 | — | blocked | blocked | — | 20 | blocked |
| P-HUD-16 | CPU during burst (%) | — | < 20 | 18.0 % @ f2a2b73, 2026-11-01 | 49.5 % | 18.0 % | -31.5 % | 3 | ▲ improved |
| P-HUD-17 | CPU settle after hide (ms) | — | < 1000 | 782.3 ms @ e81e185, 2026-11-01 | 782.3 ms | 2373.9 ms ⚠ | +1591.6 ms | 250 | ▼ regressed ⚠ |

## Focused Run Notes

- `P-HUD-08`/`P-HUD-09` use the new 100-switch soak. This run measured +1.0 MB footprint growth and 104 target-class objects (1040/1000 switches). A second 100-switch drill added 97 target objects (970/1000), confirming that the new-method object growth is repeatable even though the single-run footprint change was within budget.
- `P-HUD-05` counted one miss among 780 burst+paced samples. The miss was d1.0 row 13, immediately after the HUD moved from display 1 to display 0. A controlled 40-switch run alternating between two displays had no misses, so the official miss remains unresolved rather than deterministically reproduced.
- `P-HUD-10` was zero immediately after the first official burst, down from one HUD hosting view in the previous run.
- `P-HUD-17` was measured three times with a single paced switch and 1 s `top` samples. The three confirmations were 2600.6, 2373.9, and 2233.3 ms; the median 2373.9 ms is a confirmed regression and over budget.
- `P-HUD-11…15` remain blocked because the one permitted corrected `xctrace` smoke could not attach (`Cannot find process for provided pid`). No hitch or stall values were inferred. See `build/bench/20261101-041426/BLOCKED.md`.
- Exploration switched the display boundary, fade window, animation boundary, ultra-rapid path, and repeated short bursts. No controlled display transition reproduced the official miss; an ultra-rapid run missed its first two rows; one repeated-burst HUD remained at alpha 0.036 at the 2 s check and cleared on recheck.
