# One winnable pattern and what it pays.
#
# Patterns are matched against a 25-bit daub mask (bit n = cell n is daubed).
# ANY_LINE exists so the twelve straight lines are one table row instead of twelve.
class_name PatternPrize
extends Resource

enum Kind {
	CELLS,    ## Every cell in `cells` must be daubed.
	ANY_LINE, ## Any one of the five rows, five columns or two diagonals.
}

## The five rows, five columns, then both diagonals.
const LINES = [
	[0, 1, 2, 3, 4], [5, 6, 7, 8, 9], [10, 11, 12, 13, 14], [15, 16, 17, 18, 19], [20, 21, 22, 23, 24],
	[0, 5, 10, 15, 20], [1, 6, 11, 16, 21], [2, 7, 12, 17, 22], [3, 8, 13, 18, 23], [4, 9, 14, 19, 24],
	[0, 6, 12, 18, 24], [4, 8, 12, 16, 20],
]

static var _line_masks : Array = []

@export var pattern_id : String = ""
@export var kind : Kind = Kind.CELLS

## CELLS only: the cell indices that must all be daubed.
@export var cells : PackedInt32Array = PackedInt32Array()

## Multiplier applied to the bet when this pattern is the best one achieved.
@export var payout_factor : int = 0

var _cells_mask : int = -1


static func LineMasks() -> Array:
	if _line_masks.is_empty():
		for line in LINES:
			var mask := 0
			for cell in line:
				mask |= 1 << cell
			_line_masks.append(mask)
	return _line_masks


func CellsMask() -> int:
	if _cells_mask == -1:
		_cells_mask = 0
		for cell in cells:
			_cells_mask |= 1 << cell
	return _cells_mask


func Matches(daub_mask : int) -> bool:
	match kind:
		Kind.CELLS:
			var wanted := CellsMask()
			return wanted != 0 and (daub_mask & wanted) == wanted
		Kind.ANY_LINE:
			for line_mask in LineMasks():
				if (daub_mask & line_mask) == line_mask:
					return true
	return false


func Describe() -> String:
	return "%s pays %dx" % [pattern_id, payout_factor]
