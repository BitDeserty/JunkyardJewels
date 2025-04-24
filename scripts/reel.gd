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

var timer : Timer

var shader_material : ShaderMaterial

signal _finished

func set_shader_strength(value: float):
	shader_material.set_shader_parameter("strength", value)

func set_reel_speed(value: float):
	target_speed = value
	set_shader_strength( value / 1000 )

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
	target_speed = 1000

func HomeReel(_target : int):
	continuous_spin = false
	temp_curve = home_curve
	
	timer.start(temp_curve.max_domain)
	current_speed = 0.0
	target_speed = 500
		
func StopReel(_target : int):
	continuous_spin = false
	temp_curve = stop_curve
	
	timer.start(temp_curve.max_domain)
	current_speed = current_speed
	target_speed = 1000
	
func UpdateReel(delta):
	#if (curving_to_target):
	if timer.time_left > 0.0:
		# Use the curve to determine the speed based on normalized time (0 to 1)
		var ramp_duration = temp_curve.max_domain
		var curve_value = temp_curve.sample( ramp_duration - timer.time_left)
		
		# Calculate the current speed based on the curve value
		current_speed = curve_value * target_speed  # Apply the max speed based on curve value
	else:
		if continuous_spin:
			current_speed = target_speed
		else:
			current_speed = 0
			target_speed = 0

	# Increase the offset to create the spinning effect
	yoffset += current_speed * delta
			
	# Apply the vertical offset to the texture
	offset = Vector2(0, yoffset)
	
	# Optionally, wrap the texture vertically to create a seamless loop
	if yoffset > texture.get_height() - 64:
		yoffset = 0.0  # Reset offset once it exceeds the texture height
	#else:
		#target_speed = 0
	set_shader_strength(current_speed / 1000)


func CalculateStopPosition(pos : int) -> int:
	var retval = (pos * SYMBOL_SIZE)
	return retval

func _on_timeout():
	if !continuous_spin:
		print("Reel stopped")
		emit_signal("_finished")
