extends Node
class_name ReelSet

signal _reels_homed
signal _reels_started
signal _reels_stopped

func _ready():
	pass
	
func _process(_delta):
	pass
	
func SpinReels():
	$Reel1.get_node("Sprite2D").SpinReel()
	await get_tree().create_timer(0.2).timeout
	$Reel2.get_node("Sprite2D").SpinReel()
	await get_tree().create_timer(0.2).timeout
	$Reel3.get_node("Sprite2D").SpinReel()
	await $Reel3.get_node("Sprite2D")._finished
	emit_signal("_reels_started")

func HomeReels(reel1 : int, reel2 : int, reel3 : int):
	print("Homing Reels")
	$Reel1.get_node("Sprite2D").HomeReel(reel1)
	$Reel2.get_node("Sprite2D").HomeReel(reel2)
	$Reel3.get_node("Sprite2D").HomeReel(reel3)
	await $Reel3.get_node("Sprite2D")._finished
	emit_signal("_reels_homed")
	
func StopReels(reel1 : int, reel2 : int, reel3 : int):
	$Reel1.get_node("Sprite2D").connect("_finished", Callable(self, "_on_reel_stop"))
	$Reel2.get_node("Sprite2D").connect("_finished", Callable(self, "_on_reel_stop"))
	$Reel3.get_node("Sprite2D").connect("_finished", Callable(self, "_on_reel_stop"))
	
	$Reel1.get_node("Sprite2D").StopReel(reel1)
	await get_tree().create_timer(1).timeout
	
	$Reel2.get_node("Sprite2D").StopReel(reel2)
	await get_tree().create_timer(1).timeout
	
	$Reel3.get_node("Sprite2D").StopReel(reel3)
	await $Reel3.get_node("Sprite2D")._finished
	emit_signal("_reels_stopped")
	
	$Reel1.get_node("Sprite2D").disconnect("_finished", Callable(self, "_on_reel_stop"))
	$Reel2.get_node("Sprite2D").disconnect("_finished", Callable(self, "_on_reel_stop"))
	$Reel3.get_node("Sprite2D").disconnect("_finished", Callable(self, "_on_reel_stop"))

func _on_reel_stop():
	$"../SlotGame/Camera2D".add_trauma(5)
