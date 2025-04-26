extends State
class_name ReelSpinStartState

@onready var strip = $"../ReelStrip"
@export var start_curve : Curve

var timer : Timer

signal _reel_started

func Enter():
	print("Entering Reel Spin Start State for %s" % get_parent().name)
	timer = Timer.new()
	add_child(timer)
	timer.connect("timeout", Callable(self, "_on_timeout"))
	timer.one_shot = true
	
	timer.start(start_curve.max_domain)
	strip.current_speed = 0.0
	strip.target_speed = strip.FULL_SPEED
	
func Update(_delta:float):
	#if (curving_to_target):
	if timer.time_left > 0.0:
		# Use the curve to determine the speed based on normalized time (0 to 1)
		var curve_value = start_curve.sample(start_curve.max_domain - timer.time_left)
		
		# Calculate the current speed based on the curve value
		strip.current_speed = int(curve_value * strip.FULL_SPEED)  # Apply the max speed based on curve value
	else:
		strip.current_speed = int(strip.target_speed)
	strip.UpdateReel(_delta)
	
func Exit():
	emit_signal("_reel_started")
	
func _on_timeout():
	state_transition.emit(self, "ReelSpinningState")
