# One row of the paytable. Rules are tested in order and the first match wins, so
# order the highest-paying rules first in PaytableData.rules.
class_name PayRule
extends Resource

enum Kind {
	LINE,    ## Every reel must match `pattern` position-for-position (Sym.ANY wildcards).
	COUNT,   ## `symbol` must appear on at least `min_count` reels, anywhere.
	SET_ALL, ## Every reel shows some symbol from `pattern`, in any arrangement.
}

@export var kind : Kind = Kind.LINE

## LINE: one Sym value per reel, positionally, or Sym.ANY (-1) to accept anything.
## SET_ALL: the allowed symbols, unordered -- position carries no meaning here.
@export var pattern : PackedInt32Array = PackedInt32Array()

## COUNT only: which symbol to tally.
@export var symbol : int = Sym.BLANK

## COUNT only: how many reels must show it.
@export var min_count : int = 0

## Multiplier applied to the bet when this rule matches.
@export var factor : int = 0


func Matches(line : PackedInt32Array) -> bool:
	match kind:
		Kind.LINE:
			if pattern.size() != line.size():
				return false
			for i in line.size():
				if pattern[i] != Sym.ANY and pattern[i] != line[i]:
					return false
			return true
		Kind.COUNT:
			var seen := 0
			for s in line:
				if s == symbol:
					seen += 1
			return seen >= min_count
		Kind.SET_ALL:
			# An empty set would otherwise match every possible line.
			if pattern.is_empty():
				return false
			for s in line:
				if not pattern.has(s):
					return false
			return true
	return false


func Describe() -> String:
	if kind == Kind.COUNT:
		return "%d+ %s pays %d" % [min_count, Sym.NameOf(symbol), factor]

	var names : Array[String] = []
	for s in pattern:
		names.append(Sym.NameOf(s))

	if kind == Kind.SET_ALL:
		return "any 3 of %s pays %d" % [", ".join(names), factor]
	return "%s pays %d" % [" / ".join(names), factor]
