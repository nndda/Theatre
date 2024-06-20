# Theatre

Text-based linear dialogue system for Godot 4. Literally just a text file! Written in human-readable syntax and VCS-friendly. Edit it with your favourite editor or directly in Godot script editor while keeping your codes and story separate.

> [!NOTE]
> This project is currently in its alpha stage and is subject to frequent and breaking changes, and bugs.
```
Dia:
    "Welcome! {d=0.8}to the
    [fx1]Theatre[/fx1]!
        d=0.9
    a text-based dialogue system
        d=0.3
    developed for Godot {gd_ver}
        d=0.8
    [fx3](well,{d = 0.8} 4.3 specifically)[/fx3]."


    ＼(^ ▽ ^)

```

# Features

## Dialogue tags

Fine-tune your dialogue flow with `{delay}` and `{speed}`.
```
Godette:
    "Hello!{delay = 0.7} nice to meet you"
```

## Function calls

Connect your story to the game with function calls.
```
{player_name}:
    "Thanks! that feels so much better"

    Player.heal(20)
```

Call functions only at specific points in the Dialogue.
```
Dia:
    "Let me just...{d = 0.7}
    set the mood a little...{1.2}
    {0}there we go"

# Call this function using its index: {0}
    Environment.brightness(0.8)
```

# Quick Start

Write your epic Dialogue!
```gdscript
# write it directly with triple quotation marks
var epic_dialogue = Dialogue.new("""

Dia:
    "For performance reason, I'd recommend
    using the method below instead."

""")

# alternatively, write it in a *.dlg.txt or *.dlg  file, and load it
var epic_dialogue = Dialogue.load("res://epic_dialogue.dlg")
```

Set the Stage! Create a `Stage` node, and reference the `Label` & `DialogueLabel` node to display your Dialogue. Adjust and configure your `Stage` via the inspector. Alternatively, you can also set them in script:
```gdscript
@onready var stage : Stage = $Stage

func _ready():
    stage.allow_cancel = false
    stage.allow_skip = false
    stage.allow_func = true
    stage.speed_scale = 1.0
```

Progress your Dialogue with `Stage.progress()`.
```
func _input(event):
    if event.is_action_pressed("ui_accept"):
        stage.progress()
```

And finally, start the Stage
```gdscript
    stage.start(epic_dialogue)
```
