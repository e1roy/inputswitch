# Bench baseline

Per-metric standing from the focused switch-path run on 2026-11-01 (`fcb33f6`). Definitions are in [test-plan.md](test-plan.md). This baseline intentionally contains only the user-approved performance scope: `P-APP-05` and `P-HUD-01…17`; functional and `P-SET-*` results were not collected.

- **Env of record**: `Mac16,8/26B123/3x/2x/2src`
- **Last run**: 2026-11-01 · `fcb33f6` · focused switch path
- **Paced method**: 3 rounds × 20 switches; 60 total latency samples. Duration intervals: d0.1/500 ms, d0.8/1200 ms, d1.0/1500 ms.
- **Memory method**: one 100-switch soak at 400 ms for `P-HUD-08`; the comparable `P-HUD-09` value uses a second, warm 100-switch phase. The immediately-post-launch graph was retained as startup evidence but excluded from the per-switch value because it included one-time view-graph and image-cache creation.
- **P-HUD-17 note**: the current 2,775.8 ms median is a nominal `▼` from the previous 2,373.9 ms, but it is not attributable to code: a same-machine control build of `e81e185` measured 2,875.9 ms.

Trend vs. previous: `▲ improved` · `≈ within noise` · `▼ regressed` · `new`. `⚠` marks a value over its budget. The previous comparable run is `f2a2b73` (`build/bench/20261101-041426`); the old 2000-switch `P-HUD-08`/`P-HUD-09` values from `e81e185` remain in history but are excluded from comparison.

## APP

| ID | Metric (unit) | Variant | Budget | Best (value @ commit, date) | Previous | Latest | Δ prev | Noise | Trend |
|---|---|---|---|---|---|---|---|---|---|
| P-APP-05 | Cold first-switch latency (ms) | — | < 300 | 43.4 ms @ f2a2b73, 2026-11-01 | 43.4 ms | 48.6 ms | +5.2 ms | 30 | ≈ |

## HUD

| ID | Metric (unit) | Variant | Budget | Best (value @ commit, date) | Previous | Latest | Δ prev | Noise | Trend |
|---|---|---|---|---|---|---|---|---|---|
| P-HUD-01 | Switch → visible, p50 (ms) | — | < 50 | 31.5 ms @ f2a2b73, 2026-11-01 | 31.5 ms | 32.2 ms | +0.7 ms | 5 | ≈ |
| P-HUD-02 | Switch → visible, p95 (ms) | — | < 100 | 39.5 ms @ f2a2b73, 2026-11-01 | 39.5 ms | 42.0 ms | +2.5 ms | 10 | ≈ |
| P-HUD-03 | Switch → visible, max (ms) | — | < 200 | 48.5 ms @ f2a2b73, 2026-11-01 | 48.5 ms | 49.7 ms | +1.2 ms | 20 | ≈ |
| P-HUD-04 | Visible-span error (ms) | d0.1 | ≤ 80 | 35.7 ms @ f2a2b73, 2026-11-01 | 35.7 ms | 36.7 ms | +1 ms | 20 | ≈ |
| P-HUD-04 | Visible-span error (ms) | d0.8 | ≤ 80 | 21.8 ms @ fcb33f6, 2026-11-01 | 22.5 ms | 21.8 ms | -0.7 ms | 20 | ≈ |
| P-HUD-04 | Visible-span error (ms) | d1.0 | ≤ 80 | 21.7 ms @ f2a2b73, 2026-11-01 | 21.7 ms | 21.9 ms | +0.2 ms | 20 | ≈ |
| P-HUD-05 | Missed HUDs (count) | — | 0 | 0 count @ fcb33f6, 2026-11-01 | 1 count | 0 count | -1 count | 0 | ▲ improved |
| P-HUD-06 | Leftover HUD (count) | — | 0 | 0 count @ e81e185, 2026-11-01 | 0 count | 0 count | +0 count | 0 | ≈ |
| P-HUD-07 | Panel oversize (pt) | — | 0 | 0 pt @ e81e185, 2026-11-01 | 0 pt | 0 pt | +0 pt | 2 | ≈ |
| P-HUD-08 | Soak memory growth (MB) | — | < 3 | -1.0 MB @ fcb33f6, 2026-11-01 | 1.0 MB | -1.0 MB | -2 MB | 0.5 | ▲ improved |
| P-HUD-09 | Per-switch object growth (/1000 switches) | — | 0 | 1040.0 /1000 switches @ f2a2b73, 2026-11-01 | 1040.0 /1000 switches | 1080.0 /1000 switches ⚠ | +40 /1000 switches | 0 | ▼ regressed ⚠ |
| P-HUD-10 | Live hosting views (count) | — | ≤ 2 | 0 count @ f2a2b73, 2026-11-01 | 0 count | 0 count | +0 count | 0 | ≈ |
| P-HUD-11 | Hitches, paced (count/30 s) | glass-small | 0 | — | blocked | blocked | — | 0 | blocked |
| P-HUD-11 | Hitches, paced (count/30 s) | glass-large | 0 | — | blocked | blocked | — | 0 | blocked |
| P-HUD-11 | Hitches, paced (count/30 s) | solid-small | 0 | — | blocked | blocked | — | 0 | blocked |
| P-HUD-11 | Hitches, paced (count/30 s) | solid-large | 0 | — | blocked | blocked | — | 0 | blocked |
| P-HUD-11 | Hitches, paced (count/30 s) | glass-reduce-transparency | 0 | — | blocked | blocked | — | 0 | blocked |
| P-HUD-12 | Hitches, burst (count/30 s) | — | 0 | — | blocked | blocked | — | 1 | blocked |
| P-HUD-13 | Worst hitch (ms) | — | < 17 | — | blocked | blocked | — | 4 | blocked |
| P-HUD-14 | Main-thread cost per switch (ms/switch) | — | < 4 | — | blocked | blocked | — | 0.5 | blocked |
| P-HUD-15 | Longest main-thread stall, burst (ms) | — | < 100 | — | blocked | blocked | — | 20 | blocked |
| P-HUD-16 | CPU during burst (%) | — | < 20 | 16.6 % @ fcb33f6, 2026-11-01 | 18.0 % | 16.6 % | -1.4 % | 3 | ≈ |
| P-HUD-17 | CPU settle after hide (ms) | — | < 1000 | 782.3 ms @ e81e185, 2026-11-01 | 2373.9 ms | 2775.8 ms ⚠ | +401.9 ms | 250 | ▼ regressed ⚠ |

