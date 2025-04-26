extends Node
class_name Backend

signal _playresponse(PlayResult)

#region Random Number Generator and Mapper mock
var paytable : Array


#endregion

func _ready():
	# Randomize the RNG
	randomize()
	
	# Connect the game platform to the backend
	$"../GameManager/PlayingState".connect("_playrequest", on_PlayRequest)
	
	paytable = [0, 1, 0, 2, 10, 0, 1, 0, 2, 50, 0, 1, 0, 2, 10, 0] # 16 possible outcomes


func on_PlayRequest(playdata : PlayResult):
	# Get a random number to do a lookup the paytable for the play result
	var win_index = randi() % paytable.size()
	
	# Get the payout
	playdata.payout_factor = paytable[win_index]
	
	# Calculate the winnings
	playdata.payout_amount = playdata.payout_factor * playdata.bet_amount
	
	# Create a presentation for the result and add it to the PlayResult
	# (call the Mapper to use the payout_factor to give some reel targets in a payout_index)
	
	# Send the PlayResult in a PlayResponse signal
	#if playdata.payout_factor:
	SendPlayResponse(playdata)
	#else:
		#printerr("ERR: Received PlayRequest, but no presentation data to send.")
	
func SendPlayResponse(playdata : PlayResult):
	print("Sending a PlayResponse <-")
	emit_signal("_playresponse", playdata)
