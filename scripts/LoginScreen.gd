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
	var username := username_field.text.strip_edges()
	var password := password_field.text

	if username.is_empty() or password.is_empty():
		print("Please enter both a username and a password.")
		return

	# TODO: replace this with your real authentication logic
	print("Logging in as: %s (remember me: %s)" % [username, remember_check.button_pressed])
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _on_create_account_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/CreateAccount.tscn")


func _on_forgot_password_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ForgotPassword.tscn")
