# PlayResult.gd
# RefCounted rather than Object: one of these is created per spin and nothing ever
# freed them.
extends RefCounted

class_name PlayResult

# Attributes for PlayResult
var bet_amount : int
var payout_amount : int
var payout_factor : int
var bonus_amount : int

# Which prize the backend decided on -- a stub paytable index today, a bingo pattern
# id once the card evaluator replaces the stub.
var prize_id : int

# The presentation the mapper chose to display that prize: one strip index per reel.
var reel_stops : Array[int] = []

# Constructor to initialize PlayResult
func _init(betamt: int):
	self.bet_amount = betamt
