# The seam between deciding an outcome and presenting it.
#
# Request/response rather than a plain return, because deciding an outcome may mean a
# round trip to another process: the ball call server can be in-process, in another
# browser window, or eventually across a network, and the game must not care which.
# This mirrors the _playrequest / _playresponse pair Backend already uses.
#
# Everything downstream of this class -- mapper, evaluator, paytable, reel targeting,
# payout -- is presentation and is blind to how the prize was decided.
class_name OutcomeSource
extends RefCounted

signal outcome_ready(outcome : Outcome)


# Optional: sources that need to open a connection do it here rather than in _init,
# so the caller controls when traffic starts.
func Start() -> void:
	pass


func RequestOutcome(_bet_amount : int) -> void:
	push_error("OutcomeSource.RequestOutcome must be overridden")


# Every payout factor this source is capable of emitting. The backend asserts the
# mapper can present all of them before the first spin, so a gap fails loudly at
# startup rather than hanging a reel mid-game.
func PossibleFactors() -> Array[int]:
	return []


func Describe() -> String:
	return "unknown outcome source"
