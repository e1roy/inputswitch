# Bench baseline

Per-metric standing from the focused switch-path run on 2026-11-01 (`e81e185`). Definitions are in [test-plan.md](test-plan.md). This baseline intentionally contains only the user-approved performance scope: `P-APP-05` and `P-HUD-01…17`; functional and `P-SET-*` results were not collected.

- **Env of record**: `Mac16,8/26B123/3x/2x/2src`
- **Last run**: 2026-11-01 · `e81e185` · focused switch path
- **Paced method override**: 3 rounds × 20 switches; 60 total latency samples. Duration intervals: d0.1/500 ms, d0.8/1200 ms, d1.0/1500 ms.

Trend vs. previous: `▲ improved` · `≈ within noise` · `▼ regressed` · `new`. `⚠` marks a value over its budget. There is no previous run in [history.csv](history.csv).

## APP

| ID | Metric (unit) | Variant | Budget | Best (value @ commit, date) | Previous | Latest | Δ prev | Noise | Trend |
|---|---|---|---|---|---|---|---|---|---|
| P-APP-05 | Cold first-switch latency (ms) | — | < 300 | 57.4 ms @ e81e185, 2026-11-01 | — | 57.4 ms | — | 30 | new |

## HUD

| ID | Metric (unit) | Variant | Budget | Best (value @ commit, date) | Previous | Latest | Δ prev | Noise | Trend |
|---|---|---|---|---|---|---|---|---|---|
| P-HUD-01 | Switch → visible, p50 (ms) | — | < 50 | 32.5 ms @ e81e185, 2026-11-01 | — | 32.5 ms | — | 5 | new |
| P-HUD-02 | Switch → visible, p95 (ms) | — | < 100 | 42.3 ms @ e81e185, 2026-11-01 | — | 42.3 ms | — | 10 | new |
| P-HUD-03 | Switch → visible, max (ms) | — | < 200 | 70.7 ms @ e81e185, 2026-11-01 | — | 70.7 ms | — | 20 | new |
| P-HUD-04 | Visible-span error (ms) | d0.1 | ≤ 80 | 37.0 ms @ e81e185, 2026-11-01 | — | 37.0 ms | — | 20 | new |
| P-HUD-04 | Visible-span error (ms) | d0.8 | ≤ 80 | 54.9 ms @ e81e185, 2026-11-01 | — | 54.9 ms | — | 20 | new |
| P-HUD-04 | Visible-span error (ms) | d1.0 | ≤ 80 | 74.4 ms @ e81e185, 2026-11-01 | — | 74.4 ms | — | 20 | new |
| P-HUD-05 | Missed HUDs (count) | — | 0 | 3 count @ e81e185, 2026-11-01 | — | 3 count ⚠ | — | 0 | new ⚠ |
| P-HUD-06 | Leftover HUD (count) | — | 0 | 0 count @ e81e185, 2026-11-01 | — | 0 count | — | 0 | new |
| P-HUD-07 | Panel oversize (pt) | — | 0 | 0 pt @ e81e185, 2026-11-01 | — | 0 pt | — | 2 | new |
| P-HUD-08 | Soak memory growth (MB) | — | < 3 | 4.0 MB @ e81e185, 2026-11-01 | — | 4.0 MB ⚠ | — | 0.5 | new ⚠ |
| P-HUD-09 | Per-switch object growth (/1000 switches) | — | 0 | 6172.0 /1000 switches @ e81e185, 2026-11-01 | — | 6172.0 /1000 switches ⚠ | — | 0 | new ⚠ |
| P-HUD-10 | Live hosting views (count) | — | ≤ 2 | 1 count @ e81e185, 2026-11-01 | — | 1 count | — | 0 | new |
| P-HUD-11 | Hitches, paced (count/30 s) | glass-small | 0 | — | — | blocked | — | 0 | blocked |
| P-HUD-11 | Hitches, paced (count/30 s) | glass-large | 0 | — | — | blocked | — | 0 | blocked |
| P-HUD-11 | Hitches, paced (count/30 s) | solid-small | 0 | — | — | blocked | — | 0 | blocked |
| P-HUD-11 | Hitches, paced (count/30 s) | solid-large | 0 | — | — | blocked | — | 0 | blocked |
| P-HUD-11 | Hitches, paced (count/30 s) | glass-reduce-transparency | 0 | — | — | blocked | — | 0 | blocked |
| P-HUD-12 | Hitches, burst (count/30 s) | — | 0 | — | — | blocked | — | 1 | blocked |
| P-HUD-13 | Worst hitch (ms) | — | < 17 | — | — | blocked | — | 4 | blocked |
| P-HUD-14 | Main-thread cost per switch (ms) | — | < 4 | — | — | blocked | — | 0.5 | blocked |
| P-HUD-15 | Longest main-thread stall, burst (ms) | — | < 100 | — | — | blocked | — | 20 | blocked |
| P-HUD-16 | CPU during burst (%) | — | < 20 | 49.5 % @ e81e185, 2026-11-01 | — | 49.5 % ⚠ | — | 3 | new ⚠ |
| P-HUD-17 | CPU settle after hide (ms) | — | < 1000 | 782.3 ms @ e81e185, 2026-11-01 | — | 782.3 ms | — | 250 | new |

## Focused Run Notes

- `P-HUD-10` counts the one HUD-specific hosting view. Three additional SwiftUI hosting-view objects belong to the Settings controller retained after the launch-time setup window was closed; they are not switch-path HUD hosts.
- `P-HUD-11…15` are blocked because `xctrace` could not attach or connect to `DTServiceHub`. No hitch or Time Profiler numbers were inferred. See the run-local `BLOCKED.md` and `sample` artifacts.
- `P-HUD-05` observed three missing appearances in one clean 200-switch burst. A targeted 200-switch repro missed none. HUD coordinates changed in the same rows, so display/WindowServer reconfiguration is a competing explanation rather than a confirmed code regression.
