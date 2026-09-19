# The boundary between deciding an outcome and the thing that decides it.
#
# The slot client talks to the ball call server exclusively through this interface,
# so the server being in-process (LocalTransport), in another browser tab
# (BroadcastTransport) or across a network (a future WebSocketTransport) is not a
# distinction the game can see.
class_name BallCallTransport
extends RefCounted

signal message_received(message : Dictionary)
signal connection_changed(peer_connected : bool)


func Start() -> void:
	push_error("BallCallTransport.Start must be overridden")


func Send(_message : Dictionary) -> void:
	push_error("BallCallTransport.Send must be overridden")


func IsPeerConnected() -> bool:
	return false


func Describe() -> String:
	return "unknown transport"
