extends Control
## Every location and its level textures/sizes are editable in IslandMap.tscn.
signal selected(key: String)

var selected_key: String = "guesthouse"
var clock: float = 0.0
var editor_icons: Dictionary = {}
@onready var locations: Control = $Locations
@onready var boat: TextureRect = $Boat

func _ready() -> void:
    # Remember the artwork position and size set in the editor.
    for button in locations.get_children():
        var icon: TextureRect = button.get_node("Icon")
        editor_icons[str(button.get_meta("location_key"))] = {
            "size": icon.size, "position": icon.position
        }
    IslandGame.changed.connect(refresh)
    refresh()

func select_location(key: String) -> void:
    set_selection(key)
    selected.emit(key)

func set_selection(key: String) -> void:
    selected_key = key
    refresh()

func get_location_texture(key: String) -> Texture2D:
    for button in locations.get_children():
        if str(button.get_meta("location_key")) != key:
            continue
        var textures: Array = button.get_meta("level_textures", [])
        if textures.is_empty():
            return button.get_node("Icon").texture
        var level: int = int(IslandGame.data.buildings.get(key, 1))
        return textures[clampi(level - 1, 0, textures.size() - 1)]
    return null

func refresh() -> void:
    for child in locations.get_children():
        var button: Button = child as Button
        var key: String = str(button.get_meta("location_key"))
        var icon: TextureRect = button.get_node("Icon") as TextureRect
        button.set_pressed_no_signal(key == selected_key)
        if IslandGame.FACILITIES.has(key):
            var level: int = int(IslandGame.data.buildings[key])
            var level_sizes: Array = button.get_meta("level_sizes")
            var artwork_size: Vector2 = level_sizes[clampi(level - 1, 0, level_sizes.size() - 1)]
            icon.texture = get_location_texture(key)
            var base: Dictionary = editor_icons[key]
            var first_level_size: Vector2 = level_sizes[0]
            # Grow relative to the editor size, keeping the building's feet fixed.
            icon.size = base.size * artwork_size / first_level_size
            var growth: Vector2 = (icon.size - base.size) * icon.scale
            icon.position = base.position - Vector2(growth.x / 2.0, growth.y)
            icon.visible = level > 0
            button.get_node("PlotMarker").visible = level == 0
            var badge: Panel = button.get_node("LevelPlate")
            var badge_label: Label = button.get_node("LevelLabel")
            badge.visible = level > 0
            badge_label.visible = level > 0
            badge.position = Vector2(button.size.x - 44.0, maxf(0.0, icon.position.y + 4.0))
            badge_label.position = badge.position
            badge_label.text = "L%d" % level
            var state := "Build site" if level == 0 else ("Open" if IslandGame.active(key) else "Needs workers")
            button.tooltip_text = "%s • Level %d • %s" % [IslandGame.FACILITIES[key].title, level, state]
        else:
            var forest: bool = key == "forest"
            button.tooltip_text = "%s • Health %d / 100" % ["Mangrove Forest" if forest else "Coral Sanctuary", IslandGame.data.forest if forest else IslandGame.data.marine]

func _process(delta: float) -> void:
    clock += delta
    boat.position = Vector2(size.x * 0.06 + sin(clock * 0.15) * 20, size.y * 0.78 + sin(clock * 1.4) * 4)
