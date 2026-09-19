# Turns a decided prize into a reel presentation that displays it.
#
# This is the "mapper" a Class II machine needs: the outcome is already decided, and
# the reels only have to show a combination worth the same amount. Rather than trying
# to construct such a combination on demand, the index is built by brute force at
# startup -- every combination is priced by the evaluator and filed under its factor.
# Mapping is then a random pick from a bucket, so Evaluate(MapToStops(f)) == f holds
# by construction instead of by careful coding.
#
# 24^3 = 13,824 combinations for a three reel game, so the build is instant.
class_name OutcomeMapper
extends RefCounted

var _buckets : Dictionary = {}
var _stop_count : int = 0
var _total : int = 0


func BuildIndex(strip : ReelStripData, evaluator : CombinationEvaluator) -> void:
	_buckets.clear()
	_stop_count = strip.StopCount()
	_total = 0

	var scratch : Dictionary = {}
	for stop1 in _stop_count:
		for stop2 in _stop_count:
			for stop3 in _stop_count:
				var factor := evaluator.Evaluate(stop1, stop2, stop3)
				if not scratch.has(factor):
					scratch[factor] = []
				scratch[factor].append(_Encode(stop1, stop2, stop3))
				_total += 1

	# Freeze the buckets: nothing mutates them after this point.
	for factor in scratch:
		_buckets[factor] = PackedInt32Array(scratch[factor])


func MapToStops(payout_factor : int) -> Array[int]:
	var bucket : PackedInt32Array = _buckets.get(payout_factor, PackedInt32Array())
	if bucket.is_empty():
		# Should be impossible: the backend asserts coverage at startup.
		push_error("No reel combination pays %dx -- cannot present this prize." % payout_factor)
		var fallback : Array[int] = [0, 0, 0]
		return fallback
	return _Decode(bucket[randi() % bucket.size()])


func HasFactor(payout_factor : int) -> bool:
	return _buckets.has(payout_factor) and not (_buckets[payout_factor] as PackedInt32Array).is_empty()


func BucketSize(payout_factor : int) -> int:
	if not _buckets.has(payout_factor):
		return 0
	return (_buckets[payout_factor] as PackedInt32Array).size()


func Factors() -> Array:
	var factors := _buckets.keys()
	factors.sort()
	return factors


func TotalCombinations() -> int:
	return _total


func _Encode(stop1 : int, stop2 : int, stop3 : int) -> int:
	return (stop1 * _stop_count + stop2) * _stop_count + stop3


func _Decode(code : int) -> Array[int]:
	var stops : Array[int] = [
		(code / (_stop_count * _stop_count)) % _stop_count,
		(code / _stop_count) % _stop_count,
		code % _stop_count,
	]
	return stops
