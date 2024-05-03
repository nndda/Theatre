---
hide:
  - navigation
---

# Quick Start

You've installed the plugin. You had the characters, plot, and the worldbuilding of your story ready, or maybe not, thats ok too.
Lets start with writing the `Dialogue`.

## Writing the Dialogue

Create a new text file in your project. And write your dialogue with the following syntax:

```
Actor name:
    "The syntax is similar to languages like YAML"

Actor name:
    "You just need the character or actor's name,
    with `:` at the end"

Actor name:
    "and the dialogue body indented"

Actor name:
    The quotation marks is also entirely optional

# You can also comment using (#) symbol
```

In this example, we'll save the file as `res://intro.dlg.txt`. Now that the `Dialogue` is ready, lets set up the `Stage`.

[More on writing Dialogue here.](../classes/dialogue/syntax)

!!! important

    Dialogue resource are saved with the file extension `*.dlg.txt`

## Setting up the Stage

Create a new 2D scene. And add `Label`, and `DialogueLabel` node.

To tidy things up a little, we'll put those two inside a `PanelContainer`. Here's what the current scene should looks like:

```
- YourScene
  \- PanelContainer
      |- Label
      \- DialogueLabel
```

Attach a script to your scene's root. And create a `Stage` variable with `@onready` keyword.

```gdscript
@onready var stage = Stage.new()
```

Reference the `Label` and `DialogueLabel` node we made before as the arguments, written inside a dictionary:

```gdscript
@onready var stage = Stage.new({
    'actor_label': $PanelContainer/Label,
    'dialogue_label': $PanelContainer/DialogueLabel
})
```

### Starting

Now, lets create another variable to store the Dialogue. Use `Dialogue.load()` and pass the absolute path of the text file as the parameter:

```gdscript
var intro = Dialogue.load('res://intro.txt')
```

After that, you can start it with `Stage.start()` method:

```gdscript
func _ready():
    stage.start(intro)
```

Now the Dialogue will start when you play the scene. And thats it!... or is it?

Something doesn't feel right. You can't progress the dialogue no matter what key you pressed.

### Progressing

The `Stage.progress()` does exactly what it says. You have to trigger the progress manually. In this example, we'll use `_input(event)` and Godot's default action key `'ui_accept'` (space/enter key).

```gdscript
func _input(event):
    if event.is_action_pressed('ui_accept'):
        stage.progress()
```

Now, everytime `'ui_accept'` key is pressed, the Dialogue should progress.

## Additional stuff

### Toggling the UI

You might want to only show the UI when theres a Dialogue running, and hide it when the Dialogue ends.

`Stage` class is also equipped with signals such as `started`, `finished`, and `progressed` that are pretty self-explanatory.

We'll connect these signals in `_ready()` before starting the Dialogue. And just call the method `show` and `hide` on the parents UI Node `$PanelContainer`:

```gdscript
func _ready():
    stage.started.connect(
        $PanelContainer.show
    )
    stage.finished.connect(
        $PanelContainer.hide
    )

    stage.start(intro)
```

In this example, we only used `show` and `hide` method for simplicity. You can use `AnimationPlayer` or `Tween` for more fancy transition.

## Summary

And, thats it!

Here is the finalized script of the scene:
```gdscript
extends Node2D

@onready var stage = Stage.new({
    'actor_label' : $PanelContainer/Label,
    'dialogue_label' : $PanelContainer/DialogueLabel
})

var intro = Dialogue.load('res://intro.txt')

func _input(event):
    if event.is_action_pressed('ui_accept'):
        stage.progress()

func _ready():
    stage.started.connect(
        $PanelContainer.show
    )
    stage.finished.connect(
        $PanelContainer.hide
    )

    stage.start(intro)
```

## Next step

More about writing you `Dialogue` on [Dialogue syntax](../classes/dialogue/syntax) page.