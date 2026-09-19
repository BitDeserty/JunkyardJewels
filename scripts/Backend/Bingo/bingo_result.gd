# What one bingo game produced. Carries the presentation detail the console needs
# alongside the prize the slot client actually acts on.
class_name BingoResult
extends RefCounted

var prize_id : int = -1
var payout_factor : int = 0
var pattern_id : String = ""

## Which ball completed the winning pattern, 1-based. 0 when nothing hit.
var on_ball : int = 0

## Final 25-bit daub mask, for highlighting the card.
var daub_mask : int = 0


func IsWin() -> bool:
	return prize_id >= 0


func _to_string() -> String:
	if not IsWin():
		return "no pattern"
	return "%s on ball %d, pays %dx" % [pattern_id, on_ball, payout_factor]
