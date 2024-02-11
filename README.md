# godot-theater

Text based linear dialogue system for Godot 4

> [!IMPORTANT]
> Make sure to include `*.txt` in the [resource options](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html#resource-options) when exporting your project, if you are using text files.

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

### Preparsing Dialogues

Parsing Dialogue files and string is slow. Its best to create them prior to loading your scene, so that they are created and ready to be used.

If you used text files, you can call `Dialogue.crawl()` at the start of your project, to preparse all of the Dialogue text files. Which then you can load as usual using `Dialogue.load()`

```gdscript
func _init():
    Dialogue.crawl()

func _ready():
    var story = Dialogue.load("res://story.txt")
```
