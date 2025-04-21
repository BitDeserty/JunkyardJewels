extends State
class_name PlayingState

@onready var bank_instance = $"../../Bank" as Bank

func Enter():
	print("Entering Playing State")
	
	# Disable the button deck
	$"../../Buttons/BetButton/BetButton".disabled = true
	#$"../../Buttons/SpinButton/SpinButton".disabled = true
	$"../../Buttons/BillInsert/BillInsertButton".disabled = true
	
	$"../../Buttons/SpinButton/SpinButton".connect("pressed", Callable(self, "_on_spin_button_pressed"))
	#$"../../Buttons/BillInsert/BillInsertButton".connect("pressed", Callable(self, "_on_bill_insert_button_pressed"))
	#$"../../Buttons/BetButton/BetButton".connect("pressed", Callable(self, "_on_bet_button_pressed"))
	
	
	# Start the reels spinning
	$"../../ReelSet".SpinReels()
	
	# Request a play from the RNG
	#	Fire a PlayRequest(betamt) event
	
func Update(_delta : float):
	await($"../../ReelSet"._reels_started)
	# Wait for PlayResponse(PlayResult)
	
func Exit():
	# Enable the button deck
	$"../../Buttons/BetButton/BetButton".disabled = false
	$"../../Buttons/SpinButton/SpinButton".disabled = false
	$"../../Buttons/BillInsert/BillInsertButton".disabled = false
	
	$"../../Buttons/SpinButton/SpinButton".disconnect("pressed", Callable(self, "_on_spin_button_pressed"))
	#$"../../Buttons/BillInsert/BillInsertButton".disconnect("pressed", Callable(self, "_on_bill_insert_button_pressed"))
	#$"../../Buttons/BetButton/BetButton".disconnect("pressed", Callable(self, "_on_bet_button_pressed"))


# Respond to a PlayResponse(PlayResult)
func _on_playresponse():
	pass
	# Set the reel targets
	# Call SpinToTargets(targets)
	
	# If there is a bonus presentation, go to the BonusState
	
	# If there is a win, go to the PayoutState
	
	# Else, go back to IdleState

func _on_spin_button_pressed():
	# Set the reel targets
	
	# Disable the spin button so you can't hit it twice before the reels have stopped
	$"../../Buttons/SpinButton/SpinButton".disabled = true
	
	# Command to stop the reels at the specified targets
	$"../../ReelSet".StopReels(6, 12, 16)
	print("Stopping at 6 12 16")
	
	# Wait for the reels to stop
	await($"../../ReelSet"._reels_stopped)
	
	# If there is a bonus presentation, go to the BonusState
	
	# If there is a win, go to the PayoutState
	
	# Else, go back to IdleState
	$"..".change_state(self, "IdleState")
