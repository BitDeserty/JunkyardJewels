# Entry point for both builds.
#
# Godot export presets cannot override run/main_scene, so which app a build becomes
# is decided by a custom feature tag set on the preset instead. The console preset
# declares "ballcall_console"; everything else boots the cabinet.
extends Node

const CLIENT_SCENE : String = "res://main.tscn"
const CONSOLE_SCENE : String = "res://ballcall_console.tscn"


func _ready():
	var scene := CONSOLE_SCENE if OS.has_feature("ballcall_console") else CLIENT_SCENE

	# Deferred: swapping the scene from inside _ready runs while the tree is still
	# busy adding this node, which Godot refuses.
	get_tree().change_scene_to_file.call_deferred(scene)
