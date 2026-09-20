extends State
class_name ReelSpinStopState

@onready var strip = $"../ReelStrip"
@export var stop_curve : Curve

var timer : Timer

signal _reel_stopped

# How finely the stop curve is integrated. The curve dips negative near the end (the
# reel overshoots and springs back), so this has to be a real integral rather than an
# average speed.
const INTEGRATION_STEPS : int = 256

var _cumulative : PackedFloat32Array
var _integral_total : float = 0.0
var _travel_distance : float = -1.0

var _start_offset : float = 0.0
var _remaining : float = 0.0


# How far the reel coasts while the stop ramp plays out, in pixels. The seek state
# uses this to decide when to hand over. Derived from the curve rather than hardcoded,
# so retuning stop_curve.tres keeps the handoff correct instead of silently drifting.
func GetTravelDistance() -> float:
	_EnsureIntegral()
	return _travel_distance


func Enter():
	print("Entering Reel Spin Stop State for %s" % get_parent().name)
	_EnsureIntegral()

	if timer == null:
		timer = Timer.new()
		timer.one_shot = true
		add_child(timer)
		timer.connect("timeout", Callable(self, "_on_timeout"))

	# Scale the ramp to exactly the distance left, so the reel lands dead on target
	# without a correcting jump at the end. The ramp duration is fixed, so the only
	# thing that varies spin to spin is a few percent of speed -- imperceptible.
	_start_offset = strip.yoffset
	_remaining = strip.DistanceToTarget(float(get_parent().GetReelTarget()))

	timer.start(stop_curve.max_domain)

	strip.target_speed = 0


func Update(_delta:float):
	if timer.time_left > 0.0:
		var elapsed : float = stop_curve.max_domain - timer.time_left
		var travelled : float = _SampleIntegral(elapsed) / _integral_total
		strip.SetOffset(_start_offset + _remaining * travelled)

		# Speed is now only driving the motion blur.
		strip.current_speed = stop_curve.sample(elapsed) * strip.FULL_SPEED
		strip.set_shader_strength(strip.current_speed / strip.FULL_SPEED)
	else:
		strip.current_speed = 0.0
		strip.set_shader_strength(0.0)


func Exit():
	# Land exactly on the commanded stop. The symbol under the payline now provably
	# matches the outcome the backend priced.
	strip.SetOffset(float(get_parent().GetReelTarget()))
	strip.current_speed = 0.0
	strip.set_shader_strength(0.0)
	emit_signal("_reel_stopped")


func _on_timeout():
	state_transition.emit(self, "ReelIdleState")


func _EnsureIntegral() -> void:
	if _travel_distance >= 0.0:
		return

	# Cumulative integral of the speed curve, sampled at midpoints.
	_cumulative = PackedFloat32Array()
	_cumulative.resize(INTEGRATION_STEPS + 1)
	_cumulative[0] = 0.0

	var step : float = stop_curve.max_domain / INTEGRATION_STEPS
	var running : float = 0.0
	for i in INTEGRATION_STEPS:
		running += stop_curve.sample(step * (i + 0.5)) * step
		_cumulative[i + 1] = running

	_integral_total = running
	_travel_distance = absf(running) * strip.FULL_SPEED

	assert(not is_zero_approx(_integral_total),
		"stop_curve integrates to zero -- the reel would never cover any distance.")


func _SampleIntegral(elapsed : float) -> float:
	var position : float = clampf(elapsed / stop_curve.max_domain, 0.0, 1.0) * INTEGRATION_STEPS
	var low : int = int(floor(position))
	if low >= INTEGRATION_STEPS:
		return _cumulative[INTEGRATION_STEPS]
	return lerpf(_cumulative[low], _cumulative[low + 1], position - low)
