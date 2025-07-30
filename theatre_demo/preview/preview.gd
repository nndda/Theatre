extends Control

# Script for the preview scene.
# NOTE: Want to see demo scene instead?
# Check out res://theatre_demo/1_intro.tscn

@export var stage : TheatreStage
@export var progress_bar : ProgressBar
@export var progress_label : RichTextLabel
var progress_label_tween : Tween
@export var restart_label : RichTextLabel

var tree : SceneTree

var dlg := Dialogue.load(
    "res://dialogue/preview-advanced.dlg"
)
var bbcode_regex := RegEx.new()

func _ready() -> void:
    restart_label.visible = false
    progress_label.modulate = Color.TRANSPARENT
    tree = get_tree()
    bbcode_regex.compile(DialogueParser.REGEX_BBCODE_TAGS)

    # NOTE: Optimize resolution to create preview GIF image.
    # Require display/window/stretch/mode to be set to `disabled`
    #DisplayServer.window_set_size($ReferenceRect.size)

    stage.dialogue_label.character_drawn.connect(_dialogue_label_character_drawn)

    # NOTE: Autoplay Dialogue
    #stage.dialogue_label.text_rendered.connect(progress_dlg)
    #stage.finished.connect(tree.quit)

    stage.progressed_at.connect(_stage_progressed_at)
    stage.start(dlg)

# NOTE: Autoplay Dialogue
#func progress_dlg(_text : String) -> void:
    #await tree.create_timer(2.8).timeout
    #stage.progress()

    # NOTE: Ends demo on specific line
    #if stage.get_line() == 1:
        #tree.quit()

# NOTE: Manual Dialogue control
func _input(event: InputEvent) -> void:
    if event.is_action_pressed(&"ui_accept"):
        if stage.is_playing():
            progress_label_tween = create_tween()\
                .set_trans(Tween.TRANS_EXPO)\
                .set_ease(Tween.EASE_OUT)\
                .set_parallel()
            progress_label_tween.tween_property(
                progress_label, ^"modulate", Color.TRANSPARENT, 0.45
            )
            progress_label_tween.tween_property(
                progress_label, ^"scale", Vector2(1.2, 1.2), 0.45
            )
            stage.progress()
        else:
            progress_bar.value = 0
            stage.start(dlg)

func _dialogue_label_character_drawn() -> void:
    progress_bar.value += 1.0

func _dialogue_label_text_rendered(_rendered_text: String) -> void:
    progress_label.scale = Vector2.ONE
    progress_label_tween = create_tween()\
        .set_trans(Tween.TRANS_EXPO)\
        .set_ease(Tween.EASE_OUT)
    progress_label_tween.tween_property(
        progress_label, ^"modulate", Color.WHITE, 0.45
    )

func _stage_progressed_at(_line : int, line_data : Dictionary) -> void:
    progress_bar.value = 0
    progress_bar.max_value = bbcode_regex.sub(
        line_data[DialogueParser.Key.CONTENT], "", true
    ).length()

func _stage_started() -> void:
    restart_label.visible = false

func _stage_finished() -> void:
    restart_label.visible = true

func _stage_cancelled() -> void:
    restart_label.visible = true
