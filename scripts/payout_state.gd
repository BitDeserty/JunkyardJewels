extends State
class_name PayoutState

@onready var bank_instance = $"../../Bank" as Bank

# Primed by PlayingState before the transition, the same way a reel is given its
# target before it is told to seek.
var payout_amount : int = 0


func SetPayout(amount : int) -> void:
	payout_amount = amount


func Enter():
	print("*Entering Game Payout State, paying %d credits" % payout_amount)

	# Disable the button deck while the meters roll up
	$"../../Buttons/BetButton/BetButton".disabled = true
	$"../../Buttons/SpinButton/SpinButton".disabled = true
	$"../../Buttons/BillInsert/BillInsertButton".disabled = true

	bank_instance.IncrementWin(payout_amount)
	bank_instance.IncrementCredits(payout_amount)

	# Hand control back only once both meters have settled, otherwise the next play
	# starts a second rollup on top of one still running.
	if $"../../WinMeter".rolling:
		await $"../../WinMeter".rollup_finished
	if $"../../CreditMeter".rolling:
		await $"../../CreditMeter".rollup_finished

	payout_amount = 0
	state_transition.emit(self, "IdleState")


func Update(_delta : float):
	pass


func Exit():
	# Enable the button deck
	$"../../Buttons/BetButton/BetButton".disabled = false
	$"../../Buttons/SpinButton/SpinButton".disabled = false
	$"../../Buttons/BillInsert/BillInsertButton".disabled = false
