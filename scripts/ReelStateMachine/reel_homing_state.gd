extends State
class_name ReelHomingState

@onready var strip = $"../ReelStrip"
@export var home_curve : Curve

var timer : Timer
var target_position : int
var target_symbol : int

signal _reel_homed

func Enter():
	print("Entering ReelHoming State for %s" % get_parent().name)
	timer = Timer.new()
	add_child(timer)
	timer.connect("timeout", Callable(self, "_on_timeout"))
	timer.one_shot = true
	
	# Calculate the target position to stop at (target * SYMBOL_SIZE)
	
	target_position = strip.CalculateStopPosition(target_symbol)
	
	timer.start(home_curve.max_domain)
	strip.current_speed = 500
	strip.target_speed = 0
	
	
func Update(_delta:float):
	#if (curving_to_target):
	if timer.time_left > 0.0:
		# Use the curve to determine the speed based on normalized time (0 to 1)
		var curve_value = home_curve.sample(home_curve.max_domain - timer.time_left)
		
		# Calculate the current speed based on the curve value
		strip.current_speed = int(curve_value * strip.FULL_SPEED)  # Apply the max speed based on curve value
	else:
		strip.current_speed = int(strip.target_speed)
	strip.UpdateReel(_delta)
	
func Exit():
	print("Homed to %d" % strip.yoffset)
	emit_signal("_reel_homed")
	
	
func _on_timeout():
	state_transition.emit(self, "ReelIdleState")
