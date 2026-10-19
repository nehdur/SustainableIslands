extends RefCounted

const CREAM: Color = Color("#f7f3e7")
const GREEN: Color = Color("#376f60")
const PALE: Color = Color("#e4e8d8")
const INK: Color = Color("#233f43")
const MUTED: Color = Color("#617a78")


static func apply(root: Node) -> void:
	if root is Panel or root is PanelContainer:
		var panel: Control = root as Control
		var style: StyleBoxFlat = copy_style(panel, "panel")

		style.bg_color = CREAM
		panel.add_theme_stylebox_override("panel", style)

	elif root is LineEdit:
		var field: LineEdit = root as LineEdit

		for state in ["normal", "focus", "read_only"]:
			var style: StyleBoxFlat = copy_style(field, "normal")

			style.bg_color = Color("#eef1e5")
			style.border_color = (
				GREEN if state == "focus"
				else Color("#cad6c4")
			)

			field.add_theme_stylebox_override(state, style)

		field.add_theme_color_override("font_color", INK)
		field.add_theme_color_override(
			"font_uneditable_color", MUTED
		)
		field.add_theme_color_override(
			"font_placeholder_color", MUTED
		)
		field.add_theme_color_override("caret_color", GREEN)
		field.add_theme_color_override(
			"selection_color", Color("#b8cdb0")
		)
		field.add_theme_color_override("font_selected_color", INK)

	elif root is CheckBox:
		var check: CheckBox = root as CheckBox

		for state in [
			"normal", "hover", "pressed",
			"hover_pressed", "disabled"
		]:
			check.add_theme_stylebox_override(
				state, StyleBoxEmpty.new()
			)

		for state in [
			"font_color",
			"font_hover_color",
			"font_pressed_color",
			"font_hover_pressed_color"
		]:
			check.add_theme_color_override(state, INK)

	elif root is LinkButton:
		var link: LinkButton = root as LinkButton

		link.add_theme_color_override("font_color", GREEN)
		link.add_theme_color_override("font_hover_color", INK)
		link.add_theme_color_override("font_pressed_color", INK)

	elif root is Button:
		paint_button(root as Button)

	elif root is Label:
		var label: Label = root as Label
		var name_lower: String = str(label.name).to_lower()

		var text_color: Color = (
			MUTED
			if "subtitle" in name_lower or name_lower == "orlabel"
			else INK
		)

		label.add_theme_color_override("font_color", text_color)

	elif root is ColorRect:
		var background: ColorRect = root as ColorRect
		background.color = Color("#e8eddf")

	for child in root.get_children():
		apply(child)


static func copy_style(
	control: Control,
	style_name: String
) -> StyleBoxFlat:
	var original: StyleBox = control.get_theme_stylebox(style_name)

	if original is StyleBoxFlat:
		return original.duplicate() as StyleBoxFlat

	return StyleBoxFlat.new()


static func paint_button(button: Button) -> void:
	var primary: bool = str(button.name) in [
		"LoginButton",
		"CreateButton",
		"SendButton",
		"PlayButton",
		"ContinueIsland"
	]

	var caption: String = button.text.to_lower()

	primary = (
		primary
		or caption.begins_with("continue island")
		or caption == "view season results"
	)

	var colors: Dictionary = {
		"normal": GREEN if primary else PALE,
		"hover": (
			Color("#488b74") if primary
			else Color("#d6e1c5")
		),
		"pressed": (
			Color("#294f46") if primary
			else Color("#b8cdb0")
		),
		"disabled": Color("#dce0d6")
	}

	for state in colors:
		var style: StyleBoxFlat = copy_style(button, "normal")

		style.bg_color = colors[state]
		style.border_color = Color("#cad6c4")

		button.add_theme_stylebox_override(state, style)

	for state in [
		"font_color",
		"font_hover_color",
		"font_pressed_color",
		"font_focus_color"
	]:
		button.add_theme_color_override(
			state, CREAM if primary else INK
		)

	button.add_theme_color_override("font_disabled_color", MUTED)
