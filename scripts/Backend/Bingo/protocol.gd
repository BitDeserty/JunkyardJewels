# The wire format between the slot client and the ball call server.
#
# Defined once and used by both ends so there is exactly one definition of the
# protocol. Messages travel as JSON strings; these builders return the Dictionary
# form and the transport does the encoding.
#
# Only PLAY_RESPONSE changes what the game does. CARD_DEALT, BALL_CALLED and
# PATTERN_HIT exist so a viewer can watch the outcome being decided -- the client
# ignores them, which is the point being demonstrated.
class_name Protocol

const HELLO : String = "HELLO"
const HELLO_ACK : String = "HELLO_ACK"
const PLAY_REQUEST : String = "PLAY_REQUEST"
const CARD_DEALT : String = "CARD_DEALT"
const BALL_CALLED : String = "BALL_CALLED"
const PATTERN_HIT : String = "PATTERN_HIT"
const PLAY_RESPONSE : String = "PLAY_RESPONSE"

const ROLE_CLIENT : String = "client"
const ROLE_SERVER : String = "server"


static func Hello(session_id : String, role : String) -> Dictionary:
	return {"type": HELLO, "session_id": session_id, "role": role}


static func HelloAck(session_id : String, role : String) -> Dictionary:
	return {"type": HELLO_ACK, "session_id": session_id, "role": role}


static func PlayRequest(session_id : String, seq : int, bet_amount : int) -> Dictionary:
	return {"type": PLAY_REQUEST, "session_id": session_id, "seq": seq, "bet_amount": bet_amount}


static func CardDealt(seq : int, numbers : PackedInt32Array) -> Dictionary:
	return {"type": CARD_DEALT, "seq": seq, "card": Array(numbers)}


static func BallCalled(seq : int, ball : int, index : int) -> Dictionary:
	return {"type": BALL_CALLED, "seq": seq, "ball": ball, "index": index}


static func PatternHit(seq : int, pattern_id : String, on_ball : int, daub_mask : int) -> Dictionary:
	return {"type": PATTERN_HIT, "seq": seq, "pattern_id": pattern_id,
		"on_ball": on_ball, "daub_mask": daub_mask}


static func PlayResponse(seq : int, prize_id : int, payout_factor : int) -> Dictionary:
	return {"type": PLAY_RESPONSE, "seq": seq, "prize_id": prize_id, "payout_factor": payout_factor}


static func Encode(message : Dictionary) -> String:
	return JSON.stringify(message)


# Returns an empty Dictionary rather than null on malformed input -- a message from
# another window is untrusted, and callers check `type` anyway.
static func Decode(payload : String) -> Dictionary:
	var parsed = JSON.parse_string(payload)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Discarded malformed ball call message: %s" % payload)
		return {}
	return parsed
