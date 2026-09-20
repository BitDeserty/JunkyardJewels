# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Junkyard Jewels — a Class II slot machine built in **Godot 4.7** (GDScript, Mobile renderer, 640x360 fixed viewport, pixel-snapped 2D). Outcomes are decided by a real bingo game, and that ball call server also ships as a second app so the two can be shown side by side.

Main scene is `boot.tscn`, which routes to `main.tscn` (the cabinet) or `ballcall_console.tscn` (the server) depending on a build feature tag. A single reel is the reusable `reel.tscn`.

The two-app demo is live at https://bitdeserty.github.io/JunkyardJewels/ and embedded on the project's portfolio page.

## Commands

Godot is not on `PATH`. On this machine it lives at:

```
E:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe
```

Run the game (`godot` below = that binary):

```bash
godot --path "I:/Code/Godot Projects/JunkyardJewels"
```

Run the backend self-check — enumerates all 13,824 reel combinations, asserts every prize the outcome source can award is displayable, verifies `Evaluate(MapToStops(f)) == f`, then simulates 20,000 bingo games and prints the empirical prize distribution and RTP. **This is the closest thing the repo has to a test suite**, and CI runs it before every deploy:

```bash
godot --headless --path "I:/Code/Godot Projects/JunkyardJewels" -- --selftest
```

Run the ball call console on its own (outside a web build it has no channel, so it generates demo games and mirrors its protocol log to stdout):

```bash
godot --headless --fixed-fps 60 --quit-after 4000 --path "I:/Code/Godot Projects/JunkyardJewels" res://ballcall_console.tscn
```

Build the demo locally — two exports, then combine them into one shared-engine site:

```bash
godot --headless --path . --export-release "Web" build/client/index.html
godot --headless --path . --export-release "Web Console" build/console/index.html
python tools/pack_demo_site.py build/client build/console site
```

Pushing to `main` runs `.github/workflows/deploy-demo.yml`, which does the above and publishes to GitHub Pages. There is no linter.

## Architecture

### Class II separation: outcome, mapping, presentation

```
BallCallServer ──► Outcome{prize_id, payout_factor} ──► OutcomeMapper ──► stops[3] ──► ReelSet
  bingo game                     ▲                           ▲
  decides the prize     BallCallTransport          CombinationEvaluator
                     (local | broadcast)        (ReelStripData + PaytableData)
```

The reels are a skin. A bingo game decides what a spin is worth; the mapper then picks a reel combination worth exactly that much. Nothing downstream of the outcome knows or cares how the prize was decided.

**`OutcomeSource` is request/response, not a return value** — deciding an outcome may mean a round trip to another process:

```gdscript
func RequestOutcome(bet_amount : int) -> void
signal outcome_ready(outcome : Outcome)
```

`Backend.on_PlayRequest` parks the `PlayResult` in `_pending`, and `_on_outcome_ready` completes the mapping and emits `_playresponse`. **Both outcome sources stay connected for the whole session**; `_pending` decides whose answer counts, so a late reply from the loser of a race is ignored rather than landing on the next spin.

### The bingo ball call

`scripts/Backend/Bingo/` holds the game: `BingoCard` (5x5, free centre, B/I/N/G/O column ranges), `CardDistributor`, `BallCaller`, `CardEvaluator`, and `PatternPrizeTable` (a `.tres`). `BallCallServer` composes them and narrates the game over the protocol; `BingoOutcomeSource` is the client and holds *no* bingo logic at all — it speaks the protocol and nothing else.

**The ball budget is the RTP lever.** 39 balls against the shipped prize table measures **~91%** over 260k simulated games; two balls either way swings it roughly 8 points. A single 20k-game self-test run carries about ±0.8 points, so don't read one run's figure to a decimal place. Rough distribution: no pattern 55%, any line 36%, four corners 6.4%, postage stamp 2.4%, letter x 0.35%, coverall effectively never.

### The transport seam and the two builds

`BallCallTransport` is what makes the split cheap. `LocalTransport` runs the server in-process (editor, self-test, offline fallback); `BroadcastTransport` carries the same protocol between two browser windows over a `BroadcastChannel`. `BingoOutcomeSource` takes a transport, so **there is no separate "remote" client class** — where the server lives is decided entirely by which transport it was handed.

