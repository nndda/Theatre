# godot-theater

Text based linear dialogue system for Godot 4

## Usage
Set the Stage! define the `Label` & `RichTextLabel` node to display your Dialogue
```gdscript
@onready var stage = Stage.new({
    container_name = $DialogueContainer/Name,
    container_body = $DialogueContainer/Body
})
```

Write your epic Dialogue! Write it directly with triple quotation marks, or write it in a *.txt file, and load it.
```gdscript
var epic_dialogue = Dialogue.new("""

character_name
   'You can write the dialogue directly like this'

character_name
   'Or use *.txt files'

""")
```

And start the Theatre
```gdscript
func _ready():
    stage.start(epic_dialogue)
```
