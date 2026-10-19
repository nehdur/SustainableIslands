extends Control

var metrics: Dictionary = {}
var bars: Dictionary = {}
var selected: String = "guesthouse"

var detail: VBoxContainer
var tabs: TabContainer
var journal: RichTextLabel
var toast: Label
var forecast_label: Label
var day_button: Button
var sound_button: Button
var cloud_button: Button
var modal: Control
var audio: AudioStreamPlayer
var island_map: Control
var map_stage: Control

var is_syncing: bool = false


func _ready() -> void:
	# Background
	var background := ColorRect.new()
	background.color = Color("#e8eddf")
	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override(
			"margin_" + side, 32
		)

	add_child(margin)
	var layout: VBoxContainer = add_column(margin, 20)

	# Header
	var header: HBoxContainer = add_row(layout, 18)

	add_image(
		header,
		"res://assets/island/leaf.svg",
		Vector2(58, 58)
	)

	var brand: VBoxContainer = add_column(header, 2)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	add_label(brand, "SustainableIsland", 32)
	add_label(
		brand,
		"Manage tourism. Protect your island.",
		20
	)

	add_button(header, "Quick actions", show_toolbox)
	add_button(header, "Guide", show_help)
	sound_button = add_button(header, "Sound", toggle_sound)
	add_button(header, "Menu", go_menu)

	# Summary cards
	var summary: HBoxContainer = add_row(layout, 18)

	var titles: Dictionary = {
		"money": "ISLAND COINS",
		"day": "DAY / 14",
		"ap": "ACTIONS LEFT",
		"rating": "TOURISM RATING"
	}

	for key in titles:
		var card: PanelContainer = add_panel(summary)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var row: HBoxContainer = add_row(card, 14)
		var heading: Label = add_label(row, titles[key], 18)
		heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		metrics[key] = add_label(row, "", 30)

	# Main content
	var body: HBoxContainer = add_row(layout, 24)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Island map
	var map_panel: PanelContainer = add_panel(body)
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var map_column: VBoxContainer = add_column(map_panel, 6)

	add_label(map_column, "Explore your island", 27)
	add_label(
		map_column,
		"Select an icon to manage its location.",
		20
	)

	map_stage = Control.new()
	map_stage.custom_minimum_size = Vector2(0, 400)
	map_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_stage.clip_contents = true
	map_column.add_child(map_stage)

	island_map = Control.new()
	island_map.set_script(
		load("res://scripts/IslandMap.gd")
	)
	island_map.size = Vector2(1200, 800)
	map_stage.add_child(island_map)

	island_map.connect("selected", select_zone)
	map_stage.resized.connect(fit_map)

	# Sidebar
	var sidebar: VBoxContainer = add_column(body, 16)
	sidebar.custom_minimum_size.x = 570

	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL

	tabs.add_theme_stylebox_override(
		"panel",
		IslandUI.style(IslandUI.CREAM)
	)
	tabs.add_theme_stylebox_override(
		"tab_selected",
		IslandUI.style(IslandUI.CREAM)
	)
	tabs.add_theme_stylebox_override(
		"tab_unselected",
		IslandUI.style(Color("#dce5d6"))
	)
	tabs.add_theme_color_override(
		"font_selected_color", IslandUI.INK
	)
	tabs.add_theme_color_override(
		"font_unselected_color", IslandUI.MUTED
	)
	tabs.add_theme_font_size_override("font_size", 23)

	sidebar.add_child(tabs)

	# Manage tab
	var manage_scroll := ScrollContainer.new()
	manage_scroll.name = "Manage"
	manage_scroll.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
	)
	tabs.add_child(manage_scroll)

	detail = add_column(manage_scroll, 16)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Island health tab
	var health_scroll := ScrollContainer.new()
	health_scroll.name = "Island health"
	health_scroll.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
	)
	tabs.add_child(health_scroll)

	var health: VBoxContainer = add_column(health_scroll, 18)
	health.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var people: HBoxContainer = add_row(health, 20)

	for key in ["jobs", "satisfaction"]:
		var column: VBoxContainer = add_column(people, 4)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		add_label(
			column,
			"Local jobs / 12" if key == "jobs" else "Satisfaction",
			21
		)
		metrics[key] = add_label(column, "", 28)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	health.add_child(grid)

	for key in ["marine", "forest", "water", "energy", "waste"]:
		var column: VBoxContainer = add_column(grid, 8)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var label: Label = add_label(column, "", 21)

		var bar := ProgressBar.new()
		bar.custom_minimum_size.y = 14
		bar.max_value = 200 if key == "waste" else 100
		bar.show_percentage = false

		bar.add_theme_stylebox_override(
			"background",
			IslandUI.style(Color("#dce5d6"), 6, 0)
		)
		bar.add_theme_stylebox_override(
			"fill",
			IslandUI.style(Color("#5c9682"), 6, 0)
		)

		column.add_child(bar)
		bars[key] = {"label": label, "bar": bar}

	bars["impact"] = add_label(health, "", 21)

	add_label(
		health,
		"Lower waste and impact are better.",
		20,
		true
	)
	add_button(health, "Season goals", show_goals)

	# Journal tab
	var journal_page: VBoxContainer = add_column(tabs, 16)
	journal_page.name = "Journal"

	add_label(journal_page, "Island journal", 27)

	journal = RichTextLabel.new()
	journal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	journal.add_theme_color_override(
		"default_color", IslandUI.INK
	)
	journal.add_theme_font_size_override(
		"normal_font_size", 22
	)
	journal.scroll_following = true
	journal_page.add_child(journal)

	cloud_button = add_button(
		sidebar,
		"Save / cloud sync",
		sync_cloud
	)

	# Footer
	var footer: PanelContainer = add_panel(layout)
	var footer_row: HBoxContainer = add_row(footer, 24)

	var messages: VBoxContainer = add_column(footer_row, 4)
	messages.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	forecast_label = add_label(messages, "", 22, true)

	toast = add_label(
		messages,
		"Progress autosaves after your decisions.",
		19,
		true
	)
	toast.max_lines_visible = 2

	day_button = add_button(
		footer_row,
		"Next Day →",
		next_day,
		true
	)
	day_button.custom_minimum_size.x = 280

	audio = AudioStreamPlayer.new()
	add_child(audio)

	IslandGame.changed.connect(refresh)
	refresh()
	call_deferred("fit_map")

	if IslandGame.data.explored.is_empty():
		show_help()
	elif IslandGame.data.finished:
		show_ending()


