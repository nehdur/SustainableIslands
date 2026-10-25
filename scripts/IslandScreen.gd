extends Control
## Layout: Game.tscn. State/rules: autoloads/IslandGame.gd.
## This controller updates existing nodes; it never creates UI nodes.

var selected: String = "guesthouse"
var is_syncing: bool = false

@onready var island_map: Control = %IslandMap
@onready var journal: RichTextLabel = %JournalText
@onready var toast: Label = %ToastLabel
@onready var forecast_label: Label = %ForecastLabel
@onready var day_button: Button = %NextDayButton
@onready var sound_button: Button = %SoundButton
@onready var cloud_button: Button = %CloudButton
@onready var audio: AudioStreamPlayer = %Audio
@onready var modal: Control = %GameDialog

@onready var metrics: Dictionary = {
	"money": %MoneyValue, "day": %DayValue, "ap": %ActionsValue,
	"rating": %RatingValue, "jobs": %JobsValue, "satisfaction": %SatisfactionValue
}
@onready var bars: Dictionary = {
	"marine": {"label": %MarineLabel, "bar": %MarineBar},
	"forest": {"label": %ForestLabel, "bar": %ForestBar},
	"water": {"label": %WaterLabel, "bar": %WaterBar},
	"energy": {"label": %EnergyLabel, "bar": %EnergyBar},
	"waste": {"label": %WasteLabel, "bar": %WasteBar},
	"impact": %ImpactLabel
}

func _ready() -> void:
	show_page(0)
	IslandGame.changed.connect(refresh)
	refresh()
	if IslandGame.data.explored.is_empty():
		show_help()
	elif IslandGame.data.finished:
		show_ending()


func refresh() -> void:
	for key in ["money", "day", "ap"]:
		metrics[key].text = str(int(IslandGame.data[key]))

	metrics.day.text = "%d/14" % int(IslandGame.data.day)
	metrics.rating.text = "%d/100" % IslandGame.rating()
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

	refresh_detail()


func show_page(page: int) -> void:
	%ManagePage.visible = page == 0
	%HealthPage.visible = page == 1
	%JournalPage.visible = page == 2
	%ManageTab.set_pressed_no_signal(page == 0)
	%HealthTab.set_pressed_no_signal(page == 1)
	%JournalTab.set_pressed_no_signal(page == 2)


func select_zone(key: String) -> void:
	selected = key
	island_map.set_selection(key)
	IslandGame.visit(key)
	show_page(0)
	play_sound("click")
	refresh_detail()

func refresh_detail() -> void:
	# Same labels/buttons every time; update text, image, visibility and state.
	%SelectedIcon.texture = island_map.get_location_texture(selected)
	var facility: bool = IslandGame.FACILITIES.has(selected)
	%FacilityActions.visible = facility
	%NatureActions.visible = not facility
	if facility:
		var item: Dictionary = IslandGame.FACILITIES[selected]
		var level: int = int(IslandGame.data.buildings[selected])
		var workers: int = int(IslandGame.data.staff[selected])
		var price: int = IslandGame.cost(selected)
		%SelectedTitle.text = item.title
		%SelectedSDG.text = item.sdg
		%SelectedDescription.text = item.description
		%SelectedStatus.text = "Level %d / %d  •  Workers %d / %d" % [level, item.max, workers, item.staff]
		%BuildButton.text = ("Build" if level == 0 else "Upgrade") + " • %d coins" % price
		%BuildButton.disabled = level >= int(item.max) or IslandGame.blocked(price) != ""
		%BuildButton.tooltip_text = "Maximum level reached." if level >= int(item.max) else IslandGame.blocked(price)
		%HireButton.disabled = level == 0 or workers >= int(item.staff) or IslandGame.blocked(0) != "" or IslandGame.jobs() + int(item.staff) - workers > IslandGame.WORKERS
		%ReleaseButton.disabled = workers == 0 or IslandGame.blocked(0) != ""
	else:
		var forest: bool = selected == "forest"
		%SelectedTitle.text = "Mangrove Forest" if forest else "Coral Sanctuary"
		%SelectedSDG.text = "SDG 15 • Life on land" if forest else "SDG 14 • Life below water"
		%SelectedDescription.text = "Native planting restores forest habitats. Hotel construction and accumulated waste damage the forest." if forest else "Protect marine habitats from tourism waste. Recycling prevents damage; conservation restores reef health."
		%SelectedStatus.text = "Health %d / 100" % int(IslandGame.data.forest if forest else IslandGame.data.marine)
		%ConserveButton.text = "Plant native trees • 130 coins" if forest else "Protect the reef • 130 coins"
		%ConserveButton.disabled = IslandGame.blocked(130) != ""

func _on_conserve_pressed() -> void:
	do_action("forest" if selected == "forest" else "reef")


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
	modal.close()

func dialog(title: String, text: String, height: int = 570) -> Control:
	modal.open(title, text, height)
	return modal

func show_toolbox() -> void:
	modal.open("Care for your island", "Each action costs 1 management point.\nActions remaining: %d   •   Coins: %d" % [IslandGame.data.ap, IslandGame.data.money], 610, "actions")
	modal.cleanup_button.disabled = IslandGame.blocked(100) != ""
	modal.supplies_button.disabled = IslandGame.blocked(80) != ""
	modal.culture_button.disabled = IslandGame.blocked(90) != ""

func next_day() -> void:
	if IslandGame.data.finished:
		show_ending()
	elif int(IslandGame.data.ap) > 0:
		modal.open("End today with actions remaining?", "You still have %d actions.\n\nUnused actions do not carry over. End the day to welcome tourists and calculate costs." % IslandGame.data.ap, 430, "confirm")
	else:
		advance_day()


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
	show_page(2)


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
		if modal.visible:
			close_modal()
		else:
			go_menu()
