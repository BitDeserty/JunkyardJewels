extends State
class_name IdleState

@onready var bank_instance = $"../../Bank" as Bank

func Enter():
	print("Entering Idle State")
	# Enable the button deck
	$"../../Buttons/BetButton/BetButton".disabled = false	
	$"../../Buttons/SpinButton/SpinButton".disabled = false
	$"../../Buttons/BillInsert/BillInsertButton".disabled = false
	
	$"../../Buttons/SpinButton/SpinButton".connect("pressed", Callable(self, "_on_spin_button_pressed"))
	$"../../Buttons/BillInsert/BillInsertButton".connect("pressed", Callable(self, "_on_bill_insert_button_pressed"))
	$"../../Buttons/BetButton/BetButton".connect("pressed", Callable(self, "_on_bet_button_pressed"))
	
	$"../../Buttons/PaytableButton/PaytableButton".visible = true
	
func Update(_delta : float):
	pass
	
func Exit():
	
	$"../../Buttons/SpinButton/SpinButton".disconnect("pressed", Callable(self, "_on_spin_button_pressed"))
	$"../../Buttons/BillInsert/BillInsertButton".disconnect("pressed", Callable(self, "_on_bill_insert_button_pressed"))
	$"../../Buttons/BetButton/BetButton".disconnect("pressed", Callable(self, "_on_bet_button_pressed"))

func _on_spin_button_pressed() -> void:
	print("Spin button pressed from Idle State!")
		# Check the bet against the bank
	if bank_instance.GetBet() <= bank_instance.GetCredits():
		bank_instance.IncrementCredits(bank_instance.GetBet() * -1)
		$"..".change_state(self, "PlayingState")
	else:
		print("Not enough credits for bet.")
		var tween = get_tree().create_tween()
		tween.tween_callback($"../../CreditMeter".set_modulate.bind(Color.BLUE)).set_delay(.5)
		tween.tween_callback($"../../CreditMeter".set_modulate.bind(Color.RED)).set_delay(.5)

func _on_bet_button_pressed() -> void:
	print("Bet button pressed!")
	$"..".change_state(self, "BetIncrementState")
	
func _on_bill_insert_button_pressed() -> void:
	if $InsertBillTip.visible:
		$InsertBillTip.visible = false
	$"..".change_state(self, "BillInsertState")
