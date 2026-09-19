extends Sprite2D

var yoffset : float = 0.0  # This will track the vertical offset of the texture
var current_speed : float
var target_speed : float

const NUMBER_OF_SYMBOLS : int = 24
const SYMBOL_SIZE : int = 32
const STRIP_HEIGHT : int = NUMBER_OF_SYMBOLS * SYMBOL_SIZE
const FULL_SPEED : int = 1000

const STRIP_DATA_PATH : String = "res://resources/reel_strip.tres"

var shader_material : ShaderMaterial

# The same strip layout the backend prices outcomes against, so anything this reel
# reports about what it landed on agrees with what the player was paid.
var strip_data : ReelStripData

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

	strip_data = load(STRIP_DATA_PATH) as ReelStripData
	assert(strip_data != null and strip_data.IsValid(), "Missing or empty %s" % STRIP_DATA_PATH)
	assert(strip_data.StopCount() == NUMBER_OF_SYMBOLS,
		"%s describes %d stops but the art has %d" % [STRIP_DATA_PATH, strip_data.StopCount(), NUMBER_OF_SYMBOLS])

	shader_material = material as ShaderMaterial  # Access the material assigned to the sprite
	if not shader_material:
		shader_material = ShaderMaterial.new()
		shader_material.shader = preload("res://resources//reel.gdshader")
		material = shader_material



func UpdateReel(delta):
	# Increase the offset to create the spinning effect
	SetOffset(yoffset + current_speed * delta)

	set_shader_strength(current_speed / FULL_SPEED)


# The one place yoffset is written. Wrapping over the FULL strip height keeps the
# loop seamless: the displayed row counts down as the offset counts up, so rolling
# 767 -> 0 lands exactly where continuing to scroll would have. (The old wrap at
# STRIP_HEIGHT - SYMBOL_SIZE * 2 skipped a row every lap and put a third of the
# stop positions permanently out of reach.)
func SetOffset(value : float) -> void:
	yoffset = fposmod(value, float(STRIP_HEIGHT))
	offset = Vector2(0, yoffset)


# Forward distance still to travel to reach a stop position, accounting for the wrap.
func DistanceToTarget(target_position : float) -> float:
	return fposmod(target_position - yoffset, float(STRIP_HEIGHT))


func CalculateStopPosition(pos : int) -> int:
	var retval = (pos * SYMBOL_SIZE)
	return retval


# Which stop index the reel is currently sitting on, for logging and verification.
func CurrentStopIndex() -> int:
	return posmod(int(round(yoffset / SYMBOL_SIZE)), NUMBER_OF_SYMBOLS)


func SymbolAtStop(stop_index : int) -> int:
	return strip_data.SymbolAtStop(stop_index)
