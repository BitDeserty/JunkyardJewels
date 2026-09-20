# TEMPORARY stand-in for the bingo engine.
#
# Draws uniformly from the flat prize list the backend has always used, so the
# distribution is unchanged from before the mapper existed. This whole file is
# scaffolding: Milestone 3 replaces it with BingoOutcomeSource and deletes it.
class_name StubRngOutcomeSource
extends OutcomeSource

# The original Backend.gd paytable: 16 prizes, drawn with equal probability.
# Untyped on purpose -- a PackedInt32Array constructor is not a constant expression.
const PRIZES = [0, 1, 0, 2, 10, 0, 1, 0, 2, 50, 0, 1, 0, 2, 10, 0]


func DrawOutcome(_bet_amount : int) -> Outcome:
	var prize_id := randi() % PRIZES.size()
	return Outcome.new(prize_id, PRIZES[prize_id])


func PossibleFactors() -> Array[int]:
	var factors : Array[int] = []
	for factor in PRIZES:
		if not factors.has(factor):
			factors.append(factor)
	factors.sort()
	return factors
