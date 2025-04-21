# PlayResult.gd
extends Object

class_name PlayResult

# Attributes for PlayResult
var betamt: int
var payout_index: int
var bonus_index: int

# Constructor to initialize PlayResult
func _init(betamt: int, payout_index: int, bonus_index: int):
	self.betamt = betamt
	self.payout_index = payout_index
	self.bonus_index = bonus_index
