# What the outcome source decided, before any of it is turned into a presentation.
#
# prize_id identifies WHICH prize was won (a paytable index under the stub, a bingo
# pattern id once the card evaluator replaces it). payout_factor is what it is worth
# as a multiple of the bet. Only payout_factor drives the reel mapping.
class_name Outcome
extends RefCounted

var prize_id : int
var payout_factor : int


func _init(id : int, factor : int):
	prize_id = id
	payout_factor = factor


func _to_string() -> String:
	return "Outcome(prize %d, pays %dx)" % [prize_id, payout_factor]
