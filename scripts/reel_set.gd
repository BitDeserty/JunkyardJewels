extends Node
class_name ReelSet

@onready var reels_homed : bool = false
signal _reels_homed
signal _reels_started
signal _reels_stopped

func _ready():
	$Reel1.connect("_reel_homed", Callable(self, "CheckReelsHomed"))
	$Reel2.connect("_reel_homed", Callable(self, "CheckReelsHomed"))
	$Reel3.connect("_reel_homed", Callable(self, "CheckReelsHomed"))
	
	$Reel1.connect("_reel_started", Callable(self, "CheckReelsStarted"))
	$Reel2.connect("_reel_started", Callable(self, "CheckReelsStarted"))
	$Reel3.connect("_reel_started", Callable(self, "CheckReelsStarted"))
	
	$Reel1.connect("_reel_stopped", Callable(self, "CheckReelsStopped"))
	$Reel2.connect("_reel_stopped", Callable(self, "CheckReelsStopped"))
	$Reel3.connect("_reel_stopped", Callable(self, "CheckReelsStopped"))
	
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
	if num_reels_homed == get_child_count():
		num_reels_homed = 0
		emit_signal("_reels_homed")
		

var num_reels_started : int
func CheckReelsStarted():
	num_reels_started = num_reels_started + 1
	if num_reels_started == get_child_count():
		num_reels_started = 0
		emit_signal("_reels_started")
		

var num_reels_stopped : int
func CheckReelsStopped():
	$"../SlotGame/Camera2D".add_trauma(5)
	num_reels_stopped = num_reels_stopped + 1
	if num_reels_stopped == get_child_count():
		num_reels_stopped = 0
		emit_signal("_reels_stopped")
	
func StopReels(reel1 : int, reel2 : int, reel3 : int):
	$Reel1.SetReelTarget(reel1)
	$Reel1.change_state($Reel1.current_state, "ReelSpinSeekState")
	await get_tree().create_timer(0.2).timeout
	$Reel2.SetReelTarget(reel2)
	$Reel2.change_state($Reel2.current_state, "ReelSpinSeekState")
	await get_tree().create_timer(0.4).timeout
	$Reel3.SetReelTarget(reel3)
	$Reel3.change_state($Reel3.current_state, "ReelSpinSeekState")
	await $Reel3._reel_stopped
