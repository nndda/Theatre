extends Control

var stage = Stage.new({
    container_name = $DialogueContainer/MarginContainer/VBoxContainer/Name,
    container_body = $DialogueContainer/MarginContainer/VBoxContainer/Body
})
var epic_dialogue : Dialogue

# Loading Dialogue resources via `Dialogue.new()` can take some time depending on how long the text file is.
# You can use `Dialogue.crawl()' to preload all the Dialogue files in your project.
# Which then you can access through `Dialogue.load()` a lot faster.
func _init():
    Dialogue.crawl()

# NOTE: Its best to call `Dialogue.crawl()` at the start of the project

func _ready():
    epic_dialogue = Dialogue.load("res://theatre_demo/demo_dialogue.txt")

    stage.start(epic_dialogue)


    stage.started.connect( func():
        $DialogueContainer.show()
    )
    stage.resetted.connect( func(_step, _set):
        $DialogueContainer.hide()
    )
    stage.finished.connect( func():
        $DialogueContainer.hide()
    )

func _input(event):
    if event.is_action_pressed("space"):
        stage.progress()

    # In some cases, you might want the player to be able to end the Dialogue whenever they want.
    # `Stage.reset()` can be used to end the current Dialogue and reset everything
    if event.is_action_pressed("esc"):
        stage.reset()


# Demo scene stuff
# =============================================================================


@onready var start_button : Button = $StartButton

func _on_ready():
    start_button.pressed.connect(stage.start.bind(epic_dialogue))

func _process(_delta):
    start_button.disabled = stage.is_playing()
    start_button.visible = !stage.is_playing()
