extends Control

var recovery_token: String = ""
var requested_email: String = ""
var busy: bool = false
var completed: bool = false

func _ready() -> void:
	$EmailField.grab_focus()

func _on_send_pressed() -> void:
	if busy or completed:
		return
	var email: String = $EmailField.text.strip_edges()
	if not email.contains("@") or email.ends_with("@"):
		$StatusLabel.text = "Please enter a valid email address."
		return
	set_busy(true)
	$StatusLabel.text = "Sending your reset code..."
	var result: Dictionary = await Supabase.reset_password(email)
	if result.ok:
		requested_email = email
		recovery_token = ""
		$CodeField.text = ""
		$CodeField.show()
		$PasswordField.show()
		$ConfirmField.show()
		$ResetButton.show()
		$StatusLabel.text = "If that account exists, a code was sent. Check your email and spam folder."
		$SendButton.text = "Resend Code"
	else:
		$StatusLabel.text = str(result.error)
	set_busy(false)
	if result.ok:
		$CodeField.grab_focus()

func _on_reset_pressed() -> void:
	if busy or completed:
		return
	var code: String = $CodeField.text.strip_edges()
	var password: String = $PasswordField.text
	if code.is_empty():
		$StatusLabel.text = "Enter the code from your latest reset email."
		return
	if password.length() < 8:
		$StatusLabel.text = "Use a password with at least 8 characters."
		return
	if password != $ConfirmField.text:
		$StatusLabel.text = "The passwords do not match."
		return
	set_busy(true)
	$StatusLabel.text = "Updating your password..."
	if recovery_token.is_empty():
		var verified: Dictionary = await Supabase._request(HTTPClient.METHOD_POST,
			"/auth/v1/verify", {"email": requested_email, "token": code, "type": "recovery"})
		if not verified.ok:
			$StatusLabel.text = str(verified.error) + " Request a new code if it expired."
			set_busy(false)
			return
		if verified.data is Dictionary:
			recovery_token = str(verified.data.get("access_token", ""))
		if recovery_token.is_empty():
			$StatusLabel.text = "Verification failed. Request a new code."
			set_busy(false)
			return
	var headers := PackedStringArray(["Authorization: Bearer " + recovery_token])
	var result: Dictionary = await Supabase._request(HTTPClient.METHOD_PUT,
		"/auth/v1/user", {"password": password}, false, headers)
	if result.ok:
		completed = true
		recovery_token = ""
		$CodeField.text = ""
		$PasswordField.text = ""
		$ConfirmField.text = ""
		$StatusLabel.text = "Password updated! Go back and log in with your new password."
	else:
		if int(result.status) == 401 or int(result.status) == 403:
			recovery_token = ""
		$StatusLabel.text = str(result.error)
	set_busy(false)
	if completed:
		$BackButton.grab_focus()

func set_busy(value: bool) -> void:
	busy = value
	$SendButton.disabled = busy or completed
	$ResetButton.disabled = busy or completed
	$BackButton.disabled = busy
	$EmailField.editable = not busy and requested_email.is_empty()
	for field in [$CodeField, $PasswordField, $ConfirmField]:
		field.editable = not busy and not completed

func _on_back_pressed() -> void:
	if not busy:
		recovery_token = ""
		get_tree().change_scene_to_file("res://scenes/LoginScreen.tscn")
