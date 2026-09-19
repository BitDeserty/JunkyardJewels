# Reads a set of reel stop indices off the strip and prices the resulting line.
#
# This is the authority on what a presentation is worth. OutcomeMapper is built by
# running every possible combination through here, which is what guarantees that a
# mapped presentation always evaluates back to the prize it was mapped from.
class_name CombinationEvaluator
extends RefCounted

var _strip : ReelStripData
var _paytable : PaytableData


func _init(strip : ReelStripData, paytable : PaytableData):
	_strip = strip
	_paytable = paytable


# Hot path: called 24^3 times while the mapper builds its index, so it avoids
# allocating anything per call beyond the single line buffer.
func Evaluate(stop1 : int, stop2 : int, stop3 : int) -> int:
	var line := PackedInt32Array([
		_strip.SymbolAtStop(stop1),
		_strip.SymbolAtStop(stop2),
		_strip.SymbolAtStop(stop3),
	])
	return _paytable.FactorFor(line)


func EvaluateStops(stops : Array) -> int:
	assert(stops.size() == 3, "Expected 3 reel stops, got %d" % stops.size())
	return Evaluate(stops[0], stops[1], stops[2])


func LineSymbols(stops : Array) -> PackedInt32Array:
	var line := PackedInt32Array()
	for stop in stops:
		line.append(_strip.SymbolAtStop(stop))
	return line


func DescribeStops(stops : Array) -> String:
	var names : Array[String] = []
	for symbol in LineSymbols(stops):
		names.append(Sym.NameOf(symbol))
	return "%s -> %s" % [str(stops), " / ".join(names)]
