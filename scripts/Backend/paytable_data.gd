# The ordered list of winning combinations for the reel presentation.
#
# This is the SYMBOL paytable -- what a given line of symbols is worth. It is not
# the prize distribution; how often each prize is awarded is the outcome source's
# business (a stub RNG today, the bingo card evaluator later).
class_name PaytableData
extends Resource

## Tested top to bottom, first match wins. Deliberately an untyped Array: a typed
## Array[PayRule] has to be spelled a particular way inside the .tres and this one
## was hand-authored. Re-saving the resource from the editor is safe either way.
@export var rules : Array = []


func FactorFor(line : PackedInt32Array) -> int:
	for rule in rules:
		if rule != null and rule.Matches(line):
			return rule.factor
	return 0


# Every factor this table is capable of awarding. The backend checks the outcome
# source can't emit anything outside this set.
func PayableFactors() -> Array[int]:
	var factors : Array[int] = [0]
	for rule in rules:
		if rule != null and not factors.has(rule.factor):
			factors.append(rule.factor)
	factors.sort()
	return factors


func IsValid() -> bool:
	if rules.is_empty():
		return false
	for rule in rules:
		if not (rule is PayRule):
			push_error("Paytable contains a %s where a PayRule was expected." % type_string(typeof(rule)))
			return false
	return true