Export presets cannot override `run/main_scene`, so the console build is selected by a `ballcall_console` custom feature tag that `boot.gd` branches on. Do not try to strip engine scripts from the client build with export filters — `class_name` registration is project-wide and excluded scripts break the registry.

`tools/pack_demo_site.py` combines the two exports into one site. Both `index.wasm` files are byte identical, and the loader resolves the pack as `mainPack || ${executable}.pck`, so both apps share one engine and differ only by a ~220KB pack — 79MB becomes 38MB and the browser caches the engine once across both frames.

It also injects a `#canvas` rule into each shell. The engine sizes the canvas to **project resolution ÷ device pixel ratio**, which ignores the container entirely: 640x360 at dpr 1 so a desktop looks right by accident, but a tiny window at dpr 2 or 3. The rule stretches the element to fill its frame while leaving the backing store at 640x360, so a phone GPU still only draws 640x360 and the pixel art upscales with hard edges. **It needs `!important`** — the engine writes width and height *inline* at runtime, and only an author `!important` declaration beats a normal inline one. This assumes the container is 16:9, which the embed page guarantees.

**`BroadcastChannel` is origin-scoped**, so both builds must be served from one origin; the embedding page's origin is irrelevant. Chrome also partitions channels by top-level site, so two iframes on one page work but an embedded client will not reach a console opened in its own tab.

### Reel strip and paytable data

Both live in `.tres` under `resources/` and are tunable in the editor:

- **`reel_strip.tres`** — the 24-stop layout of `assets/symbols.png`. Even indices are blanks; odd carry CHERRY x3, BAR3/BAR2/BAR1/SEVEN x2 each, CACTUS x1.
- **`paytable.tres`** — ordered `PayRule` list, **first match wins**. Kinds: `LINE` (positional, `Sym.ANY` wildcards), `COUNT` (tally one symbol anywhere), `SET_ALL` (every reel shows something from `pattern`, used for "any three bars").
- **`bingo_prizes.tres`** — pattern prizes plus the ball budget.

`ReelStripData.SymbolAtStop` is the single authority on "stop index → symbol on the payline"; `payline_offset` (23) is the one calibrated number, confirmed against the screen.

**Widening the paytable is free.** RTP is set entirely by how often bingo awards each factor, so adding ways to *display* a factor cannot move it. Current buckets: 50x = 1 combination, 10x = 16, 2x = 235, 1x = 567, 0x = 13,005. The 2x bucket matters most — it is shown on ~43% of spins, and at 16 combinations it visibly repeated.

### Two finite state machines

`scripts/FiniteStateMachine.gd` + `scripts/State.gd` are a generic reused pair. An FSM collects every child that `is State` into `states` keyed by **lowercased node name** and enters its exported `initial_state`. Used twice:

1. **Game flow** — `GameManager` in `main.tscn`: `StartupState`, `IdleState`, `PlayingState`, `PayoutState`, `BetIncrementState`, `BillInsertState`, `BonusState` (stub).
2. **Per-reel motion** — `ReelStateMachine` in `reel.tscn`: homing → idle → spin start → spinning → spin seek → spin stop.

Transitions: **from inside a state** `state_transition.emit(self, "Target")`; **from outside** `fsm.change_state(fsm.current_state, "Target")`, which silently aborts if the passed source is not current. A state needing data is primed before the transition — `SetReelTarget`, `PayoutState.SetPayout`.

### Reel choreography and targeting

`reel_set.gd` conducts three `reel.tscn` instances, fanning each reel's `_reel_*` signal into a counter and re-emitting the aggregate. `reelstrip.gd` owns motion: `SetOffset` is the **only** writer of `yoffset` and wraps over the full `STRIP_HEIGHT`, which keeps the loop seamless because the displayed row counts down as the offset counts up.

Stopping is exact, deliberately — the symbol under the payline has to match what was paid. The seek state hands over when `DistanceToTarget(target) <= stop_state.GetTravelDistance()` after a guaranteed full revolution; `GetTravelDistance` is the numerically integrated `stop_curve`, so retuning the curve keeps the handoff correct. The stop state scales its ramp to the distance actually remaining and snaps on `Exit()`.

