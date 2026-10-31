# Bench baseline

Per-metric standing, rewritten by the `input-switch-bench-test` skill after every run from [history.csv](history.csv). Definitions, units and budgets are in [test-plan.md](test-plan.md). All metrics are lower-is-better.

- **Env of record**: — (set by the first run; values are only compared within one env)
- **Last run**: —

Trend vs. previous: `▲ improved` · `≈ within noise` · `▼ regressed` · `new`. `⚠` marks a value over its budget in test-plan.md. Variant rows (e.g. P-HUD-11 `glass-large`) are added as they are first measured.

## APP

| ID | Metric (unit) | Variant | Best (value @ commit, date) | Previous | Latest | Δ prev | Trend |
|---|---|---|---|---|---|---|---|
| P-APP-01 | Idle footprint (MB) | — | — | — | — | — | — |
| P-APP-02 | Idle CPU (%) | — | — | — | — | — | — |
| P-APP-03 | Idle wakeups (/s) | — | — | — | — | — | — |
| P-APP-04 | App-owned leaks (count) | — | — | — | — | — | — |
| P-APP-05 | Cold first-switch latency (ms) | — | — | — | — | — | — |

## HUD

| ID | Metric (unit) | Variant | Best (value @ commit, date) | Previous | Latest | Δ prev | Trend |
|---|---|---|---|---|---|---|---|
| P-HUD-01 | Switch → visible, p50 (ms) | — | — | — | — | — | — |
| P-HUD-02 | Switch → visible, p95 (ms) | — | — | — | — | — | — |
| P-HUD-03 | Switch → visible, max (ms) | — | — | — | — | — | — |
| P-HUD-04 | Visible-span error (ms) | — | — | — | — | — | — |
| P-HUD-05 | Missed HUDs (count) | — | — | — | — | — | — |
| P-HUD-06 | Leftover HUD (count) | — | — | — | — | — | — |
| P-HUD-07 | Panel oversize (pt) | — | — | — | — | — | — |
| P-HUD-08 | Soak memory growth (MB) | — | — | — | — | — | — |
| P-HUD-09 | Per-switch object growth (/1000 switches) | — | — | — | — | — | — |
| P-HUD-10 | Live hosting views (count) | — | — | — | — | — | — |
| P-HUD-11 | Hitches, paced (count/30 s) | — | — | — | — | — | — |
| P-HUD-12 | Hitches, burst (count/30 s) | — | — | — | — | — | — |
| P-HUD-13 | Worst hitch (ms) | — | — | — | — | — | — |
| P-HUD-14 | Main-thread cost per switch (ms) | — | — | — | — | — | — |
| P-HUD-15 | Longest main-thread stall, burst (ms) | — | — | — | — | — | — |
| P-HUD-16 | CPU during burst (%) | — | — | — | — | — | — |
| P-HUD-17 | CPU settle after hide (ms) | — | — | — | — | — | — |

## SET

| ID | Metric (unit) | Variant | Best (value @ commit, date) | Previous | Latest | Δ prev | Trend |
|---|---|---|---|---|---|---|---|
| P-SET-01 | Churn memory growth (MB) | — | — | — | — | — | — |
| P-SET-02 | Retained after close (MB) | — | — | — | — | — | — |
| P-SET-03 | Idle CPU, Settings open (%) | — | — | — | — | — | — |
| P-SET-04 | Wallpaper accumulation (MB) | — | — | — | — | — | — |
| P-SET-05 | Slider drag hitches (count) | — | — | — | — | — | — |
| P-SET-06 | Tint writes during drag (/s) | — | — | — | — | — | — |
| P-SET-07 | Longest main-thread stall, churn (ms) | — | — | — | — | — | — |
| P-SET-08 | SwiftUI updates at idle (count) | — | — | — | — | — | — |

## Functional

| Component | Latest | Failing IDs | Since |
|---|---|---|---|
| HUD | — | — | — |
| SRC | — | — | — |
| MENU | — | — | — |
| SET | — | — | — |
| LIFE | — | — | — |
