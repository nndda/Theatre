# Theatre

Text based linear dialogue system for Godot 4.

> [!NOTE]
> This project is currently in alpha stage and is subject to frequent changes and bugs.

# Features

## Literally just a text file

Human readable syntax and VCS friendly! edit it with your favourite editor, or directly in Godot script editor while keeping your codes and your story separate.
```
Dia:
    "The syntax is designed to be human-readable.
    Similar to languages like YAML."

Dia:
    "Although it's far more simplified and limited."

Dia:
    "You can also do things like calling
    functions, and variables."

```

## Dialogue tags

Get more control on how your dialogue flow with `{delay}` and `{speed}`.
```
Dia:
    "Hello!{delay = 0.7} nice to meet"
```

## Function calls

Connect your story to the game with function calls.
```
{player_name}:
    "Thanks! that feels so much better"
    Player => heal(20)
```

# Quick Start

Write your epic Dialogue!
```gdscript
# write it directly with triple quotation marks
var epic_dialogue = Dialogue.new("""

Dia:
   'Hello, world!'

""")

# alternatively, write it in a *.txt file, and load it
var epic_dialogue = Dialogue.load("res://epic_dialogue.txt")
```

Set the Stage! define the `Label` & `DialogueLabel` node to display your Dialogue
```gdscript
@onready var stage = Stage.new({
    actor_label = $Label,
    dialogue_label = $DialogueLabel
})

# and progress the Dialogue
func _input(event):
    if event.is_action_pressed("ui_accept"):
        stage.progress()
```

And finally, start the Stage
```gdscript
func _ready():
    stage.start(epic_dialogue)
```
