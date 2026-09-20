# The ball call server: deals a card, calls the balls, evaluates the card, and
# reports the prize. This is the thing that actually decides what a spin is worth.
#
# A Node rather than a RefCounted because it paces the ball call with scene timers.
# Pacing is presentation only -- the game is fully decided the moment the sequence is
# drawn, and the delay exists so a viewer can watch it happen.
class_name BallCallServer
extends Node

signal outbound(message : Dictionary)

## Seconds between called balls. 0 resolves the whole game instantly, which is what
## the self-test and the console-less fallback want.
##
## Paced against the wall clock rather than a per-ball timer: browsers throttle
## hidden or off-screen frames to about one frame a second, and a frame-driven delay
## would stretch a two second call into forty. Catching up in chunks looks worse than
## smooth, but only happens when nobody is looking at it, and the spin still lands on
## time.
@export var ball_call_pace : float = 0.0

var table : PatternPrizeTable
var distributor : CardDistributor
var caller : BallCaller
var evaluator : CardEvaluator

## A game left suspended longer than this is treated as abandoned. Browsers freeze
## hidden frames outright, so a call can stop mid-way and never resume -- without
## this the server would refuse every later request for the rest of the session.
const STALE_GAME_MS : int = 4000

var _busy : bool = false
var _generation : int = 0
var _game_started : int = 0


func Configure(prize_table : PatternPrizeTable) -> void:
	table = prize_table
	distributor = CardDistributor.new()
	caller = BallCaller.new()
	evaluator = CardEvaluator.new(table)


func HandleMessage(message : Dictionary) -> void:
	match message.get("type", ""):
		Protocol.HELLO:
			emit_signal("outbound", Protocol.HelloAck(
				message.get("session_id", ""), Protocol.ROLE_SERVER))
		Protocol.PLAY_REQUEST:
			_RunGame(int(message.get("seq", 0)))
		_:
			pass


# Runs one bingo game and narrates it. The prize is settled before the first ball is
# reported; everything before PLAY_RESPONSE is for the viewer.
func _RunGame(seq : int) -> void:
	var elapsed := Time.get_ticks_msec() - _game_started
	if _busy:
		if elapsed < STALE_GAME_MS:
			push_warning("Ball call server received a play request while a game was running.")
			return
		push_warning("Abandoning a ball call stalled for %dms; the frame was probably hidden."
			% elapsed)

	# Anything still running under an older generation stops emitting.
	_generation += 1
	var generation := _generation
	_busy = true
	_game_started = Time.get_ticks_msec()

	var card := distributor.Deal()
	var called := caller.CallSequence(table.ball_budget)
	var result := evaluator.Evaluate(card, called)

	emit_signal("outbound", Protocol.CardDealt(seq, card.numbers))

	var started := Time.get_ticks_msec()

	for i in called.size():
		if ball_call_pace > 0.0:
			var due := started + int(ball_call_pace * 1000.0 * i)
			while Time.get_ticks_msec() < due:
				await get_tree().process_frame
				if generation != _generation:
					return  # Superseded; the newer game owns _busy now.

		var ball : int = called[i]
		emit_signal("outbound", Protocol.BallCalled(seq, ball, card.IndexOf(ball)))

		if result.IsWin() and result.on_ball == i + 1:
			emit_signal("outbound", Protocol.PatternHit(
				seq, result.pattern_id, result.on_ball, result.daub_mask))

	emit_signal("outbound", Protocol.PlayResponse(seq, result.prize_id, result.payout_factor))
	if generation == _generation:
		_busy = false
