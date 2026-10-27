extends Control

@onready var reset_dialog: Control = $ResetDialog

func _ready() -> void:
	var profile := Supabase.user_id if Supabase.is_logged_in() else "guest"
	if IslandGame.profile != profile:
		IslandGame.select_profile(profile)
	set_busy(true)
	$StatusLabel.text = await IslandGame.cloud_load()
	var notice: String = IslandGame.storage_notice
	if not notice.is_empty() and notice != "Saved on this device":
		$StatusLabel.text += "\n" + notice
	$ContinueButton.text = ("View Season Results" if IslandGame.data.finished
		else "Continue Island • Day %d" % IslandGame.data.day)
	set_busy(false)

func set_busy(busy: bool) -> void:
	for button in [$ContinueButton, $StartButton, $BackButton, $QuitButton]:
		button.disabled = busy

func play() -> void:
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func confirm_new() -> void:
	set_busy(true)
	reset_dialog.show()
	$ResetDialog/DialogPanel/CancelButton.grab_focus()

func cancel_new() -> void:
	reset_dialog.hide()
	set_busy(false)
	$StartButton.grab_focus()

func _on_start_confirmed() -> void:
	IslandGame.reset()
	IslandGame.save_local()
	play()

func logout() -> void:
	Supabase.sign_out()
	IslandGame.select_profile("guest")
	get_tree().change_scene_to_file("res://scenes/LoginScreen.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _unhandled_key_input(event: InputEvent) -> void:
	if reset_dialog.visible and event.is_action_pressed("ui_cancel"):
		cancel_new()
		get_viewport().set_input_as_handled()
