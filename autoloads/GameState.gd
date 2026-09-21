extends Node

signal stats_changed
signal turn_advanced(turn: int)
signal game_ended(prosperity: float, sustainability: float, ending_key: String)

var economy: int = 50
var employment: int = 50
var environment: int = 50
var satisfaction: int = 50

var turn: int = 1
var max_turns: int = 8
var action_points: int = 2
var max_action_points: int = 2

var log_entries: Array = []

func apply_decision(decision: Dictionary) -> void:
	economy = clamp(economy + int(decision.get("economy", 0)), 0, 100)
	employment = clamp(employment + int(decision.get("employment", 0)), 0, 100)
	environment = clamp(environment + int(decision.get("environment", 0)), 0, 100)
	satisfaction = clamp(satisfaction + int(decision.get("satisfaction", 0)), 0, 100)
	action_points -= 1
	log_entries.append("Season %d: %s" % [turn, decision.get("title", "")])
	emit_signal("stats_changed")

func can_take_action() -> bool:
	return action_points > 0

func end_season() -> void:
	# Base tourism pressure on the environment each season
	environment = clamp(environment - 3, 0, 100)
	if environment < 30:
		satisfaction = clamp(satisfaction - 5, 0, 100)
	elif environment > 70:
		satisfaction = clamp(satisfaction + 3, 0, 100)
	emit_signal("stats_changed")

	turn += 1
	action_points = max_action_points
	if turn > max_turns:
		_end_game()
	else:
		emit_signal("turn_advanced", turn)

func _end_game() -> void:
	var prosperity: float = (economy + employment) / 2.0
	var sustainability: float = (environment + satisfaction) / 2.0
	var ending_key: String

	if prosperity >= 50 and sustainability >= 50:
		ending_key = "model"
	elif prosperity >= 50 and sustainability < 50:
		ending_key = "overtourism"
	elif prosperity < 50 and sustainability >= 50:
		ending_key = "protected_poor"
	else:
		ending_key = "failed"

	emit_signal("game_ended", prosperity, sustainability, ending_key)

func reset() -> void:
	economy = 50
	employment = 50
	environment = 50
	satisfaction = 50
	turn = 1
	action_points = max_action_points
	log_entries.clear()
	emit_signal("stats_changed")
