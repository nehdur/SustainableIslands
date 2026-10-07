extends Control
signal selected(key: String)
const POINTS := {"guesthouse":Vector2(500,304),"hotel":Vector2(769,268),"market":Vector2(341,470),"culture":Vector2(646,540),"forest":Vector2(340,220),"reef":Vector2(986,603),"waste":Vector2(862,436),"utilities":Vector2(627,207)}
var markers: Dictionary = {}
var selected_key := "guesthouse"
var clock := 0.0
var boat: TextureRect

func _ready() -> void:
 clip_contents = true
 IslandUI.texture(self,"res://assets/island/island_map.svg",Rect2(0,0,1200,800))
 for key in POINTS:
  var pos: Vector2 = POINTS[key]
  var box := Control.new()
  box.position = pos - Vector2(65,95)
  add_child(box)
  var sprite := IslandUI.texture(box,"res://assets/island/%s.svg" % key,Rect2(0,0,130,130))
  var title: String = IslandGame.FACILITIES[key].title if IslandGame.FACILITIES.has(key) else ("Mangrove Forest" if key == "forest" else "Coral Sanctuary")
  var btn := IslandUI.button(box,title,Rect2(-35,115,205,44),func():
   selected_key = key
   selected.emit(key)
   refresh()
  )
  btn.add_theme_font_size_override("font_size",18)
  btn.tooltip_text = "Explore " + title
  var status := IslandUI.label(box,"",Rect2(-30,163,205,26),17,Color("23464a"))
  status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  markers[key] = {"sprite":sprite,"button":btn,"status":status}
 boat = IslandUI.texture(self,"res://assets/island/boat.svg",Rect2(20,600,106,106))
 IslandGame.changed.connect(refresh)
 refresh()

func refresh() -> void:
 for key in markers:
  var m: Dictionary = markers[key]
  m.button.modulate = Color("fff0c6") if key == selected_key else Color.WHITE
  if IslandGame.FACILITIES.has(key):
   var level := int(IslandGame.data.buildings[key])
   m.sprite.modulate = Color(1,1,1,0.45) if level == 0 else Color.WHITE
   m.status.text = "Build site" if level == 0 else "Lv.%d  •  %s" % [level,"Open" if IslandGame.active(key) else "Needs workers"]
  else:
   m.status.text = "Health %d / 100" % int(IslandGame.data.forest if key == "forest" else IslandGame.data.marine)

func _process(delta: float) -> void:
 clock += delta
 boat.position = Vector2(70 + sin(clock * 0.15) * 38, 617 + sin(clock * 1.4) * 4)
 queue_redraw()

func _draw() -> void:
 # Tiny visitors walk the village paths; their count follows tourism activity.
 var count := mini(10, int(IslandGame.data.visitors))
 for i in range(count):
  var t := fmod(clock * 0.035 + i * 0.095, 1.0)
  var p := Vector2(358,460).lerp(Vector2(828,431),t)
  p.y += sin(t * PI) * -55 + (i % 3) * 9
  draw_circle(p + Vector2(0,6),5,Color("577d68"))
  draw_circle(p,4,Color("f5dfb3"))