Spin feel lives in the `Curve` resources (`start_curve.tres`, `stop_curve.tres`, `home_curve.tres`), sampled over each curve's own `max_domain`. Current speed also drives the blur in `reel.gdshader`.

### Money and meters

`bank.gd` is the only owner of `balance` / `betamt` / `winmeter`. `cabinet.gd::_ready` wires its signals to the three `RichTextLabel` meters. Never write meter text directly.

Both counting meters expose `rolling` and `rollup_finished`. **Check `rolling` before awaiting** — a settled meter never emits again and awaiting it hangs the state machine. `PayoutState` waits for both before returning to Idle.

## Conventions and gotchas

- **Browsers freeze hidden and off-screen iframes** — not throttle, freeze. A paced ball call stops mid-game and never resumes. Hence `BallCallServer`'s stale-game recovery (abandon past `STALE_GAME_MS`, supersede via a generation counter), its wall-clock pacing, and `Backend.SPIN_TIMEOUT` resolving a spin in-process if the console never answers. Anything new that paces over frames needs the same treatment.
- **Both builds are ~39MB and load independently**, so neither can assume it started first. Both ends announce themselves and the channel stays open all session.
- **State scripts reach the scene with hardcoded relative node paths** (`$"../../Buttons/SpinButton/SpinButton"`). Renaming or reparenting in `main.tscn` breaks scripts that never mention the node by class. Grep before moving anything.
- Every game state enables/disables the three button-deck buttons in `Enter()`/`Exit()` and connects/disconnects its own handlers there. Keep it symmetric.
- `PlayingState.Enter` awaits `_reels_started` after `SpinReels()` has staggered 0.6s, and a reel reports started only when `start_curve` (1.0s) finishes. Shortening that curve below 0.6s hangs the spin.
- Naming is mixed by layer: engine callbacks and signals are `snake_case` with a leading underscore on custom signals (`_playrequest`, `_reels_homed`); the game's own API methods are `PascalCase` (`SpinReels`, `MapToStops`, `RequestOutcome`). Follow the surrounding file.
- This codebase uses the older `connect("name", Callable(...))` / `emit_signal("name", ...)` form throughout. Match it.
- Signals declared without parameters cannot be emitted with them — `win_incremented` was silently broken this way until the payout path used it.
- `const` cannot hold a constructor call. `PackedInt32Array([...])` and typed `Array[String]` literals both fail; use plain array literals.
- Hand-authored `.tres` files use untyped `Array` for resource lists (`PaytableData.rules`, `PatternPrizeTable.prizes`) because the typed-array spelling is fragile to write by hand. Re-saving from the editor is safe.
- `*.tscn*.tmp` files in the repo root are editor scratch; they're gitignored.

## Known issues

Deferred, none blocking, roughly in order of how much they'll bite:

- **Standalone exports still mis-scale.** The canvas-fill rule is injected by `tools/pack_demo_site.py`, so it only reaches the packed demo. A raw export opened on its own still sizes its canvas to project resolution ÷ device pixel ratio. The general fix is `html/custom_html_shell` on both presets, at the cost of maintaining a copy of Godot's shell across engine versions.
- **Touch targets are small on a phone.** The bill insert button is 8x8 logical px, which is about 4x4 CSS px at phone scale — hittable but not comfortable. The spin button (80x48) is fine.
- **Timer leak** — `ReelHomingState` and `ReelSpinStartState` each create a `Timer` child on every `Enter()` and never free it, so nodes accumulate one per spin. `ReelSpinStopState` creates one lazily instead; the other two still need the same fix.
- **`BonusState` is an empty stub** and `bonus_amount` is never set, so the bonus branch in `playing_state.gd` stays commented out.
- **CI annotations** — `actions/*` target the deprecated Node 20, and `ubuntu-latest` migrates to Ubuntu 26 in October 2026.
- **`RefCounted` signal cycles** — `BingoOutcomeSource` connects to its transport and the transport holds a callback back. They're kept alive by `Backend` and leak only at shutdown; worth knowing if transports ever get swapped at runtime.
- **`addons/godot-git-plugin/win64/~libgit_plugin…dll`** was deleted as part of an unrelated commit (Godot cleaned up its own temp file and `git add -A` swept it in). Harmless, but unreviewed.