# UI helpers

func add_column(parent: Node, gap: int = 16) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", gap)
	parent.add_child(column)
	return column


func add_row(parent: Node, gap: int = 16) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", gap)
	parent.add_child(row)
	return row


func add_panel(parent: Node) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel",
		IslandUI.style(IslandUI.CREAM, 18, 22)
	)
	parent.add_child(panel)
	return panel


func add_label(
	parent: Node,
	text: String,
	font_size: int = 24,
	wrap: bool = false
) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", IslandUI.INK)
	label.add_theme_font_size_override("font_size", font_size)

	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	parent.add_child(label)
	return label


func add_button(
	parent: Node,
	text: String,
	action: Callable,
	primary: bool = false
) -> Button:
	var button: Button = IslandUI.button(
		parent, text, Rect2(), action, primary
	)
	button.custom_minimum_size.y = 60
	return button


func add_image(
	parent: Node,
	path: String,
	minimum: Vector2
) -> void:
	var image := TextureRect.new()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture = load(path)
	image.custom_minimum_size = minimum
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)


# Map layout

func fit_map() -> void:
	var factor: float = maxf(
		map_stage.size.x / 1200.0,
		map_stage.size.y / 800.0
	)

	island_map.scale = Vector2.ONE * factor
	island_map.position = (
		map_stage.size - Vector2(1200, 800) * factor
	) / 2.0


