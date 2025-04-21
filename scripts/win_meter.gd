extends RichTextLabel

func _on_win_incremented(winamt):
	var startnum = int(self.text)
	var stepspeed : float = 0.02
	var formatted_number : String = str(winamt).pad_zeros(4)
	
	for i in range(startnum, winamt + 1, 1):
		await get_tree().create_timer(stepspeed).timeout
		formatted_number = str(i).pad_zeros(4)
		self.text = formatted_number
