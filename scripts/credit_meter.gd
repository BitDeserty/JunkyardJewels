extends RichTextLabel

@onready var bank_instance = $"../Bank" as Bank

## True while the meter is counting. Check this before awaiting rollup_finished --
## a meter that has already settled will never emit again.
var rolling : bool = false

signal rollup_finished

func _on_credits_incremented(amount : int):
	if amount == 0:
		return

	var startnum = int(self.text)
	var stepspeed : float = 0.01
	var iter : int = 1
	var balance : int = bank_instance.GetCredits()
	var formatted_number : String = str(balance).pad_zeros(4)

	if amount < 0:
		iter = -1

	rolling = true
	for i in range(startnum, balance + iter, iter):
		await get_tree().create_timer(stepspeed).timeout
		formatted_number = str(i).pad_zeros(4)
		self.text = formatted_number

	# Land on the real balance even if the loop above never ran (text out of sync).
	self.text = str(balance).pad_zeros(4)
	rolling = false

	# Deferred so a rollup that finishes synchronously still lets whoever triggered
	# it arm their await first.
	call_deferred("emit_signal", "rollup_finished")
