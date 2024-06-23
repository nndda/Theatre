extends Control


# This is a minimal Theatre setup to demonstrate the plugin's
# core and basic functions.


# Write your Dialogue, save it to a *.dlg file
# and load it with Dialogue.load()
var epic_dialogue = Dialogue.load('res://theatre_demo/base/demo_dialogue.dlg')


# In your scene, make sure you have:
# Label, and DialogueLabel node

# Add Stage node to your scene,
# and reference it in a variable.
@onready var your_stage = $Stage

# Click on your Stage node,
# and view the inspector.

# Assign the Label node to 'actor_label' property
# and the DialogueLabel node to 'dialogue_label' property.


# Set up a way to progress your Dialogue,
# here, we will be using input event.
func _input(event):
    # Enter / Space key
    if event.is_action_pressed('ui_accept'):
        your_stage.progress()
        # Call Stage.progress() to progress your Dialogue

# Now, everytime 'ui_accept' key is pressed,
# the dialogue should progress.

func _ready() -> void:
    # After that, you can then trigger
    # the Stage to start the Dialogue
    # using Stage.start()
    your_stage.start(epic_dialogue)
