extends State
class_name PlayingState

@onready var bank_instance = $"../../Bank" as Bank
@onready var backend = $"../../Backend" as Backend

signal _playrequest(PlayResult)

func Enter():
	print("*Entering Game Playing State")

	# Disable the button deck
	$"../../Buttons/BetButton/BetButton".disabled = true
	#$"../../Buttons/SpinButton/SpinButton".disabled = true # Comment this out for 2-touch
	$"../../Buttons/BillInsert/BillInsertButton".disabled = true
	
	$"../../Buttons/SpinButton/SpinButton".connect("pressed", Callable(self, "_on_spin_button_pressed")) # Uncomment this for 2-touch
	#$"../../Buttons/BillInsert/BillInsertButton".connect("pressed", Callable(self, "_on_bill_insert_button_pressed"))
	#$"../../Buttons/BetButton/BetButton".connect("pressed", Callable(self, "_on_bet_button_pressed"))
	
	backend.connect("_playresponse", Callable(self, "_on_playresponse"))
	
	# Start the reels spinning
	await $"../../ReelSet".SpinReels()
	
	# Request a play from the RNG
	# Build the request
	var playreq = PlayResult.new(bank_instance.GetBet())
	await $"../../Buttons/SpinButton/SpinButton".pressed # Uncomment this for 2-touch
	
	# Send a PlayRequest(betamt) 
	print("Sending a PlayRequest ->")
	emit_signal("_playrequest", playreq)
	
func Update(_delta : float):
	pass
	
	
func Exit():
	# Enable the button deck
	$"../../Buttons/BetButton/BetButton".disabled = false
	$"../../Buttons/SpinButton/SpinButton".disabled = false
	$"../../Buttons/BillInsert/BillInsertButton".disabled = false
	
	$"../../Buttons/SpinButton/SpinButton".disconnect("pressed", Callable(self, "_on_spin_button_pressed")) # Uncomment this for 2-touch
	#$"../../Buttons/BillInsert/BillInsertButton".disconnect("pressed", Callable(self, "_on_bill_insert_button_pressed"))
	#$"../../Buttons/BetButton/BetButton".disconnect("pressed", Callable(self, "_on_bet_button_pressed"))

	backend.disconnect("_playresponse", Callable(self, "_on_playresponse"))

# Respond to a PlayResponse(PlayResult)
# This function takes the PlayResult data and runs a presentation by running through relevant states
# and passing the data through. Later I plan to change this to something using a Builder design pattern
# to build a presentation. This will come in handy for later video slots.
func _on_playresponse(_playdata : PlayResult):
	# Set the reel targets
	# TODO: Setting and spinning to targets.
	print("PlayResponse received! Commanding reels to stop at 12, 12, 12 (Test hardcode)")
	
	# Call SpinToTargets(targets)
	$"../../ReelSet".StopReels(12, 12, 12)
	
	# Wait for the reels to stop
	await $"../../ReelSet"._reels_stopped
	
	## If there is a bonus presentation, go to the BonusState
	#if PlayResult.bonus_amount:
		#$"..".change_state(self, "BonusState")
	#
	## If there is a win, go to the PayoutState
	#if PlayResult.payout_amount:
		#$"..".change_state(self, "PayoutState")
	
	# Else, go back to IdleState
	$"..".change_state(self, "IdleState")
