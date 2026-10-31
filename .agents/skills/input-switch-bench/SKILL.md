---
name: input-switch-bench
description: Full bench cycle for InputSwitch: run input-switch-bench-test, fix every finding with input-switch-bench-fix, then re-run the bench to confirm, all on a local branch. Use when asked to test and fix, or 测试并修复 InputSwitch.
---

You are the coordinator. You run no measurements and change no code yourself. Each phase runs in its **own subagent** (Agent tool), one at a time, so the tester never sees the fixing steps and no two phases share the machine. All phases change system state (input source, `/Applications` install, preferences), so they always run **sequentially**. If you cannot spawn subagents, invoke the same skills inline, in the same order.

Cycle dir: `CYCLE=build/bench/cycle-$(date +%Y%m%d-%H%M%S)`. Keep a running log in `$CYCLE/CYCLE.md`.

## 1. Branch

- `git status --porcelain` must be empty. If not, stop and ask the user to commit or stash first. Fixes need a clean tree to stay isolated.
- `git switch -c bench/$(date +%Y%m%d-%H%M)` from the current HEAD. Every commit in this cycle lands on this branch. Nothing is pushed, and the starting branch is left untouched.

Done when: the new branch is checked out, and its name and starting commit are in CYCLE.md.

## 2. Measure

Subagent: "Run the `input-switch-bench-test` skill on HEAD. Reply with the REPORT.md path."

Then commit its `docs/bench/` changes: `bench: record run <run dir> at <short sha>`.

Done when: the report exists and the run's history/baseline rows are committed.

## 3. Triage

Read the report and build the **fix queue**: every finding with a test ID (or an explore finding with a concrete repro), in the report's severity order, with confirmed regressions (`▼`) first.

These stay out of the queue and go to the user under **needs decision**:
- blocked checks
- findings whose fix changes intended behaviour or design
- findings that question a budget
- proposed new test-plan rows

Done when: the queue and the needs-decision list are both in CYCLE.md, each item with its ID and one-line reason.

## 4. Fix, one finding per subagent

For each queue item in order, start a fresh subagent: "Run the `input-switch-bench-fix` skill with target `<ID>`. Reply with the outcome (committed / not fixed / did not reproduce), the before → after numbers, and the FIX.md path."

After each one, check that `git status --porcelain` is empty, and log the outcome and commit sha in CYCLE.md. If a fix also cured a later queue item, it still gets its own fix run, which then ends as *did not reproduce*. That is the proof.

Done when: every queue item has an outcome in CYCLE.md.

## 5. Confirm

If step 4 made no commits, skip this step.

Subagent: "Run the `input-switch-bench-test` skill on HEAD. Reply with the REPORT.md path." Commit its `docs/bench/` changes as in step 2.

Compare against the step 2 run:
- Each fixed ID should now show `▲` or be within budget.
- Any new `▼` or new `F-…` failure is a regression from this cycle. Find the fix commit responsible: the one touching the code the regression points at, or bisect the cycle's fix commits with that metric's tight measurement. `git revert` it, and log both the regression and the revert.

Done when: no new regression remains on the branch unreverted.

## 6. Report

Finish CYCLE.md and reply with:
- The branch name, and its commits since the start.
- A table of finding → outcome → before → after → commit.
- Reverted fixes and why.
- The needs-decision list.
- The two report paths (step 2 and step 5).
- How to land it: review with `git log -p <start>..<branch>`, then merge or open a PR. That choice is the user's.
