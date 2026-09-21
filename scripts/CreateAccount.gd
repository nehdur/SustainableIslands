extends Control


@onready var username_field: LineEdit = $CenterContainer/AuthPanel/VBox/UsernameField
@onready var email_field: LineEdit = $CenterContainer/AuthPanel/VBox/EmailField
@onready var password_field: LineEdit = $CenterContainer/AuthPanel/VBox/PasswordField
@onready var confirm_password_field: LineEdit = $CenterContainer/AuthPanel/VBox/ConfirmPasswordField
@onready var create_button: Button = $CenterContainer/AuthPanel/VBox/CreateButton
@onready var back_button: Button = $CenterContainer/AuthPanel/VBox/BackButton
@onready var status_label: Label = $CenterContainer/AuthPanel/VBox/StatusLabel


func _ready() -> void:
	create_button.pressed.connect(_on_create_pressed)
	back_button.pressed.connect(_on_back_pressed)
	status_label.text = ""


func _on_create_pressed() -> void:

	var username := username_field.text.strip_edges()
	var email := email_field.text.strip_edges()
	var password := password_field.text
	var confirm_password := confirm_password_field.text


	if username.is_empty():
		status_label.text = "Please enter a username."
		return


	if email.is_empty() or not email.contains("@"):
		status_label.text = "Please enter a valid email address."
		return


	if password.length() < 6:
		status_label.text = "Password must be at least 6 characters."
		return


	if password != confirm_password:
		status_label.text = "Passwords do not match."
		return


	create_button.disabled = true
	create_button.text = "Creating Account..."
	status_label.text = "Please wait..."


	var result := await Supabase.sign_up(
		email,
		password,
		username
	)


	if not result["ok"]:

		status_label.text = "Signup failed: %s" % result["error"]

		create_button.disabled = false
		create_button.text = "➕ Create Account"

		return


	# If email confirmation is disabled, Supabase gives us a session immediately.
	if Supabase.is_logged_in():

		var load_result := await Supabase.load_game_state()

		if load_result["ok"]:
			_apply_saved_state(load_result)

		get_tree().change_scene_to_file(
			"res://scenes/MainMenu.tscn"
		)

	else:

		status_label.text = "Account created! Please check your email, then log in."

		create_button.disabled = false
		create_button.text = "➕ Create Account"


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


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(
		"res://scenes/LoginScreen.tscn"
	)
