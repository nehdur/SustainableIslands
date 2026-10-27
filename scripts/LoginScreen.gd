extends Control

@onready var username_field: LineEdit = $UsernameField
@onready var password_field: LineEdit = $PasswordField
@onready var login_button: Button = $LoginButton
@onready var remember_check: CheckBox = $RememberCheck
@onready var feedback: Label = $FeedbackLabel

func _ready() -> void:
	var preferences := ConfigFile.new()
	if preferences.load("user://login_preferences.cfg") == OK:
		username_field.text = str(preferences.get_value("login", "name", ""))
		remember_check.button_pressed = not username_field.text.is_empty()

func _on_login_pressed() -> void:
	if login_button.disabled:
		return
	var login_name := username_field.text.strip_edges()
	if login_name.is_empty() or password_field.text.is_empty():
		feedback.text = "Enter your username or email and password."
		return
	set_busy(true)
	feedback.text = "Connecting..."
	var result: Dictionary = await Supabase.sign_in_user_or_email(login_name, password_field.text)
	if not result.ok:
		feedback.text = "Login failed: " + str(result.error)
		set_busy(false)
		return
	var preferences := ConfigFile.new()
	preferences.set_value("login", "name", login_name if remember_check.button_pressed else "")
	preferences.save("user://login_preferences.cfg")
	IslandGame.select_profile(Supabase.user_id)
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func set_busy(busy: bool) -> void:
	for button in [login_button, $CreateAccountButton, $ForgotPasswordButton, $GuestButton, remember_check]:
		button.disabled = busy
	username_field.editable = not busy
	password_field.editable = not busy
	login_button.text = "Logging in..." if busy else "Log in"

func _on_password_submitted(_text: String) -> void:
	_on_login_pressed()

func _on_create_account_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/CreateAccount.tscn")

func _on_forgot_password_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ForgotPassword.tscn")

func _on_guest_pressed() -> void:
	Supabase.sign_out()
	IslandGame.select_profile("guest")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
