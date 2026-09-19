# Carries the ball call protocol between two browser windows over a BroadcastChannel.
#
# This is the only class that knows the game and the ball call server are in separate
# runtimes. BingoOutcomeSource and BallCallServer are unchanged by its existence,
# which is what the transport interface was for.
#
# BroadcastChannel is scoped to ORIGIN, so both builds must be served from the same
# origin. The origin of the page embedding them is irrelevant. Note also that Chrome
# partitions channels by top-level site: two iframes on one page share a partition,
# but an embedded client will not reach a console opened in its own tab.
class_name BroadcastTransport
extends BallCallTransport

const CHANNEL_NAME : String = "junkyard-jewels"

var _role : String
var _window : JavaScriptObject
var _peer_seen : bool = false

# Held as a member deliberately. A create_callback result that goes out of scope is
# collected and the channel silently stops delivering, with no error anywhere.
var _deliver : JavaScriptObject


func _init(role : String):
	_role = role


func Start() -> void:
	if not OS.has_feature("web"):
		push_error("BroadcastTransport only works in a web export.")
		return

	_deliver = JavaScriptBridge.create_callback(Callable(self, "_on_js_message"))

	JavaScriptBridge.eval("""
		window.__jjChannel = new BroadcastChannel("%s");
		window.__jjSend = (s) => window.__jjChannel.postMessage(s);
	""" % CHANNEL_NAME, true)

	_window = JavaScriptBridge.get_interface("window")
	_window.__jjDeliver = _deliver

	# The handler is installed from JS so the MessageEvent is unwrapped to a plain
	# string first -- a JS event object cannot cross into GDScript.
	JavaScriptBridge.eval("window.__jjChannel.onmessage = (e) => window.__jjDeliver(e.data);", true)


func Send(message : Dictionary) -> void:
	if _window == null:
		return
	_window.__jjSend(Protocol.Encode(message))


func IsPeerConnected() -> bool:
	return _peer_seen


func Describe() -> String:
	return "broadcast channel, %s" % _role


# create_callback hands the JS arguments over as a single Array.
func _on_js_message(args : Array) -> void:
	if args.is_empty():
		return

	var message := Protocol.Decode(str(args[0]))
	if message.is_empty():
		return

	if not _peer_seen:
		_peer_seen = true
		emit_signal("connection_changed", true)

	emit_signal("message_received", message)
