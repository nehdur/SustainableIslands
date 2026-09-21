extends Control

var stat_bars := {}
var turn_label: Label
var action_label: Label
var end_season_button: Button

var decision_popup: PopupPanel
var decision_vbox: VBoxContainer
var decision_title: Label

var summary_popup: PopupPanel
var summary_label: Label

var end_popup: PopupPanel
var end_title: Label
var end_desc: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	GameState.stats_changed.connect(_on_stats_changed)
	GameState.turn_advanced.connect(_on_turn_advanced)
	GameState.game_ended.connect(_on_game_ended)
	_refresh_all()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.15, 0.2)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 16)
	main_vbox.offset_left = 24
	main_vbox.offset_top = 24
	main_vbox.offset_right = -24
	main_vbox.offset_bottom = -24
	add_child(main_vbox)

	var title := Label.new()
	title.text = "SustainableIsland Tourism Council"
	title.add_theme_font_size_override("font_size", 28)
	main_vbox.add_child(title)

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 24)
	main_vbox.add_child(top_bar)

	turn_label = Label.new()
	top_bar.add_child(turn_label)

	action_label = Label.new()
	top_bar.add_child(action_label)

	var stats_box := HBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 20)
	main_vbox.add_child(stats_box)

	for stat_name in ["economy", "employment", "environment", "satisfaction"]:
		var vb := VBoxContainer.new()
		vb.custom_minimum_size = Vector2(180, 0)
		var lbl := Label.new()
		lbl.text = stat_name.capitalize()
		vb.add_child(lbl)
		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.value = 50
		bar.show_percentage = true
		vb.add_child(bar)
		stats_box.add_child(vb)
		stat_bars[stat_name] = bar

	var zones_label := Label.new()
	zones_label.text = "Zones - click to manage"
	zones_label.add_theme_font_size_override("font_size", 20)
	main_vbox.add_child(zones_label)

	var zones_grid := GridContainer.new()
	zones_grid.columns = 3
	zones_grid.add_theme_constant_override("h_separation", 16)
	zones_grid.add_theme_constant_override("v_separation", 16)
	main_vbox.add_child(zones_grid)

	for zone in GameData.zones:
		var btn := Button.new()
		btn.text = "%s\n(%s)" % [zone["name"], zone["sdg"]]
		btn.custom_minimum_size = Vector2(220, 70)
		btn.pressed.connect(_on_zone_pressed.bind(zone))
		zones_grid.add_child(btn)

	var bottom_bar := HBoxContainer.new()
	main_vbox.add_child(bottom_bar)

	end_season_button = Button.new()
	end_season_button.text = "End Season"
	end_season_button.custom_minimum_size = Vector2(160, 44)
	end_season_button.pressed.connect(_on_end_season_pressed)
	bottom_bar.add_child(end_season_button)

	_build_decision_popup()
	_build_summary_popup()
	_build_end_popup()

func _build_decision_popup() -> void:
	decision_popup = PopupPanel.new()
	decision_popup.size = Vector2i(420, 320)
	add_child(decision_popup)

	decision_vbox = VBoxContainer.new()
	decision_vbox.add_theme_constant_override("separation", 10)
	decision_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	decision_vbox.offset_left = 16
	decision_vbox.offset_top = 16
	decision_vbox.offset_right = -16
	decision_vbox.offset_bottom = -16
	decision_popup.add_child(decision_vbox)

	decision_title = Label.new()
	decision_title.add_theme_font_size_override("font_size", 20)
	decision_vbox.add_child(decision_title)

func _build_summary_popup() -> void:
	summary_popup = PopupPanel.new()
	summary_popup.size = Vector2i(420, 220)
	add_child(summary_popup)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 16
	vb.offset_top = 16
	vb.offset_right = -16
	vb.offset_bottom = -16
	vb.add_theme_constant_override("separation", 12)
	summary_popup.add_child(vb)

	summary_label = Label.new()
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(summary_label)

	var summary_button := Button.new()
	summary_button.text = "Continue"
	summary_button.pressed.connect(func(): summary_popup.hide())
	vb.add_child(summary_button)

func _build_end_popup() -> void:
	end_popup = PopupPanel.new()
	end_popup.size = Vector2i(460, 260)
	add_child(end_popup)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 16
	vb.offset_top = 16
	vb.offset_right = -16
	vb.offset_bottom = -16
	vb.add_theme_constant_override("separation", 12)
	end_popup.add_child(vb)

	end_title = Label.new()
	end_title.add_theme_font_size_override("font_size", 24)
	vb.add_child(end_title)

	end_desc = Label.new()
	end_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(end_desc)

	var end_button := Button.new()
	end_button.text = "Play Again"
	end_button.pressed.connect(_on_play_again_pressed)
	vb.add_child(end_button)

func _refresh_all() -> void:
	_on_stats_changed()
	turn_label.text = "Season %d / %d" % [GameState.turn, GameState.max_turns]

func _on_stats_changed() -> void:
	stat_bars["economy"].value = GameState.economy
	stat_bars["employment"].value = GameState.employment
	stat_bars["environment"].value = GameState.environment
	stat_bars["satisfaction"].value = GameState.satisfaction
	action_label.text = "Actions left this season: %d" % GameState.action_points

func _on_zone_pressed(zone: Dictionary) -> void:
	if not GameState.can_take_action():
		summary_label.text = "You're out of actions for this season. Press End Season to continue."
		summary_popup.popup_centered()
		return

	decision_title.text = zone["name"] + "\n" + zone["sdg"]

	for c in decision_vbox.get_children():
		if c != decision_title:
			c.queue_free()

	for decision in zone["decisions"]:
		var btn := Button.new()
		btn.text = decision["title"] + "\n" + decision["description"]
		btn.custom_minimum_size = Vector2(380, 80)
		btn.pressed.connect(_on_decision_chosen.bind(decision))
		decision_vbox.add_child(btn)

	decision_popup.popup_centered()

func _on_decision_chosen(decision: Dictionary) -> void:
	GameState.apply_decision(decision)
	decision_popup.hide()
	if not GameState.can_take_action():
		summary_label.text = "No actions left. Press End Season to move to the next tourist season."
		summary_popup.popup_centered()

func _on_end_season_pressed() -> void:
	GameState.end_season()

func _on_turn_advanced(turn: int) -> void:
	turn_label.text = "Season %d / %d" % [turn, GameState.max_turns]
	summary_label.text = "Season complete. Tourism pressure affects the environment each season - keep an eye on your Environment score."
	summary_popup.popup_centered()

func _on_game_ended(prosperity: float, sustainability: float, ending_key: String) -> void:
	var ending: Dictionary = GameData.endings[ending_key]
	end_title.text = ending["title"]
	end_desc.text = ending["description"] + "\n\nFinal Prosperity: %.0f / 100\nFinal Sustainability: %.0f / 100" % [prosperity, sustainability]
	end_popup.popup_centered()

func _on_play_again_pressed() -> void:
	end_popup.hide()
	GameState.reset()
	_refresh_all()
