extends State
class_name BillInsertState

@onready var bank_instance = $"../../Bank" as Bank

func Enter():
	print("Entering Bill Insert State")
	# Disable the button deck
	$"../../Buttons/BetButton/BetButton".disabled = true
	$"../../Buttons/SpinButton/SpinButton".disabled = true
	$"../../Buttons/BillInsert/BillInsertButton".disabled = true
	
	#$"../../Buttons/SpinButton/SpinButton".connect("pressed", Callable(self, "_on_spin_button_pressed"))
	#$"../../Buttons/BillInsert/BillInsertButton".connect("pressed", Callable(self, "_on_bill_insert_button_pressed"))
	#$"../../Buttons/BetButton/BetButton".connect("pressed", Callable(self, "_on_bet_button_pressed"))
	
	# Move the camera down to view the bill being inserted
	$"../../SlotGame/Camera2D".view_payout()
	
	# Play the bill insert animation
	$"../../Buttons/BillInsert/BillInsert".play("default")
	
	print("Inserting $100!")
	
func Update(_delta : float):
	pass
	
func Exit():
	# Enable the button deck
	$"../../Buttons/BetButton/BetButton".disabled = false
	$"../../Buttons/SpinButton/SpinButton".disabled = false
	$"../../Buttons/BillInsert/BillInsertButton".disabled = false
	
	#$"../../Buttons/SpinButton/SpinButton".disconnect("pressed", Callable(self, "_on_spin_button_pressed"))
	#$"../../Buttons/BillInsert/BillInsertButton".disconnect("pressed", Callable(self, "_on_bill_insert_button_pressed"))
	#$"../../Buttons/BetButton/BetButton".disconnect("pressed", Callable(self, "_on_bet_button_pressed"))

	# Move the camera back to the playing position
	$"../../SlotGame/Camera2D".view_game()
	
func _on_bill_insert_animation_finished() -> void:
	bank_instance.IncrementCredits(100)
	
	state_transition.emit(self, "IdleState")
