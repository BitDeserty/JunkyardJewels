# The seam between deciding an outcome and presenting it.
#
# Everything downstream of this class -- mapper, evaluator, paytable, reel targeting,
# payout -- is presentation and is deliberately blind to how the prize was decided.
# Milestone 3 subclasses this with a bingo engine (card distribution, ball call, card
# evaluation) and nothing else in the game has to change.
class_name OutcomeSource
extends RefCounted


func DrawOutcome(_bet_amount : int) -> Outcome:
	push_error("OutcomeSource.DrawOutcome must be overridden")
	return null


# Every payout factor this source is capable of emitting. The backend asserts the
# mapper can present all of them before the first spin, so a gap fails loudly at
# startup rather than hanging a reel mid-game.
func PossibleFactors() -> Array[int]:
	return []
