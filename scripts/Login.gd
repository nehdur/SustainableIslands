extends Control


var email_input: LineEdit
var username_input: LineEdit
var password_input: LineEdit
var status_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:

	var background := ColorRect.new()
	background.color = Color(0.05, 0.15, 0.20)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)


	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)


	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 0)
	center.add_child(panel)


	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)


	var title := Label.new()
	title.text = "SustainableIsland"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)


	var subtitle := Label.new()
	subtitle.text = "Sustainable Islands Tourism Council"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)


	email_input = LineEdit.new()
	email_input.placeholder_text = "Email"
	box.add_child(email_input)


	username_input = LineEdit.new()
	username_input.placeholder_text = "Username"
	box.add_child(username_input)


	password_input = LineEdit.new()
	password_input.placeholder_text = "Password"
	password_input.secret = true
	box.add_child(password_input)


	var login_button := Button.new()
	login_button.text = "Log In"
	login_button.custom_minimum_size = Vector2(0, 44)
	login_button.pressed.connect(_on_login_pressed)
	box.add_child(login_button)


	var create_button := Button.new()
	create_button.text = "Create Account"
	create_button.custom_minimum_size = Vector2(0, 44)
	create_button.pressed.connect(_on_create_account_pressed)
	box.add_child(create_button)


	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(status_label)


func _on_login_pressed() -> void:

	var email := email_input.text.strip_edges()
	var password := password_input.text

	if email == "":
		status_label.text = "Enter your email."
		return

	if password == "":
		status_label.text = "Enter your password."
		return

	status_label.text = "Logging in..."

	var result := await Supabase.sign_in(
		email,
		password
	)

	if not result["ok"]:
		status_label.text = "Login failed: %s" % result["error"]
		return

	status_label.text = "Loading your game..."

	var load_result := await Supabase.load_game_state()

	if not load_result["ok"]:
		status_label.text = "Could not load your save."
		return

	_apply_saved_state(load_result)

	get_tree().change_scene_to_file(
		"res://scenes/Main.tscn"
	)


func _on_create_account_pressed() -> void:

	var email := email_input.text.strip_edges()
	var username := username_input.text.strip_edges()
	var password := password_input.text

	if email == "":
		status_label.text = "Enter an email."
		return

	if username == "":
		status_label.text = "Enter a username."
		return

	if password == "":
		status_label.text = "Enter a password."
		return

	if password.length() < 6:
		status_label.text = "Password must be at least 6 characters."
		return

	status_label.text = "Creating account..."

	var result := await Supabase.sign_up(
		email,
		password,
		username
	)

	if not result["ok"]:
		status_label.text = "Signup failed: %s" % result["error"]
		return

	if Supabase.is_logged_in():

		var load_result := await Supabase.load_game_state()

		if load_result["ok"]:
			_apply_saved_state(load_result)

		get_tree().change_scene_to_file(
			"res://scenes/Main.tscn"
		)

	else:

		status_label.text = "Account created. Please confirm your email, then log in."


func _apply_saved_state(result: Dictionary) -> void:

	var rows = result["data"]

	if not rows is Array:
		return

	if rows.is_empty():
		return

	var row: Dictionary = rows[0]

	GameState.economy = int(
		row.get("economy", 50)
	)

	GameState.employment = int(
		row.get("employment", 50)
	)

	GameState.environment = int(
		row.get("environment", 50)
	)

	GameState.satisfaction = int(
		row.get("satisfaction", 50)
	)

	GameState.turn = int(
		row.get("turn", 1)
	)

	GameState.action_points = int(
		row.get("action_points", 2)
	)

	var logs = row.get(
		"log_entries",
		[]
	)

	if logs is Array:
		GameState.log_entries = logs

	GameState.emit_signal(
		"stats_changed"
	)
