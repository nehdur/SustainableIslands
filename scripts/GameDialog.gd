extends Control
## Dialog controls are editable nodes in GameDialog.tscn.
signal action_requested(kind: String)
signal end_day_confirmed

@onready var panel: Panel = %DialogPanel
@onready var title_label: Label = %DialogTitle
@onready var message_label: RichTextLabel = %DialogMessage
@onready var action_choices: Control = %ActionChoices
@onready var confirm_button: Button = %ConfirmDayButton
@onready var cleanup_button: Button = %CleanupAction
@onready var supplies_button: Button = %SuppliesAction
@onready var culture_button: Button = %CultureAction

func open(title: String, message: String, height: int = 690, mode: String = "info") -> void:
	title_label.text = title
	message_label.text = message
	var dialog_height := clampi(height, 540, 800)
	if mode == "actions":
		dialog_height = maxi(dialog_height, 700)
	panel.offset_top = -dialog_height / 2.0
	panel.offset_bottom = dialog_height / 2.0
	action_choices.visible = mode == "actions"
	confirm_button.visible = mode == "confirm"
	message_label.offset_bottom = -410.0 if mode == "actions" else (-236.0 if mode == "confirm" else -156.0)
	message_label.scroll_to_line(0)
	show()
	%CloseDialogButton.grab_focus()

func close() -> void:
	hide()

func _on_action_pressed(kind: String) -> void:
	action_requested.emit(kind)

func _on_end_day_pressed() -> void:
	end_day_confirmed.emit()
