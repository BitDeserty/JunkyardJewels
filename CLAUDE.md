# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Junkyard Jewels — a Class II-style 3-reel slot machine built in **Godot 4.7** (GDScript, Mobile renderer, 640x360 fixed viewport, pixel-snapped 2D). Main scene is `main.tscn` (root node `Cabinet`); a single reel is the reusable `reel.tscn`.

## Commands

Godot is not on `PATH` in this environment — substitute the path to the editor binary (`godot` below).

```bash
godot --path "I:/Code/Godot Projects/JunkyardJewels"
```

Run the backend self-check: enumerates all 13,824 reel combinations, prints the bucket size for every payout factor, and asserts that every prize the outcome source can award maps to a presentation that prices back to it. This is the closest thing the repo has to a test suite — run it after any change to the strip, the paytable, the evaluator or the mapper.

```bash
godot --headless --path "I:/Code/Godot Projects/JunkyardJewels" -- --selftest
```

Export the Web build (the only configured preset, output goes to `../../../Dev/Output/JunkyardJewels/Index.html`):

```bash
godot --headless --path "I:/Code/Godot Projects/JunkyardJewels" --export-release "Web"
```

There is no linter or CI. Beyond the self-check, verification is done by running the game and reading the `print` trace that every state emits on `Enter()`.

## Architecture

### Class II separation: outcome vs. presentation

The game is split the way a Class II machine is: something decides the prize, and the reels only *present* it. The pipeline lives in `scripts/Backend/`:

```
StubRngOutcomeSource ──→ Outcome{prize_id, payout_factor} ──→ OutcomeMapper ──→ stops[3]
                                                                    ↑
                                                       CombinationEvaluator
                                                    (ReelStripData + PaytableData)
```

- `PlayingState` builds a `PlayResult` and emits `_playrequest`.
- `Backend` (wired to `PlayingState` by node path in its own `_ready`) asks `outcome_source` for an `Outcome`, computes `payout_amount`, then asks `OutcomeMapper` for reel stops that display that factor, and emits `_playresponse`.
- `PlayingState` sends those stops to `ReelSet`, then routes to `PayoutState` when the win is non-zero.

**`OutcomeSource` is the swap seam.** Everything downstream of it is blind to how the prize was decided. `StubRngOutcomeSource` is temporary scaffolding — it draws uniformly from the flat 16-entry prize list the backend has always used. Replacing it with a bingo engine (card distribution, ball call, card evaluation) is the only change that layer requires.

**The mapper is a brute-force reverse index, not a constructor.** `OutcomeMapper.BuildIndex` enumerates all 24³ combinations at startup, prices each one through `CombinationEvaluator`, and buckets them by payout factor. Mapping a prize is then a random pick from a bucket, which makes `Evaluate(MapToStops(f)) == f` true *by construction*. Add a rule to the paytable and the index picks it up automatically — there is nothing to keep in sync.

`Backend._AssertPrizeCoverage` fails at startup if the outcome source can award a factor no combination displays. Keep that invariant: a gap would otherwise surface as a reel hanging mid-spin.

### Reel strip and paytable data

Both live in `.tres` resources under `resources/` and are tunable in the editor without touching code:

- **`reel_strip.tres`** (`ReelStripData`) — the 24-stop layout of `assets/symbols.png`. Even indices are blanks; odd indices carry CHERRY ×3, BAR3/BAR2/BAR1/SEVEN ×2 each, CACTUS ×1.
- **`paytable.tres`** (`PaytableData`) — an ordered list of `PayRule` sub-resources, **first match wins**, so the highest-paying rules must come first. `LINE` rules match position-for-position (`Sym.ANY` = -1 wildcards); `COUNT` rules tally one symbol anywhere on the line.

`ReelStripData.SymbolAtStop` is the single source of truth for "stop index → symbol on the payline", and `payline_offset` is the one calibrated number in the system. Because the evaluator and mapper both go through it, the *math* is self-consistent regardless of its value — a wrong offset only makes the screen disagree with what was paid.

### Two finite state machines

`scripts/FiniteStateMachine.gd` + `scripts/State.gd` are a generic, reused pair. An FSM node collects every child that `is State` into `states` keyed by **lowercased node name**, and enters the node assigned to its exported `initial_state`. Both are used twice over:

1. **Game flow** — `GameManager` (in `main.tscn`) with `StartupState`, `IdleState`, `PlayingState`, `PayoutState`, `BetIncrementState`, `BillInsertState`, `BonusState` (still a stub).
2. **Per-reel motion** — `ReelStateMachine` (`scripts/ReelStateMachine/`, root of `reel.tscn`) with `ReelHomingState` → `ReelIdleState` → `ReelSpinStartState` → `ReelSpinningState` → `ReelSpinSeekState` → `ReelSpinStopState`.

