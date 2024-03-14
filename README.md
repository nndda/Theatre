# godot-theater

Text based linear dialogue system for Godot 4.

> [!WARNING]
> This project is in alpha and still under development.

## Usage
Set the Stage! define the `Label` & `DialogueLabel` node to display your Dialogue
```gdscript
@onready var stage = Stage.new({
    actor_label = $DialogueContainer/Label,
    dialogue_label = $DialogueContainer/DialogueLabel
})
```

Write your epic Dialogue! Write it directly with triple quotation marks
```gdscript
var epic_dialogue = Dialogue.new("""

Dia:
   'Hello, world!'

""")
```

or write it in a `*.txt` file, and load it instead.
```gdscript
var epic_dialogue = Dialogue.load("res://epic_dialogue.txt")
```

Progress the Dialogue with your own method
```gdscript
func _input(event):
    if event.is_action_pressed("ui_accept"):
        stage.progress()
```

And start the Stage
```gdscript
func _ready():
    stage.start(epic_dialogue)
```

# Features

## Literally just a text file
Human readable syntax and VCS friendly! edit it with your favourite editor, or directly in Godot script editor while keeping your codes and your story separate.

## Dialogue tags
Control how your dialogue flow with `{delay}` and `{speed}`.

```
Dia:
    "Hello!{delay = 0.7} nice to meet you!"
```

## Function calls
Connect your story to the game with function calls.

```
{player_name}:
    "Thanks! that feels so much better"
    Player => heal(20)
```

