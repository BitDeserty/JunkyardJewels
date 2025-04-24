# PlayResult.gd
extends Object

class_name PlayResult

# Attributes for PlayResult
var bet_amount : int
var payout_amount : int
var payout_factor : int
var bonus_amount : int

# Constructor to initialize PlayResult
func _init(bet_amount: int):
	self.bet_amount = bet_amount