## Focused Run Notes

- `P-HUD-09` remains over budget at 108 target objects after 100 switches, or 1,080 objects/1,000 switches. The dominant classes are 68 `Closure context`, 22 `CGImage`, 11 `NSImageArrayRepProvider`, two unknown-layout closures, two `ImageProviderBox<NSImage>`, and three singleton image classes. Allocation and reverse-reference traces place the recurring closures in `HUDOverlayView`'s SwiftUI view graph; six of ten sampled new closures were rooted in that hosting view or `HUDPanel`, including animation modifier contexts. A second incremental 20-switch owner drill added 63 closures and no new providers, confirming the closure path is dominant.
- `P-HUD-08` measured -1.0 MB over the 100-switch soak. The sampled footprint rose from 49 MB to a 51 MB warm-up peak, then settled at 48 MB; this passes the <3 MB budget and does not show linear footprint growth.
- `P-HUD-05` is 0/780 official burst+paced samples. A deterministic focus-window helper forced 24 display transitions across all three screens during three additional 40-switch runs; all 120/120 HUDs appeared (worst 41.6 ms), so the previous one-off display-boundary miss did not reproduce.
- `P-HUD-17` was stable at 2,760.3–2,823.0 ms (nine repeats; median 2,775.8, SD 21.2). The same method against a freshly built `e81e185` app on this machine gave 2,863.9–2,914.3 ms (five repeats; median 2,875.9). Since the current source tree is byte-identical to `f2a2b73` and both old/current builds now settle near 2.8 s, the 782→2,374→2,776 ms movement is environment/metric drift rather than a code regression. The value is nevertheless over budget.
- `P-HUD-11…15` remain blocked. Release and Debug attach both failed with `Cannot find process for provided pid`; a Debug launch attempt reached the recorder but failed with `Error connecting to DTServiceHub`. No hitch, profiler, or stalls-lane value was inferred.
- `P-HUD-16` improved to a 16.6% burst-active median (16.6/16.8/16.6), inside the <20% budget. `P-HUD-10` remained at zero hosting views after burst.
