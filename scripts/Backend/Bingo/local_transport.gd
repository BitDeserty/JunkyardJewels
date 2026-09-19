# Runs the ball call server in this same process.
#
# Used in the editor, in headless self-tests, and as the fallback when the game is
# embedded without a console alongside it. Messages still go through the real
# protocol rather than short-circuiting to a function call, so the local path
# exercises exactly what the cross-window path will.
class_name LocalTransport
extends BallCallTransport

var _server : BallCallServer


func _init(server : BallCallServer):
	_server = server
	_server.connect("outbound", Callable(self, "_on_server_outbound"))


func Start() -> void:
	call_deferred("emit_signal", "connection_changed", true)


# Deferred so the local path resolves on a later frame like every other transport.
# Delivered inline, a whole bingo game would run inside the caller's stack frame and
# the play response would land before the request call had even returned.
func Send(message : Dictionary) -> void:
	_server.call_deferred("HandleMessage", message)


func IsPeerConnected() -> bool:
	return _server != null


func Describe() -> String:
	return "in-process"


func _on_server_outbound(message : Dictionary) -> void:
	emit_signal("message_received", message)
