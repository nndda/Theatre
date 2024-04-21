extends Control

# The Stage variable is defined here, so it can be accessible everywhere in this script.

# Stage use Dictionary of nodes and UI elements used as its parameter,
# so it needs to be initialized in _ready() or with @onready.
@onready var stage = Stage.new({

    # Label node used to display the speaker/narrator name.
    actor_label = $DialogueContainer/MarginContainer/VBoxContainer/Name,

    # DialogueLabel node used to display the Dialogue body.
    dialogue_label = $DialogueContainer/MarginContainer/VBoxContainer/Body

})

# The Dialogue is also defined here too.
var epic_dialogue = Dialogue.load('res://theatre_demo/demo_dialogue.dlg.txt')

func _ready():
    # Run Stage.start() method to start a dialogue.
    stage.start(epic_dialogue)

    # You might also want to hide the dialogue UI when its finished,
    # and only show it when its started.

    # Here, we will connect a few signals from our Stage.

    # The signal 'started' will be emitted when the dialogue started,
    # when the signal fired, the dialogue ui will be shown
    stage.started.connect( func():
        $DialogueContainer.show()
    )

    # The 'finished' and `resetted` signal will be emitted when the dialogue is ended or aborted
    stage.finished.connect( func():
        $DialogueContainer.hide()
    )
    stage.resetted.connect( func(_step, _set): # `resetted` signal return 2 arguments
        $DialogueContainer.hide()
    )

    # In that code above we simply used show/hide method to toggle the UI
    # You can use the signal to start your custom animation or tween

# To progress the Dialogue, in this example, we'll use _input(event).
func _input(event):
    # Now, everytime 'space' key is pressed, the dialogue will progress.
    if event.is_action_pressed("space"):
        stage.progress()
    # And everytime 'esc' key is pressed, the dialogue will be aborted.
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
