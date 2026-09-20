# The ball call server, running as its own app with its face showing.
#
# This is the same BallCallServer the game runs in-process; the only difference is
# that here it paces the call so a viewer can watch, and renders the CARD_DEALT /
# BALL_CALLED / PATTERN_HIT messages it was already emitting. The server needed no
# changes to be displayed, which is why those messages were defined up front.
#
# The UI is built in code rather than authored as a scene: it is a fixed 640x360
# layout with no art, and a generated tree is easier to keep correct than a hand
# maintained .tscn.
extends Control

const PRIZE_TABLE_PATH : String = "res://resources/bingo_prizes.tres"

## Seconds per ball. 39 balls at 0.05 puts a call at about two seconds, which sits
## just under the reels' spin-up so the client visibly waits on the result.
const BALL_PACE : float = 0.05

const DEMO_INTERVAL : float = 4.0

const CELL : int = 34
const GRID_X : int = 14
const GRID_Y : int = 60
const LOG_X : int = 214
const COLUMN_LETTERS : String = "BINGO"

const COL_BG := Color(0.055, 0.063, 0.082)
const COL_PANEL := Color(0.105, 0.121, 0.149)
const COL_CELL := Color(0.145, 0.165, 0.200)
const COL_DAUB := Color(0.118, 0.380, 0.310)
const COL_HIT := Color(0.780, 0.580, 0.153)
const COL_TEXT := Color(0.878, 0.898, 0.925)
const COL_DIM := Color(0.494, 0.545, 0.612)

var server : BallCallServer
var transport : BallCallTransport
var prize_table : PatternPrizeTable

var _cells : Array = []
var _cell_text : Array = []
var _card : PackedInt32Array = PackedInt32Array()
var _log : RichTextLabel
var _status : Label
var _ball : Label
var _ball_caption : Label
var _demo_seq : int = 0


func _ready():
	_BuildUi()

	prize_table = load(PRIZE_TABLE_PATH) as PatternPrizeTable
	assert(prize_table != null and prize_table.IsValid(),
		"Could not load a valid bingo prize table from %s" % PRIZE_TABLE_PATH)

	server = BallCallServer.new()
	server.name = "BallCallServer"
	add_child(server)
	server.Configure(prize_table)
	server.ball_call_pace = BALL_PACE
	server.connect("outbound", Callable(self, "_on_server_outbound"))

	if OS.has_feature("web"):
		transport = BroadcastTransport.new(Protocol.ROLE_SERVER)
		transport.connect("message_received", Callable(self, "_on_transport_message"))
		transport.Start()

		# Announced rather than waiting to be asked. Both builds are large and load
		# independently, so whichever comes up second would otherwise never be heard.
		transport.Send(Protocol.Hello("console", Protocol.ROLE_SERVER))
		_SetStatus("listening, no client yet", COL_DIM)
		_Log("ball call server ready, %d balls per game" % prize_table.ball_budget, COL_DIM)
	else:
		# Running the scene straight from the editor: drive it locally so the
		# animation can be checked without a second build.
		_SetStatus("editor preview", COL_DIM)
		_Log("no browser channel, generating demo games", COL_DIM)
		_RunDemoLoop()


#region Message handling
func _on_transport_message(message : Dictionary) -> void:
	var kind : String = message.get("type", "")
	if kind == Protocol.PLAY_REQUEST:
		_SetStatus("client connected", COL_DAUB)
		_Log("<- %s  bet %s" % [kind, message.get("bet_amount", 0)], COL_TEXT)
	elif kind == Protocol.HELLO:
		_SetStatus("client connected", COL_DAUB)
		_Log("<- %s  session %s" % [kind, message.get("session_id", "")], COL_DIM)

	server.HandleMessage(message)


func _on_server_outbound(message : Dictionary) -> void:
	if transport != null:
		transport.Send(message)
	_Render(message)


func _Render(message : Dictionary) -> void:
	match message.get("type", ""):
		Protocol.CARD_DEALT:
			_card = PackedInt32Array(message.get("card", []))
			_ShowCard()
			_Log("   card dealt", COL_DIM)
		Protocol.BALL_CALLED:
			var ball : int = int(message.get("ball", 0))
			var index : int = int(message.get("index", -1))
			_ball.text = str(ball)
			_ball_caption.text = "column %s" % COLUMN_LETTERS[BingoCard.ColumnForBall(ball)]
			if index >= 0:
				_SetCell(index, COL_DAUB)
		Protocol.PATTERN_HIT:
			var pattern_id : String = str(message.get("pattern_id", ""))
			_HighlightPattern(pattern_id, int(message.get("daub_mask", 0)))
			_Log("   %s on ball %d" % [pattern_id, int(message.get("on_ball", 0))], COL_HIT)
		Protocol.PLAY_RESPONSE:
			var factor : int = int(message.get("payout_factor", 0))
			_Log("-> PLAY_RESPONSE  pays %dx" % factor, COL_HIT if factor > 0 else COL_DIM)
