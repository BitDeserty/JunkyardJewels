extends State
class_name ReelSpinSeekState

@onready var strip = $"../ReelStrip"

func Enter():
	print("Entering Reel Spin Seek State for %s, target %d" % [get_parent().name, $"../".GetReelTarget()])

	strip.current_speed = 0.0
	strip.target_speed = strip.FULL_SPEED
	
func Update(_delta:float):
	strip.current_speed = int(strip.target_speed)
	strip.UpdateReel(_delta)
	
	# Spin until we are almost to the target. This magic number is tuned by hand because I can't math it just yet.
	# I use the absolute difference with a tolerance to account for the inexactness of float math, as well as to give a little
	# bit of natural slop to the stop positions of the reels.
	if abs(((int(strip.yoffset) + 140) % strip.STRIP_HEIGHT) - $"../".GetReelTarget()) <= 5:
		state_transition.emit(self, "ReelSpinStopState")
	
func Exit():
	pass
