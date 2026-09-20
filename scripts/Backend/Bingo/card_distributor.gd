# Deals cards. One per play today; a real system deals a card per player per game,
# which is what the phantom-player option would exercise.
class_name CardDistributor
extends RefCounted


func Deal() -> BingoCard:
	var numbers := PackedInt32Array()
	numbers.resize(BingoCard.CELLS)

	for column in BingoCard.COLUMNS:
		var pool : Array[int] = []
		var first := column * BingoCard.NUMBERS_PER_COLUMN + 1
		for n in BingoCard.NUMBERS_PER_COLUMN:
			pool.append(first + n)
		pool.shuffle()

		for row in BingoCard.ROWS:
			var index := row * BingoCard.COLUMNS + column
			numbers[index] = 0 if index == BingoCard.FREE_INDEX else pool[row]

	return BingoCard.new(numbers)
