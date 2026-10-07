class_name IslandUI
extends RefCounted
const INK := Color("233f43")
const MUTED := Color("617a78")
const CREAM := Color("f7f3e7")
const GREEN := Color("376f60")

static func style(color: Color, radius: int = 18, padding: int = 16) -> StyleBoxFlat:
 var s := StyleBoxFlat.new()
 s.bg_color = color
 s.set_corner_radius_all(radius)
 s.content_margin_left = padding
 s.content_margin_right = padding
 s.content_margin_top = padding
 s.content_margin_bottom = padding
 return s

static func panel(parent: Node, rect: Rect2, color: Color = CREAM) -> Panel:
 var p := Panel.new()
 p.position = rect.position
 p.size = rect.size
 p.add_theme_stylebox_override("panel", style(color))
 parent.add_child(p)
 return p

static func label(parent: Node, text: String, rect: Rect2, font_size: int = 24, color: Color = INK) -> Label:
 var l := Label.new()
 l.text = text
 l.position = rect.position
 l.size = rect.size
 l.add_theme_font_size_override("font_size", font_size)
 l.add_theme_color_override("font_color", color)
 l.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(l)
 return l

static func button(parent: Node, text: String, rect: Rect2, callback: Callable, primary: bool = false) -> Button:
 var b := Button.new()
 b.text = text
 b.position = rect.position
 b.size = rect.size
 b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 b.add_theme_font_size_override("font_size", 24)
 b.add_theme_color_override("font_color", CREAM if primary else INK)
 b.add_theme_color_override("font_hover_color", CREAM if primary else INK)
 b.add_theme_color_override("font_pressed_color", CREAM if primary else INK)
 b.add_theme_color_override("font_disabled_color", Color("87948a"))
 b.add_theme_stylebox_override("normal", style(GREEN if primary else Color("e4e8d8"),12,12))
 b.add_theme_stylebox_override("hover", style(Color("488b74") if primary else Color("d6e1c5"),12,12))
 b.add_theme_stylebox_override("pressed", style(Color("2c594f") if primary else Color("b8cdb0"),12,12))
 b.add_theme_stylebox_override("disabled", style(Color("dce0d6"),12,12))
 var focus := style(Color(0,0,0,0),12,12)
 focus.set_border_width_all(3)
 focus.border_color = Color("dba15e")
 b.add_theme_stylebox_override("focus",focus)
 b.pressed.connect(callback)
 parent.add_child(b)
 return b

static func texture(parent: Node, path: String, rect: Rect2) -> TextureRect:
 var t := TextureRect.new()
 t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 t.texture = load(path)
 t.position = rect.position
 t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 t.size = rect.size
 t.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(t)
 return t

static func paragraph(parent: Node, text: String, rect: Rect2, font_size: int = 24) -> Label:
 var l := Label.new()
 l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 l.text = text
 l.position = rect.position
 l.add_theme_font_size_override("font_size",font_size)
 l.add_theme_color_override("font_color",INK)
 l.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(l)
 l.size = rect.size
 return l
