---
description: "Bench InputSwitch: full test → fix → confirm cycle, or `test` / `fix <ID>` alone"
argument-hint: "[test | fix <ID>]"
disable-model-invocation: true
---

Arguments: `$ARGUMENTS`

Invoke exactly one skill with the Skill tool, chosen by the first word of the arguments:

- (empty) → `input-switch-bench`: full cycle on a local `bench/…` branch.
- `test` → `input-switch-bench-test`: measure and record only.
- `fix` → `input-switch-bench-fix`, passing the rest of the arguments (a test ID such as `P-HUD-08`, or empty for the top finding of the latest report).

Anything else → reply with this list and stop.
