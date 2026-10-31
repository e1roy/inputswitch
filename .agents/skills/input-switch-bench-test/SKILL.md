---
name: input-switch-bench-test
description: Performance and functional bench test of the running InputSwitch app against docs/bench/test-plan.md, recording results to the baseline so each run shows what improved or regressed. Use when asked to bench, profile, soak, stress, or 性能/功能测试 InputSwitch.
---

You are a tester hunting for problems the user would not notice in daily use: memory that creeps up over hours, a dropped frame in the HUD animation, a control that quietly does nothing. You are measuring and reporting, **not fixing**. Leave app source untouched. Every finding gets evidence and a suspected `file:line`.

Explore **depth-first**. When any number or behaviour looks off, stay on it: get a minimal repro, vary one parameter at a time, capture a trace, and narrow it down to code before you move to the next area. The test plan is the minimum. Probe past it wherever the code suggests a weak spot.

Files:

- [docs/features.md](../../../docs/features.md): every feature, with the test IDs that cover it. In the report, list each feature whose Performance column is `—`.
- [docs/bench/test-plan.md](../../../docs/bench/test-plan.md): what to measure and check, with permanent IDs, budgets and noise floors.
- [docs/bench/history.csv](../../../docs/bench/history.csv): append-only log of every measured value, all runs.
- [docs/bench/baseline.md](../../../docs/bench/baseline.md): best / previous / latest per metric, regenerated each run.
- Raw output for this run (CSV, `.trace`, `.memgraph`, screenshots, REPORT.md) goes in `RUN=build/bench/$(date +%Y%m%d-%H%M%S)` (gitignored).

## 1. Set up and protect the user's machine

- Back up preferences: `defaults export github.e1roy.inputswitch "$RUN/defaults-backup.plist"`. Record the current input source (`probe current`). Restore both in step 6 whatever happens.
- Build and install: `./start.sh` (Release build in `/Applications`). Also build Debug (`xcodebuild … -configuration Debug -derivedDataPath build/bench/dd build`). Use it only when a tool cannot attach to the Release binary ("not debuggable"); record those values with `build=debug`.
- Compile the probe: `swiftc -O .claude/skills/input-switch-bench-test/scripts/probe.swift -o build/bench/probe`. Run `probe list`. At least 2 enabled sources are required. If there are fewer, stop and ask the user to add one.
- Record the identity of the run:
  - `COMMIT=$(git rev-parse --short HEAD)`, with `-dirty` appended when `git status --porcelain -- inputswitch` is non-empty.
  - `ENV=$(sysctl -n hw.model)/$(sw_vers -buildVersion)/<displays>x<main scale>/<n sources>src`.
- Check permissions: Screen Recording (for `screencapture`) and Accessibility for the terminal host (for UI scripting with `osascript`/System Events). A check that needs a missing permission is **blocked**. It is never skipped silently.

Done when: backup exists, both builds exist, the probe lists ≥ 2 sources, and `COMMIT`, `ENV` and permissions are known.

## 2. Performance

Measure every non-retired `P-…` row of the test plan, using its phase and method. Each measured value goes into `$RUN/results.csv` with the `history.csv` header, and rows with variants get one line per variant.

Done when: every `P-…` ID has a value or a blocked reason, and every over-budget value has been drilled down depth-first.

## 3. Functional

Execute every non-retired `F-…` row and observe the outcome. Write `$RUN/functional.csv` with columns `id,status,evidence` (status is `pass`, `fail` or `blocked`).

Done when: every `F-…` ID has a status, and every fail has repro steps and evidence.

## 4. Explore

Spend a deliberate pass off the plan. Re-read [HUDController.swift](../../../inputswitch/HUD/HUDController.swift), [InputSourceService.swift](../../../inputswitch/Core/InputSourceService.swift) and the Settings views looking for race windows, unbounded caches, observation loops, and state that only resets on relaunch. Then attack each one you find. Combine stressors as well (rapid switching *while* dragging the Intensity slider, while Settings opens and closes, across a display change).

Whatever proves worth re-checking on every run gets proposed as a new test-plan row in the report (next free ID, with method, budget and noise). The plan file itself stays unchanged until the user approves the row.

Done when: at least five self-chosen scenarios beyond the plan have been run and recorded.

## 5. Record and compare

1. Append `$RUN/results.csv` (without its header) to `docs/bench/history.csv`.
2. For each metric + variant, take the history rows with the same `env` and `build`:
   - **previous**: the most recent earlier run.
   - **best**: the lowest value. Ties go to the earliest run.
   - **trend**: if \|latest − previous\| ≤ the row's noise floor, `≈`. Otherwise `▲ improved` when latest < previous, or `▼ regressed` when latest > previous. Use `new` when there is no previous value.
   - `⚠` when latest is over budget, whatever the trend.
3. A `▼` is re-measured twice more before it is reported — that metric's phase only, not the whole plan. It counts only if the median of the three still regresses. Then list the suspect commits with `git log --oneline <previous commit>..HEAD -- inputswitch/`.
4. A different `env` from the baseline's env of record → record the values, and compare only against earlier runs with that env. Note it in the report, and leave the env of record unchanged unless the user asks.
5. Rewrite every row of `docs/bench/baseline.md` from history: Best, Previous, Latest, Δ prev, Trend, the **Last run** line, and the Functional table. Add rows for new IDs and variants, and strike through retired ones.

Done when: history.csv has this run's rows, and every baseline row reflects them.

## 6. Restore and report

- Quit the app. Run `defaults import github.e1roy.inputswitch "$RUN/defaults-backup.plist"`, then `probe select <original id>`. Relaunch `/Applications/inputswitch.app`.
- Write `$RUN/REPORT.md`:
  1. **Summary**: confirmed regressions, then the top findings in severity order (crash/data loss > leak/unbounded growth > visible hitch/latency > functional bug > polish).
  2. **Changes since the previous run**: every `▲` and `▼` with old → new value, plus the suspect commits for each `▼`.
  3. **Findings**: one block each with severity, test ID (or "explore"), repro steps, expected vs. actual, evidence (numbers, trace path, screenshot), and suspected `file:line`.
  4. **Proposed test-plan rows** from step 4.
  5. **Blocked / not covered**, and what the user must do (grant a permission, attach a second display, …) to cover it.
- Leave `docs/bench/` changes uncommitted for the user to review. Reply with the summary, the regressions, and the report path. Name the IDs worth fixing first.

Done when: preferences and input source are restored, the app is running, and REPORT.md accounts for every test-plan ID plus the exploration pass.
