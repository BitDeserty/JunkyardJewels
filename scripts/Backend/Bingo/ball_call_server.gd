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
@export var ball_call_pace : float = 0.0

var table : PatternPrizeTable
var distributor : CardDistributor
var caller : BallCaller
var evaluator : CardEvaluator

var _busy : bool = false


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
	if _busy:
		push_warning("Ball call server received a play request while a game was running.")
		return
	_busy = true

	var card := distributor.Deal()
	var called := caller.CallSequence(table.ball_budget)
	var result := evaluator.Evaluate(card, called)

	emit_signal("outbound", Protocol.CardDealt(seq, card.numbers))

	for i in called.size():
		var ball : int = called[i]
		emit_signal("outbound", Protocol.BallCalled(seq, ball, card.IndexOf(ball)))
		if ball_call_pace > 0.0:
			await get_tree().create_timer(ball_call_pace).timeout
		if result.IsWin() and result.on_ball == i + 1:
			emit_signal("outbound", Protocol.PatternHit(
				seq, result.pattern_id, result.on_ball, result.daub_mask))

	emit_signal("outbound", Protocol.PlayResponse(seq, result.prize_id, result.payout_factor))
	_busy = false
