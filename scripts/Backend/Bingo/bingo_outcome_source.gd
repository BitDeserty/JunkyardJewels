# Asks the ball call server to run a bingo game and reports the prize it returns.
#
# This is the whole client side of the split. It holds no bingo logic: it speaks the
# protocol and nothing else, so the server being in-process or in another window is
# decided entirely by which BallCallTransport it was handed.
class_name BingoOutcomeSource
extends OutcomeSource

var _transport : BallCallTransport
var _table : PatternPrizeTable
var _session_id : String
var _seq : int = 0
var _pending_seq : int = -1


func _init(transport : BallCallTransport, table : PatternPrizeTable):
	_transport = transport
	_table = table
	_session_id = "%08x" % randi()
	_transport.connect("message_received", Callable(self, "_on_message"))


func Start() -> void:
	_transport.Start()
	_transport.Send(Protocol.Hello(_session_id, Protocol.ROLE_CLIENT))


func RequestOutcome(bet_amount : int) -> void:
	_seq += 1
	_pending_seq = _seq
	_transport.Send(Protocol.PlayRequest(_session_id, _seq, bet_amount))


# The prize table is the authority on what the server can award, so the backend's
# startup coverage check works the same for bingo as it did for the stub.
func PossibleFactors() -> Array[int]:
	return _table.PayableFactors()


func Describe() -> String:
	return "bingo ball call (%s, %d balls)" % [_transport.Describe(), _table.ball_budget]


func _on_message(message : Dictionary) -> void:
	if message.get("type", "") != Protocol.PLAY_RESPONSE:
		# Card deals and ball calls are for whatever is drawing the server's view.
		return

	var seq := int(message.get("seq", -1))
	if seq != _pending_seq:
		push_warning("Ignored a ball call response for spin %d while waiting on %d."
			% [seq, _pending_seq])
		return

	_pending_seq = -1
	emit_signal("outcome_ready", Outcome.new(
		int(message.get("prize_id", -1)),
		int(message.get("payout_factor", 0))))
