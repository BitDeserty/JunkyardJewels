extends RichTextLabel

## True while the meter is counting. See CreditMeter for why this exists.
var rolling : bool = false

signal rollup_finished

func _on_win_incremented(winamt):
	var startnum = int(self.text)
	var stepspeed : float = 0.02
	var formatted_number : String = str(winamt).pad_zeros(4)

	# Counting down is a reset between plays, not a rollup -- just snap to it.
	if winamt <= startnum:
		self.text = formatted_number
		return

	rolling = true
	for i in range(startnum, winamt + 1, 1):
		await get_tree().create_timer(stepspeed).timeout
		formatted_number = str(i).pad_zeros(4)
		self.text = formatted_number

	self.text = str(winamt).pad_zeros(4)
	rolling = false

	call_deferred("emit_signal", "rollup_finished")
