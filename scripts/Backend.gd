extends Node
class_name Backend

signal _playresponse(PlayResult)

const REEL_STRIP_PATH : String = "res://resources/reel_strip.tres"
const PAYTABLE_PATH : String = "res://resources/paytable.tres"

# Who decides the prize. Swapping this one line for BingoOutcomeSource is the whole
# of Milestone 3 as far as the rest of the game is concerned.
var outcome_source : OutcomeSource

# Who turns a decided prize into something the reels can show.
var strip_data : ReelStripData
var paytable : PaytableData
var evaluator : CombinationEvaluator
var mapper : OutcomeMapper


func _ready():
	# Randomize the RNG
	randomize()

	_LoadPresentationData()

	outcome_source = StubRngOutcomeSource.new()

	mapper = OutcomeMapper.new()
	mapper.BuildIndex(strip_data, evaluator)
	_AssertPrizeCoverage()

	# Connect the game platform to the backend
	$"../GameManager/PlayingState".connect("_playrequest", on_PlayRequest)

	if "--selftest" in OS.get_cmdline_user_args():
		RunSelfTest()


func on_PlayRequest(playdata : PlayResult):
	# Ask the outcome source what was won. Nothing below this line knows or cares
	# whether that came from an RNG or a bingo card.
	var outcome := outcome_source.DrawOutcome(playdata.bet_amount)

	playdata.prize_id = outcome.prize_id
	playdata.payout_factor = outcome.payout_factor

	# Calculate the winnings
	playdata.payout_amount = playdata.payout_factor * playdata.bet_amount

	# Map the prize onto a reel combination worth exactly that much.
	playdata.reel_stops = mapper.MapToStops(playdata.payout_factor)

	print("Sending a PlayResponse <- prize %d, %dx = %d credits, reels %s" % [
		playdata.prize_id,
		playdata.payout_factor,
		playdata.payout_amount,
		evaluator.DescribeStops(playdata.reel_stops),
	])
	SendPlayResponse(playdata)


func SendPlayResponse(playdata : PlayResult):
	emit_signal("_playresponse", playdata)


func _LoadPresentationData() -> void:
	strip_data = load(REEL_STRIP_PATH) as ReelStripData
	assert(strip_data != null and strip_data.IsValid(),
		"Could not load a valid reel strip from %s" % REEL_STRIP_PATH)

	paytable = load(PAYTABLE_PATH) as PaytableData
	assert(paytable != null and paytable.IsValid(),
		"Could not load a valid paytable from %s" % PAYTABLE_PATH)

	evaluator = CombinationEvaluator.new(strip_data, paytable)


# The reels have to be able to SHOW every prize the source can award. If they can't,
# fail here at startup rather than hanging a reel on a target that doesn't exist.
func _AssertPrizeCoverage() -> void:
	var missing : Array[int] = []
	for factor in outcome_source.PossibleFactors():
		if not mapper.HasFactor(factor):
			missing.append(factor)

	assert(missing.is_empty(),
		"No reel combination pays %s. Add a rule to %s, or stop the outcome source awarding it."
			% [str(missing), PAYTABLE_PATH])


# Run with: godot --headless --path <project> -- --selftest
func RunSelfTest() -> void:
	print("\n=== Backend self-test ===")
	print("Strip: %d stops, payline_offset %d, reversed %s"
		% [strip_data.StopCount(), strip_data.payline_offset, strip_data.payline_reversed])

	for rule in paytable.rules:
		print("  rule: %s" % rule.Describe())

	print("Enumerated %d combinations." % mapper.TotalCombinations())

	var expected := strip_data.StopCount() ** 3
	assert(mapper.TotalCombinations() == expected,
		"Expected %d combinations, indexed %d" % [expected, mapper.TotalCombinations()])

	for factor in mapper.Factors():
		var size := mapper.BucketSize(factor)
		print("  pays %3dx : %5d combinations (%.4f%% of the strip)"
			% [factor, size, 100.0 * size / mapper.TotalCombinations()])

	var source_factors := outcome_source.PossibleFactors()
	print("Outcome source can award: %s" % str(source_factors))

	# The invariant the whole mapper exists to guarantee.
	var checked := 0
	for factor in source_factors:
		for _i in 2000:
			var stops := mapper.MapToStops(factor)
			var priced := evaluator.EvaluateStops(stops)
			assert(priced == factor,
				"Mapper returned %s for %dx but it prices at %dx" % [str(stops), factor, priced])
			checked += 1
	print("Verified %d mapped presentations price back to their prize." % checked)

	print("=== Backend self-test passed ===\n")
	get_tree().quit()
