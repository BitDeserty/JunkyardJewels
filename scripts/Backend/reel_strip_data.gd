# The physical layout of a reel strip, plus the one piece of calibration that ties
# a commanded stop index to the symbol the player actually sees on the payline.
#
# All three reels currently share a single strip (assets/symbols.png). Giving a reel
# its own strip later means authoring a second .tres and handing it to that reel.
class_name ReelStripData
extends Resource

## One entry per stop position, top to bottom, using the Sym enum values.
@export var symbols : PackedInt32Array = PackedInt32Array()

## Which strip row sits on the payline when the reel is stopped at index 0.
## Increasing yoffset slides the strip downwards, so the row on the payline counts
## DOWN as the stop index counts up -- hence the subtraction in SymbolAtStop.
## This number is calibrated by eye once; see SymbolAtStop.
@export var payline_offset : int = 23

## Clear this if calibration shows the strip reads forwards rather than backwards.
@export var payline_reversed : bool = true


func StopCount() -> int:
	return symbols.size()


# The single source of truth for "stop index -> symbol on the payline". The backend
# evaluator and the mapper both go through here, so the math is self-consistent no
# matter how this is calibrated; miscalibration only makes the screen disagree with
# the math, which is exactly what the one-time visual check catches.
func SymbolAtStop(stop_index : int) -> int:
	var count := symbols.size()
	if count == 0:
		return Sym.BLANK
	if payline_reversed:
		return symbols[posmod(payline_offset - stop_index, count)]
	return symbols[posmod(payline_offset + stop_index, count)]


func IsValid() -> bool:
	return not symbols.is_empty()
