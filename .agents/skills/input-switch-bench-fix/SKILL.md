---
name: input-switch-bench-fix
description: Fix one finding from an input-switch-bench-test report (over-budget or regressed P-… metric, failed F-… check, or explore finding) and prove it with before/after measurements. Use when asked to fix a bench finding or 修复性能问题.
argument-hint: "[test ID or finding, e.g. P-HUD-08]"
---

One invocation fixes **one** finding and proves it. The proof is the finding's own test-plan measurement, run the same way before and after. A fix is done when the numbers say so.

Target: $ARGUMENTS

Files: the latest `build/bench/*/REPORT.md` (the newest run directory that has one), [docs/bench/test-plan.md](../../../docs/bench/test-plan.md) (method, budget, noise per ID), [docs/bench/baseline.md](../../../docs/bench/baseline.md), and [docs/features.md](../../../docs/features.md) (which feature an ID belongs to). This run's output goes in `RUN=build/bench/fix-<ID>-$(date +%Y%m%d-%H%M%S)`.

## 1. Pick the finding

- `git status --porcelain` must be empty, so this fix stays isolated. If not, stop and say so.
- On the default branch → `git switch -c bench-fix/<ID>-$(date +%Y%m%d)`. On any other branch (e.g. an `input-switch-bench` cycle branch) → stay on it.
- Target given → find it in the latest report. Target empty → list the report's findings with severity and test ID, and fix the highest-severity one. Confirmed regressions (`▼`) come first.
- Read its test-plan row and its feature row in features.md.
- **Guard set**: every other `P-…` and `F-…` ID of that feature, the unit tests, and any ID the report links to the same suspected code.

Done when: one ID is chosen, and its method, budget, noise and guard set are written at the top of `$RUN/FIX.md`.

## 2. Measure *before*

Protect the machine exactly as in `input-switch-bench-test` step 1 (preferences backup, original input source, `./start.sh`, compiled probe), and restore it as in its step 6 when you finish, whatever the outcome.

Measure the target ID with its full test-plan method, 3×, and take the median. Use the same `env` and `build` as the report. Measure each guard ID once.

- Within budget and not worse than the baseline's previous value by more than noise → the finding does not reproduce. Stop and report that, with the numbers. Flakiness and environment drift are findings too.

Done when: the target's three before-values and median, and every guard's before-value, are in FIX.md.

## 3. Diagnose

Invoke the `diagnosing-bugs` skill. Its feedback loop is the **tightest** form of the target's method that still goes red on this finding. For example, a 200-switch burst plus `heap $PID --addresses=<class>` count instead of a 15-minute soak, or one Time Profiler capture of a single burst. Red means the loop reproduces the over-budget or regressed value.

Record in FIX.md the loop command, the ranked hypotheses, and the one the evidence confirmed.

Done when: the confirmed root cause points at specific code (`file:line`) and explains the measured number.

## 4. Fix

- Change the code at the root cause. Follow the conventions in `CLAUDE.md`; the HUD hosting-view and panel rules there exist because of past failures.
- Put decision logic in a pure function or value type, and cover it with a unit test that fails before the fix and passes after, when the seam allows it.
- The budget in test-plan.md stays as it is: the code moves to meet it. If you judge a budget wrong, argue it in the reply.
- If the feature's behaviour changes, update its rows in features.md and test-plan.md in the same change.

Done when: the tight loop from step 3 is green and the unit tests pass.

## 5. Measure *after*

Rebuild and reinstall (`./start.sh`), then repeat step 2 exactly: target 3× with the full method, guards once.

- **Fixed**: target median within budget, and better than *before* by more than noise.
- **Guards hold**: no guard worse than its before-value by more than noise, and no `F-…` guard failing.

Either one missing → back to step 3 with the new evidence. After three rounds without both, the outcome is **not fixed**: `git stash push -u -m "bench-fix <ID>: not fixed"` to keep the attempt and leave the tree clean, then report what you learned.

Done when: both conditions hold, with all numbers in FIX.md.

## 6. Report

Finish `$RUN/FIX.md` with: before → after for the target (all three runs + median) and every guard, the root cause, the change (files and why), and the regression test.

**Fixed** → commit the fix (code, tests, and any features.md / test-plan.md update) on the current branch. Lead the message with the test ID and before → after, e.g. `perf(hud): free stale hosting views (P-HUD-10: 14 → 1)`, and give the confirmed hypothesis in its body. Nothing is pushed.

`docs/bench/history.csv` and `baseline.md` are written only by full `input-switch-bench-test` runs, so leave them unchanged.

Reply with the outcome (committed / not fixed / did not reproduce), the before → after table, the root cause, the commit sha or stash name, and the FIX.md path.
