extends Control

@onready var stage : Stage = $Stage
@onready var progress_bar : ProgressBar = $PanelContainer/CenterContainer/VBoxContainer/ProgressBar

var dlg := Dialogue.load(
    "res://theatre_demo/preview/preview-advanced.dlg"
)
var dlg_chr_count : int

func _ready() -> void:
    dlg_chr_count = dlg._strip(stage.variables, true, true).length()
    progress_bar.value = 0
    progress_bar.max_value = dlg_chr_count
    print(dlg.humanize())

    stage.dialogue_label.character_drawn.connect(
        func():
            progress_bar.value += 1
    )

    stage.start(dlg)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed(&"ui_accept"):
        if stage.is_playing():
            stage.progress()
        else:
            progress_bar.value = 0
            stage.start(dlg)
