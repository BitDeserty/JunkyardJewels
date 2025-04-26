extends State
class_name ReelSpinningState

@onready var strip = $"../ReelStrip"

func Enter():
	print("Entering Reel Spinning State for %s" % get_parent().name)
	
func Update(_delta:float):
	strip.current_speed = int(strip.target_speed)
	strip.UpdateReel(_delta)
	
func Exit():
	pass
