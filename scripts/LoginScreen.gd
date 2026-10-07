extends Control

@onready var username_field: LineEdit = $CenterContainer/LoginPanel/VBox/UsernameField
@onready var password_field: LineEdit = $CenterContainer/LoginPanel/VBox/PasswordField
@onready var login_button: Button = $CenterContainer/LoginPanel/VBox/LoginButton
@onready var create_account_button: Button = $CenterContainer/LoginPanel/VBox/CreateAccountButton
@onready var forgot_password_button: LinkButton = $CenterContainer/LoginPanel/VBox/RememberRow/ForgotPasswordButton
@onready var remember_check: CheckBox = $CenterContainer/LoginPanel/VBox/RememberRow/RememberCheck


var feedback: Label
var guest_button: Button

func _ready() -> void:
	feedback = Label.new()
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.custom_minimum_size = Vector2(620, 54)
	feedback.add_theme_font_size_override("font_size", 20)
	$CenterContainer/LoginPanel/VBox.add_child(feedback)
	guest_button = Button.new()
	guest_button.text = "Play offline as guest"
	guest_button.custom_minimum_size.y = 48
	guest_button.add_theme_font_size_override("font_size", 24)
	$CenterContainer/LoginPanel/VBox.add_child(guest_button)
	guest_button.pressed.connect(func():
		Supabase.sign_out()
		IslandGame.select_profile("guest")
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	# Remember-email only: passwords and access tokens are never stored on disk.
	remember_check.text = "Remember email"
	var cfg := ConfigFile.new()
	if cfg.load("user://login_preferences.cfg") == OK:
		username_field.text = str(cfg.get_value("login", "name", ""))
		remember_check.button_pressed = not username_field.text.is_empty()
	login_button.pressed.connect(_on_login_pressed)
	create_account_button.pressed.connect(_on_create_account_pressed)
	forgot_password_button.pressed.connect(_on_forgot_password_pressed)
	password_field.text_submitted.connect(func(_t): _on_login_pressed())


func _on_login_pressed() -> void:
	var username_or_email := username_field.text.strip_edges()
	var password := password_field.text

	if username_or_email.is_empty():
		feedback.text = "Please enter your username or email."
		return

	if password.is_empty():
		feedback.text = "Please enter your password."
		return

	login_button.disabled = true
	guest_button.disabled = true
	create_account_button.disabled = true
	forgot_password_button.disabled = true
	feedback.text = "Connecting…"
	login_button.text = "Logging in..."

	var result := await Supabase.sign_in_user_or_email(
		username_or_email,
		password
	)

	if not result["ok"]:
		feedback.text = "Login failed: " + str(result["error"])
		guest_button.disabled = false
		create_account_button.disabled = false
		forgot_password_button.disabled = false

		login_button.disabled = false
		login_button.text = "➜ Log In"

		return

	IslandGame.select_profile(Supabase.user_id)
	var cfg := ConfigFile.new()
	cfg.set_value("login", "name", username_or_email if remember_check.button_pressed else "")
	cfg.save("user://login_preferences.cfg")

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
