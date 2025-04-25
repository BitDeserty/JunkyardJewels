extends Node
class_name Bank

var balance : int = 0
var betamt : int = 1
var winmeter : int = 0

signal credits_incremented(balance : int)
signal bet_incremented(betamt : int)
signal win_incremented

func GetCredits() -> int:
	return balance
	
func GetBet() -> int:
	return betamt
	
func GetWin() -> int:
	return winmeter
	
func IncrementCredits(amount : int):
	balance += amount
	emit_signal("credits_incremented",amount)
	
func IncrementBet():
	if (betamt < 10):
		betamt = betamt + 1
	else:
		betamt = 1
	emit_signal("bet_incremented",betamt)
	
func IncrementWin(amount : int):
	winmeter += amount
	emit_signal("win_incremented", winmeter)
