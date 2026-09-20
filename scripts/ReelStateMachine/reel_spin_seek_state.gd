extends State
class_name ReelSpinSeekState

@onready var strip = $"../ReelStrip"
@onready var stop_state = $"../ReelSpinStopState"

var _travelled : float = 0.0
var _stop_travel : float = 0.0

# Guarantees at least one more full revolution once a target arrives, so a reel whose
# target happens to be right under it doesn't stop the instant it starts seeking.
var _min_travel : float = 0.0


func Enter():
	print("Entering Reel Spin Seek State for %s, target %d" % [get_parent().name, $"../".GetReelTarget()])

	_travelled = 0.0
	_stop_travel = stop_state.GetTravelDistance()
	_min_travel = float(strip.STRIP_HEIGHT)

	strip.current_speed = 0.0
	strip.target_speed = strip.FULL_SPEED


func Update(_delta:float):
	strip.current_speed = int(strip.target_speed)
	strip.UpdateReel(_delta)
	_travelled += strip.current_speed * _delta

	if _travelled < _min_travel:
		return

	# Hand over as soon as the target is within coasting range of the stop ramp. The
	# ramp then scales itself to whatever distance is actually left, so this only has
	# to be approximately right -- unlike the old equality-with-tolerance test, which
	# the reel stepped straight over at 16 pixels per frame.
	if strip.DistanceToTarget(float($"../".GetReelTarget())) <= _stop_travel:
		state_transition.emit(self, "ReelSpinStopState")


func Exit():
	pass
