extends Node
class_name Backend

signal _playresponse(PlayResult)

const REEL_STRIP_PATH : String = "res://resources/reel_strip.tres"
const PAYTABLE_PATH : String = "res://resources/paytable.tres"
const PRIZE_TABLE_PATH : String = "res://resources/bingo_prizes.tres"

## Clear this to run on the flat RNG stub instead of the bingo ball call server.
@export var use_bingo_engine : bool = true

## How long to wait for a ball call console to answer before giving up and running
## the server in-process. The demo must never be broken by a missing peer.
const CONSOLE_HANDSHAKE_TIMEOUT : float = 1.5

# Who decides the prize.
var outcome_source : OutcomeSource

# The ball call server and the channel the game reaches it through. Swapping
# LocalTransport for BroadcastTransport is what moves the server into its own window.
var prize_table : PatternPrizeTable
var ball_server : BallCallServer
var transport : BallCallTransport

# Who turns a decided prize into something the reels can show.
var strip_data : ReelStripData
var paytable : PaytableData
var evaluator : CombinationEvaluator
var mapper : OutcomeMapper

var _pending : PlayResult
var _peer_connected : bool = false


func _ready():
	# Randomize the RNG
	randomize()

	_LoadPresentationData()
	_CreateOutcomeSource()

	mapper = OutcomeMapper.new()
	mapper.BuildIndex(strip_data, evaluator)
	_AssertPrizeCoverage()

	# Connect the game platform to the backend
	$"../GameManager/PlayingState".connect("_playrequest", on_PlayRequest)
	outcome_source.connect("outcome_ready", Callable(self, "_on_outcome_ready"))
	outcome_source.Start()
	print("Ball call: %s" % outcome_source.Describe())

	if transport is BroadcastTransport:
		_WatchForConsole()

	if "--selftest" in OS.get_cmdline_user_args():
		RunSelfTest()


# A play is now a round trip: park the request and finish when the outcome lands.
func on_PlayRequest(playdata : PlayResult):
	if _pending != null:
		push_error("A play request arrived while spin data was still pending.")
		return

	_pending = playdata
	print("Requesting an outcome from %s" % outcome_source.Describe())
	outcome_source.RequestOutcome(playdata.bet_amount)


func _on_outcome_ready(outcome : Outcome):
	var playdata := _pending
	_pending = null
	if playdata == null:
		push_warning("Received an outcome with no play request waiting on it.")
		return

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


func _CreateOutcomeSource() -> void:
	if not use_bingo_engine:
		outcome_source = StubRngOutcomeSource.new()
		return

	prize_table = load(PRIZE_TABLE_PATH) as PatternPrizeTable
	assert(prize_table != null and prize_table.IsValid(),
		"Could not load a valid bingo prize table from %s" % PRIZE_TABLE_PATH)

	ball_server = BallCallServer.new()
	ball_server.name = "BallCallServer"
	add_child(ball_server)
	ball_server.Configure(prize_table)

	# On the web the server normally lives in its own window alongside this one. The
	# in-process server above stays built either way, as the fallback.
	if OS.has_feature("web"):
		transport = BroadcastTransport.new(Protocol.ROLE_CLIENT)
		transport.connect("connection_changed", Callable(self, "_on_peer_connection_changed"))
	else:
		transport = LocalTransport.new(ball_server)

	outcome_source = BingoOutcomeSource.new(transport, prize_table)


func _on_peer_connection_changed(peer_connected : bool) -> void:
	_peer_connected = peer_connected


# If nothing answers on the channel, fall back to the in-process server so the game
# still plays when it is embedded on its own.
func _WatchForConsole() -> void:
	await get_tree().create_timer(CONSOLE_HANDSHAKE_TIMEOUT).timeout
	if _peer_connected:
		return

	push_warning("No ball call console answered in %.1fs; running the server in-process."
		% CONSOLE_HANDSHAKE_TIMEOUT)

	outcome_source.disconnect("outcome_ready", Callable(self, "_on_outcome_ready"))
	transport = LocalTransport.new(ball_server)
	outcome_source = BingoOutcomeSource.new(transport, prize_table)
	outcome_source.connect("outcome_ready", Callable(self, "_on_outcome_ready"))
	outcome_source.Start()
	print("Ball call fell back to: %s" % outcome_source.Describe())


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
	print("Outcome source: %s" % outcome_source.Describe())
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

	if prize_table != null:
		_SelfTestBingo()

	print("=== Backend self-test passed ===\n")
	get_tree().quit()


# Simulates the bingo game directly rather than through the transport, so the prize
# distribution and the resulting RTP are visible without waiting on message traffic.
func _SelfTestBingo() -> void:
	print("\n--- Bingo ball call ---")
	print("Ball budget: %d of %d" % [prize_table.ball_budget, BallCaller.BALL_COUNT])
	for prize in prize_table.prizes:
		print("  pattern: %s" % prize.Describe())

	var games := 20000
	var distributor := CardDistributor.new()
	var caller := BallCaller.new()
	var card_evaluator := CardEvaluator.new(prize_table)

	var counts : Dictionary = {}
	var total_factor := 0

	for _i in games:
		var card := distributor.Deal()
		var called := caller.CallSequence(prize_table.ball_budget)
		var result := card_evaluator.Evaluate(card, called)

		var key : String = result.pattern_id if result.IsWin() else "(no pattern)"
		counts[key] = counts.get(key, 0) + 1
		total_factor += result.payout_factor

	for key in counts:
		print("  %-16s %6.2f%% of games" % [key, 100.0 * counts[key] / games])
	print("Simulated RTP over %d games: %.1f%%" % [games, 100.0 * total_factor / games])

	# Same coverage invariant as the reels, checked against the prize table directly.
	for factor in prize_table.PayableFactors():
		assert(mapper.HasFactor(factor),
			"Bingo can award %dx but no reel combination displays it." % factor)
