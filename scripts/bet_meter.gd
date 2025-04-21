extends RichTextLabel

func _on_bet_incremented(betamt):
	var formatted_number : String = str(betamt).pad_zeros(4)
	self.text = formatted_number