func clean_map() -> void:
	var markers: Dictionary = island_map.get("markers")

	for key in markers:
		var marker: Dictionary = markers[key]
		var button: Button = marker["button"]
		var status_label: Label = marker["status"]

		# Remove overlapping map labels.
		button.text = ""
		button.position = Vector2(-4, -4)
		button.size = Vector2(138, 138)
		status_label.hide()

		var title: String

		if IslandGame.FACILITIES.has(key):
			title = IslandGame.FACILITIES[key].title
		else:
			title = (
				"Mangrove Forest"
				if key == "forest"
				else "Coral Sanctuary"
			)

		button.tooltip_text = title + " — select to manage"

		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0, 0, 0, 0)

		if key == selected:
			normal.bg_color = Color(1, 0.97, 0.83, 0.12)
			normal.border_color = Color("#fff0c6")
			normal.set_border_width_all(2)
			normal.set_corner_radius_all(18)

		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(1, 0.97, 0.83, 0.16)
		hover.border_color = Color("#fff0c6")
		hover.set_border_width_all(3)
		hover.set_corner_radius_all(18)

		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("focus", hover)
		button.add_theme_stylebox_override("pressed", hover)


# Refresh displayed information

func refresh() -> void:
	for key in ["money", "day", "ap"]:
		metrics[key].text = str(int(IslandGame.data[key]))

	metrics.rating.text = "%d / 100" % IslandGame.rating()
	metrics.jobs.text = str(IslandGame.jobs())
	metrics.satisfaction.text = (
		"%d%%" % int(IslandGame.data.satisfaction)
	)

	for key in ["marine", "forest", "water", "energy", "waste"]:
		bars[key].label.text = "%s  %d / %d" % [
			key.capitalize(),
			int(IslandGame.data[key]),
			200 if key == "waste" else 100
		]
		bars[key].bar.value = IslandGame.data[key]

	bars.impact.text = (
		"Environmental impact: %d / 100"
		% IslandGame.impact()
	)

	forecast_label.text = IslandGame.forecast()
	sound_button.text = (
		"Sound: off" if IslandGame.muted else "Sound: on"
	)

	if IslandGame.data.finished:
		day_button.text = "View results"
	elif int(IslandGame.data.day) == 14:
		day_button.text = "Finish season →"
	else:
		day_button.text = "Next Day →"

	if IslandGame.data.log.is_empty():
		journal.text = (
			"Your story starts here. "
			+ "Select a location and make your first decision."
		)
	else:
		journal.text = "\n\n".join(
			PackedStringArray(IslandGame.data.log)
		)

	clean_map()
	refresh_detail()


func select_zone(key: String) -> void:
	selected = key
	IslandGame.visit(key)
	tabs.current_tab = 0
	play_sound("click")
	clean_map()
	refresh_detail()


func clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func refresh_detail() -> void:
	clear_children(detail)

	var heading: HBoxContainer = add_row(detail, 16)

	add_image(
		heading,
		"res://assets/island/%s.svg" % selected,
		Vector2(76, 76)
	)

	var names: VBoxContainer = add_column(heading, 4)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if IslandGame.FACILITIES.has(selected):
		var item: Dictionary = IslandGame.FACILITIES[selected]
		var level: int = int(IslandGame.data.buildings[selected])
		var workers: int = int(IslandGame.data.staff[selected])
		var price: int = IslandGame.cost(selected)

		add_label(names, item.title, 29, true)
		add_label(names, item.sdg, 19, true)
		add_label(detail, item.description, 22, true)

		add_label(
			detail,
			"Level %d / %d  •  Workers %d / %d" % [
				level, item.max, workers, item.staff
			],
			21
		)

		var build_button: Button = add_button(
			detail,
			("Build" if level == 0 else "Upgrade")
			+ " • %d coins" % price,
			do_build,
			true
		)

		build_button.disabled = (
			level >= int(item.max)
			or IslandGame.blocked(price) != ""
		)

		build_button.tooltip_text = (
			"Maximum level reached."
			if level >= int(item.max)
			else IslandGame.blocked(price)
		)

		var teams: HBoxContainer = add_row(detail, 12)

		var hire_button: Button = add_button(
			teams, "Assign team", do_hire
		)
		var release_button: Button = add_button(
			teams, "Release team", do_release
		)

		hire_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		release_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		hire_button.add_theme_font_size_override("font_size", 22)
		release_button.add_theme_font_size_override("font_size", 22)

		hire_button.disabled = (
			level == 0
			or workers >= int(item.staff)
			or IslandGame.blocked(0) != ""
			or (
				IslandGame.jobs() + int(item.staff) - workers
				> IslandGame.WORKERS
			)
		)

		release_button.disabled = (
			workers == 0
			or IslandGame.blocked(0) != ""
		)

	else:
		var forest: bool = selected == "forest"

		add_label(
			names,
			"Mangrove Forest" if forest else "Coral Sanctuary",
			29,
			true
		)

		add_label(
			names,
			"SDG 15 • Life on land"
			if forest
			else "SDG 14 • Life below water",
			19,
			true
		)

		add_label(
			detail,
			(
				"Native planting restores forest habitats. "
				+ "Hotel construction and accumulated waste "
				+ "damage the forest."
			)
			if forest
			else (
				"Protect marine habitats from tourism waste. "
				+ "Recycling prevents damage; conservation "
				+ "restores reef health."
			),
			22,
			true
		)

		add_label(
			detail,
			"Health %d / 100" % int(
				IslandGame.data.forest
				if forest
				else IslandGame.data.marine
			),
			22
		)

		var action: String = "forest" if forest else "reef"

		var button: Button = add_button(
			detail,
			"Plant native trees • 130 coins"
			if forest
			else "Protect the reef • 130 coins",
			do_action.bind(action),
			true
		)

		button.disabled = IslandGame.blocked(130) != ""

		add_label(
			detail,
			"Restores up to 12 health points.",
			21,
			true
		)

	add_label(
		detail,
		"Each management change uses 1 daily action.",
		19,
		true
	)


