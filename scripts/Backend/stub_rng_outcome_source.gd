# Flat-RNG stand-in for the bingo engine.
#
# Draws uniformly from the prize list the backend used before the ball call server
# existed. Kept as the self-test fixture and as a way to run the game with the bingo
# engine switched off -- note its distribution is a testing artefact, not a real
# paytable: it returns 493.75%.
class_name StubRngOutcomeSource
extends OutcomeSource

const PRIZES = [0, 1, 0, 2, 10, 0, 1, 0, 2, 50, 0, 1, 0, 2, 10, 0]


func RequestOutcome(_bet_amount : int) -> void:
	var prize_id := randi() % PRIZES.size()
	var outcome := Outcome.new(prize_id, PRIZES[prize_id])

	# Deferred so every source resolves asynchronously and the caller always gets to
	# arm its handler first, exactly as a real round trip would behave.
	call_deferred("emit_signal", "outcome_ready", outcome)


func PossibleFactors() -> Array[int]:
	var factors : Array[int] = []
	for factor in PRIZES:
		if not factors.has(factor):
			factors.append(factor)
	factors.sort()
	return factors


func Describe() -> String:
	return "stub rng (%d flat prizes)" % PRIZES.size()
