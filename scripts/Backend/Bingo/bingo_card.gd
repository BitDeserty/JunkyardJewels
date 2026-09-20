# A single 75-ball bingo card: 5 columns of 5, free centre.
#
# Cells are stored row-major, so index = row * 5 + column and the B/I/N/G/O
# columns read left to right the way they are displayed. Column c draws from
# [c * 15 + 1, c * 15 + 15], which is the standard US 75-ball layout.
class_name BingoCard
extends RefCounted

const COLUMNS : int = 5
const ROWS : int = 5
const CELLS : int = 25
const NUMBERS_PER_COLUMN : int = 15

## Centre cell, always daubed.
const FREE_INDEX : int = 12

## 25 entries, row-major. FREE_INDEX holds 0.
var numbers : PackedInt32Array

# ball -> cell index. Built once because IndexOf runs for every ball of every game,
# and a linear scan there dominates the self-test.
var _index_by_number : Dictionary = {}


func _init(card_numbers : PackedInt32Array):
	numbers = card_numbers
	for i in CELLS:
		if i != FREE_INDEX:
			_index_by_number[numbers[i]] = i


func NumberAt(index : int) -> int:
	return numbers[index]


func IndexOf(ball : int) -> int:
	return _index_by_number.get(ball, -1)


func HasNumber(ball : int) -> bool:
	return IndexOf(ball) != -1


# Which column a ball belongs to, regardless of whether this card holds it.
static func ColumnForBall(ball : int) -> int:
	return (ball - 1) / NUMBERS_PER_COLUMN


# The mask with only the free centre daubed -- the state every card starts in.
static func StartingMask() -> int:
	return 1 << FREE_INDEX


func _to_string() -> String:
	var rows : Array[String] = []
	for r in ROWS:
		var cells : Array[String] = []
		for c in COLUMNS:
			var i := r * COLUMNS + c
			cells.append("**" if i == FREE_INDEX else str(numbers[i]).pad_zeros(2))
		rows.append(" ".join(cells))
	return "\n".join(rows)
