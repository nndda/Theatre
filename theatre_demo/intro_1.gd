extends Control

# The Stage variable were defined here, so it can be accessible everywhere in this script.
# Stage use Dictionary of Nodes and UI elements used as its parameter,
# it needs to be initialized in _ready() or with @onready
@onready var stage = Stage.new({
    # Label node used to display the name of the speaker/narrator
    container_name = $DialogueContainer/MarginContainer/VBoxContainer/Name,
    # RichTextLabel node used to display the Dialogue body
    container_body = $DialogueContainer/MarginContainer/VBoxContainer/Body
})

# The Dialogue were also defined here too for convenience.
# You need to include `*.txt` in Project > Exports... > Resources
var epic_dialogue = Dialogue.load("res://theatre_demo/demo_dialogue.txt")

func _ready():
    # Run `Dialogue.start()` method to start the assigned dialogue.
    stage.start(epic_dialogue)

    # You might also want to hide dialogue UI when its finished,
    # and show it when its started.
    # The signal 'started' will be emitted when the dialogue started,
    # when the signal fired, the dialogue ui will be shown
    stage.started.connect( func():
        $DialogueContainer.show()
    )
    # Just like before, the 'finished' signal will be emitted when the dialogue is ended or aborted
    stage.resetted.connect( func(_step, _set): # `resetted` signal return 2 arguments
        $DialogueContainer.hide()
    )
    stage.finished.connect( func():
        $DialogueContainer.hide()
    )
    # In that code above we simply used show/hide method to toggle the UI
    # You can use the signal to start your custom animation or tween

# To progress the Dialogue in this example, we'll use _input(event)
# now, everytime "space" key is pressed, the dialogue will progress.
# You can always progress it with `Stage.progress()`
func _input(event):
    if event.is_action_pressed("space"):
        stage.progress()


# Demo scene stuff
# =============================================================================


@onready var start_button : Button = $StartButton

func _on_ready():
    start_button.pressed.connect(stage.start.bind(epic_dialogue))

func _process(_delta):
    start_button.disabled = stage.is_playing()
    start_button.visible = !stage.is_playing()
