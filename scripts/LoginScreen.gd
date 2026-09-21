extends Control

@onready var username_field: LineEdit = $CenterContainer/LoginPanel/VBox/UsernameField
@onready var password_field: LineEdit = $CenterContainer/LoginPanel/VBox/PasswordField
@onready var login_button: Button = $CenterContainer/LoginPanel/VBox/LoginButton
@onready var create_account_button: Button = $CenterContainer/LoginPanel/VBox/CreateAccountButton
@onready var forgot_password_button: LinkButton = $CenterContainer/LoginPanel/VBox/RememberRow/ForgotPasswordButton
@onready var remember_check: CheckBox = $CenterContainer/LoginPanel/VBox/RememberRow/RememberCheck


func _ready() -> void:
	login_button.pressed.connect(_on_login_pressed)
	create_account_button.pressed.connect(_on_create_account_pressed)
	forgot_password_button.pressed.connect(_on_forgot_password_pressed)
	password_field.text_submitted.connect(func(_t): _on_login_pressed())


func _on_login_pressed() -> void:
	var username_or_email := username_field.text.strip_edges()
	var password := password_field.text

	if username_or_email.is_empty():
		print("Please enter your username or email.")
		return

	if password.is_empty():
		print("Please enter your password.")
		return

	login_button.disabled = true
	login_button.text = "Logging in..."

	var result := await Supabase.sign_in_user_or_email(
		username_or_email,
		password
	)

	if not result["ok"]:
		print("Login failed: ", result["error"])

		login_button.disabled = false
		login_button.text = "➜ Log In"

		return

	print("Login successful!")

	var load_result := await Supabase.load_game_state()

	if not load_result["ok"]:
		print("Could not load your save: ", load_result["error"])

		login_button.disabled = false
		login_button.text = "➜ Log In"

		return

	_apply_saved_state(load_result)

	get_tree().change_scene_to_file(
		"res://scenes/MainMenu.tscn"
	)
	
	
func _apply_saved_state(result: Dictionary) -> void:
	var rows = result["data"]

	if not rows is Array:
		return

	if rows.is_empty():
		return

	var row: Dictionary = rows[0]

	GameState.economy = int(row.get("economy", 50))
	GameState.employment = int(row.get("employment", 50))
	GameState.environment = int(row.get("environment", 50))
	GameState.satisfaction = int(row.get("satisfaction", 50))

	GameState.turn = int(row.get("turn", 1))
	GameState.action_points = int(row.get("action_points", 2))

	var logs = row.get("log_entries", [])

	if logs is Array:
		GameState.log_entries = logs

	if GameState.has_signal("stats_changed"):
		GameState.emit_signal("stats_changed")


func _on_create_account_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/CreateAccount.tscn")


func _on_forgot_password_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ForgotPassword.tscn")
