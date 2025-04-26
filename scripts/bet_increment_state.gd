extends State
class_name BetIncrementState

@onready var bank_instance = $"../../Bank" as Bank

func Enter():
	print("*Entering Game BetIncrementState")
	# Disable the button deck
	$"../../Buttons/BetButton/BetButton".disabled = true
	$"../../Buttons/SpinButton/SpinButton".disabled = true
	$"../../Buttons/BillInsert/BillInsertButton".disabled = true
	
	#$"../../Buttons/SpinButton/SpinButton".connect("pressed", Callable(self, "_on_spin_button_pressed"))
	#$"../../Buttons/BillInsert/BillInsertButton".connect("pressed", Callable(self, "_on_bill_insert_button_pressed"))
	#$"../../Buttons/BetButton/BetButton".connect("pressed", Callable(self, "_on_bet_button_pressed"))
	
	bank_instance.IncrementBet()
	await get_tree().create_timer(0.1).timeout
	state_transition.emit(self, "IdleState")
	
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