Two transition paths coexist, and which is correct depends on who is transitioning:

- **From inside a state**: `state_transition.emit(self, "TargetStateName")`.
- **From outside**: `fsm.change_state(fsm.current_state, "TargetStateName")` — this is how `ReelSet` drives each reel. `change_state` rejects the call if the passed source state is not the current state, so a wrong source silently aborts with a printed warning.

A state that needs data primes it on the target before transitioning — `SetReelTarget` before a reel seeks, `PayoutState.SetPayout` before the payout transition.

### Reel choreography and targeting

`scripts/reel_set.gd` conducts the three `reel.tscn` instances. It fans each reel's `_reel_homed` / `_reel_started` / `_reel_stopped` into a counter and re-emits the aggregate `_reels_*` signal once all three arrive. `SpinReels()` and `StopReels(stops)` stagger the reels with `await` timers, producing the left-to-right cascade.

`scripts/reelstrip.gd` owns the motion. `SetOffset` is the **only** place `yoffset` is written; it wraps over the full `STRIP_HEIGHT`, which keeps the loop seamless because the displayed row counts down as the offset counts up. Speed is never hand-animated — the homing, start and spinning states each sample a `Curve` resource (`resources/start_curve.tres`, `home_curve.tres`) using the curve's own `max_domain` as the state's duration, so **tuning spin feel means editing those `.tres` curves**. Current speed also drives the radial blur in `resources/reel.gdshader`.

Stopping is exact, and deliberately so — the symbol under the payline has to match what was paid:

- `ReelSpinSeekState` hands over when `DistanceToTarget(target) <= stop_state.GetTravelDistance()`, after a guaranteed minimum of one full revolution.
- `GetTravelDistance` is the numerically integrated `stop_curve` × `FULL_SPEED`, so retuning that curve keeps the handoff correct instead of drifting.
- `ReelSpinStopState` scales its ramp to exactly the distance remaining and snaps to the target in `Exit()`. The curve dips negative near the end — that is the intended overshoot-and-settle, and the integral accounts for it.

### Money and meters

`scripts/bank.gd` is the only owner of `balance` / `betamt` / `winmeter`, exposed through `Get*` / `Increment*` / `ResetWin` plus `credits_incremented` / `bet_incremented` / `win_incremented`. `cabinet.gd::_ready` connects those to the three `RichTextLabel` meters, which count digit-by-digit with `await` timers. Never write meter text directly — change the `Bank` and let the signal drive the display.

Both counting meters expose a `rolling` flag and a `rollup_finished` signal. **Check `rolling` before awaiting** — a meter that already settled will never emit again, and awaiting it hangs the state machine. `PayoutState` waits for both meters before returning to `IdleState` so a second play cannot start a rollup on top of a running one.

## Conventions and gotchas

- **State scripts reach the rest of the scene with hardcoded relative node paths** (`$"../../Buttons/SpinButton/SpinButton"`, `$"../../ReelSet"`). Renaming or reparenting a node in `main.tscn` breaks scripts that never mention it by class. Grep for the node name before moving anything.
- Every game state enables/disables the three button-deck buttons in `Enter()`/`Exit()` and connects/disconnects its own `pressed` handlers there. Keep that symmetric — a state that connects without disconnecting will double-fire on the next visit.
- `PlayingState.Enter` awaits `_reels_started` *after* `SpinReels()` has already staggered for 0.6 s, and a reel reports started only when `start_curve` (1.0 s) finishes. Shortening `start_curve.tres` below 0.6 s makes the signal fire before the await is armed and hangs the spin.
- `ReelHomingState` and `ReelSpinStartState` create a new `Timer` child on every `Enter()` and never free it. `ReelSpinStopState` creates one lazily instead; the other two still leak a node per spin.
- Naming is mixed by layer: engine callbacks and signals are `snake_case` with a leading underscore on custom signals (`_playrequest`, `_reels_homed`), while the game's own API methods are `PascalCase` (`SpinReels`, `IncrementCredits`, `MapToStops`). Follow the surrounding file.
- Godot 4.7 style would be `signal_name.connect(callable)`; this codebase consistently uses the older `connect("name", Callable(...))` / `emit_signal("name", ...)` form. Match it.
- Signals declared without parameters cannot be emitted with them — `win_incremented` was silently broken this way until the payout path started using it.
- The commented-out `# Uncomment this for 2-touch` lines in `playing_state.gd` toggle between one-press spin and a second press to stop the reels — they come in matched sets across `Enter`/`Exit`.
- `*.tscn*.tmp` files in the repo root are Godot editor scratch files covered by `.gitignore`; ignore them.