# Gameplay actions

func play_sound(sound_name: String) -> void:
	if not IslandGame.muted:
		audio.stop()
		audio.stream = load(
			"res://assets/audio/%s.wav" % sound_name
		)
		audio.play()


func show_message(message: String) -> void:
	toast.text = message
	toast.tooltip_text = message
	play_sound("click")


func do_build() -> void:
	show_message(IslandGame.build(selected))


func do_hire() -> void:
	show_message(IslandGame.hire(selected))


func do_release() -> void:
	show_message(IslandGame.release(selected))


func do_action(kind: String) -> void:
	show_message(IslandGame.conserve(kind))
	close_modal()


# Dialogs

func close_modal() -> void:
	if is_instance_valid(modal):
		remove_child(modal)
		modal.queue_free()

	modal = null


func dialog(
	title: String,
	text: String,
	height: int = 570
) -> Panel:
	close_modal()

	modal = Control.new()
	modal.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	add_child(modal)

	var shade := ColorRect.new()
	shade.color = Color(0.08, 0.19, 0.20, 0.76)
	shade.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	modal.add_child(shade)

	var panel: Panel = IslandUI.panel(
		modal,
		Rect2(470, (1080 - height) / 2.0, 980, height)
	)

	IslandUI.label(
		panel, title, Rect2(36, 26, 910, 60), 34
	)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(36, 105)
	scroll.size = Vector2(908, height - 205)
	scroll.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
	)
	panel.add_child(scroll)

	var text_label := Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.text = text
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.add_theme_color_override(
		"font_color", IslandUI.INK
	)
	text_label.add_theme_font_size_override("font_size", 25)
	scroll.add_child(text_label)

	IslandUI.button(
		panel,
		"Continue",
		Rect2(36, height - 76, 908, 52),
		close_modal,
		true
	)

	return panel


func show_help() -> void:
	dialog(
		"Welcome to SustainableIsland",
		"Select a building icon to manage it.\n\n"
		+ "Build a facility, then assign its local team to open it.\n\n"
		+ "You have 3 management actions per day.\n\n"
		+ "Open Island health to check resources and habitats. "
		+ "Open Journal to review decisions.\n\n"
		+ "Quick actions offers cleanup, supplies and workshops.\n\n"
		+ "Select Next Day to welcome tourists and pay operating costs.\n\n"
		+ "Complete 14 days with rating 70+, 8 jobs, "
		+ "marine and forest health 65+, and at least 700 coins.",
		690
	)


func ensure_toolbox() -> void:
	# Quick actions is already in the header.
	pass


