extends Node
class_name ReelSet

@onready var reels_homed : bool = false

# Explicit list rather than get_child_count(): the aggregation below counts reels, and
# adding any non-reel helper node under ReelSet would otherwise stop the _reels_*
# signals from ever firing.
@onready var reels : Array = [$Reel1, $Reel2, $Reel3]

signal _reels_homed
signal _reels_started
signal _reels_stopped

func _ready():
	for reel in reels:
		reel.connect("_reel_homed", Callable(self, "CheckReelsHomed"))
		reel.connect("_reel_started", Callable(self, "CheckReelsStarted"))
		reel.connect("_reel_stopped", Callable(self, "CheckReelsStopped"))

func _process(_delta):
	pass

func SpinReels():
	$Reel1.change_state($Reel1.current_state, "ReelSpinStartState")
	await get_tree().create_timer(0.2).timeout
	$Reel2.change_state($Reel2.current_state, "ReelSpinStartState")
	await get_tree().create_timer(0.2).timeout
	$Reel3.change_state($Reel3.current_state, "ReelSpinStartState")
	await get_tree().create_timer(0.2).timeout


var num_reels_homed : int
func CheckReelsHomed():
	num_reels_homed = num_reels_homed + 1
	if num_reels_homed == reels.size():
		num_reels_homed = 0
		emit_signal("_reels_homed")


var num_reels_started : int
func CheckReelsStarted():
	num_reels_started = num_reels_started + 1
	if num_reels_started == reels.size():
		num_reels_started = 0
		emit_signal("_reels_started")


var num_reels_stopped : int
func CheckReelsStopped():
	$"../SlotGame/Camera2D".add_trauma(5)
	num_reels_stopped = num_reels_stopped + 1
	if num_reels_stopped == reels.size():
		num_reels_stopped = 0
		emit_signal("_reels_stopped")

# stops holds one strip index per reel, in reel order, as decided by the backend.
func StopReels(stops : Array):
	assert(stops.size() == reels.size(),
		"StopReels needs %d stop indices, got %d" % [reels.size(), stops.size()])

	$Reel1.SetReelTarget(stops[0])
	$Reel1.change_state($Reel1.current_state, "ReelSpinSeekState")
	await get_tree().create_timer(0.2).timeout
	$Reel2.SetReelTarget(stops[1])
	$Reel2.change_state($Reel2.current_state, "ReelSpinSeekState")
	await get_tree().create_timer(0.4).timeout
	$Reel3.SetReelTarget(stops[2])
	$Reel3.change_state($Reel3.current_state, "ReelSpinSeekState")
	await $Reel3._reel_stopped

# What each reel is actually showing on the payline right now, for verification.
func LandedStops() -> Array:
	var landed : Array = []
	for reel in reels:
		landed.append(reel.GetReelStop())
	return landed
