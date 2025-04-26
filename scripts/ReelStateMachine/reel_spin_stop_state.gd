extends State
class_name ReelSpinStopState

@onready var strip = $"../ReelStrip"
@export var stop_curve : Curve

var timer : Timer
var target_position : int
var target_symbol : int

signal _reel_stopped

func Enter():
	print("Entering Reel Spin Stop State for %s" % get_parent().name)
	timer = Timer.new()
	add_child(timer)
	timer.connect("timeout", Callable(self, "_on_timeout"))
	timer.one_shot = true
	
	# Calculate the target position to stop at (target * SYMBOL_SIZE)
	target_symbol = 12
	target_position = strip.CalculateStopPosition(target_symbol)
	
	timer.start(stop_curve.max_domain)

	strip.target_speed = 0
	#strip.yoffset = 0
	
func Update(_delta:float):
	#if (curving_to_target):
	if timer.time_left > 0.0:
		# Use the curve to determine the speed based on normalized time (0 to 1)
		var curve_value = stop_curve.sample(stop_curve.max_domain - timer.time_left)
		
		# Calculate the current speed based on the curve value
		strip.current_speed = int(curve_value * strip.FULL_SPEED)  # Apply the max speed based on curve value
	else:
		strip.current_speed = int(strip.target_speed)
	strip.UpdateReel(_delta)
	
func Exit():
	emit_signal("_reel_stopped")
	
func _on_timeout():
	state_transition.emit(self, "ReelIdleState")
