extends Control

@onready var username_field: LineEdit = $UsernameField
@onready var email_field: LineEdit = $EmailField
@onready var password_field: LineEdit = $PasswordField
@onready var confirm_field: LineEdit = $ConfirmPasswordField
@onready var create_button: Button = $CreateButton
@onready var back_button: Button = $BackButton
@onready var status_label: Label = $StatusLabel


func _on_create_pressed() -> void:
	var username := username_field.text.strip_edges()
	var email := email_field.text.strip_edges()
	var password := password_field.text

	if username.is_empty():
		status_label.text = "Please enter a username."
		return

	if not email.contains("@"):
		status_label.text = "Please enter a valid email address."
		return

	if password.length() < 6:
		status_label.text = "Password must be at least 6 characters."
		return

	if password != confirm_field.text:
		status_label.text = "Passwords do not match."
		return

	set_busy(true)
	status_label.text = "Creating your account..."

	var result: Dictionary = await Supabase.sign_up(
		email, password, username
	)

	set_busy(false)

	if not result.get("ok", false):
		status_label.text = "Signup failed: %s" % result.get(
			"error", "Please try again."
		)
		return

	if Supabase.is_logged_in():
		IslandGame.select_profile(Supabase.user_id)
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	else:
		status_label.text = "Account created! Check your email, then log in."


func set_busy(busy: bool) -> void:
	create_button.disabled = busy
	back_button.disabled = busy
	username_field.editable = not busy
	email_field.editable = not busy
	password_field.editable = not busy
	confirm_field.editable = not busy
	create_button.text = "Creating..." if busy else "Create Account"


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LoginScreen.tscn")
