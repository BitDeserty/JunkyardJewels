# This class handles the behavior of a single reel via the states that are added as children nodes
# to it.
#
# @class ReelStateMachine
#
# @param target_symbol (int)
# @param target_position (int)
#
# @method GetReelTarget()
# @method SetReelTarget()

extends FiniteStateMachine
class_name ReelStateMachine

signal _reel_homed
signal _reel_started
signal _reel_stopped

var target_symbol : int
var target_position : int

func _ready():
	# Call the inherited _ready
	super()

	# Connect the signals from the various states to be passed up to the ReelSet
	$ReelHomingState.connect("_reel_homed", Callable(self, "on_reel_homed"))
	$ReelSpinStartState.connect("_reel_started", Callable(self, "on_reel_started"))
	$ReelSpinStopState.connect("_reel_stopped", Callable(self, "on_reel_stopped"))

func _process(_delta):
	super(_delta)

# target is a strip index (0..23); target_position is that index in pixels.
func SetReelTarget(target : int):
	target_symbol = target
	target_position = $ReelStrip.CalculateStopPosition(target)

func GetReelTarget() -> int:
	return target_position

# Where the reel is actually sitting, as a strip index. After a stop this equals
# target_symbol exactly -- the stop state lands on the commanded position.
func GetReelStop() -> int:
	return $ReelStrip.CurrentStopIndex()

func GetCurrentState():
	return self.current_state.to_string()

func on_reel_homed():
	#print("%s homed successfully" % name)
	emit_signal("_reel_homed")

func on_reel_started():
	#print("%s started a spin" % name)
	emit_signal("_reel_started")

func on_reel_stopped():
	#print("%s stopped on position %d" % [name, $ReelStrip.offset])
	emit_signal("_reel_stopped")
