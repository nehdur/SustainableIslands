extends Node
## Persistent music plus sound players stored in IslandAudio.tscn.

@export var hover_sounds: bool = true

var muted: bool = false
var last_feedback_frame: int = -1
var last_hover_ms: int = -1000

@onready var music: AudioStreamPlayer = $Music
@onready var ambience: AudioStreamPlayer = $Ambience
@onready var effects: Node = $Effects


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    (music.stream as AudioStreamOggVorbis).loop = true
    (ambience.stream as AudioStreamOggVorbis).loop = true
    music.play()
    ambience.play()
    set_muted(IslandGame.muted)

    # Connect existing and future buttons, including TextureButtons.
    get_tree().node_added.connect(_connect_button)
    _connect_existing(get_tree().root)


func set_muted(value: bool) -> void:
    muted = value
    music.stream_paused = muted
    ambience.stream_paused = muted
    if muted:
        for player in effects.get_children():
            player.stop()


func play_sfx(sound_name: String) -> void:
    if muted:
        return
    var player := effects.get_node_or_null(sound_name) as AudioStreamPlayer
    if player == null:
        return
    player.play()
    if sound_name != "hover":
        last_feedback_frame = Engine.get_process_frames()


func _connect_existing(node: Node) -> void:
    _connect_button(node)
    for child in node.get_children():
        _connect_existing(child)


func _connect_button(node: Node) -> void:
    if node is BaseButton:
        var button := node as BaseButton
        if not button.pressed.is_connected(_on_button_pressed):
            button.pressed.connect(_on_button_pressed, CONNECT_DEFERRED)
            button.mouse_entered.connect(_on_button_hover.bind(button))


func _on_button_pressed() -> void:
    # A build/upgrade sound already confirms that same button press.
    if last_feedback_frame != Engine.get_process_frames():
        play_sfx("click")


func _on_button_hover(button: BaseButton) -> void:
    if not hover_sounds or button.disabled:
        return
    var now: int = Time.get_ticks_msec()
    if now - last_hover_ms >= 120:
        play_sfx("hover")
        last_hover_ms = now