func show_toolbox() -> void:
	var panel: Panel = dialog(
		"Care for your island",
		"Each action costs 1 management point.\n"
		+ "Actions remaining: %d   •   Coins: %d" % [
			IslandGame.data.ap,
			IslandGame.data.money
		],
		610
	)

	var choices: Array = [
		[
			"cleanup",
			"Collect waste • 100 coins • -25 waste, +3 marine",
			100
		],
		[
			"supplies",
			"Emergency supplies • 80 coins • +40 water & energy",
			80
		],
		[
			"culture",
			"Cultural workshop • 90 coins • +8 satisfaction",
			90
		]
	]

	for i in range(choices.size()):
		var entry: Array = choices[i]
		var button: Button = IslandUI.button(
			panel,
			entry[1],
			Rect2(36, 228 + i * 84, 908, 62),
			do_action.bind(entry[0])
		)
		button.disabled = IslandGame.blocked(int(entry[2])) != ""


func show_goals() -> void:
	dialog(
		"Your 14-day challenge",
		"Meet ALL five goals:\n\n"
		+ "Tourism rating: %d / 70 required\n" % IslandGame.rating()
		+ "Local employment: %d / 8 jobs required\n" % IslandGame.jobs()
		+ "Marine health: %d / 65 required\n" % IslandGame.data.marine
		+ "Forest health: %d / 65 required\n" % IslandGame.data.forest
		+ "Remaining budget: %d / 700 coins required\n\n"
			% IslandGame.data.money
		+ "Rating considers habitats, satisfaction, "
		+ "employment and financial stability.",
		670
	)


func show_journal() -> void:
	tabs.current_tab = 2


func next_day() -> void:
	if IslandGame.data.finished:
		show_ending()
		return

	if int(IslandGame.data.ap) > 0:
		var panel: Panel = dialog(
			"End today with actions remaining?",
			"You still have %d actions.\n\n" % IslandGame.data.ap
			+ "Unused actions do not carry over. "
			+ "End the day to welcome tourists and calculate costs.",
			430
		)

		IslandUI.button(
			panel,
			"End day anyway",
			Rect2(36, 244, 908, 52),
			advance_day
		)
	else:
		advance_day()


func advance_day() -> void:
	var report: Dictionary = IslandGame.end_day()
	play_sound("day")

	if bool(report.get("finished", false)):
		show_ending()
	else:
		dialog(
			"Daily island report",
			str(report.get("report", "")),
			570
		)


func show_ending() -> void:
	var success: bool = IslandGame.won()

	dialog(
		"Sustainable Island award!" if success else "Season review",
		"Your island welcomed %d visitors and created %d jobs.\n\n"
		% [
			IslandGame.data.total_visitors,
			IslandGame.jobs()
		]
		+ "Final tourism rating: %d / 100\n" % IslandGame.rating()
		+ "Marine health: %d   •   Forest health: %d\n" % [
			IslandGame.data.marine,
			IslandGame.data.forest
		]
		+ "Remaining funds: %d coins\n\n" % IslandGame.data.money
		+ (
			"You balanced local livelihoods with nature!"
			if success
			else "Try staffing a market early and investing in recycling."
		)
		+ "\n\nReturn to Menu to start a new island.",
		650
	)

	play_sound("success" if success else "day")


# Saving and navigation

func toggle_sound() -> void:
	IslandGame.toggle_sound()
	refresh()


func go_menu() -> void:
	if is_syncing:
		show_message("Please wait for cloud sync to finish.")
		return

	IslandGame.save_local()

	get_tree().change_scene_to_file(
		"res://scenes/MainMenu.tscn"
	)


func sync_cloud() -> void:
	if is_syncing:
		return

	if not IslandGame.save_local():
		show_message(IslandGame.storage_notice)
		return

	if not Supabase.is_logged_in():
		show_message(
			"Saved on this device. "
			+ "Guest mode does not use cloud storage."
		)
		return

	is_syncing = true
	cloud_button.disabled = true
	cloud_button.text = "Syncing…"

	await IslandGame.cloud_save()

	is_syncing = false
	cloud_button.disabled = false
	cloud_button.text = "Save / cloud sync"
	show_message(IslandGame.last_sync)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_instance_valid(modal):
			close_modal()
		else:
			go_menu()
