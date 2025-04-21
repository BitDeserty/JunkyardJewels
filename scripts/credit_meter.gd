extends RichTextLabel

@onready var bank_instance = $"../Bank" as Bank

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
		
	for i in range(startnum, balance + iter, iter):
		await get_tree().create_timer(stepspeed).timeout
		formatted_number = str(i).pad_zeros(4)
		self.text = formatted_number
