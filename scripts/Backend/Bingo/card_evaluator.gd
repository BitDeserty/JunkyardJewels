# Daubs a card against a ball sequence and prices the result.
#
# The prize is the best pattern achieved by the end of the call, which is why the
# whole sequence is daubed before the table is consulted. `on_ball` is then found by
# replaying the daub to see when that winning pattern first completed -- purely so
# the console can say "letter x on ball 24".
class_name CardEvaluator
extends RefCounted

var _table : PatternPrizeTable


func _init(table : PatternPrizeTable):
	_table = table


func Evaluate(card : BingoCard, called : PackedInt32Array) -> BingoResult:
	var result := BingoResult.new()

	var mask := BingoCard.StartingMask()
	var history : Array[int] = []
	for ball in called:
		var index := card.IndexOf(ball)
		if index != -1:
			mask |= 1 << index
		history.append(mask)

	result.daub_mask = mask

	var best := _table.BestFor(mask)
	if best == null:
		return result

	result.prize_id = _table.PrizeIdOf(best)
	result.payout_factor = best.payout_factor
	result.pattern_id = best.pattern_id
	result.on_ball = _FirstBallCompleting(best, history)
	return result


# Daub mask after each ball is already recorded, so this is a scan, not a re-simulation.
func _FirstBallCompleting(prize : PatternPrize, history : Array[int]) -> int:
	for i in history.size():
		if prize.Matches(history[i]):
			return i + 1
	return 0
