extends State
class_name StartupState

@onready var bank_instance = $"../../Bank" as Bank
@export var fade_duration : float = 1.0    # Duration for the fade out

func Enter():
	print("Entering Startup State")
	
	# Disable the button deck
	$"../../Buttons/BetButton/BetButton".disabled = true
	$"../../Buttons/SpinButton/SpinButton".disabled = true
	$"../../Buttons/BillInsert/BillInsertButton".disabled = true
	
	#$"../../Buttons/SpinButton/SpinButton".connect("pressed", Callable(self, "_on_spin_button_pressed"))
	#$"../../Buttons/BillInsert/BillInsertButton".connect("pressed", Callable(self, "_on_bill_insert_button_pressed"))
	#$"../../Buttons/BetButton/BetButton".connect("pressed", Callable(self, "_on_bet_button_pressed"))

	# Listen for reels homed signal
	$"../../ReelSet".connect("_reels_homed", Callable(self, "_on_reels_homed"))
	
	# Start the reels spinning
	$"../../ReelSet".HomeReels(12, 12, 12)
	$TitleSplash.visible = true
	

func Update(_delta : float):
	await($"../../ReelSet"._reels_homed)

func Exit():
	# Enable the button deck
	$"../../Buttons/BetButton/BetButton".disabled = false
	$"../../Buttons/SpinButton/SpinButton".disabled = false
	$"../../Buttons/BillInsert/BillInsertButton".disabled = false
	
	#$"../../Buttons/SpinButton/SpinButton".disconnect("pressed", Callable(self, "_on_spin_button_pressed"))
	#$"../../Buttons/BillInsert/BillInsertButton".disconnect("pressed", Callable(self, "_on_bill_insert_button_pressed"))
	#$"../../Buttons/BetButton/BetButton".disconnect("pressed", Callable(self, "_on_bet_button_pressed"))
	
	$"../../ReelSet".disconnect("_reels_homed", Callable(self, "_on_reels_homed"))

func _on_reels_homed():
	#$TitleSplash.visible = false
	fade_out()
	$"../IdleState/InsertBillTip".visible = true
	$"..".change_state(self, "IdleState")
	
# Function to fade out the texture
func fade_out() -> void:
	# Ensure the texture is visible and has a material to modify
	if $TitleSplash:
		# Start the fade animation using the tween
		var tween = get_tree().create_tween()
		tween.tween_property($TitleSplash, "modulate:a", 0.0, fade_duration)
		tween.tween_callback(($TitleSplash.set_visible.bind(false)))
