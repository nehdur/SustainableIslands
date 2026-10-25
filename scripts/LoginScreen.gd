extends Control

@onready var username_field: LineEdit = $UsernameField
@onready var password_field: LineEdit = $PasswordField
@onready var login_button: Button = $LoginButton
@onready var create_account_button: Button = $CreateAccountButton
@onready var forgot_password_button: LinkButton = $ForgotPasswordButton
@onready var remember_check: CheckBox = $RememberCheck
@onready var feedback: Label = $FeedbackLabel
@onready var guest_button: Button = $GuestButton


func _ready() -> void:
	login_button.pressed.connect(_on_login_pressed)
	create_account_button.pressed.connect(_on_create_account_pressed)
	forgot_password_button.pressed.connect(_on_forgot_password_pressed)
	password_field.text_submitted.connect(_on_password_submitted)

	# GuestButton is already connected in the TSCN.
	var preferences := ConfigFile.new()

	if preferences.load("user://login_preferences.cfg") == OK:
		username_field.text = str(
			preferences.get_value("login", "name", "")
		)
		remember_check.button_pressed = not username_field.text.is_empty()


func _on_login_pressed() -> void:
	var username_or_email: String = username_field.text.strip_edges()
	var password: String = password_field.text

	if username_or_email.is_empty():
		feedback.text = "Please enter your username or email."
		return

	if password.is_empty():
		feedback.text = "Please enter your password."
		return

	set_busy(true)
	feedback.text = "Connecting..."

	var result: Dictionary = await Supabase.sign_in_user_or_email(
		username_or_email,
		password
	)

	if not result.get("ok", false):
		feedback.text = "Login failed: " + str(
			result.get("error", "Please try again.")
		)
		set_busy(false)
		return

	IslandGame.select_profile(Supabase.user_id)
	save_preferences(username_or_email)
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func set_busy(busy: bool) -> void:
	login_button.disabled = busy
	create_account_button.disabled = busy
	forgot_password_button.disabled = busy
	guest_button.disabled = busy
	username_field.editable = not busy
	password_field.editable = not busy
	remember_check.disabled = busy
	login_button.text = "Logging in..." if busy else "Log in"


func save_preferences(username_or_email: String) -> void:
	var preferences := ConfigFile.new()
	var saved_name: String = (
		username_or_email if remember_check.button_pressed else ""
	)

	preferences.set_value("login", "name", saved_name)
	preferences.save("user://login_preferences.cfg")


func _on_password_submitted(_text: String) -> void:
	if not login_button.disabled:
		_on_login_pressed()


func _on_create_account_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/CreateAccount.tscn")


func _on_forgot_password_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ForgotPassword.tscn")


func _on_guest_pressed() -> void:
	Supabase.sign_out()
	IslandGame.select_profile("guest")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