#endregion


#region Card display
func _ShowCard() -> void:
	for i in BingoCard.CELLS:
		if i == BingoCard.FREE_INDEX:
			_cell_text[i].text = "FREE"
			_cell_text[i].add_theme_font_size_override("font_size", 9)
			_SetCell(i, COL_DAUB)
		else:
			_SetCell(i, COL_CELL)
			if i < _card.size():
				_cell_text[i].text = str(_card[i])
				_cell_text[i].add_theme_font_size_override("font_size", 13)


func _SetCell(index : int, colour : Color) -> void:
	if index >= 0 and index < _cells.size():
		_cells[index].color = colour


# The winning cells aren't sent -- the console owns the same prize table, so it works
# out which cells to light from the pattern id and the final daub mask.
func _HighlightPattern(pattern_id : String, daub_mask : int) -> void:
	for prize in prize_table.prizes:
		if prize == null or prize.pattern_id != pattern_id:
			continue

		if prize.kind == PatternPrize.Kind.ANY_LINE:
			var masks := PatternPrize.LineMasks()
			for i in masks.size():
				if (daub_mask & masks[i]) == masks[i]:
					for cell in PatternPrize.LINES[i]:
						_SetCell(cell, COL_HIT)
					return
		else:
			for cell in prize.cells:
				_SetCell(cell, COL_HIT)
		return
#endregion


func _SetStatus(text : String, colour : Color) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", colour)


func _Log(line : String, colour : Color) -> void:
	_log.push_color(colour)
	_log.add_text(line + "\n")
	_log.pop()

	# Mirrored to stdout so the protocol is followable from a terminal, which is the
	# only way to watch it in a headless run.
	print("[console] %s" % line.strip_edges())


func _RunDemoLoop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(DEMO_INTERVAL).timeout
		_demo_seq += 1
		_Log("<- PLAY_REQUEST  bet 1", COL_TEXT)
		server.HandleMessage(Protocol.PlayRequest("editor", _demo_seq, 1))


#region UI construction
func _BuildUi() -> void:
	_AddRect(Rect2(0, 0, 640, 360), COL_BG)
	_AddLabel("ball call server", Rect2(14, 10, 300, 20), COL_TEXT, 13)
	_status = _AddLabel("", Rect2(320, 10, 306, 20), COL_DIM, 12)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_AddRect(Rect2(8, 34, 190, 318), COL_PANEL)
	for c in BingoCard.COLUMNS:
		var letter := _AddLabel(COLUMN_LETTERS[c], Rect2(GRID_X + c * CELL, 40, CELL, 16), COL_DIM, 11)
		letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	for i in BingoCard.CELLS:
		var row : int = i / BingoCard.COLUMNS
		var col : int = i % BingoCard.COLUMNS
		var box := Rect2(GRID_X + col * CELL, GRID_Y + row * CELL, CELL - 2, CELL - 2)
		_cells.append(_AddRect(box, COL_CELL))

		var text := _AddLabel("", box, COL_TEXT, 13)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_cell_text.append(text)

	_ball = _AddLabel("-", Rect2(14, 246, 170, 52), COL_TEXT, 40)
	_ball.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ball_caption = _AddLabel("", Rect2(14, 300, 170, 18), COL_DIM, 11)
	_ball_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_AddRect(Rect2(LOG_X - 8, 34, 418, 318), COL_PANEL)
	_log = RichTextLabel.new()
	_log.position = Vector2(LOG_X, 42)
	_log.size = Vector2(402, 302)
	_log.scroll_following = true
	_log.add_theme_font_size_override("normal_font_size", 11)
	add_child(_log)


func _AddRect(box : Rect2, colour : Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = box.position
	rect.size = box.size
	rect.color = colour
	add_child(rect)
	return rect


func _AddLabel(text : String, box : Rect2, colour : Color, font_size : int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = box.position
	label.size = box.size
	label.add_theme_color_override("font_color", colour)
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	return label
#endregion
