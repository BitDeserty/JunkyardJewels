# The prize schedule for the bingo game, plus the ball budget that governs how often
# each pattern lands. Tested top to bottom, first match wins, so order by payout
# descending -- a coverall contains every lesser pattern.
class_name PatternPrizeTable
extends Resource

## Ordered, highest paying first. Untyped Array for the same reason as PaytableData.
@export var prizes : Array = []

## How many balls are called per game. The single biggest lever on the prize
## distribution and therefore on RTP -- run --selftest after changing it.
@export var ball_budget : int = 42


func BestFor(daub_mask : int) -> PatternPrize:
	for prize in prizes:
		if prize != null and prize.Matches(daub_mask):
			return prize
	return null


func PrizeIdOf(prize : PatternPrize) -> int:
	return prizes.find(prize)


# Every factor this table can award, including the zero for no pattern.
func PayableFactors() -> Array[int]:
	var factors : Array[int] = [0]
	for prize in prizes:
		if prize != null and not factors.has(prize.payout_factor):
			factors.append(prize.payout_factor)
	factors.sort()
	return factors


func IsValid() -> bool:
	if prizes.is_empty():
		return false
	for prize in prizes:
		if not (prize is PatternPrize):
			push_error("Prize table contains a %s where a PatternPrize was expected."
				% type_string(typeof(prize)))
			return false
	return true
