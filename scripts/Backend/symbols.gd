# Symbol vocabulary shared by the reel strip, the paytable and the evaluator.
#
# The values are the indices stored in ReelStripData.symbols, so renumbering the
# enum invalidates every reel_strip.tres already authored. Append, don't reorder.
class_name Sym

enum { BLANK, CHERRY, BAR1, BAR2, BAR3, SEVEN, CACTUS }

# Wildcard slot in a PayRule LINE pattern: matches whatever landed there.
const ANY : int = -1

const NAMES = ["BLANK", "CHERRY", "BAR1", "BAR2", "BAR3", "SEVEN", "CACTUS"]

static func NameOf(symbol : int) -> String:
	if symbol == ANY:
		return "ANY"
	if symbol < 0 or symbol >= NAMES.size():
		return "UNKNOWN(%d)" % symbol
	return NAMES[symbol]
