extends Control


# This is a minimal Theatre setup to demonstrate the plugin's
# core and basic functions.


# Write your Dialogue, save it as a *.dlg file
# and load it using Dialogue.load()
var epic_dialogue = Dialogue.load('res://dialogue/demo_dialogue.dlg')


# In your scene, make sure you have:
# a Label and a DialogueLabel node.

# Add TheatreStage node to your scene,
# and reference it in a variable.
@onready var your_stage = $TheatreStage

# Click on your TheatreStage node,
# and view the inspector.

# Assign the Label node to 'actor_label' property
# and the DialogueLabel node to 'dialogue_label' property.

# Set up a way to progress your Dialogue.
# Here, we will use an input event.
func _input(event):
    # Enter / Space key
    if event.is_action_pressed('ui_accept'):
        your_stage.progress()
        # Call TheatreStage.progress() to progress your Dialogue

# Now, everytime 'ui_accept' key is pressed,
# the Dialogue should progress.

func _ready() -> void:
    # After that, you can then trigger
    # the TheatreStage to start the Dialogue
    # using TheatreStage.start()
    your_stage.start(epic_dialogue)
