extends Sprite2D

var camera : Camera2D

var target_speed: float = 0.0 # Adjust this for faster or slower scrolling
var current_speed : float = 0.0

var yoffset: float = 0.0  # This will track the vertical offset of the texture
#var curving_to_target : bool = false

@export var start_curve : Curve
@export var stop_curve : Curve
@export var home_curve : Curve

var temp_curve : Curve
var continuous_spin : bool

const NUMBER_OF_SYMBOLS : int = 24
const SYMBOL_SIZE : int = 32
const STRIP_HEIGHT : int = NUMBER_OF_SYMBOLS * SYMBOL_SIZE
const FULL_SPEED : int = 1000

var timer : Timer

var shader_material : ShaderMaterial
var target_position : int
var target_symbol : int

signal _finished

func set_shader_strength(value: float):
	shader_material.set_shader_parameter("strength", value)

# Used by external
func set_reel_speed(value: float):
	target_speed = value
	set_shader_strength( value / FULL_SPEED )

func _ready():
	# Check reel art matches code constants
	assert(texture.get_height() == STRIP_HEIGHT)
	
	timer = Timer.new()
	add_child(timer)
	timer.connect("timeout", Callable(self, "_on_timeout"))
	timer.one_shot = true
	
	# Make sure the sprite uses a texture
	texture = preload("res://assets//symbols.png")
	
	shader_material = material as ShaderMaterial  # Access the material assigned to the sprite
	if not shader_material:
		shader_material = ShaderMaterial.new()
		shader_material.shader = preload("res://resources//reel.gdshader")
		material = shader_material

func _process(delta):
	UpdateReel(delta)
	
func SpinReel():
	continuous_spin = true
	temp_curve = start_curve
	
	timer.start(temp_curve.max_domain)
	current_speed = 0.0
	target_speed = FULL_SPEED

func HomeReel(target : int):
	continuous_spin = false
	temp_curve = home_curve
	
	# Calculate the target position to stop at (target * SYMBOL_SIZE)
	target_position = CalculateStopPosition(target)
	target_symbol = target
	
	timer.start(temp_curve.max_domain)
	current_speed = 500
	target_speed = 0
		
func StopReel(target : int):
	continuous_spin = false
	temp_curve = stop_curve
	
	# Calculate the target position to stop at (target * SYMBOL_SIZE)
	target_position = CalculateStopPosition(target)
	target_symbol = target
	
	timer.start(temp_curve.max_domain)
	current_speed = current_speed
	target_speed = 0
	yoffset = 0
	
func UpdateReel(delta):
	#if (curving_to_target):
	if timer.time_left > 0.0:
		# Use the curve to determine the speed based on normalized time (0 to 1)
		var ramp_duration = temp_curve.max_domain
		var time_left = timer.time_left
		var curve_value = temp_curve.sample( ramp_duration - time_left)
		
		# Calculate the current speed based on the curve value
		current_speed = int(curve_value * FULL_SPEED)  # Apply the max speed based on curve value
	else:
		current_speed = int(target_speed)

	# Increase the offset to create the spinning effect
	yoffset += current_speed * delta
	
	# If going past the end, wrap the texture vertically to create a seamless loop
	if yoffset > texture.get_height() - (SYMBOL_SIZE * 2):
		yoffset = 0.0
	elif yoffset < 0.0:
		yoffset = texture.get_height() - (SYMBOL_SIZE * 2)

	# Apply the vertical offset to the texture
	offset = Vector2(0, yoffset)
	
	set_shader_strength(current_speed / FULL_SPEED)


func CalculateStopPosition(pos : int) -> int:
	var retval = (pos * SYMBOL_SIZE)
	return retval

func _on_timeout():
	if !continuous_spin:
		# Check if we have reached the target position
		if yoffset < target_position:
			print("oops, missed the target, end position %d, target is %d" % [yoffset, target_position]  )
			#var tween = get_tree().create_tween()
			#tween.tween_property(self, "offset", Vector2(0,yoffset), target_position)
			print("After skooch %d" % offset.y)
			
		if target_position:
			if yoffset >= target_position:
				yoffset = target_position  # Ensure we stop exactly at the target position
			print("Reel stopped at position %d, target is %d" % [yoffset, target_position]  )
			
		else:
			print("Reel stopped wherever")
		
		emit_signal("_finished")
	else:
		print("Reel spun up!")
		emit_signal("_finished")
