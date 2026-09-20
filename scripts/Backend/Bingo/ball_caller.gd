# Draws the ball sequence for one game.
#
# The call is drawn without replacement from 1..75 and then truncated to a budget.
# That budget is the single biggest lever on the prize distribution: call more balls
# and every pattern gets likelier, so it is what a real system tunes to hit a target
# RTP. 39 balls against the shipped prize table measures ~91% over 260k simulated
# games -- moving it two balls either way swings RTP by roughly 8 points. The
# self-test's 20k-game sample carries about +/-0.8 points, so don't read one run's
# figure to a decimal place. Run it after changing this.
class_name BallCaller
extends RefCounted

const BALL_COUNT : int = 75
const DEFAULT_BUDGET : int = 39


func CallSequence(budget : int = DEFAULT_BUDGET) -> PackedInt32Array:
	var balls : Array[int] = []
	for n in BALL_COUNT:
		balls.append(n + 1)
	balls.shuffle()

	var drawn := PackedInt32Array()
	var count : int = clampi(budget, 1, BALL_COUNT)
	for i in count:
		drawn.append(balls[i])
	return drawn
