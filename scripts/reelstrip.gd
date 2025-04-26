extends Sprite2D

var yoffset : float = 0.0  # This will track the vertical offset of the texture
var current_speed : float
var target_speed : float

const NUMBER_OF_SYMBOLS : int = 24
const SYMBOL_SIZE : int = 32
const STRIP_HEIGHT : int = NUMBER_OF_SYMBOLS * SYMBOL_SIZE
const FULL_SPEED : int = 1000

var shader_material : ShaderMaterial

#signal _finished

# Sets the strength of the blur effect.
#
# @param value (float) - The strength of the effect, a float from 0 t 1
# @return void
func set_shader_strength(value: float) -> void:
	shader_material.set_shader_parameter("strength", value)


func _ready():
	# Make sure the sprite uses a texture
	texture = preload("res://assets//symbols.png")

	# Check reel art matches code constants
	assert(texture.get_height() == STRIP_HEIGHT)
	
	shader_material = material as ShaderMaterial  # Access the material assigned to the sprite
	if not shader_material:
		shader_material = ShaderMaterial.new()
		shader_material.shader = preload("res://resources//reel.gdshader")
		material = shader_material
		


func UpdateReel(delta):
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
