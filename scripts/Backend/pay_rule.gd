# One row of the paytable. Rules are tested in order and the first match wins, so
# order the highest-paying rules first in PaytableData.rules.
class_name PayRule
extends Resource

enum Kind {
	LINE,  ## Every reel must match `pattern` position-for-position (Sym.ANY wildcards).
	COUNT, ## `symbol` must appear on at least `min_count` reels, anywhere.
}

@export var kind : Kind = Kind.LINE

## LINE only: one Sym value per reel, or Sym.ANY (-1) to accept anything.
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
	return false


func Describe() -> String:
	if kind == Kind.COUNT:
		return "%d+ %s pays %d" % [min_count, Sym.NameOf(symbol), factor]
	var names : Array[String] = []
	for s in pattern:
		names.append(Sym.NameOf(s))
	return "%s pays %d" % [" / ".join(names), factor]
