extends Control

@export var stage : Stage
@export var progress_bar : ProgressBar
var tree : SceneTree

var dlg := Dialogue.load(
    "res://theatre_demo/preview/preview-advanced.dlg"
)
var dlg_chr_count : int

func _ready() -> void:
    tree = get_tree()
    # NOTE: Optimize resolution to create preview GIF image.
    # Require display/window/stretch/mode to be set to `disabled`
    #DisplayServer.window_set_size($ReferenceRect.size)

    dlg_chr_count = dlg._strip(stage.variables, true, true).length()
    progress_bar.value = 0
    progress_bar.max_value = 117
    print(dlg.humanize())

    stage.dialogue_label.character_drawn.connect(
        func():
            progress_bar.value += 1
    )

    # NOTE: Autoplay Dialogue
    #stage.dialogue_label.text_rendered.connect(progress_dlg)
    #stage.finished.connect(tree.quit)

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
            stage.progress()
        else:
            progress_bar.value = 0
            stage.start(dlg)
