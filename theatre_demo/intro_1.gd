extends Node2D

# The Stage variable were defined here, so it can be accessible everywhere in this script.
# Since Stage use Nodes as parameter, it needs to be initialized in _ready() or with @onready
@onready var stage = Stage.new({
    container_name = $DialogueContainer/MarginContainer/VBoxContainer/Name,
    container_body = $DialogueContainer/MarginContainer/VBoxContainer/Body
})

# The Dialogue were also defined here too for convenience.
# You need to include `*.txt` in Project > Exports... > Resources
var epic_dialogue = Dialogue.new("res://demo/demo_dialogue.en.txt")

func _ready():
    stage.start(epic_dialogue)

    # You might also want to hide or show the dialogue UI when its started or finished.
    # The 'started' emitted when the dialogue started,
    # when the signal fired, the dialogue ui will be shown
    #stage.started.connect( func():
        #$DialogueContainer.show()
    #)
    # And we'll hide the UI when its finished
    #stage.finished.connect( func():
        #$DialogueContainer.hide()
    #)

# To progress the dialogue, we'll use _input(event)
# now, everytime "ui_accept" is pressed, the dialogue will progress.
# You can always progress it with Stage.progress()
func _input(event):
    if event.is_action_pressed("ui_accept"):
        stage.progress()
