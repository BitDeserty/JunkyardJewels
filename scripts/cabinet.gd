# #### JUNKYARD JEWELS v0.1.0 ####
extends Node2D

# Singletons #

# Instantiate the BankManager
@onready var bank_instance = $Bank as Bank

# Instantiate the RNG
@onready var backend = $Backend as Backend

# Instantiate the GameManager
@onready var gamemanager_instance = $GameManager as FiniteStateMachine

func _ready():
	# Connect the meters
	bank_instance.connect("credits_incremented", Callable($CreditMeter, "_on_credits_incremented"))
	bank_instance.connect("bet_incremented", Callable($BetMeter, "_on_bet_incremented"))
	bank_instance.connect("win_incremented", Callable($WinMeter, "_on_win_incremented"))

	
# Move this out to a separate ViewPaytableState
func _on_back_to_game_button_released() -> void:
	$SlotGame/Camera2D.view_game()
	$Buttons/PaytableButton/PaytableButton.visible = true
	$Buttons/BackToGameButton/BackToGameButton.visible = false
