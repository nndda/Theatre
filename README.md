# godot-theater

Text based linear dialogue system for Godot 4

### Usage

```gdscript
# Define Label and RichTextLabel node
@onready var stage = Stage.new({
    container_name = $DialogueContainer/Name,
    container_body = $DialogueContainer/Body
})

# Write your epic dalogue
var epic_dialogue = Dialogue.new("""
character_name
   'You can write the dialogue directly like this'

character_name
   'Or load it with *.txt files'
""")

func _ready():
	# Start the dialogue
	stage.start(epic_dialogue)

```
